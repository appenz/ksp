// Set inclination to zero.

declare parameter incl_new is 0, lan_new is 0.

run once libguido.
myinit().

set firsttime to true.
set done to False.  

// Check if there is anything to do.

set i to ship:orbit:inclination - incl_new.

set d to vcrs(ship:velocity:orbit, body:position):direction.
if i > 0 { set d to d:inverse. }
wait_turn(d).

set i to ship:orbit:inclination - incl_new.
set min_i to 999.

// Do this until it flips...
until abs(i) > (min_i+0.001) {
    set i to ship:orbit:inclination - incl_new.
    set d to vcrs(ship:velocity:orbit, body:position):direction.
    if i > 0 { set d to d:inverse. }
    lock steering to d.

    // How much throttle? Ignore for now...
    set dv to 2*ship:velocity:orbit:mag*sin(i/2).
    set dt to abs(dv)/(ship:maxthrust/ship:mass).

    if abs(i) > 10 and vang(ship:facing:vector,d:vector) < 2 {
        lock throttle to 1.0.
    } else if abs(i) > 1 and vang(ship:facing:vector,d:vector) < 5 {
        lock throttle to 0.1.
    } else if vang(ship:facing:vector,d:vector) < 10{
        lock throttle to 0.01.
    }
    print1s("incl: "+round(i,3)).
    wait 0.1.

    if abs(i) < min_i { set min_i to abs(i). }.
    } 
    lock throttle to 0.

    set i to ship:orbit:inclination - incl_new.
    if abs(i) < 1 {
    set done to true.
}


set i to abs(ship:orbit:inclination - incl_new).
print "done. incl: "+round(i,3).
myexit().