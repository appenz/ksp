// Common Functions

@lazyglobal off.

// Constants

declare global ksplaunchpad to   LATLNG(-0.0972077948308072,  -74.557676885654786).
declare global ksprunwaystart to LATLNG(-0.048599996665065981,-74.724473624279071).
declare global ksprunwayend to   LATLNG(-0.05016922733662988, -74.498071382014942).
declare global ksplandingspot to LATLNG(-0.0,-74.72).

// Quick function to check for 1%, 2% and 5% deviation

function prec_01 {
  parameter a, b.
  if abs(a-b)/max(abs(a),abs(b)) < 0.01 { return True. } 
  return False. 
}

function prec_02 {
  parameter a, b.
  if abs(a-b)/max(abs(a),abs(b)) < 0.02 { return True. } 
  return False. 
}

function prec_05 {
  parameter a, b.
  if abs(a-b)/max(abs(a),abs(b)) < 0.05 { return True. } 
  return False. 
}

// Safe staging

function safe_stage {
    print "staging.".
    wait until stage:ready.
    stage.
    wait 0.1.
    
    // Extend solar panels if we just activated ion engines
    declare local elist to 0.
    declare local e to 0.
    list engines in elist.
    for e in elist {
        if e:IGNITION AND e:name = "ionEngine" {
            panels ON.
            print "switching to ion engines, extending solar panels.".
            break.
        }
            
    }
}

// Burn Maneuver Node
// Based on code from KOS documentation

function exec_n {
  parameter n.
  
  if n:deltav:mag < 1 {
      print "Node have dv ov "+n:deltav:mag +" m/s, ignoring.".
      REMOVE n.
      return True.
  }
  
  if ship:maxthrust = 0 {
      print "fuel exhausted. staging.".
      safe_stage().
      wait 0.1.
  }
  
  declare local dt to n:deltav:mag/(ship:maxthrust/ship:mass).
   
  print "executing node in "+round(n:eta,1)+" s  with dv: "+round(n:deltav:mag,1).
  print "est. time: "+round(dt,1).
   
  wait_turn(n:deltav:direction).
   
   if n:eta - dt/2 - 15 > 0 {
      print "waiting for burn.".
      rwait(n:eta - dt/2 -15).
      lock steering to  n:deltav.
      pwait(15).
  } else if n:eta > 0 {
      print "too close: "+round(n:eta,1)+" s".
      lock steering to  n:deltav.
      pwait(n:eta).
  }
  
  lock steering to  n:deltav.
  declare local dv0 to n:deltav.
  
  until false {
      if ship:maxthrust = 0 {
          print "fuel exhausted. staging.".
          wait until stage:ready. 
          safe_stage().
          wait 0.1.
      } else {
          set_throttle(n:deltav:mag,5).
          if vdot(dv0, n:deltav) < 0 { break. }
          if n:deltav:mag < 0.1
          {
            wait until vdot(dv0, n:deltav) < 0.5.
            break.
          }
      }
      wait 0.1.
  }
  lock throttle to 0.
  unlock steering.
  print "done. dv: "+round(n:deltav:mag,1)+" m/s".
  wait 0.1.
  remove n.
}

// Time needed for Hohmann transfer from alt1->alt2

function t_hohmann {
  parameter alt1.
  parameter alt2.
  return constant:pi*( (alt1+alt2+2*body:radius)^3/(8*body:mu) )^0.5.
}

// Velocity at a specific altitude for current orbit.

function vv_alt {
  parameter r.
  declare local gm to body:mu.
  return (gm*(2/(r+body:radius)-1/ship:orbit:semimajoraxis))^0.5.
}

// Velocity at a specific altitude for an arbitrary orbit

function vv_axis {
  parameter r.
  parameter axis.
  declare local gm to body:mu.
  return (gm*(2/(r+body:radius)-1/axis))^0.5.
}

// Velocity for a circular orbit at a given altitude AGL

function vv_circular {
  parameter r.
  return vv_axis(r, r+body:radius).
}

// Horizontal Vector

function v_hor {
  parameter v.
  declare local up_vec to 0.
  set up_vec to heading(0,90):vector.
  return v - (v*up_vec)*up_vec.
}

// Find closest approach of A to B for the next full orbit of A

