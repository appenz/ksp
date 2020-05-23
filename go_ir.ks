//
//  Launch a new IR Telescope on a new orbit
//

parameter ir_ap.
parameter ir_pe.
parameter ir_incl is 0.
parameter ir_lan is 0.

run once libguido.
run once liborbital.

if ir_ap < ir_pe {
	panic("AP < PE!.").
}

set ir_ap to 1000000*ir_ap.
set ir_pe to 1000000*ir_pe.

// Launch from Kerbin to Minmus
print "Launching IR Telescope to Orbit".
print "AP  : "+km(ir_ap).
print "PE  : "+km(ir_pe).
if ir_incl <> 0 {
	print "Incl: "+ir_incl.
	print "LAN : "+ir_lan.
}

if body = Kerbin {
  if ship:altitude < 65000 {
	myquicksave("x0-prelaunch").
    run go_orb(250000).
    myquicksave("x1-orbit").
  }
  lock throttle to 0.
  panels ON.

  if ship:orbit:inclination > 0.01 {
    run incl.
    myquicksave("x2a-postincl").
  }

  // Escape Kerbin
  // We are sloppy and don't care where we burn.
  // 1000 m/s burn should do it.
  set mynode to NODE(time:seconds+600,0,0,1000).
  ADD mynode.
  exec_n(mynode,0).
  wait_until_in_orbit_of(Sun).		
  print "In orbit around the Sun.".
  myquicksave("x3-solarorbit").
} 

if ship:apoapsis > ir_ap {
	// Outside of Kerbin Orbit.
	run reorb(ir_pe).
	set n to change_ap_at_pe(ir_ap).
	ADD n.
	exec_n(n).
	myquicksave("x5-finalorbit").
} else {
	// Outside of Kerbin Orbit.
	run reorb(ir_ap).
	set n to change_pe_at_ap(ir_pe).
	ADD n.
	exec_n(n).
	myquicksave("x5-finalorbit").

}
myexit().
