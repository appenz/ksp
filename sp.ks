//
// Launch Spaceplane
//

run once libguido.
run once liborbital.
myinit().
clearscreen.


// Speeds
set v_to to 100.
set v_acc to 1000.

// Pitch
set p_to_roll to 0.
set p_to to 15.
set p_climb to 15.
set p_final to 15.

// Transition altitudes
set a_acc to 12000.
set a_target to 80000.
set v_target to vv_circular(a_target).
set n to ship:name.

if n = "SSTO-1" {
  set p_climb to 20.
} else if n = "SSTO-2" {
  set p_to_roll to 7.
  set p_climb to 23.
} else {
  print "Standard SSTO Space Plane".
}

function u_status {
  p_status("Space Plane "+mytimer(),0).
  p_status("Alt: "+km(ship:altitude)+" / "+percent(ship:altitude,a_target),2).
  p_status("AP:  "+km(ship:apoapsis)+" / "+percent(ship:apoapsis,a_target),3). 
  p_status("v:   "+round(ship:velocity:orbit:mag)+" m/s  / "+percent(ship:velocity:orbit:mag,v_target),4). 
}

function smooth_pitch {
  parameter mycourse.
  parameter old_pitch.
  parameter new_pitch.
  parameter t is 15.
  
  local s is 0.
  local p is 0.
  
  until s > t {
    set p to (old_pitch*(t-s)+new_pitch*s)/t.
    lock steering to heading( mycourse, p ).
    set s to s+0.1.
    u_status().
    p_status("pitch: "+round(p,1)+"     "+old_pitch+" -> "+new_pitch,1).
    wait 0.1.
  }
}


mytimer_s().
clr_status().

if ship:altitude < 0.75*a_acc {
    // Assume we are on the ground.

    print "  take off at   "+v_to+" m/s   pitch "+p_to+" deg.".
    print "  accelerate at "+a_acc+" m  to "+v_acc+" m/s".
    print "  target altitude "+a_target+" m".
    brakes on.
    myquicksave("x0-pretakeoff",10).
    brakes off.

    lock throttle to 1.0.
    wait 1.

    print mytimer()+"starting engine.".
    stage.

    lock steering to heading(90.42, p_to_roll).

    until ship:velocity:surface:mag > v_to {
      u_status().
      p_status("takeoff roll "+round(ship:velocity:surface:mag)+" / "+percent(ship:velocity:surface:mag,v_to),1).
    }

    print mytimer()+"takeoff at v: "+round(ship:velocity:surface:mag,1).
    smooth_pitch(90, 0, p_to, 1).

    wait until ship:altitude > 100.
    print mytimer()+"takeoff complete alt: 100m   v: "+round(ship:velocity:surface:mag,1).
    gear off.
    smooth_pitch(90, p_to, p_climb, 10).

    p_status("climbing to "+km(a_acc),1).
    until ship:altitude > a_acc {
        u_status().
        wait 0.1.
    }
}

if ship:velocity:surface:mag < v_acc {
  print mytimer()+"reached a_acc: "+a_acc+" v: "+round(ship:velocity:surface:mag,1).
  print mytimer()+"accelerating to "+round(v_acc,1).
  lock steering to heading(90, max(0,min(5,(a_acc-ship:altitude)/100))).
  lock throttle to 1.0.

  p_status("accelerating to "+v_acc,1).
  until ship:velocity:surface:mag > v_acc {
      u_status().
  }

  print mytimer()+"reached v_acc: "+round(ship:velocity:surface:mag,1).
}

if ship:apoapsis < a_target {
    print mytimer()+"climbing for final burn v:"+round(ship:velocity:surface:mag,1).
    lock steering to heading(90,p_final).
    set_engine("nuclear",1,mytimer()).
    lock throttle to 1.0.
    p_status("final burn with jet engines.",1).

    set v_old to ship:velocity:surface:mag.
    until ship:velocity:surface:mag < v_old OR ship:apoapsis > a_target {
      u_status().
      set v_old to ship:velocity:surface:mag.
      wait 1.
    }

    print mytimer()+"losing speed. switching Rapiers at alt: "+km(ship:altitude).
    rapier_space().
    INTAKES off.

    p_status("burn with rocket engines.",1).
    until ship:apoapsis > a_target {
        u_status().
    }
}

print mytimer()+"reached ap: "+a_target+"  alt: "+km(ship:altitude)+" v: "+round(ship:velocity:surface:mag,1).

p_status("Waiting to exit athmosphere.",1).
until ship:altitude > 60000 and ship:apoapsis > a_target*0.999 {
  if ship:apoapsis < a_target {
    lock throttle to abs( (ship:apoapsis-a_target)/a_target)/100+0.1.
  } else {
    lock throttle to 0.
  }
  u_status().
}

lock throttle to 0.

print mytimer()+"50k, exiting planning circularization. ap: "+km(ship:apoapsis)+"  v: "+round(ship:velocity:surface:mag,1).
myquicksave("x1-apoapsis-ok").

set mynode to circularize_at_ap().
add mynode.
exec_n(mynode,3).

print mytimer()+"orbit reached: A/P/T  "+km(ship:apoapsis)+" / "+km(ship:periapsis)+" / "+a_target.
myquicksave("x2-low-orbit").
myexit().