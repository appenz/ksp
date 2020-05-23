// Rendevous with another craft

run once libguido.
run once liborbital.

myinit().

declare parameter dst is vessel("KSS").

set alt_ship to (ship:apoapsis+ship:periapsis)/2.
set alt_dst to (dst:apoapsis+dst:periapsis)/2.

if dst:distance > 10000 {

  // Calculate time for Hohmann Transfer
  set t_trans to t_hohmann(alt_ship, alt_dst).

  // Calculate how much target will have moved
  set a_trans to 180-360/dst:orbit:period*t_trans.

  print "calculating hohmann transfer.".
  print "duration: "+round(t_trans,0)+" sec".
  print "phase an: "+round(a_trans,1)+" deg".

  set a to 999.

  lock steering to prograde.

  until a-a_trans < 0.1 {
    set a to mod(dst:longitude-ship:longitude+720,360).
    set da to mod(a-a_trans+720,360).
    set dt to da/( 360*(dst:orbit:period-ship:orbit:period) / (ship:orbit:period^2)  )*0.9. 
    print1s("delta:"+round(da,4)+"  dt: "+round(dt,1)+" s").
    
    // Adjust speed
    set_warp_for_t(dt-10).
    wait max(dt-55,1).
  }
  
  wait_turn(ship:prograde).
  lock steering to ship:prograde.
  wait 1.
  print "starting burn.".
  until ship:apoapsis > alt_dst {
    if alt_dst-ship:apoapsis < 1000 {
      lock throttle to 0.01.
    } else {
      lock throttle to 0.1.
    }
    wait 0.1.
  }

  lock throttle to 0.
  wait 0.1.
  rwait(eta:apoapsis).
}

set done to false.

until done {

  // Adjust speed if needed.
  set v_rel to dst:velocity:orbit - ship:velocity:orbit.
  print "v_rel: "+v_rel:mag+"  dist: "+dst:position:mag.
  
  if v_rel:mag > 1 {

    // Zero out relative speed.
    print "reducing relative speed.".
    set v_rel to dst:velocity:orbit - ship:velocity:orbit.
    wait_turn(v_rel:direction).

    until v_rel:mag < 1 {
      set v_rel to dst:velocity:orbit - ship:velocity:orbit.
      lock steering to v_rel:direction.
      set_throttle(v_rel:mag,2).
      wait 0.1.
    }
    lock throttle to 0.
    wait 0.1.      
  } 

  // Move closer if needed

  print "v_rel: "+round(v_rel:mag,1)+"  dist: "+round(dst:position:mag).

  if dst:position:mag > 100 {
    print "accelerating toward target.".

    wait_turn(dst:position:direction).
    wait 1.
    set v_rel to dst:velocity:orbit - ship:velocity:orbit.
    set speed to max(2,dst:position:mag/120).
    print "approaching v: "+speed.
   
    until v_rel:mag > speed {
      set_throttle(10,2).
      lock steering to dst:position:direction.
      set v_rel to dst:velocity:orbit - ship:velocity:orbit.
      wait 0.1.
    }

    lock throttle to 0.

    print "in transit, turning to break.".

    set old_dist to 999999.

    until dst:position:mag < 100 OR old_dist < dst:position:mag {
      set v_rel to dst:velocity:orbit - ship:velocity:orbit.
      lock steering to v_rel:direction.
      set dv to v_rel:mag.
      set dt to dv/(ship:maxthrust/ship:mass).
      set t_left to dst:position:mag/dv.
      if t_left < 10 {
        set_throttle(dv,10).
      }

      set old_dist to dst:position:mag.
      wait 0.2.
    }
  }

  set v_rel to dst:velocity:orbit - ship:velocity:orbit.
  if dst:position:mag < 100 AND v_rel:mag < 1 {
    set done to True.
  }
}

// Try to get speed down to as low as possible.

// Zero out relative speed.
print "arrived. attempting to zero speed.".
set v_rel to dst:velocity:orbit - ship:velocity:orbit.
wait_turn(v_rel:direction).
wait 2.

set v_old to 99999.
until v_rel:mag > v_old {
  set v_old to v_rel:mag.
  set v_rel to dst:velocity:orbit - ship:velocity:orbit.
  lock steering to v_rel:direction.
  lock throttle to 0.01.
  wait 0.1.
  set v_rel to dst:velocity:orbit - ship:velocity:orbit.
}
lock throttle to 0.

myexit().
print "done.".
