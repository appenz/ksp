// Spaceplane launch

run once libguido.
myinit().



// Speeds
set v_to to 100.
set v_acc to 1000.

// Pitch
set p_to to 15.
set p_climb to 15.
set p_final to 15.

// Transition altitudes
set a_acc to 12000.
set a_target to 70000.
set n to ship:name.

if n = "Other" {
  // Do nothing
  print "Other???".
} else {
  print "Standard SSTO Space Plane".
}

mytimer_s().

if ship:altitude < 0.75*a_acc {
  // Assume we are on the ground.

  print "  take off at   "+v_to+" m/s   pitch "+p_to+" deg.".
  print "  accelerate at "+a_acc+" m  to "+v_acc+" m/s".
  print "  target altitude "+a_target+" m".

  lock throttle to 1.0.
  wait 1.

  print mytimer()+"starting engine.".
  stage.

  lock steering to heading(90.42, 0).

  wait until ship:velocity:surface:mag > v_to.

  print mytimer()+"takeoff at v: "+round(ship:velocity:surface:mag,1).
  smooth_pitch(90, 0, p_to, 1).

  wait until ship:altitude > 100.
  print mytimer()+"takeoff complete alt: 100m   v: "+round(ship:velocity:surface:mag,1).
  gear off.
  smooth_pitch(90, p_to, p_climb, 10).

  wait until ship:altitude > a_acc.
}

if ship:velocity:surface:mag < v_acc {
  print mytimer()+"reached a_acc: "+a_acc+" v: "+round(ship:velocity:surface:mag,1).
  print mytimer()+"accelerating to "+round(v_acc,1).
  lock steering to heading(90, max(0,min(5,(a_acc-ship:altitude)/100))).

  wait until ship:velocity:surface:mag > v_acc.

  print mytimer()+"reached v_acc: "+round(ship:velocity:surface:mag,1).
}

if ship:apoapsis < a_target {
    print mytimer()+"climbing for final burn.".
    lock steering to heading(90,p_final).
    set_engine("nuclear",1).

    set v_old to ship:velocity:surface:mag.
    until ship:velocity:surface:mag < v_old {
      set v_old to ship:velocity:surface:mag.
      wait 1.
    }

    print mytimer()+"losing speed. switching Rapiers at alt: "+ship:altitude.
    rapier_space().
    toggle INTAKES.

    wait until ship:apoapsis > a_target.
}

print mytimer()+"reached ap: "+a_target+"  alt: "+ship:altitude+" v: "+round(ship:velocity:surface:mag,1).
smooth_pitch(90,p_final,0,10).

// Calculate length of burn.

set max_acc to ship:maxthrust/ship:mass.
set t_ap to eta:apoapsis.
set ap to ship:apoapsis.
set pe to ship:periapsis.
set v_ap to vv_alt(ap).
set v_new to vv_circular(ap).
set target_v_ap to vv_axis(ap,(ap+2*body:radius+ap)/2).
set dt_ap to abs(v_ap-target_v_ap)/max_acc.

lock throttle to 0.
print "waiting "+(t_ap-dt_ap/2)+" s".
pwait(t_ap-dt_ap/2).

lock throttle to 1.
wait until ship:periapsis > a_target.
lock throttle to 0.

print "Orbit reached: A/P/T  "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+" / "+a_target.
myexit().