// Launch from Kerbin to Minmus
print "Minmus 1.0".
run once libguido.

KUniverse:QUICKSAVETO("x0-prelaunch").
if body = Kerbin {
  if ship:altitude < 65000 {
    run go_orb(250000).
  }
  lock throttle to 0.
  myquicksave("x1-orbit").
  if ship:orbit:inclination < 5 {
    run incl.
    run incl(6,Minmus:orbit:lan).
  }
  myquicksave("x2a-postincl").
  if ship:apoapsis < 1000000*0.99 {
    run reorb(1000000).
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x2-pretransfer").
  }
  myquicksave("x2b-pretransfer").
  run tr_min.
} 

if body = Minmus {
  // In SOI of Minimus, but not yet on a stable orbit.
  if ship:apoapsis < 0 OR ship:apoapsis > 100000 { run tr_min. }
}

if ship:apoapsis > 11000 { run reorb(10000). }
if ship:orbit:inclination > 0.1 { run incl. }
myquicksave("x6-minimus-orbit").
//run hit(0,6).
print "You arrived on Minmus!".
myexit().
