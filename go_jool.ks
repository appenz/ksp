// Launch from Kerbin to Dres
run once libguido.

clearscreen.
print "Jool Launcher".

if body = Kerbin {
    if ship:altitude < 65000 {
        myquicksave("x0-prelaunch").
        run go_orb(250000).
        lock throttle to 0.
        myquicksave("x1-orbit").
    }
    if ship:orbit:inclination > 0.01 {
        run incl.
        myquicksave("x2a-postincl").
    }
    if ship:apoapsis < 1000000*0.99 {
        run reorb(5000000).
        myquicksave("x2b-pretransfer").
    }
    run tr_pl(Jool).
} else {
  // In SOI, but not yet on a stable orbit.
  if ship:apoapsis < 0 OR ship:apoapsis > 100000000 {   run tr_pl(Jool). }
}

panic("You arrived at Jool!").
myexit().

