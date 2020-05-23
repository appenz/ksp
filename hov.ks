// Hover to a location. 
//
// Assumes:
// - No staging required

run once libguido.
myinit().

declare parameter thespot is latlng(0,0).

if floor(thespot:distance-latlng(0,0):distance)<10 {
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
      
    until al < alt_tar {
        set a_max to maxthrust/mass.
        set al to alt:radar.
        set up_vec to heading(0,90):vector.
   
        set dx_vec to (loc:position-ship:position).
        set v_vec to ship:velocity:surface.
   
        // Calculate time to impact (0 MSL)
        set v to -v_vec*up_vec.

        set hv_vec to v_vec - (v_vec*up_vec)*up_vec.        
        set vv_vec to v_vec - hv_vec. 

        // Time to impact and time until we want to have stopped
        set t_left to (-v+(v^2+2*(max(al,0))*g)^0.5)/g+0.00001. 
        set t_left_stop to (-v+(v^2+2*(max(al-alt_tar,0))*g)^0.5)/g+0.00001.


        // Calculate target velocity that would make us hit the target 
        set v_target_vec to dx_vec*(1/t_left).
        
        // Correct by the fact that we want to have v=0 at al=0
        // Split into horizontal and vertical
        set hv_target_vec to v_target_vec - (v_target_vec*up_vec)*up_vec.        
        set vv_target_vec to v_target_vec - hv_target_vec. 
        // Define velocity goal
        set v_goal to t_left_stop*a_max.
        
        // If vertical speed exceeds target, correct it to target
        if vv_target_vec:mag > v_goal {
          set vv_target_vec to vv_target_vec:normalized*v_goal.
        }         
        
        set v_target_vec to hv_target_vec + vv_target_vec.
                          
        // Burn is the difference between velocities.
        set delta_v to v_target_vec-v_vec.
                
        if (delta_v*up_vec < 0 OR v_goal > vv_target_vec:mag) {
          // Make sure we never steer up and we don't brake befor necessary.
          p_status("retro: horizontal mode.",0).
          set hdelta_v to delta_v - (delta_v*up_vec)*up_vec.        
          set delta_v to hdelta_v.
          set mod to 0.
        } else {
          p_status("retro: vertical mode.",0).
          set mod to 1.
        }
      
        // Dampen small corrections      
        if delta_v:mag > 1 {
          set thr_mm to 1.0.
        } else {
          set thr_mm to 0.1.
        }

        if vang(delta_v,ship:facing:vector) > 10 AND mod = 0 {
            // Too far off, don't burn yet.
            set thr_mm to 0.
            p_status("retro: turning da: "+round(vang(delta_v,ship:facing:vector),1),0).
        }


        // For the last 30 seconds, smooth turn to retrograde
        if t_left < 30 AND vang(delta_v,ship:retrograde:vector) > abs(t_left) {
            p_status("retro: angle correction ",0).    
            lock steering to (abs(30-t_left)/10*ship:retrograde:vector+delta_v:normalized):direction.
        } else {
            lock steering to delta_v:direction.
        }
        
        if time:seconds-t0 > 5 { 
          // Set throttle to time it takes to normalize delta_v
          lock throttle to thr_mm*max(min(1.0,1*(delta_v:mag)/(a_max-g)),0).
          p_status("dst : "+km(dx_vec:mag),1).
          p_status("v   : "+round(v,2)+"  goal: "+round(v_goal,2),2).
          p_status("dv_v: "+round(delta_v*up_vec,1)+"  dv:"+round(delta_v:mag,1),3).  
          p_status("thr : "+round(throttle,2)+"  t: "+round(t_left,1),4).
          p_status("alt : "+km(al)+"  / da: "+round(al-alt_tar,1),5).
          p_status(" h/v: "+round(hv_vec:mag,1)+" / "+round(vv_vec:mag,1),6).
          p_status("dh/v: "+round(hv_target_vec:mag,1)+" / "+round(vv_target_vec:mag,1),7).
          wait 0.1.
        }
    }
    lock throttle to 0.0.
    unlock throttle.
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

  p_status("tland.",0).

  sas off.
  lock steering to heading(0,90).
  lock throttle to 0.

  // turn
  if vang(ship:facing:vector,up_vec) > 45 {
      until vang(ship:facing:vector,up_vec) < 45 {
        p_status("hover: turn da "+round(vang(ship:facing:vector,up_vec),1),0).
      }
      wait 0.1.
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

    p_status("dst : "+km(dx_vec:mag),1).
    p_status("v   : "+round(v,1)+"  vs. "+round(v_goal,1),2).
    p_status("dv_v: "+round(delta_v*up_vec,1)+"  dv:"+round(delta_v:mag,1),3).  
    p_status("thr : "+round(throttle,2),4).
    p_status("alt : "+km(al)+"  / da: "+round(al-alt_tar,1),5).
    p_status("ctrl: "+round(h_speed,1)+" / "+inc_m,6).
    p_status("",7)

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

clr_status().
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
