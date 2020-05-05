// Change Orbit of Current Ship

declare parameter alt_new.

// Target Velocity in new orbit to get a rough idea of scale
set v_target to sqrt(body:MU/(body:Radius + alt_new)).
set max_acc to ship:maxthrust/ship:mass.
set t to abs( (v_target-ship:velocity:orbit:mag)/max_acc).

set throttle_max to MIN(1.0, MAX(0.1, t/10)).
set maxburn to 60+t/throttle_max/2.

print "Change to new Circular Orbit v0.1".
print "target altitude: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis).
print "target velocity: "+floor(v_target)+" m/s".
print "buffer time    : "+maxburn.
print "est. throttle  : "+throttle_max.

sas off.

set done to False.

until done = True  {

  set ea to eta:apoapsis.
  set ep to eta:periapsis.
	
  if ea < ep {
	
    // Apoapsis Maneuver
    // First check if AE > new altitude, abort if not

    if ship:apoapsis < alt_new*0.99 {
      // Can't raise as AP and PE would switch
      print "AP: skipping, raise AP before PE.".
      wait ea+10.
    } else {
      // Wait for AP       
      print "AP: "+floor(ea)+" sec".
      wait ea-maxburn.
      print "turning.".
      	
      if ship:periapsis < alt_new {
        // raising PE
        lock steering to ship:prograde.
        wait 60.

        until ship:periapsis > alt_new*0.99 {
          lock throttle to throttle_max.
          wait .1.
        }
        lock throttle to 0.
      } else {
        // lower PE
        lock steering to ship:retrograde.
        wait 60.

        until ship:periapsis < alt_new*1.01 {
          lock throttle to throttle_max.
          wait .1.
        }
        lock throttle to 0.
      }
    }	
  } else {
	
    // Periapsis Maneuver
    // First check if PE < new altitude, abort if not

    if ship:periapsis > alt_new*1.01 {
      // Can't lower AP as AP and PE would switch
      print "PE: skipping, lower PE before AP.".
      wait ep+10.
    } else {
      // Wait for PE       
      print "PE: "+floor(ep)+" sec".
      wait ep-maxburn.
      print "turning.".
		
      if ship:apoapsis < alt_new {
        // raising AP
        lock steering to ship:prograde.
        wait 60.

        until ship:apoapsis > alt_new*0.99 {
          lock throttle to throttle_max.
          wait .1.
        }
        lock throttle to 0.
      } else {
        // lower AP
        lock steering to ship:retrograde.
        wait 60.

        until ship:apoapsis < alt_new*1.01 {
          lock throttle to throttle_max.
          wait .1.
        }
        lock throttle to 0.
      }
    }
  }
	
  set apo_p to abs( (ship:apoapsis-alt_new)/alt_new). 
  set per_p to abs( (ship:periapsis-alt_new)/alt_new). 
  print "check: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+ "  "+floor(apo_p*100)+"% / "+floor(per_p*100)+"%".
  if apo_p < 0.01 AND per_p < 0.01 {
    set done to True.
  } else {
    wait 20.
  }
}