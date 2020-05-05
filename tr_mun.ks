// Transfer from 80,000m Kerbin Orbit to Mun Orbit
print "Mun Transfer v0.1".

// Target body and ejection angle
set dst to Mun.
set dst_ang to 125.
set dst_ap to dst:orbit:apoapsis*0.9.

set ang to 999.

// Enable different parts of the program for debugging

if ship:obt:body = dst {
  // At the Moon already...
  print "In SOI of Mun, skipping transfer.".
  set phase1 to False.
  set phase2 to False.
} else {
  set phase1 to True.
  set phase2 to True.
}  
set phase3 to True.

function turn {
  parameter v.
  lock steering to v.
  set warpmode to "physics".
  set warp to 3.
  wait until vang(ship:facing:vector, v:vector) < 5.
  set warp to 0. 
  set warpmode to "rails".
}

if phase1 {

  print "waiting for transfer window.".

  // Wait for transfer window

  until ang < 1 { 
    set ang_mun to dst:geoposition:LNG.
    set ang_ship to ship:geoposition:LNG.
    set ang to MAX(MOD(ang_mun-ang_ship+720-dst_ang,360),0.0001).

    // Estimate how long we need to wait
    set dt to MAX(ABS(ship:orbit:period/360*ang),1).
    print "eta: "+floor(dt)+" s ( "+floor(ang)+" )".
    if dt > 60 {
      set warpmode to "rails".
      warpto(time:seconds+dt-60).
      wait dt-60.
    } else if dt > 10 {
      lock steering to ship:prograde.
      set warpmode to "physics".
      warpto(time:seconds+dt/2).
      wait dt/2.
    } else {
      lock steering to ship:prograde.
      wait dt/3.
    }
  }

  print "starting high velocity burn".
  lock steering to ship:prograde.

  until ship:apoapsis > dst_ap {

      if ship:apoapsis/dst_ap < 0.9 { set thr to 1.0. }
      else if ship:apoapsis/dst_ap < 0.98 { set thr to 0.1. }
      else {set thr to 0.01.}

      lock throttle to thr.

      if maxthrust = 0 {
          print "Fuel exhausted. Staging.".
          stage.
      } 

      wait 0.1.
  }

  lock throttle to 0.

  print "burn complete.".
}

if phase2 {
  // Get us close
  set warpmode to "rails".
  set warp to 5.
  wait until ship:obt:body = dst.
  set warp to 0.
}

if phase3 {
  print "entered SOI. Alt: "+floor(ship:altitude)+"  PE: "+floor(ship:periapsis).

  // Slow down to capture
  turn(ship:retrograde).
  print "breaking for capture.".
  until ship:apoapsis > 0 AND ship:periapsis < 25000 {
    lock throttle to 0.1.
    if maxthrust = 0 {
        print "Fuel exhausted. Staging.".
        stage.
    } 
    wait 0.1.
  }
  lock throttle to 0.
  wait 1.

  print "time to PE: "+floor(eta:periapsis).
  set warpmode to "rails".
  warpto(time:seconds+eta:periapsis-30). 
  wait eta:periapsis-30.
  print "turning for burn.".
  turn(ship:retrograde).
  print "lowering AP.".
  until ship:apoapsis < 100000 {
    if eta:periapsis > 10 AND eta:periapsis < 200 {
      lock throttle to 0.
    } else if eta:periapsis > 5 AND eta:periapsis < 200 {
      lock throttle to 0.1.
    } else {
      lock throttle to 1.0.
    }
    wait 0.1.
  }
  print "AP: "+ship.apoapsis.
}

