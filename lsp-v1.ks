// Spaceplane return

run once libguido.
myinit().

set runway_g to ksprunwaystart.
set runway_lat to runway_g:lat.
set runway_lng to runway_g:lng.
set landing_spot_alt to runway_g:TERRAINHEIGHT.

set v_td to 50.
set v_cruise to 300.
set dst_lng to mod(runway_lng-100+720,360).
set p_entry to 45. 
set n to ship:name.
set glideslope to 0.15.
set ap_alt_error to 50.

if n = "Other" {
  // Do nothing
  print "Other???".
} else {
  print "Standard SSTO Space Plane".
}

print "  v_td: "+v_td+" m/s".

print "Space plane landing started. alt: "+round(ship:altitude).
print "Landing spot altitude: "+km(landing_spot_alt).

if ship:periapsis >  68000 {

  // Plan re-entry.
  
  print "re-entry maneuver.".
  set da to mod(dst_lng-longitude+720,360).
  set dt to da*ship:orbit:period/360.
  set dv to vv_alt(ship:apoapsis)-vv_axis(ship:apoapsis,(ship:apoapsis+2*body:radius+0)/2).
  set mynode to NODE(dt+time:seconds,0,0,-dv).
  ADD mynode.
  exec_n(mynode).
    
  print "re-entry set up complete. pe: "+km(ship:periapsis).

  wait 3.
  set warpmode to "rails".
  set warp to 4.
  wait until ship:altitude < 70000.
  
  print "re-entry into athmosphere.".
  lock steering to heading(90,10).
  brakes on.  
  set warpmode to "physics".
  set warp to 3.
  
  wait until ship:altitude < 30000.
  print "30,000 feet.".
  smooth_pitch(90, 10, 0, 10).
  pstop().
 }

// Descent to 10,000

if ship:altitude > 10000 { 
  brakes on.
  set steering to heading(90,0).
  print "descending to 10,000 m".
  set pitch_high to True.
    until ship:altitude < 10000 {
    set v to ship:velocity:surface:mag.
    if v < 1400 AND pitch_high {
        print "speed < 1,400 m/s. pitching down.".
        smooth_pitch(90, 0, -20, 10).
        set pitch_high to False.
    }
    wait 0.1.
  }  
} 

// From now on, we fly actively to the runway. 
// Accelerate if needed. Steer to the right latitude.

if alt:radar > 100 {
  // Transitioning to flight
  
  brakes off.
  print "transitioning to flight. a: "+ship:altitude.

  set p_base to 0.  
  set_engine("nuclear",0).
  rapier_air().
  intakes on.
  lock throttle to 0.
  wait 0.1.
  set old_dst to 999999.
  
  until alt:radar < 50 {
  
    // distance and velocity is horizontal component only.
    set dst to  v_hor(ship:position-runway_g:position):mag.
    set v to v_hor(ship:velocity:surface):mag.
    set a to ship:altitude.

    // -- Throttle     
    if dst > v_cruise*60 {
        set v_target to v_cruise.
    } else if dst > v*15 {
       set v_target to v_td*1.5.        
    } else {
        set v_target to v_td.
    }

    if v < v_target {
        set throttle to min(1.0,(v_target-v)/v_target*25).
    } else {
        set throttle to 0.0.
    }    

    // -- Pitch
    if old_dst < dst {
      // past the target
      set tar_alt to landing_spot_alt.
    } else {
      set tar_alt to min(9000,dst*glideslope)+landing_spot_alt-ap_alt_error.
    }
    set old_dst to dst.
    set del_p to max(min((tar_alt-a)/10,5),-20).
    set p to p_base+del_p.

    // -- Heading
    set d_lat to abs(latitude-runway_lat).
    set d_head to min(5,abs(d_lat)*500).

    if latitude < runway_lat {
        lock steering to heading(90-d_head,p).
    } else {
        lock steering to heading(90+d_head,p).
    }
    
    // Gear at 2km distance. 
    if gear = False and dst < 2000 {
      gear on.
    }

    print1s(  "dst: "   +round(dst,1)+
         "  d_lat: " +round(d_lat,4)+
         "  d_head: "+round(d_head,2)+
         "  v: "     +round(v,1) +
         "  a: "     +round(a,0) +
         "  da: "    +round(tar_alt-a) +
         "  p: "     +round(p,1)
         ).
         
    wait 0.2.
  }
}

// Land.

// Flare and land.
lock steering to heading(90.42, 4).
lock throttle to 0.0.
brakes on.

until v < 0.1. {
  wait 0.1.
}

myexit().
print "Landed.".