function find_closest {
  parameter orbl_a.
  parameter orbl_b.
  
  declare local t to time:seconds.
  declare local dt_max to orbl_a:orbit:period. 
  declare local dt to 0.  
  declare local a_v to 0.
  declare local b_v to 0.
  declare local min_d to 999999999999.
  declare local old_min_d to 999999999999.
  declare local min_t to 0.
  
  declare local step to 0.01.
  
  // Check time in steps of 1/100.
  until dt > dt_max {
      set a_v to positionat(orbl_a,t+dt).
      set b_v  to positionat(orbl_b, t+dt).
      if (a_v-b_v):mag < min_d {
        set min_t to t+dt.
        set min_d to (a_v-b_v):mag.
      }
      set dt to dt+0.01*dt_max.
  }

  // We have an initial closest approach, now hillclimb
  
  set step to 0.01.
  set dt to min_t-t.
  
  // Check time in steps of 1/1000.
  until step < 0.000001 {
  
      set old_min_d to min_d.
      
      // Try dt+step*max
      set a_v to positionat(orbl_a, t+dt+step*dt_max).
      set b_v to positionat(orbl_b, t+dt+step*dt_max).
      if (a_v-b_v):mag < min_d {
        set dt to dt+step*dt_max.
        set min_d to (a_v-b_v):mag.
      }
      set a_v to positionat(orbl_a, t+dt-step*dt_max).
      set b_v to positionat(orbl_b, t+dt-step*dt_max).
      if (a_v-b_v):mag < min_d {
        set dt to dt-step*dt_max.
        set min_d to (a_v-b_v):mag.
      }      
      //print " dt/min_d/step  "+round(dt,1)+" / "+km(min_d)+" / "+step.
      if min_d <= old_min_d {
        // No improvement, so let's lower granularity
        set step to step/4.
      }
  }
  return min_d.
}  

// Geo coordinates for landing

declare global lat_to_m to 1.
declare global lng_to_m to 1.

function calibrate_geo {
  set lat_to_m to (latlng(0,0):position-latlng(1,0):position):mag.
  set lng_to_m to (latlng(0,0):position-latlng(0,1):position):mag.
  print "calibration of geo coordinates (equator).".
  print "1 deg lat in m: "+lat_to_m.
  print "1 deg lat in m: "+lng_to_m.
}

function geo_v {
  parameter geo_pos.
  parameter alt is 0.
  return V(geo_pos:lat*lat_to_m, geo_pos:lng*lng_to_m, geo_pos:terrainheight+alt).  
}

function rn_v {
  parameter v.
  return "("+round(v:x,1)+" "+round(v:y,1)+" "+round(v:z,1)+")".
}

// Burn at max thrust for dt

function burn {
  parameter dt.
  parameter thr.
  lock throttle to thr.
  declare local t0 is time:seconds.
  until time:seconds-t0 > dt {
      if ship:maxthrust = 0 {
          print "fuel exhausted. staging.".
          stage.
          wait 0.1.
      }
      wait 0.01.
  }
  lock throttle to 0.0.
}

// Set throttle to a 10 second burn or to max

function set_throttle {
  parameter delta_v.
  parameter dt.
  declare local max_thrust to ship:maxthrust.
  
  //print max_thrust+" "+delta_v+" "+dt.
  if max_thrust > 0 {
    lock throttle to max(min(1.0,abs(delta_v/(max_thrust/ship:mass))/dt),0.01).
  } else {
    lock throttle to 0.01.
  }
}

// timed_turn(direction, time)
// Turns the ship and returns after exactly [time] seconds

function timed_turn {
  parameter v.
  parameter t.
  lock steering to v.
  set warpmode to "physics".
  set warp to 3.
  wait t.
  kuniverse:timewarp:cancelwarp(). 
}

function wait_turn {
  parameter v.
  lock steering to v.
  set warpmode to "physics".
  set warp to 3.
  until vang(ship:facing:vector,v:vector) < 2 {
    //print ship:facing:vector +" "+ v:vector.
    wait 0.2.
  }
  kuniverse:timewarp:cancelwarp(). 
}

function wait_until_in_orbit_of {
  parameter dst_body.
  
  if ship:obt:body <> dst_body {
        print "waiting for SOI of "+dst_body:name.
        wait 1.
        set warpmode to "rails".
        set warp to 7.
        wait until ship:obt:body = dst_body.
        set warp to 0.
  }  
}

