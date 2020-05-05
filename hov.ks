// Hover to a location. 
//
// Assumes:
// - No staging required

run once libguido.
myinit().

declare parameter thespot is latlng(0,0).

if floor(thespot:distance-latlng(0,0):distance)<10 {
  print "default".
  if body = Kerbin {
    set thespot_v to ksplaunchpad.
  } else if body = Minmus {
    set thespot to latlng(0,6).
  }
}

myinit().

// Land from suborbital flight 

function retro {

    parameter loc.
    
    set bd to ship:orbit:body.
    set g to bd:mu / bd:radius^2.
    set a_max to maxthrust/mass.
    set v to 999.
    set al to alt:radar.
    set alt_tar to 200.

    set t0 to time:seconds.
   
    print "auto-land at "+loc.
   
    until al < alt_tar {
        set a_max to maxthrust/mass.
        set al to alt:radar.
        set up_vec to heading(0,90):vector.
   
        set dx_vec to (loc:position-ship:position).
        set v_vec to ship:velocity:surface.
   
        // Calculate time to impact (0 MSL)
        set v to -v_vec*up_vec.
        set t_left to (-v+(v^2+2*(max(al-alt_tar,0))*g)^0.5)/g+0.00001.
        
        // Calculate target velocity that would make us hit the target 
        set v_target_vec to dx_vec*(1/t_left).
        
        // Correct by the fact that we want to have v=0 at al=0
        // Split into horizontal and vertical
        set hv_target_vec to v_target_vec - (v_target_vec*up_vec)*up_vec.        
        set vv_target_vec to v_target_vec - hv_target_vec. 
        // Define velocity goal
        set v_goal to t_left*a_max.
        
        // If vertical speed exceeds target, correct it to target
        if vv_target_vec:mag > v_goal {
          set vv_target_vec to vv_target_vec:normalized*v_goal.
        }         
        
        set v_target_vec to hv_target_vec + vv_target_vec.
                          
        // Burn is the difference between velocities.
        set delta_v to v_target_vec-v_vec.
                
        if delta_v*up_vec < 0 OR v_goal > vv_target_vec:mag {
          // Make sure we never steer up and we don't break befor necessary.
          print1s("stopping upwards movement.").
          set hdelta_v to delta_v - (delta_v*up_vec)*up_vec.        
          set delta_v to hdelta_v.
        }
      
        // Dampen small corrections      
        if delta_v:mag > 1 {
          set thr_mm to 1.0.
        } else {
          set thr_mm to 0.1.
        }
         
        lock steering to delta_v:direction.
        
        if time:seconds-t0 > 5 { 
          // Set throttle to time it takes to normalize delta_v
          lock throttle to thr_mm*max(min(1.0,1*(delta_v:mag)/(a_max-g)),0).
          print "v: "+round(v,1)+" thr: "+round(throttle,2)+"  al: "+round(al-alt_tar,1)+" dv: "+round(delta_v:mag,1)+" dv_vert: "+round(delta_v*up_vec,1)+"  t_left: "+round(t_left,1)+"  v_goal: "+round(v_goal,1).
          wait 0.1.
        }
    }
    lock throttle to 0.0.
    unlock throttle.
    print "transition to hover.".
}


// Land from suborbital flight 

function tspot {

    parameter loc.
    
    set bd to ship:orbit:body.
    set g to bd:mu / bd:radius^2.
    set a_max to maxthrust/mass.
    set v_land to 0.
    set al to alt:radar-100.
    set up_vec to heading(0,90):vector.
  
              
    // Calculate distance in horizontal plane
    set dx_vec to (loc:position-ship:position).
    set hx_vec to dx_vec - (dx_vec*up_vec)*up_vec.
    
    // Calculate velocity in horizontal plane.
    set dv_vec to ship:velocity:surface.
    set hv_vec to dv_vec - (dv_vec*up_vec)*up_vec.
  
    // Calculate horizontal velocity that gets us to the target.
    set v to dv_vec*up_vec.
    set t_left to (-v+(v^2+2*al*g)^0.5)/g.
 
    set dv_target_vec to dx_vec*(1/t_left).
    set hv_target_vec to dv_target_vec - (dv_target_vec*up_vec)*up_vec.
    
    // Burn is the difference between velocities.
    set delta_hv to hv_target_vec-hv_vec.
    
    lock steering to delta_hv:direction.
    pwait(10).
    
    set t to delta_hv:mag/a_max.
    lock throttle to 1.0.
    wait t.
    lock throttle to 0.0.
    unlock throttle.
}

