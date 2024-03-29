// Planetary Tranfer Library

@lazyglobal off.

run once libguido.
run once libtransfer.

// Orbit table
// Format is Body, Standard Orbit, Aerocapture Orbit, Departure Orbit

declare global orbit_table to list(
    list(Kerbin, 150, 45, 1000),
    list(Duna, 100, 15, 500),
    list(Eve, 200, 90, 500 ),
    list(Dres, 100, 100, 500)
).

function get_orbit_data {
    parameter dst.
    declare local p to 0.

    for p in orbit_table {
        if ship:orbit:body = p[0] {
            return p.
        }
    }
    print "orbital parameter lookup failed for "+dst.
    return list(0,0,0).
}

// Get into a stable orbit around a planet or moon
// Assumes we are already in the SOI of the planet
//
// Parameters: Destination, target altitude (0 for capture), yes/no flag if we should try to fix inclination.

function capture_1 {
    parameter dst is ship:orbit:body.
    parameter dst_alt is -1.
    parameter wrp is 0.
    
    declare local s to "".
    
    // If no altitude was specified, figure it out
    
    if dst_alt <= 0 {
       local p_data is get_orbit_data(dst).
       if dst_alt = 0 {
            // Aerocapture
            set dst_alt to p_data[2]*1000.
            set s to ", aerocapture".
       } else {
            set dst_alt to p_data[1]*1000.
            set s to ", standard orbit".
       }
    }
    
    print "Capture mode for "+dst:name+" target alt "+km(dst_alt)+s.
    
    // Error checking that we in the right spot.
    
    if dst = ship:orbit:body {
        print "in SOI of "+body:name+"  pe: "+floor(ship:periapsis).
        if ship:apoapsis > 0 AND ship:periapsis > dst_alt*0.75 {
            print "We are in a stable orbit. Nothing to do.".
            return True.
        }
    } else {
        if dst:orbit:body = ship:orbit:body {
            print "in SOI of "+body:name+", parent of "+dst:name+"  pe: "+floor(ship:periapsis).
            panic("Capture to moons not supported yet.").
            return False.
        } else {
            print "Error: destination"+dst:name+" is not in orbit of "+body:name.
            panic("Wrong planet?").
        }
    }
    

    // If there is no maneuver node, create one. 
    local mynode is NODE(600+time:seconds,0,0,0).  
    if NOT hasnode { ADD mynode. }
    else set mynode to nextnode.

    local old_node to list(mynode:prograde, mynode:normal, mynode:radialout, mynode:eta+time:seconds).
        
    local n_pro to 0.
    local n_nor to 0.
    local n_rad to 0.
    local step to 20.
    local v to 0.
    local i to 0.
    
    local pe to calc_pe(mynode,0).
    local original_pe to pe.
    local old_pe to 0.
    local old_i to 0.
    local old_i2 to 0.
    
    clr_status().
  

    // Burn retro
    // Goal is to set/keep PE to target by going radial to raise and retrograde to lower

    set step to 1.
    set pe to vary_node(mynode, old_node, n_pro, n_nor, n_rad, 0, 0).

    until mynode:orbit:apoapsis > 0 AND mynode:orbit:apoapsis < 100000000 AND pe > dst_alt {
        set old_pe to pe.       
        if pe < dst_alt {
            // Vary radial, in whichever direction increases the PE.
            set v to vary_node(mynode, old_node, n_pro, n_nor, n_rad+step, 0, 0).
            if  v > old_pe {
                set n_rad to n_rad+step.
            } else { 
                set v to vary_node(mynode, old_node, n_pro, n_nor, n_rad-step, 0, 0).
                if  v > old_pe {
                    set n_rad to n_rad-step.
                }
            }
        } else {
            // PE is not too low, burn retrograde
            set n_pro to n_pro-step.
        }

        set pe to vary_node(mynode, old_node, n_pro, n_nor, n_rad, 0, 0).
 
        p_status("PE:  "+km(pe)+" ("+percent(pe, original_pe)+")",1).
        p_status("Incl:"+round(i    ,1),2).
        p_status("Pro: "+round(n_pro,2),3).
        p_status("Nor: "+round(n_nor,2),4).
        p_status("Rad: "+round(n_rad,2),5).
        p_status("step:"+round(step,2),6).
    }
    
    print "Maneuver pe: "+km(mynode:orbit:periapsis)+"  incl:"+mynode:orbit:inclination..
    exec_n(nextnode,wrp).
    wait 1.
    myquicksave("x6-dstorbit-1").
}

function capture_2 {

    parameter dst_alt.
    parameter wrp is 0.

    if ship:apoapsis > 0 AND ship:apoapsis < dst_alt*1.1 AND ship:periapsis > dst_alt*0.9 {
        print "Orbit looking good enough. Capture module done.".
        return True.
    }

    // Now plan the Periapsis burn.
    // This time we can simply calculate with VV equations.

    local dv is vv_circular(ship:periapsis)-vv_alt(ship:periapsis).    
    local  mynode is NODE(eta:periapsis+time:seconds,0,0,dv).  
    ADD mynode.
    
    print "breaking at PE for "+round(dv,1)+" m/s".
           
    exec_n(nextnode,wrp).
    
    print "Welcome to "+body:name+"  ap/pe: "+km(ship:apoapsis)+" / "+km(ship:periapsis).
    myquicksave("x7-dstorbit-2").
}

function capture {
    parameter dst.
    parameter dst_alt is -1.
    parameter wrp is 0.
 
    if ship:orbit:body <> dst {
      print "Wrong planet?".
      return False.
    }
 
    // Twice seems to work better
    capture_1(dst, dst_alt,wrp). 
    capture_2(dst_alt,wrp).
    
}



















