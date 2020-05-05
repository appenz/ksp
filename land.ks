// Landing function for any planet. 
//
// Assumes:
// - No staging required
// - Ignores athmosphere (for now)


run once libguido.
myinit().

// Land from suborbital flight 

function land {
  set bd to ship:orbit:body.
  set g to bd:mu / bd:radius^2.
  set a_max to maxthrust/mass - g.
  set v_land to 0.

  print " ".
  print "--- Lander v1.0 ---".
  print "landing on "+bd:name.
  print "alt  : "+round(alt:radar,2)+" m".
  print "a_max: "+round(a_max,1)+" m/s".

  sas off.
  lock steering to srfretrograde.
  lock throttle to 0.

  // turn
  print "turning retrograde.".
  wait until vang(ship:facing:vector,srfretrograde:vector) < 10 OR alt:radar < 5.
  print "turn complete.".

  // Set up math
  set v to ship:velocity:surface:mag.
  set al to alt:radar.

  set thr to 0.

  until al < 20 AND v < 0.25 {

    set v to ship:velocity:surface:mag.
    set al to alt:radar.
    set a_max to maxthrust/mass - g.
    set t_left to (-v+(v^2+2*al*g)^0.5)/g.
    set t_v0 to abs(v-v_land)/a_max.  
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
land().
lock throttle to 0.0.
wait 1.
unlock throttle.
