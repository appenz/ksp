// Launch from Kerbin to Minmus
print "Minmus 1.0".

KUniverse:QUICKSAVETO("x0-prelaunch").
if body = Kerbin {
  if ship:altitude < 65000 {
    run go_orb.
  }
  lock throttle to 0.
  wait until KUniverse:CANQUICKSAVE.
  KUniverse:QUICKSAVETO("x1-orbit").
  if ship:orbit:inclination < 5 {
    run reorb(80000).
    run incl.
    run incl(6,Minmus:orbit:lan).

  }
  run reorb(80000).
  wait until KUniverse:CANQUICKSAVE.
  KUniverse:QUICKSAVETO("x2-pretransfer").
  run tr_min.
} else {
  // In SOI of Minimus, but not yet on a stable orbit.
  if ship:apoapsis < 0 OR ship:apoapsis > 100000 { run tr_min. }
}

if ship:apoapsis > 11000 { run reorb(10000). }
//if ship:orbit:inclination > 0.1 { run incl. }
wait until KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("x3-dstorbit").
//run hit(0,6).
print "You arrived on Minmus!".

