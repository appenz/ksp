// Orbital Launch Control

run once libguido.
run once libtransfer.
myinit().

declare parameter apoa is 80000.
set v_target to vv_circular(apoa).

set incl to 0.

clearscreen.

print "Orbital Launch Control v0.1".
print "
Orbit:  " + apoa + " m, " + incl + " deg".

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
    } else if n = "KSS-4" {
        set elist to list(e[9],e[8],e[4]).
    } else if n:startswith("KSS-") {
        set elist to list(e[1],e[0]).
        print "Type: KSS Launcher (LL).".
    } else if n = "Minimus-Lab" {
        set elist to list(e[6],e[5],e[4],e[3]).
    } else if n = "Duna-4" {
        set elist to list(e[10],e[9]).
    } else if n:startswith("Duna-5") {
        // Quad Booster + 8 nuclear
        set elist to list(e[9],e[8], e[7]).
    } else if n:startswith("Duna-6") {
        set elist to list(e[5],e[4], e[3]).
    } else if n:startswith("Duna-") {
        // Duna Series. Engine cluster + 4x nuclear.
        set elist to list(e[4],e[3]).
    } else if n = "Eve-Lander3" OR n = "Eve-Lander4" {
        set elist to list(e[21],e[17], e[16]).
    } else if n:startswith("Eve-Lander") {
        set elist to list(e[14],e[10], e[9]).
    } else if n:startswith("Sat-1") {
       set elist to list(e[5],e[4],e[3]).
    } else if n:startswith("Sat-2") {
       set elist to list(e[2],e[1],e[0]).    
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
        safe_stage().
        wait 0.1.
    }
}

function u_status {
  p_status("Rocket Launch "+mytimer(),0).
  p_status("Alt: "+km(ship:altitude)+" / "+percent(ship:altitude,apoa),2).
  p_status("AP:  "+km(ship:apoapsis)+" / "+percent(ship:apoapsis,apoa),3). 
  p_status("v:   "+round(ship:velocity:orbit:mag)+" m/s  / "+percent(ship:velocity:orbit:mag,v_target),4). 
}

// Main --------------------------------------------------

clr_status().

if ship:altitude < 1000 {

    p_status("Launching.",0).
    print " ". print "Launching.".
    print "3". wait 1. print "2". wait 1. print "1". wait 1.
    mytimer_s().

    // Launch
    safe_stage().
    lock throttle to 1.0.
    lock steering to heading(90,90).

    // Initiate gravity turn
    p_status("Ascent Phase I",0).
    print mytimer()+"climb to grav turn at "+alt_s.
    until ship:altitude > alt_s {
        u_status().
        wait 0.1.
    }


    // Raise orbit to 10k below apoapsis, wait until out of the athmosphere, stage if necessary
    print mytimer()+"gravity turn.".

}

if ship:altitude < apoa*0.75 {
    p_status("Ascent Phase II: 75% AP",0).
    print mytimer()+"raising AP to  75% of target: "+floor(apoa*0.75).
    
    until ship:altitude > 45000 {
        // Check if ascent stage is done, decouple and start transfer stage
        eng_check().

        set app to ship:apoapsis/apoa.
        if app > .75 {lock throttle to 0.0.}
        else {lock throttle to 1.0.}

        lock steering to heading(90,calc_angle(ship:altitude)).
        u_status().
        wait 0.2.
    } 
}

if ship:apoapsis < apoa*0.999 {
    // Now we are out of the athmosphere and high. Raise orbit to apoapsis, stage if necessary
    print  mytimer()+"raising AP to 100% of target: "+floor(apoa).
    p_status("Ascent Phase III: 100% AP",0).

    lock steering to ship:prograde.

    until ship:apoapsis > apoa*0.999 {
        // Check if ascent stage is done, decouple and start transfer stage
        eng_check().
        
        set app to ship:apoapsis/apoa.
        if app > .999 {lock throttle to 0.0.}
        else {lock throttle to 1.0.}
        u_status().
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
set dv to v_new-v_ap.
set dt_ap to dv/max_acc.

set mynode to NODE(time:seconds+t_ap,0,0,dv).
ADD mynode.
exec_n(mynode).

print "Orbit reached: A/P/T  "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+" / "+apoa.
myexit().