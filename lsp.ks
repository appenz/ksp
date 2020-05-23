//
// Land Spaceplane
//
// Start at 80,000 ft
// Land on runway at KSC

run once libguido.
run once liborbital.
myinit().

set runway_g to ksprunwaystart.
set runway_lat to runway_g:lat.
set runway_lng to runway_g:lng.
set landing_spot_alt to runway_g:TERRAINHEIGHT.

set rw_vector to v_hor(ksprunwayend:position-ksprunwaystart:position).

set v_td to 60.
set v_cruise to 500.
set dst_lng to mod(runway_lng-105+720,360).

// Pitch parameters
set p_entry to 10. 
set p_land to 4.
set p_maxpitchdown to -20.
set n to ship:name.
set glideslope to 0.15.
set r_max to 45.

// Altitude parameters
set ap_alt_error to -10.
set alt_landing to 50.

// Configure the steering manager
set SteeringManager:ROLLCONTROLANGLERANGE to 180.


if n = "SSTO-1" {
  print "SSTO-1 Workhorse".
} else if n = "SSTO-2" {
  print "SSTO-2 Mini".
  set dst_lng to mod(runway_lng-130+720,360).
  set p_entry to 20.
  set p_maxpitchdown to -10.
  set r_max to 20.
  set p_land to 10.
  set v_td to 75.
  print "Standard SSTO Space Plane".
}

set dash_str to "---------------".

function smooth_pitch_l {
  parameter mycourse.
  parameter old_pitch.
  parameter new_pitch.
  parameter t is 15.
  
  declare local s is 0.
  
  until s > t {
    lock steering to heading( mycourse, (old_pitch*(t-s)+new_pitch*s)/t ).
    //print            heading( mycourse, (old_pitch*(t-s)+new_pitch*s)/t ).
    set s to s+0.1.
    wait 0.1.
  }
}


print "  v_td: "+v_td+" m/s".

print "Space plane landing started. alt: "+round(ship:altitude).
print "Landing spot altitude: "+km(landing_spot_alt).

if ship:periapsis >  68000 {

  // Plan re-entry.

  if abs(ship:apoapsis-80000) > 1000 {
      panic("WARNING: Apoapsis expected to be 80km. You won't hit KSC!").
  }
  
  print "re-entry maneuver.".
  set da to mod(dst_lng-longitude+720,360).
  set rot_corr to 1+ship:orbit:period/body:rotationperiod. // Kerbin rotates under us, correct for that.
  set dt to da*(ship:orbit:period)/360*rot_corr.
  set dv to vv_alt(ship:apoapsis)-vv_axis(ship:apoapsis,(ship:apoapsis+2*body:radius+0)/2).
  set mynode to NODE(dt+time:seconds,0,0,-dv).
  ADD mynode.
  exec_n(mynode,3).

  myquicksave("x5-prereentry").
    
  print "re-entry set up complete. pe: "+km(ship:periapsis).
}

if ship:altitude > 70000 {
  wait 3.
  set warpmode to "rails".
  set warp to 4.
  wait until ship:altitude < 70000.
}

if ship:altitude > 30000 {
  print "re-entry into athmosphere.".
  lock steering to heading(90,p_entry).
  brakes on.  
  set warpmode to "physics".
  set warp to 3.
  
  wait until ship:altitude < 30000.
  print "30,000 feet.".
  smooth_pitch_l(90, 10, 0, 10).
  pstop().
 }

// Descent to 10,000
if ship:altitude > 11000 AND ship:velocity:surface:mag > v_cruise { 
  clr_status().
  myquicksave("x6-above10k",1).
  p_status("Mode: Descent to 10,000",0).

  brakes on.
  lock steering to heading(90,0).

  set pitch_high to True.
  until ship:altitude < 11000 OR ship:velocity:surface:mag < v_cruise {
      set v to ship:velocity:surface:mag.
      if v < 1400 AND pitch_high {
          print "speed < 1,400 m/s. pitching down.".
          smooth_pitch_l(90, 0, p_maxpitchdown, 10).
          set pitch_high to False.
      }
      wait 0.1.
  }  
} 