function smooth_pitch {
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

function set_warp_for_t {
  parameter t.
  if t > 110000 {
      set warp to 7.
  } else if t > 11000 {
      set warp to 6.
  } else if t > 1100 {
     set warp to 5.  
  } else if t > 110 {
      set warp to 4.    
  } else if t > 55 {
      set warp to 3.    
  } else if t > 11 {
      set warp to 2.
  } else if t > 6 {
      set warp to 1.          
  } else {
      set warp to 0.
  }
}

// rwait() - Wait in rails mode

function rwait {
  parameter dt.
  if dt < 0 {
    print "warning: rwait time negative. dt = "+round(dt,3).
  }
  set warpmode to "rails".
  declare local t to time:seconds+dt. 
  until time:seconds > t {
    set_warp_for_t(t-time:seconds).
    wait 0.2.
  }
}

function pwait {
  parameter t.
  if t < 0 {
    print "warning: pwait time negative. t = "+round(t,3).
  }
  set warpmode to "physics".
  set warp to 3.
  wait t.
  set warp to 0.
}

function pfast {
  set warpmode to "physics".
  set warp to 3.
}

function pstop {
  kuniverse:timewarp:cancelwarp().  
}

// Engines

declare function set_engine {
  parameter name_str.
  parameter on.
  
  declare local c to 0.
  declare local el to 0.
  declare local e to 0.
  declare local on_str to "".
  
  list engines in el.
  for e in el {
    if e:Name:contains(name_str) {
      if on { e:ACTIVATE(). }
      else  { e:SHUTDOWN(). }
    }
    set c to c+1.
  }
  if on {set on_str to "on".  }
  else  {set on_str to "off". }
  print "switched "+c+" engines of type "+name_str+" to "+on_str.
}

declare function rapier_air {
  declare local c to 0.
  declare local el to 0.
  declare local e to 0.

  list engines in el.
  for e in el {
    if e:Name:contains("RAPIER") {
      if e:mode = "ClosedCycle" { e:TOGGLEMODE(). }
      set c to c+1.
    }
  }
  print "Switched "+c+" x RAPIERs to air-breathing.".
}

declare function rapier_space {
  declare local c to 0.
  declare local el to 0.
  declare local e to 0.

  list engines in el.
  for e in el {
    if e:Name:contains("RAPIER") {
      if e:mode <> "ClosedCycle" { e:TOGGLEMODE(). }
      set c to c+1.
    }
  }
  print "Switched "+c+" x RAPIERs to closed cycle.".
}


// Quicksave

function myquicksave {
    parameter name.
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO(name).
    print "saving progress: "+name.
}

// Printing/Logging

declare global last_print to 0.

// Print only if 1s has passed
function print1s {
  parameter s.
  if time:seconds-last_print > 1 {
    print s.
    set last_print to time:seconds.
  }
}

// Print status on the right side of the terminal.
function p_status {
  parameter s.
  parameter l.
  set s to "  "+s+"                              ".
  print s:substring(0,32) AT(terminal:width-32,l+1).
}

function clr_status {
  p_status("----------- Status -----------",-1).
  p_status("",0).
  p_status("",1).
  p_status("",2).
  p_status("",3).
  p_status("",4).
  p_status("",5).
  p_status("",6).
  p_status("------------------------------",7).
}

// Print distance as 10,000km

function p3d {
    parameter v.
    set v to floor(v).
    if v > 100 { return v. }
    if v > 10  { return "0"+v.  }
    if v > 0   { return "00"+v.  }
}

function km {
    parameter d.
    if d > 1000000000 {
        return floor(d/1000000000)+","+p3d(floor(mod(d,1000000000)/1000000))+","+p3d(floor(mod(d,1000000)/1000))+" km".
    } else if d > 1000000 {
        return floor(d/1000000)+","+p3d(floor(mod(d,1000000)/1000))+" km".
    } else if d > 1000 {
        return round(d/1000,1)+" km". 
    } else if d > 10 {
        return round(d,0)+" m".
    } else if d > 1 {
        return round(d,1)+" m".
    } else {
        return round(d,2)+" m".
    }        
}

// Print percentage of a of b
function percent {
    parameter a.
    parameter b.
    
    if b = 0 { return "N/A". }
    local p is abs(a/b)*100.
    if p > 5 {
      return round(p)+"%".
    } else {
      return round(p,1)+"%".
    }  
}

// Print percentage of a of b
function percent_err {
    parameter a.
    parameter b.
    
    return percent(a-b,b).
}

declare global time_zero to 0.

function mytimer_s {
  set time_zero to time:seconds.
}

function mytimer {
  return "["+round(time:seconds-time_zero,1)+" s]  ".
}

function myinit {
  sas off.
  lock throttle to 0.0.
  kuniverse:timewarp:cancelwarp(). 
  wait 1.
}

function myexit {
  lock throttle to 0.0.
  kuniverse:timewarp:cancelwarp(). 
  wait 0.1.
  sas on.
}

function panic {
  parameter s.
  print "PANIC: "+s.
  KUniverse:PAUSE().
}