function tland {
  parameter loc.
  set bd to ship:orbit:body.
  set g to bd:mu / bd:radius^2.
  set a_max to maxthrust/mass - g.
  set v_land to 0.
  set alt_tar to 100.

  set up_vec to heading(0,90):vector.

  sas off.
  lock steering to heading(0,90).
  lock throttle to 0.

  print "hover-land at "+loc.

  // turn
  if vang(ship:facing:vector,up_vec) > 10 {
    print "waiting to turn sfretro.".
    wait until vang(ship:facing:vector,up_vec) < 10.
  }

  // Set up math
  set v to ship:velocity:surface:mag.
  set al to alt:radar.
  set thr to 0.

  until al < 10 AND v < 0.25 {

    set v_vec to ship:velocity:surface.
    set v to -v_vec*heading(0,90):vector.
    set al to alt:radar.
    set a_max to maxthrust/mass - g.
    set t_left to (-v+(v^2+2*al*g)^0.5)/g.
    set t_v0 to abs(v-v_land)/a_max.  

    print1s("a: "+round(al,1)+" v: "+round(v,1)+" t_left: "+round(t_left,1)+" t_v0: "+round(t_v0,1)).

    if al < 20 { gear on. }
    else       { gear off. }

    // Speed
    set v_goal to (al-alt_tar)/5.
    set dv to v-v_goal.
    set thr to max(min(1.0,(dv+g)/(a_max+g)),0).
    if al > alt_tar {
      set thr to thr-0.01.
    } else {
      set thr to thr+0.01.
    }
    //print "thr:"+thr+" dv:"+dv+" goal:"+v_goal.

    // Calculate distance in horizontal plane
    set dx_vec to (loc:position-ship:position).
    set hx_vec to dx_vec - (dx_vec*up_vec)*up_vec.
    
    // Calculate velocity in horizontal plane.
    set dv_vec to ship:velocity:surface.
    set hv_vec to dv_vec - (dv_vec*up_vec)*up_vec.

    // Approximate how long it will take us to break horizontal speed
    set ha_max to (maxthrust/mass - g)*0.1*thr.
    set ht_left to hx_vec:mag/hv_vec:mag.

    // Calculate a desired velocity towards target
    // Goal is to get there in 30 seconds.
    // Max horizontal acceleration is about inclination*acceleration*throttle 

    // Max speed allowed speed is [time left] x [acceleration]
    set h_speed to ht_left*ha_max.

    // Higher precision when close.
    if hx_vec:mag > 10 {
      set inc_m to 0.2.
    } else if hx_vec:mag > 2 {
      set inc_m to 0.1.
      set h_speed to 0.5.
    } else {
      set inc_m to 0.02.
      set h_speed to 0.1.
    }

    set hv_target to hx_vec:normalized*h_speed.
    set hv_deltav to hv_vec-hv_target.

    //print "h-dist: "+round(hx_vec:mag,1)+"  h-vel: "+round(hv_vec:mag,1)+ "  inc: " + inc_m+" hv/tv/dv: " +rn_v(hv_vec) + " " + rn_v(hv_target)+ " " + rn_v(hv_deltav).
    //print "h-speed: "+round(h_speed,1)+"  ht_left: "+round(ht_left,1)+ "  inc: " + inc_m+" hv/tv/dv: " +rn_v(hv_vec) + " " + rn_v(hv_target)+ " " + rn_v(hv_deltav).
    print1s("h-speed: "+round(h_speed,1)+"  ht_left: "+round(ht_left,1)+ "  inc: " + inc_m).
        
    set str_vec to up_vec-inc_m*hv_deltav:normalized.
    lock steering to str_vec:direction.

    lock throttle to thr.
    
    if hx_vec:mag < 10 AND hv_vec:mag < 1 AND alt_tar > 0 {
      set alt_tar to alt_tar-1. 
    }
    
    wait 0.1.
  }

  print "landed.".
  lock throttle to 0.
  sas on.
}

function test_launch {
  if alt:radar > 10 { return. }
  stage.
  lock steering to heading(270,70).
  lock throttle to 1.0.
  gear off.
  wait 15.
  lock throttle to 0.
  wait(eta:apoapsis-10).
}

if true {
  retro(thespot).
  tland(thespot).
} else {
  test_launch().
  retro(ksprunwaystart).
  tland(ksprunwaystart).
}
lock throttle to 0.0.
wait 1.
myexit().
