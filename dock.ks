// Dock Two Vessels

run once libguido.

declare parameter v_max is 1.

function rcs_ctl {
  parameter d.
  parameter v.
  if d > 0.1       { set tv to -max(min(v_max, d/30),0.1). }
  else if d < -0.1 { set tv to  max(min(v_max,-d/30),0.1). }
  else {set tv to 0.}
  if v > tv {return -0.1.}
  if v < tv {return  0.1.}
  return 0.    
}

myinit().

rcs off.

set tr to target.
set cp to ship:controlpart.

print "Docking to  : "+tr:name.
print "Control from: "+cp:name.
print "Port status : "+cp:state.

// Adjust direction

print "adjusting direction.".
lock steering to lookdirup(-tr:portfacing:forevector, tr:portfacing:upvector).

set da1 to 9.
set da2 to 9.
until da1 < 1 AND da2 < 1 {
  set da1 to vang(ship:facing:forevector, -tr:portfacing:forevector).
  set da2 to vang(ship:facing:upvector,    tr:portfacing:upvector).
  print "ang diff:" + round(da1,1) + "/" + round(da2,1).
  wait 0.2.
}

// Align horizontally and vertically.

rcs on.

set done to false.

until cp:state <> "Ready" {
  set tr_dis to tr:portfacing:forevector. 
  set tr_ver to tr:portfacing:upvector. 
  set tr_hor to tr:portfacing:rightvector. 

  set tr_vec to tr:position-cp:position. 
  set tr_vel to tr:ship:velocity:orbit-ship:velocity:orbit.

  set d_dis to vdot(tr_vec, tr_dis).
  set d_ver to vdot(tr_vec, tr_ver).
  set d_hor to vdot(tr_vec, tr_hor).

  set v_dis to vdot(tr_vel, tr_dis).
  set v_ver to vdot(tr_vel, tr_ver).
  set v_hor to vdot(tr_vel, tr_hor).

  print1s("dis/ver/hor: "+round(d_dis,1)+" / "+round(d_ver,1)+" / "+round(d_hor,1)+"    "+
                          round(v_dis,1)+" / "+round(v_ver,1)+" / "+round(v_hor,1)).

  set ship:control:starboard to rcs_ctl(d_hor,v_hor).
  set ship:control:top       to -rcs_ctl(d_ver,v_ver).

  if abs(d_hor) > 0.2 or abs(d_ver) > 0.2 {
    set ship:control:fore      to rcs_ctl(0,    v_dis).
  } else {
    set ship:control:fore      to rcs_ctl(d_dis,v_dis).
  }
  wait 0.1.
}

set ship:control:neutralize to true.
rcs off.
lock throttle to 0.
unlock steering.
sas on.

print "done.".
