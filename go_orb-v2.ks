// Orbital Launch Control

run once libguido.
myinit().

declare parameter apoa is 80000.

set incl to 0.

clearscreen.print "Orbital Launch Control v0.1".
print "Orbit:  " + apoa + " m, " + incl + " deg".

set alt_s to 1000.

// Vessel specific setup
set n to ship:name.
set e_cur to 0.
list engines in e.

if ship:altitude < 1000 {
    if n = "orbital-1" OR n = "MunOrbiter" OR n = "Mun-1" OR n = "Mun-2" {
        set elist to list(e[2],e[1],e[0]).
        print "Type: 3-Stage (3 stage, SLL)".
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
    } else if n = "Duna-1" {
        set elist to list(e[4],e[3]).
    } else if n = "Duna-2" {
        set elist to list(e[4],e[3]).
    } else {
        print "Unknown vessel. Abort!".
    }
} else {
    print "Need to improvise.".
    set elist to e.
}

for e in elist {
    print "  "+e:title.
}

// Functions --------------------------------------------------



function calc_angle {
    parameter alt.

    if alt <   500 {return 90.}
    if alt <  1000 {return 85+ 5*( 1000-alt)/  500.}
    if alt <  3000 {return 80+ 5*( 3000-alt)/ 2000.}
    if alt <  7000 {return 70+10*( 7000-alt)/ 4000.}
    if alt < 13000 {return 60+10*(15000-alt)/ 6000.}
    if alt < 21000 {return 50+10*(21000-alt)/ 8000.}
    if alt < 30000 {return 40+10*(30000-alt)/ 9000.}
    if alt < 40000 {return 35+ 5*(40000-alt)/10000.}
    return 35.
}

// Check for flameout and stage if needed
function eng_check {
    set ce to elist[e_cur].   
    if ce:maxthrust = 0 {
        set e_cur to e_cur+1.
        print "fuel for "+ce:title+" exhausted.".
        wait until stage:ready. 
        print "staging.".
        stage.
        wait 0.1.
    }
}

// Main --------------------------------------------------



if ship:altitude < 1000 {

    print " ". print "Launching.".
    print "3". wait 1. print "2". wait 1. print "1". wait 1.
    mytimer_s().

    // Launch
    stage.
    lock throttle to 1.0.
    lock steering to heading(90,90).

    // Initiate gravity turn
    print mytimer()+"climb to grav turn at "+alt_s.
    wait until ship:altitude > alt_s.


    // Raise orbit to 10k below apoapsis, wait until out of the athmosphere, stage if necessary
    print mytimer()+"gravity turn.".

}

if ship:altitude < apoa*0.75 {
    print mytimer()+"raising AP to  75% of target: "+floor(apoa*0.75).
    
    until ship:altitude > 45000 {
        // Check if ascent stage is done, decouple and start transfer stage
        eng_check().

        set app to ship:apoapsis/apoa.
        if app > .75 {lock throttle to 0.0.}
        else {lock throttle to 1.0.}

        lock steering to heading(90,calc_angle(ship:altitude)).
        wait 0.2.
    } 
}

if ship:apoapsis < apoa*0.999 {
    // Now we are out of the athmosphere and high. Raise orbit to apoapsis, stage if necessary
    print  mytimer()+"raising AP to 100% of target: "+floor(apoa).

    lock steering to ship:prograde.

    until ship:apoapsis > apoa*0.999 {
        // Check if ascent stage is done, decouple and start transfer stage
        eng_check().
        
        set app to ship:apoapsis/apoa.
        if app > .999 {lock throttle to 0.0.}
        else {lock throttle to 1.0.}
        wait 0.1.
    } 

    print mytimer()+"AP rasied to "+ship:apoapsis.
    lock throttle to 0.
}


// Calculate length of burn at AP.
set max_acc to ship:maxthrust/ship:mass.
set t_ap to eta:apoapsis.
set ap to ship:apoapsis.
set v_ap to vv_alt(ap).
set v_new to vv_circular(ap).
set dt_ap to abs(v_ap-v_new)/max_acc.

print mytimer()+"burn time: "+round(dt_ap,1)+" s".
lock steering to heading(90,0).
if t_ap-dt_ap/2 > 0 {
  print mytimer()+"waiting "+(t_ap-dt_ap/2)+" s".
  pwait(t_ap-dt_ap/2).
}

print "starting burn.".

until ship:periapsis > apoa*0.999 OR (ship:apoapsis > apoa*1.2 AND ship:periapsis > apoa*0.9) OR ship:periapsis > apoa*2 {
    // Check if ascent stage is done, decouple and start transfer stage
    eng_check().

    set app to ship:periapsis/apoa.
    if app > .999 {lock throttle to 0.0.}
    else if app > .99  {lock throttle to 0.2.}
    else {lock throttle to 1.0.}
    lock steering to heading(90,0).
    wait 0.1.
} 

print "Orbit reached: A/P/T  "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+" / "+apoa.
myexit().