// From now on, we fly actively to the runway. 
// Accelerate if needed. Steer to the right latitude.

if alt:radar > 100 {
  // Flight mode

  myquicksave("x7-flying",1).
  brakes off.
  print "transitioning to flight. a: "+ship:altitude.

  set p_base to 0.  
  set_engine("nuclear",0).
  rapier_air().
  intakes on.
  lock throttle to 0.
  wait 0.1.
  set old_dst to 999999.
  clr_status().

  // Need to do this outside of the loop to avoid resetting SteeringManager
  set tar_yaw to 0.
  set p to p_maxpitchdown.
  set roll to 0.
  lock steering to heading(90+tar_yaw,p,roll).
 
  until alt:radar < alt_landing {
  
    // distance and velocity is horizontal component only.
    set dst to  v_hor(ship:position-runway_g:position):mag.
    set v to v_hor(ship:velocity:surface):mag.
    set a to ship:altitude.

    // -- Throttle/Brakes
    // Target speed at V_TD 1 km from runway. Minimum v_td, Maximum, v_cruise.
    set v_target to  min_x_max(v_td,max(dst,0)/50,v_cruise).

    if v < v_target {
        lock throttle to min(1.0,(v_target-v)/v_target*10).
        brakes off.
    } else if v > v_target*1.3 {
        lock throttle to 0.0.
        if dst > 5000 { brakes on. } // Too unstable on final 
    } else {
        lock throttle to 0.0.
        brakes off.
    }    

    // -- Pitch
    if old_dst < dst {
      // past the target
      set tar_alt to landing_spot_alt.
    } else {
      set tar_alt to min(10000,dst*glideslope)+landing_spot_alt-ap_alt_error.
    }
    set old_dst to dst.
    set del_p to min_x_max(p_maxpitchdown,(tar_alt-a)/v*10,5).
    set p to p_base+del_p.

    // -- Heading
    set d_lat to latitude-runway_lat.
    set tar_yaw to min_x_max(-5,d_lat*100,5).
    set ship_yaw to vang(v_hor(ship:facing:vector),heading(45,0):vector)-45.

    // Left had coordinate system -> positive is left
    if dst > 5000 {
      set roll to min_x_max(-r_max,-10*(tar_yaw-ship_yaw),r_max).
    } else {
      set roll to 0.
    }
    
    // Gear at 2km distance. 
    if gear = False and dst < 2000 {
      gear on.
    }

    if dst*glideslope > 10000 {
      p_status("Mode: GS Intercept",0).
    } else if v_target = v_cruise {
      p_status("Mode: On GS, max speed",0).
    } else {
      p_status("Mode: On GS, slowing down",0).
    }

    p_status("dist.: "+km(dst)+"  ETA: "+round(dst/v)+" s",1).
    p_status("speed: "+round(v,1)+" m/s  t_v:"+round(v_target,1),2).
    p_status("alt. : "+km(a)+"  vs "+km(tar_alt),3).
    p_status("pitch: "+round(p,1)+"  roll: "+round(roll,1),4).
    p_status("d_lat: "+round(d_lat,3),5).
    p_status("yaw  : "+round(ship_yaw,2)+" vs "+round(tar_yaw,2),6).
    
    set s_str to dash_str:substring(0, min_x_max(1,tar_yaw*3,13)).
    if tar_yaw < 0 {
      p_status( (" <"+s_str):padleft(15),7).
    } else {
      p_status( ("               "+s_str+"> "),7).      
    }
    wait 0.1.
  }
}

print "landing mode at alt: "+km(alt:radar).

// Flare and land.
lock steering to heading(90.42, p_land).
lock throttle to 0.0.
brakes on.

until v < 0.1. {
  p_status("Mode: Landing.",0).
  wait 0.1.
}

wait until ship:velocity:surface < 0.1.
wait 3.
myquicksave("x8-landed",10).
myexit().
print "Stopped.".

