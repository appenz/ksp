// Set inclination to zero.

declare parameter incl_new is 0, lan_new is 0.

run once libguido.
myinit().

set firsttime to true.
set done to False.  

// Check if there is anything to do.

set i to ship:orbit:inclination - incl_new.

if i > 0 {
  wait_turn(heading(180,0)).
  lock steering to heading(180,0).
} else {
  wait_turn(heading(0,0)).
  lock steering to heading(0,0).
}

until done {

  // calculate angle 
  if lan_new = 0 {
    set an_lat to ship:orbit:lan.
  } else {
    set an_lat to lan_new.
  }
  set warpmode to "rails".

  set a to 999.

  until a < 2.0 {

    set t to a/360*ship:orbit:period.

    set_warp_for_t(t).
    set ship_lat to mod(longitude+body:rotationangle+720,360).
    set a to  mod(an_lat-ship_lat+720,360).
    wait 0.1.
  }

  set warp to 0.
  print "AN. lat: "+round(latitude,2)+" incl: "+round(ship:orbit:inclination,3).
  print "ship lat: "+round(mod(longitude+body:rotationangle+720,360),2).
  print "LAN  lat: "+an_lat.
  print1s("incl: "+round(ship:orbit:inclination,3)+" ang: "+round(a,2)).

  set i to abs(ship:orbit:inclination - incl_new).
  set min_i to 999.

  // Estimate time

  until i < 0 OR mod(a+2,360) > 4 OR abs(i) > (min_i+0.001) {
    set old_i to i.
    set i to abs(ship:orbit:inclination - incl_new).
    set ship_lat to mod(longitude+body:rotationangle+720,360).
    set a to  mod(an_lat-ship_lat+720,360).
    
    // How much throttle?
    set dv to 2*ship:velocity:orbit:mag*sin(i/2).
    set dt to abs(dv)/(ship:maxthrust/ship:mass).
    
    if dt > 1 {
        lock throttle to 1.0.
    } else if dt > 0.1 {
        lock throttle to 0.1.
    } else {
        lock throttle to 0.1.
    }
    print1s("incl: "+round(ship:orbit:inclination,3)+" ang: "+round(a,2)).
    wait 0.1.
    
    if abs(i) < min_i { set min_i to abs(i). }.
  } 
  lock throttle to 0.

  set i to abs(ship:orbit:inclination - incl_new).
  if i < 0.1 {
    set done to true.
  }

  wait 2.

}

set i to abs(ship:orbit:inclination - incl_new).
print "done. incl: "+round(i,3).
myexit().