print "Eve 1.0".

KUniverse:QUICKSAVETO("x0-prelaunch").
if body = Kerbin {
  if ship:altitude < 65000 {
    run go_orb(250000).
    lock throttle to 0.
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x1-orbit").
  }
  if ship:orbit:inclination > 0.01 {
    run incl.
  }
  if ship:apoapsis < 1000000*0.99 {
    run reorb(1000000).
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x2-pretransfer").
  }
  run tr_pl(Eve).
} else {
  // In SOI, but not yet on a stable orbit.
  if ship:apoapsis < 0 OR ship:apoapsis > 200000 {   run tr_pl(Eve). }
}

wait until KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("x5-dstlow").
print "You arrived at Eve!".

