// Change Orbit of Current Ship

declare parameter alt_new.

// Target Velocity in new orbit to get a rough idea of scale
set v_target to sqrt(body:MU/(body:Radius + alt_new)).
set max_acc to ship:maxthrust/ship:mass.
set t to abs( (v_target-ship:velocity:orbit:mag)/max_acc).

set throttle_max to MIN(1.0, MAX(0.01, t/30)).
set maxburn to t/throttle_max/2.

print "Change to new Circular Orbit v0.1".
print "target altitude: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis).
print "target velocity: "+floor(v_target)+" m/s".
print "buffer time    : "+maxburn.
print "est. throttle  : "+throttle_max.

function timed_turn {
  parameter v.
  parameter t.
  lock steering to v.
  set warpmode to "physics".
  set warp to 3.
  wait t.
  kuniverse:timewarp:cancelwarp(). 
}

function rwait {
  parameter t.
  kuniverse:timewarp:cancelwarp().
  set warpmode to "rails".
  warpto(time:seconds+t-0.1).
  wait t.
  kuniverse:timewarp:cancelwarp(). 
}

function pfast {
  set warpmode to "physics".
  set warp to 3.
}

function pstop {
  kuniverse:timewarp:cancelwarp(). 
}

sas off.

set done to False.

until done = True  {

  set ea to eta:apoapsis.
  set ep to eta:periapsis.

  if ea < 60 OR ep < 60 {
    print "too close to node, waiting.".
    rwait(60).
  } else if ea < ep {
	
    // Apoapsis Maneuver
    // First check if AE > new altitude, abort if not

    if ship:apoapsis < alt_new*0.999 {
      // Can't raise as AP and PE would switch
      print "AP: skipping, raise AP before PE.".
      rwait(ea+10).
    } else {
      // Wait for AP       
      print "AP: "+floor(ea)+" sec".
      rwait(ea-maxburn-45).
      print "AP: turning.".
      	
      if ship:periapsis < alt_new {
        // raising PE
        timed_turn(prograde,45).
        until ship:periapsis > alt_new*0.999 {
          if (eta:apoapsis > maxburn/2 AND eta:apoapsis < 1000) { lock throttle to 0. set maxburn to maxburn-0.1. }
          else { lock throttle to throttle_max. }
          lock steering to prograde.
          wait .1.
        }
      } else {
        // lower PE
        timed_turn(retrograde,45).
        until ship:periapsis < alt_new*1.001 {
          if (eta:apoapsis > maxburn/2 AND eta:apoapsis < 1000) { lock throttle to 0. set maxburn to maxburn-0.1.}
          else { lock throttle to throttle_max. }
          lock steering to retrograde.
          wait .1.
        }
      }
    }	
  } else {
	
    // Periapsis Maneuver
    // First check if PE < new altitude, abort if not

    if ship:periapsis > alt_new*1.001 {
      // Can't lower AP as AP and PE would switch
      print "PE: skipping, lower PE before AP.".
      rwait(ep+10).
    } else {
      // Wait for PE       
      print "PE: "+floor(ep)+" sec".
      rwait(ep-maxburn-45).
      print "PE: turning.".
		
      if ship:apoapsis < alt_new {
        // raising AP
        timed_turn(prograde,45).
        until ship:apoapsis > alt_new*0.999 {
          if (eta:periapsis > maxburn/2 AND eta:periapsis < 1000) { lock throttle to 0. set maxburn to maxburn-0.1.}
          else { lock throttle to throttle_max. }
          lock steering to prograde.
          wait .1.
        }
      } else {
        // lower AP
        timed_turn(retrograde,45).
        until ship:apoapsis < alt_new*1.001 {
          if (eta:periapsis > maxburn/2 AND eta:periapsis < 1000) { lock throttle to 0. set maxburn to maxburn-0.1.}
          else { lock throttle to throttle_max. }
          lock steering to retrograde.
          wait .1.
        }
      }
    }
  }
  lock throttle to 0.
	
  set apo_p to abs( (ship:apoapsis-alt_new)/alt_new). 
  set per_p to abs( (ship:periapsis-alt_new)/alt_new). 
  print "check: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+ "  "+floor(apo_p*100)+"% / "+floor(per_p*100)+"%".
  if apo_p < 0.01 AND per_p < 0.01 {
    set done to True.
  } else {
    wait 1.
  }
}