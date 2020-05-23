// Transfer from 80,000m Kerbin Orbit with 6 deg inclination to Minmus Orbit
print "Minmus Transfer v1.0".

run once libguido.
run once libtransfer.
myinit().

// Do the Transfer if needed
if ship:obt:body = Kerbin {
    print "planning transfer Kerbin->Minmus. AP: "+km(ship:apoapsis).
    set done to False.

    until done {
        // Moon may get in the way, keep trying until we have Minmus
        clear_all_nodes().
        wait_transfer_window(Minmus, ship,4).

        set mynode to NODE(time:seconds+600,0,0,300).
        ADD mynode.

        until mynode:orbit:hasnextpatch AND (mynode:orbit:nextpatch:body = Minmus OR 
               mynode:orbit:nextpatch:apoapsis > Minmus:orbit:apoapsis*1.5) {
          set mynode:prograde to mynode:prograde+0.1.
        }

        if mynode:orbit:nextpatch:body = Minmus {
            print "Minmus encounter.".
            set done to True.
            wait 1.
        } else {
            if mynode:orbit:nextpatch:body = Mun {
              print "-> Mun, try next orbit.".
            } else {
              print "No encounter.".
            }
            rwait(Mun:orbit:period/4).
        }
    }

    optimize_pe(50000,100000,Minmus).
    exec_n(mynode,3).
    print "Post-burn Minmus AP: "+km(ship:orbit:nextpatch:apoapsis).
    wait_until_in_orbit_of(Minmus).
}

myquicksave("x3-minmus-SOI").

if ship:obt:body = Minmus {

    if ship:periapsis > 50000 {
        print "In Minimum SOI.".
        print "#1 PE: "+km(ship:periapsis).
        clear_all_nodes().
        set mynode to NODE(time:seconds+600,0,0,0).
        ADD mynode.

        until mynode:orbit:periapsis < 25000 OR 
                  (mynode:orbit:apoapsis > 0 AND mynode:orbit:apoapsis < 10000000) {
          set mynode:prograde to mynode:prograde-1.
        }
        exec_n(mynode,3).
        print "#2 PE: "+km(ship:periapsis).
        myquicksave("x4-minmus-low-PE").
    }

    if ship:apoapsis < 0 OR ship:apoapsis > 100000 {
        clear_all_nodes().
        set mynode to NODE(time:seconds+eta:periapsis,0,0,0).
        ADD mynode.
        print "braking to get into orbit.".

        until  mynode:orbit:periapsis < 20000 OR 
              (mynode:orbit:apoapsis < 55000 AND mynode:orbit:apoapsis > 0) {
                set mynode:prograde to mynode:prograde-1.
            }
        }
        exec_n(mynode,3).
        myquicksave("x5-minimus-initial-orbit").
}

myexit().