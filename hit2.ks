// Landing and hit a target.
//
// Assumes:
// - No staging required
// - Ignores athmosphere (for now)
// - Assume latitude is the one of the orbit (within < 0.1 deg).

parameter target_long is 4.
parameter target_lat  is 0.

run once libguido.
myinit().

// Hover just above landing site.

function set_up_landing {

  set bd to ship:orbit:body.
  set g to bd:mu / bd:radius^2.

  print " ".
  print "landing site: "+"  "+bd:name+" @ "+target_long+" long / "+target_lat+" lat".
  print "approaching site.".

  set da to mod(target_long-5-longitude+720,360).
  lock steering to ship:retrograde.

  set done to false.
  
  // Get ready for burn.
  until done {
    set da to mod(target_long-longitude+720,360).
    set dt to da/360*ship:orbit:period. 
    set a_max to maxthrust/mass - g.
    set v_orb to ship:velocity:orbit:mag.
    set dt_left to v_orb/a_max.
    set mm to 2.

    if dt > dt_left*mm+30 {    
      // Adjust speed
      set_warp_for_t(dt-dt_left*mm+30).
      print1s("dang:"+round(da,4)+"  dt: "+round(dt,1)+" s  dt_left: "+round(dt_left,1)+" s").
      wait max((dt-dt_left*mm/3+30)/2,0.1).
    } else if dt > dt_left*mm+1 {
      set warp to 0.
      pwait(dt-dt_left*mm-1).
    } else {
      set done to true.
    }
  }

  // Burn to slow down.

  set v_orb to 999.
       
  until da < 0.01 and v_orb < 0.1 {
    set da to mod(target_long-longitude+720,360).
    set dt to da/360*ship:orbit:period. 
    set a_max to maxthrust/mass - g.
    set v_orb to ship:velocity:orbit:mag.
    set dt_left to v_orb/a_max.

    set warp to 0.
    if dt > dt_left*2 {
       // plenty of time, no action
       lock throttle to 0.
    } else {
      set_throttle(v_orb,MAX(dt*2,5)).
    }
    print1s("ang:"+round(da,3)+"  dv: "+round(v_orb,2)+" m/s  dt/left: "+round(dt,1)+" / "+round(dt_left,1)).
    wait 0.1.  
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
  wait until vang(ship:facing:vector,srfretrograde:vector) < 2 OR alt:radar < 5.
  lock steering to srfretrograde.
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
    
    print1s("lat/lon: "+round(latitude,3)+" / "+round(longitude,3)).
    //print "a: "+round(al,1)+" v: "+round(v,1)+" t_left: "+round(t_left,1)+" t_v0: "+round(t_v0,1).

    if al < 20 { gear on. }

    set dt to t_left-t_v0.

    if mod(floor(time:seconds*10),10) = 0 {
      if t_left > 5 {
        print "dt : "+dt+" s".
      } else {
        print "agl: "+al+" m".
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

  print "landed.".
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