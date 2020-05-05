// Return from Minmus
run once libguido.

print "Duna Return v0.1".


if ship:apoapsis < 20000 and body = Duna {
  sas off.
  wait until KUniverse:CANQUICKSAVE.
  KUniverse:QUICKSAVETO("x4-prereturn").

  // Let's get into a 60k orbit.
  print "taking off.".
  lock steering to heading(90,90).
  lock throttle to 1.0.
  wait 3.

  print "raise ap to 60,000.".
  gear off.
  lock steering to heading(90,45).
  wait until ship:apoapsis > 60000.
  lock throttle to 0.
  print "ap: "+round(ship:apoapsis,1)+" eta "+round(eta:apoapsis,1).
  set warpmode to "rails".
  until eta:apoapsis < 30 { set warp to 3. }
  rwait(eta:apoapsis-20).

  print "turning.".
  wait_turn(heading(90,0)).
  print "circualrizing.".
  lock throttle to 1.0.
  wait until ship:periapsis > 60000 OR ship:apoapsis > 80000.
  lock throttle to 0.0.
}

if ship:apoapsis < 490000 AND ship:orbit:body = Duna {
  sas off.
  wait until KUniverse:CANQUICKSAVE.
  KUniverse:QUICKSAVETO("x5-retloworbit").
  print "adjusting inclination and raising orbit to 500,000 m".
  run incl.
  run reorb(500000).
}

if body = Duna {
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x6-pretransfer").

    // Load transfer library
    run tr_pl(Kerbin,True).
    my_transfer(Kerbin).
}

if body = Kerbin {
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x7-kerbin-soi").
    
    if ship:periapsis < 40000 {
      print "already in capture orbit.".
    } else {
        wait_turn(retrograde).
        print "PE: "+round(ship:periapsis,1).
        until ship:periapsis < 40000 {
          if ship:periapsis > 100000 { lock throttle to 1. }
          else if ship:periapsis > 41000  { lock throttle to 0.1. }
          else { lock throttle to 0.01. }
          wait 0.1.
        }
        set throttle to 0.
        unlock throttle.
    }

    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x8-captureorbit").
    print "capture orbit. PE :"+round(ship:periapsis,0).

    // We are captured, slowly lower the AP+PE
    unlock steering.
    sas on.
    wait 1.
    if sasmode <> "retrograde" {
      // To avoid annoying bug
      set sasmode to "retrograde".
    }
    
    set warp to 0.
    wait 1.
    set warpmode to "rails".
    set warp to 7.

    // Burn rest of fuel to brake once we are low.
    wait until eta:periapsis < 60 or ship:altitude < 45000.
    lock throttle to 1.0.    
    wait until maxthrust = 0 OR ship:altitude < 11000.
    lock throttle to 0.
    wait 1.
    safe_stage().

    print "waiting for 10,000 MSL".
    wait until ship:altitude < 10000.
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x9-preland").   
    
    print "waiting for parachutes to be safe.".
    wait until chutessafe = True OR ship:velocity:surface:mag < 250.
    print "chutes safe at alt "+round(alt:radar)+" m".
    wait 1.
    safe_stage().
    chute on.
    print "parachutes deployed.".
    print "done.".
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x10-landed").   
}
 