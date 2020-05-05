// Orbital Launch Control

run once libguido.
myinit().

set incl to 0.
set apoa to 80000.

clearscreen.print "Orbital Launch Control v0.1".
print "Orbit:  " + apoa + " m, " + incl + " deg".

set alt_s to 1000.

// Vessel specific setup
set n to ship:name.
set e_cur to 0.
list engines in e.

if n = "orbital-1" OR n = "MunOrbiter" OR n = "Mun-1" OR n = "Mun-2" {
    set elist to list(e[2],e[1],e[0]).
    print "Type: 3-Stage (3 stage, SLL)".
} else if n = "Mun-3-Minimus1" {
    set elist to list(e[5],e[4],e[3]).
} else if n:startswith("Mun-3") {
    set elist to list(e[3],e[2],e[1],e[0]).
    print "Type: 4-Stage (3 stage, SLLL)".
} else if n = "KSS-2" {
    set elist to list(e[2]).
    print "Type: KSS-2 (single stage L)".
} else if n:startswith("KSS-") {
    set elist to list(e[1],e[0]).
    print "Type: KSS Launcher (LL).".
} else if n = "Minimus-Lab" {
    set elist to list(e[6],e[5],e[4],e[3]).
} else {
    print "Unknown vessel. Abort!".
}

for e in elist {
    print "  "+e:title.
}

// Functions --------------------------------------------------

function calc_angle {
    parameter alt.

    if alt <   500 {return 90.}
    if alt <  1000 {return 85.}
    if alt <  3000 {return 80.}
    if alt <  7000 {return 70.}
    if alt < 15000 {return 60.}
    if alt < 20000 {return 50.}
    if alt < 30000 {return 40.}
    if alt < 40000 {return 35.}
    return 35.
}

// Check for flameout and stage if needed
function eng_check {
    set ce to elist[e_cur].   
    if ce:maxthrust = 0 {
        set e_cur to e_cur+1.
        print "Fuel for "+ce:title+" exhausted. Staging.".
        stage.
        wait 0.1.
    }
}

// Main --------------------------------------------------

print " ". print "Launching.".
print "3". wait 1. print "2". wait 1. print "1". wait 1.

// Launch
stage.
lock throttle to 1.0.
lock steering to heading(90,90).

// Initiate gravity turn
print "climb to grav turn at "+alt_s.
wait until ship:altitude > alt_s.


// Raise orbit to 10k below apoapsis, wait until out of the athmosphere, stage if necessary
print "gravity turn.".
print "raising AP to  75% of target: "+floor(apoa*0.75).

until ship:altitude > 50000 AND eta:apoapsis < 120 {
    // Check if ascent stage is done, decouple and start transfer stage
    eng_check().

    set app to ship:apoapsis/apoa.
    if app > .75 {lock throttle to 0.0.}
    else {lock throttle to 1.0.}

    lock steering to heading(90,calc_angle(ship:altitude)).
    wait 0.2.
} 

// Now we are out of the athmosphere and high. Raise orbit to apoapsis, stage if necessary
print "raising AP to 100% of target: "+floor(apoa).

until eta:apoapsis < 35 {
    // Check if ascent stage is done, decouple and start transfer stage
    eng_check().

    set app to ship:apoapsis/apoa.
    if app > .999 {lock throttle to 0.0.}
    else if app > .99  {lock throttle to 0.1.}
    else {lock throttle to 1.0.}

    lock steering to ship:prograde.
    wait 0.2.
} 

print "turning for PE raise.".
lock throttle to 0.0.
lock steering to heading (90,0).

// Raise Periapsis, stage if necessary
set t to eta:apoapsis-30.
print "Waiting "+floor(t)+" seconds for Periapsis raise.".
wait t.

// burn
until ship:periapsis > apoa {
    lock steering to heading (90,0).
    set ea to eta:apoapsis.
    if ship:periapsis < 0 {
      if ea > 25 AND ea < 120 { set thr to 0.1. }
      else {set thr to 1.0.}
    } else {
      if ea > 5 AND ea < 120 { set thr to 0. }
      else if ea < 5 { set thr to 0.2.}
      else { set thr to 1.}
    }
    lock throttle to thr.

    eng_check().
    wait 0.2.
}

lock throttle to 0.

print "Orbit reached: A/P/T  "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+" / "+apoa.
myexit().