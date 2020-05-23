// Change Orbit of Current Ship

declare parameter alt_new.
declare parameter warpspeed is 0.

run once libguido.
run once libtransfer.
myinit().

// Check if there is anything to do.

set apo_p to abs( (ship:apoapsis-alt_new)/alt_new). 
set per_p to abs( (ship:periapsis-alt_new)/alt_new). 

if apo_p < 0.01 AND per_p < 0.01 {
   print "nothing to do. reorb done.".
} else {
    set done to false.
    set firsttime to true.
    until done {
        set t_pe to eta:periapsis.
        set t_ap to eta:apoapsis.
        set ap to ship:apoapsis.
        set pe to ship:periapsis.

        set max_acc to ship:maxthrust/ship:mass.
        set v_new to vv_circular(alt_new).
        set v_ap to vv_alt(ship:apoapsis).
        set v_pe to vv_alt(ship:periapsis).
        set target_v_pe to vv_axis(ship:periapsis,(ship:periapsis+2*body:radius+alt_new)/2).
        set target_v_ap to vv_axis(ship:apoapsis,(ship:apoapsis+2*body:radius+alt_new)/2).
        set dv_ap to target_v_ap-v_ap.
        set dv_pe to target_v_pe-v_pe.
        set apo_p to abs( (ship:apoapsis-alt_new)/alt_new). 
        set per_p to abs( (ship:periapsis-alt_new)/alt_new). 

        set thr to 1.0.

        if firsttime {
            print "Change to new Circular Orbit v1.0".
            print "target altitude: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis).
            print "difference:      "+floor(apo_p*100)+"% / "+floor(per_p*100)+"%".
            print "target velocity: "+round(v_new,1)+" m/s".
            set firsttime to false.
        }

        if t_pe > t_ap and t_ap > 60 {
            // Apoapsis maneuver
            set mynode to NODE(time:seconds+eta:apoapsis,0,0,dv_ap).
            ADD mynode.
            exec_n(mynode, warpspeed).
        } else if t_pe > 60 {
            // Periapsis maneuver
            set mynode to NODE(time:seconds+eta:periapsis,0,0,dv_pe).
            ADD mynode.
            exec_n(mynode, warpspeed).
        } else {
            print "too close to node, waiting.".
            rwait(60).
        }

        set apo_p to abs( (ship:apoapsis-alt_new)/alt_new). 
        set per_p to abs( (ship:periapsis-alt_new)/alt_new). 
        print "check: "+alt_new+" vs. "+floor(ship:apoapsis)+" / "+floor(ship:periapsis)+"  "+floor(apo_p*100)+"% / "+floor(per_p*100)+"%".

        if apo_p < 0.01 AND per_p < 0.01 {
            set done to True.
        } else {
            wait 3.
        }
    }
}

// Clean up
myexit().
print "reorb done.".