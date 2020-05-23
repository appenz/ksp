// Launch from Kerbin to Duna
run once libguido.

print "Duna 1.0".

parameter alt is -1.
parameter incl_change is False.

if body = Kerbin {
  if ship:altitude < 65000 {
    myquicksave("x0-prelaunch").
    run go_orb(250000).
    myquicksave("x1-orbit").
  }
  if ship:orbit:inclination > 0.01 {
    run incl.
  }
  if ship:apoapsis < 1000000*0.99 {
    run reorb(1000000).
    myquicksave("x2-pretransfer").
  }
  run tr_pl(Duna,alt).
} else {
  // In SOI, but not yet on a stable orbit.
  if ship:apoapsis < 0 OR ship:apoapsis > 200000 {   run tr_pl(Duna). }
}

print "You arrived at Duna!".

