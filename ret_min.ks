// Return from Minmus
run once libguido.

print "Minmus Return v0.1".

sas off.

if ship:apoapsis < 20000 and body = Minmus {

  // Parked on the Mun, let's get into a 20k-30k orbit.
  print "taking off.".
  lock steering to heading(90,90).
  lock throttle to 1.0.
  wait 3.

  print "raise ap to 25,000.".
  gear off.
  lock steering to heading(90,45).
  wait until ship:apoapsis > 25000.
  lock throttle to 0.
  print "ap: "+round(ship:apoapsis,1)+" eta "+round(eta:apoapsis,1).
  set warpmode to "rails".
  until eta:apoapsis < 30 { set warp to 3. }
  rwait(eta:apoapsis-10).

  print "turning.".
  wait_turn(heading(90,0)).
  print "circualrizing.".
  lock throttle to 1.0.
  wait until ship:periapsis > 20000.
  lock throttle to 0.0.
}

wait until KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("x4-retorbit").

if ship:apoapsis > 20000 and body = Minmus {

  print "waiting for ejection point.".
  set dst_ang to -22.
  set ang to 99.

  until ang < 1 { 
    set ang to MAX(MOD(-longitude+dst_ang+720,360),0.0001).
    // Estimate how long we need to wait    
    set dt to MAX(ABS(ship:orbit:period/360*ang),1).    
    print "eta: "+floor(dt)+" s ( "+floor(ang)+" )".
    if dt > 60 {      
        set warpmode to "rails". wait 0.1.
        warpto(time:seconds+dt-30).      
        wait dt-30+1.      
        pstop().
    } else if dt > 10 {      
        lock steering to ship:prograde.      
        set warpmode to "physics".
        wait 0.1.      
        warpto(time:seconds+dt/2).      
        wait dt/2+1.      
        pstop().
    } else {      
        lock steering to ship:prograde.      
        wait dt/3.
    }
  }

  print "ejection burn.".
  wait_turn(prograde).
  set throttle to 1.0.
  wait until ship:apoapsis < 0.
  wait 0.1.
  set throttle to 0.
  until body = Kerbin {
    set warpmode to "rails".
    set warp to 5.
  }   
}


if ship:periapsis < 48000 {
  print "already in capture orbit.".
} else {

  // Multiple times... rounding errors
  print "warp for AP. 95%".
  rwait(eta:apoapsis*0.95).
  print "warp for AP. 100%".
  rwait(eta:apoapsis).

  until ship:periapsis < 48000 AND ship:periapsis > 43000 {
    // Lower PE
    print "turning retrograde.".
    wait_turn(retrograde).
    print "PE: "+ship:periapsis.
    until ship:periapsis < 48000 {
      if ship:periapsis > 200000 { lock throttle to 1. }
      else if ship:periapsis > 60000  { lock throttle to 0.1. }
      else { lock throttle to 0.01. }
      Wait 0.1.
    }
    lock throttle to 0.

    // Check in case we need to raise PE
    if ship:periapsis < 43000 {
      wait_turn(prograde).
      lock throttle to 0.01.
      wait until ship:periapsis > 43000.
      lock throttle to 0.
    }
  }

  unlock throttle.

}

wait until KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("x5-captureorbit").

print "capture orbit. PE :"+round(ship:periapsis,0).

// We are captured, slowly lower the AP+PE

unlock steering.
sas on.
wait 1.
set sasmode to "retrograde".

set warp to 0.
wait 1.
set warpmode to "rails".
set warp to 7.

wait until eta:periapsis < 60 or ship:altitude < 45000.

lock throttle to 1.0.
 
wait until maxthrust = 0.

lock throttle to 0.
wait 1.
stage.

print "waiting for 10,000 MSL".
wait until ship:altitude < 10000.
print "waiting for parachutes to be safe.".
wait until chutessafe = True OR ship:velocity:surface:mag < 250.
print "chutes safe at alt "+alt:radar.
wait 1.
stage.
chute on.

print "parachutes deployed.".
print "done.".
 