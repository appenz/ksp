//
// Adjust inclination
// Currently works for circular orbits only.
// Tries to correct AP/PE changes.
// Allows to specify the LAN.

parameter incl_new is 0.
parameter lan_new is ship:orbit:lan.
parameter wrp is 0.

run once libguido.
run once libtransfer.
myinit().

clear_all_nodes().

// Check if there is anything to do.
set i to ship:orbit:inclination - incl_new.
if abs(i) < 0.01 {
    print "inclination check passed: "+round(i,3)+" deg  error: "+percent_err(incl_new,ship:orbit:inclination).
    print "nothing to do.".
} else {
    print "incl check #1: "+round(i,3)+" deg  error: "+percent_err(incl_new,ship:orbit:inclination).

    // calculate angle 
    set mynode to NODE(time_to_long(lan_new-body:rotationangle)+time:seconds,0,0,0).
    ADD mynode.

    set step to 10.
    set i to 998.
    set old_i to 999.
    set d_nor to 0.

    clr_status().

    // Optimize inclination, very normal burn.
    until step < 0.1 OR i < 0.001 {
    	set old_i to i.
    	set mynode:normal to d_nor+step.
    	if abs(mynode:orbit:inclination-incl_new) < old_i {
    		set d_nor to d_nor+step.
    	} else {
	    	set mynode:normal to d_nor-step.
	    	if abs(mynode:orbit:inclination-incl_new) < old_i {
	    		set d_nor to d_nor-step.
	    	} 
    	}
    	set mynode:normal to d_nor.
    	set i to abs(mynode:orbit:inclination-incl_new).
    	if i >= old_i {
    		set step to step/2.
    	}
    	p_status("incl : "+round(mynode:orbit:inclination,3)+" / "+round(incl_new,3),0).
    	p_status("d_nor: "+round(d_nor,1),1).
    	p_status("step:  "+round(step,2),2).

        if mynode:deltav:mag > 2000 {
            panic("Delta V out of range?").
        }
    }

    // Try to fix any periapsis change
    set d_ap to abs(mynode:orbit:apoapsis-ship:apoapsis).
    set d_pe to abs(mynode:orbit:periapsis-ship:periapsis).
    if d_ap > d_pe {
    	// Looks like the burn changed the Apoapsis, burn node is periapsis. 
    	set dv2_tar to vv_circular(mynode:orbit:periapsis).
    	set dv2_act to vv_axis(mynode:orbit:periapsis,(mynode:orbit:apoapsis+mynode:orbit:periapsis)/2+body:radius).
    	set mynode:prograde to -(dv2_act-dv2_tar).
    } else {
    	// Looks like the burn changed the Apoapsis, burn node is periapsis. 
    	set dv2_tar to vv_circular(mynode:orbit:apoapsis).
    	set dv2_act to vv_axis(mynode:orbit:apoapsis,(mynode:orbit:apoapsis+mynode:orbit:periapsis)/2+body:radius).
    	set mynode:prograde to -(dv2_act-dv2_tar).
    }
}

if hasnode {
    exec_n(mynode,wrp).
    set i to ship:orbit:inclination - incl_new.
    print "incl. check #2: "+round(i,3)+"  error: "+percent_err(incl_new,ship:orbit:inclination).
}

myexit().