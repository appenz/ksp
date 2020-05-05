// Landing and hit a target.
//
// Assumes:
// - No staging required
// - Ignores athmosphere (for now)
// - Assume latitude is the one of the orbit (within < 0.1 deg).

parameter target_long is 6.
parameter target_lat  is 0.

run once libguido.
myinit().
calibrate_geo().

// Hover just above landing site.

function set_up_landing {

  set bd to ship:orbit:body.
  set g to bd:mu / bd:radius^2.

  print " ".
  print "landing site: "+"  "+bd:name+" @ "+target_long+" long / "+target_lat+" lat".
  print "approaching site.".

  set da to mod(target_long-longitude+720,360).
  set dt to da*ship:orbit:period/360-120.
  set g to bd:mu / bd:radius^2.

  print "est. time: "+round(dt)+" s".
  rwait(dt).
  set da to mod(target_long-longitude+720,360).
  set dt to da*ship:orbit:period/360-60.
  print "est. time: "+round(dt)+" s".
  rwait(dt).

  lock steering to heading(270,0).
  pwait(30).

  set da to mod(target_long-longitude+720,360).
  print "ready for burn.  da: "+round(da,1).

  // Burn to slow down.

  set gv_spot to geo_v(latlng(0,6)).
       
  set done to false.
  set v_est to -999.

  lock steering to retrograde.

  // Slow down to 50 orbital.

  print "slow down to 50 m/s".
  set_throttle(50,20).
  wait until ship:velocity:orbit:mag < 50.
  lock throttle to 0.0.

  print "aiming for landing spot.".
  set over to 999.

  until alt:radar < 2000 {
    set a_max to maxthrust/mass - g.
    set gv_ship to geo_v(ship:geoposition,ship:altitude).
    set dx to gv_spot:y-gv_ship:y.
    set v to ship:velocity:surface:mag.
    set al to alt:radar.
    set a_max to maxthrust/mass - g.
    set t_left to (-v+(v^2+2*al*g)^0.5)/g.
    
    if v_est = -999 {
      set v_est to 0.
    } else {
      set v_est to (old_x-dx)/(time:seconds-old_t).
    }
    set old_t to time:seconds.
    set old_x to dx.        
    set over to t_left*v_est-dx.

    print "spot/ship:"+rn_v(gv_spot)+" "+rn_v(gv_ship).
    print "dx:   "+dx.
    print "est v:"+v_est.
    print "est t:"+t_left.
    print "over :"+over.

    lock steering to heading(270,0).
    if over > 10000 { 
      lock throttle to 1.
    } else if over > 1000 {
      lock throttle to 0.1.
    } else if over >  100 {
      lock throttle to 0.01.
    } else {
      lock throttle to 0.
    }
    wait 1.  
  }

  set warp to 0.
  lock throttle to 0.
}


// Land from suborbital flight 

function land {
  set bd to ship:orbit:body.
  set g to bd:mu / bd:radius^2.
  set a_max to maxthrust/mass - g.
  set v_land to 0.

  print " ".
  print "landing on "+bd:name.
  print "alt  : "+round(alt:radar,2)+" m".
  print "a_max: "+round(a_max,1)+" m/s".

  // turn
  print "turning retrograde.".
  lock steering to srfretrograde.
  wait until vang(ship:facing:vector,srfretrograde:vector) < 2 OR alt:radar < 5.
  print "turn complete.".

  // Set up math
  set v to ship:velocity:surface:mag.
  set al to alt:radar.

  set thr to 0.

  until al < 20 AND v < 0.25 {

    // Landing basics
    set v to ship:velocity:surface:mag.
    set al to alt:radar.
    set a_max to maxthrust/mass - g.
    set t_left to (-v+(v^2+2*al*g)^0.5)/g.
    set t_v0 to abs(v-v_land)/a_max.  

    // Targeting logic
    // set dst_v to latlng(target_long, target_lat).
    // print "dst_v:"+dst_v:position.
    
    // print1s("lat/lon: "+round(latitude,3)+" / "+round(longitude,3)).
    // print "a: "+round(al,1)+" v: "+round(v,1)+" t_left: "+round(t_left,1)+" t_v0: "+round(t_v0,1).

    if al < 20 { gear on. }

    set dt to t_left-t_v0.

    if mod(floor(time:seconds*10),10) = 0 {
      if t_left > 5 {
        print1s("dt : "+dt+" s").
      } else {
        print1s("agl: "+al+" m").
      }
    }

    if t_left > 5 {
      // Still 5 seconds away, coarse maneuvers...
      if dt < 1 and v > 5 {
        set thr to 1.0.
      } else {
        set thr to 0.
      }
    } else {
      // Close to ground fine tune
      // calc acceleration that gets us to desired speed in 2 seconds
      set v_goal to max((al-20)/5,0).
      set dv to max(v-v_goal,0).
      set thr to min(1.0,(dv+g-3.0)/(a_max+g)).
      //print "thr:"+thr+" dv:"+dv+" goal:"+v_goal.
    }
    lock throttle to thr.

    wait 0.1.
  }

  print "landed lat: "+round(latitude,1)+" lng: "+round(longitude,1).
  lock throttle to 0.
  sas on.
}

function test_launch {
  stage.
  lock steering to heading(270,80).
  lock throttle to 1.0.
  gear off.
  wait 30.
  lock throttle to 0.
}

//test_launch().
set_up_landing().
land().
myexit().
sas on.