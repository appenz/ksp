// Planetary Tranfer Library

@lazyglobal off.
run once libguido.
run once liborbital.

// Pre-calculated transfer table
// Format is Src, Dst, Altitude/km, Phase Angle, Ejection Angle, Ejection Velocity.

declare global transfer_table to list(
    // Kerbin -----------------------------------------------
    list(Kerbin, Eve,    1000, -54.13,  143.44+180, 2226.01),
    list(Kerbin, Gilly,  1000, -54.13,  143.44+180, 2226.01),  // Same as Eve
    list(Kerbin, Duna,   1000,  44.36,  138.75,     2267.83),
    list(Kerbin, Dres,   1000,  82.06,  110.16,     2934.47),
    list(Kerbin, Jool,   1000,  96.58,  103.61,     3403.72),  // regular
    list(Kerbin, Jool,   5000,  96.58,  94.64,      2903.80),  // Ion engines
    // Moons
    list(Kerbin, Minmus, 1000,    124,  0,          0      ), 
    // Other Planets
    list(Duna,   Kerbin,  500, -75.19,  110.68+180, 1186.75),
    list(Eve,    Kerbin,  500,  36.07,  159.13,     3754.75),
    list(Dres,   Kerbin,  500,-329.68,  90.77+180,  1589.12)
).


// Helper functions for PE optimization

function calc_pe {
    parameter n.
    parameter mode.
    
    if mode = 0 {
        return n:orbit:periapsis.
    } else if mode = 1 {
        if NOT n:orbit:hasnextpatch  {   
            return 99999999999.
        } else {
            return n:orbit:nextpatch:periapsis.
        }
    } else if mode = 2 {
        if NOT n:orbit:hasnextpatch or NOT n:orbit:nextpatch:hasnextpatch {   
            return 99999999999.
        } else {
            return n:orbit:nextpatch:nextpatch:periapsis.
        }
    }
    panic("wrong mode in calc_pe").
}

function print_node {
    parameter n.
    print "N eta:"+round(n:eta,1)+
           " pro:"+round(n:prograde,1)+
           " rad:"+round(n:radialout,1)+
           " nor:"+round(n:normal,1).
}


function vary_node {
    parameter p_node.
    parameter base_values.
    parameter p_pro.
    parameter p_nor.
    parameter p_rad.
    parameter p_eta.
    parameter mode.     

    set p_node:prograde  to base_values[0]+p_pro. 
    set p_node:normal    to base_values[1]+p_nor.
    set p_node:radialout to base_values[2]+p_rad.
    //  set p_node:eta       to base_values[3]+p_eta-time:seconds. 
    
    return calc_pe(p_node, mode).
 }


// Optimize PE
//
// Parameters
// - Min PE, Max PE, Destination Body
// - Auto-detects which mode:
//   1. Current body PE. 
//   2. Nextpatch (e.g. interplanetary space for Duna). 
//   3. Nextpatch:nextpatch (i.e. still on Kerbin, heading for Duna).
// - Works with existing node or will create one 5 mins out.
// - Returns "best effort" optimization

function optimize_pe {

    parameter pe_min.
    parameter pe_max.
    parameter dst.
    
    local src is ship:orbit:body.
    local mynode is NODE(300+time:seconds,0,0,0).
    local old_node is 0.
    local dst_orb is 0.
    local mode is 0.
    
    // If there is no maneuver node, create one. 
    if NOT hasnode { ADD mynode. }
    else set mynode to nextnode.

    // Which mode are we in?

    
    if src = dst {
        // Already at the destination, just want to optimize the PE.
        print "Optimizing PE. In orbit around "+src:name.
        set mode to 0.
    } else {
        if NOT mynode:orbit:hasnextpatch { panic("Optinize_PE called with no encounter."). return False. }
        if mynode:orbit:nextpatch:body = dst {
            // Interplanetary, found encounter.
            print "Optimizing PE. Interplanetary orbit to "+dst:name.
            set mode to 1.
        } else {
            if NOT mynode:orbit:nextpatch:hasnextpatch OR mynode:orbit:nextpatch:nextpatch:body <> dst { 
                panic("Optinize_PE called with no encounter."). return False. 
            } else {
                // Interplanetary, found encounter.
                print "Optimizing PE. In orbit around "+src:name+" -> "+dst:name.
                set mode to 2.
            }
        }
            
            
    }
    
    // eta to -1 meaning it is immutable
    set old_node to list(mynode:prograde, mynode:normal, mynode:radialout, -1).
    
    local n_pro to 0.
    local n_nor to 0.
    local n_rad to 0.
    local n_eta to 0.
    local step to 10.
    local v to 0.
    
    local pe to calc_pe(mynode,mode).
    local old_pe to 0.
    local int_pe to 0.
    local original_pe is pe.
    print "pre-opt pe : "+km(pe).
    print "optimizing...".
    clr_status().
       
    print "starting".
    
    until  pe < pe_max or step < 0.03 {
        // remember PE calculated with current values . Copy into a PE for interrim.   
        set old_pe to vary_node(mynode, old_node, n_pro, n_nor, n_rad, n_eta, mode).
        set int_pe to old_pe.

        // Vary Normal
        
        set v to vary_node(mynode, old_node, n_pro, n_nor+step, n_rad, n_eta, mode).  
        if  v < int_pe AND v > pe_min {
            set n_nor to n_nor+step.
            set int_pe to calc_pe(mynode,mode).
        } else {
            set v to vary_node(mynode, old_node, n_pro, n_nor-step, n_rad, n_eta, mode).
            if v < int_pe AND v > pe_min {
                set n_nor to n_nor-step.
                set int_pe to calc_pe(mynode,mode).                   
            }   
        }
      
        // Vary Prograde 
        set v to vary_node(mynode, old_node, n_pro+step/5, n_nor, n_rad, n_eta, mode).
        if  v < int_pe AND v > pe_min {
            set n_pro to n_pro+step/5.
            set int_pe to calc_pe(mynode,mode).
        } else {
            set v to vary_node(mynode, old_node, n_pro-step/5, n_nor, n_rad, n_eta, mode).
            if v < int_pe AND v > pe_min {
                set n_pro to n_pro-step/5.
                set int_pe to calc_pe(mynode,mode). 
            }
        } 
        
        // Vary Radial
        set v to vary_node(mynode, old_node, n_pro, n_nor, n_rad+step, n_eta, mode).
        if  v < int_pe AND v > pe_min {
            set n_rad to n_rad+step.
            set int_pe to calc_pe(mynode,mode).
        } else { 
            set v to vary_node(mynode, old_node, n_pro, n_nor, n_rad-step, n_eta, mode).
            if v < int_pe AND v > pe_min {
                set n_rad to n_rad-step.
                set int_pe to calc_pe(mynode,mode).
            }
        } 
        
        set pe to vary_node(mynode, old_node, n_pro, n_nor, n_rad, n_eta, mode).

        p_status("PE:  "+km(pe)+" ("+percent(pe, original_pe)+")",1).
        p_status("ETA: "+round(n_eta-time:seconds)+"  step: "+round(step,2),2).
        p_status("Pro: "+round(n_pro,2),3).
        p_status("Nor: "+round(n_nor,2),4).
        p_status("Rad: "+round(n_rad,2),5).
        
        if old_pe <= pe {
            set step to step/3.
        }
    }
    
    print "post-opt pe: "+km(pe)+"  ETA/pro/nor/rad : "+round(n_eta)+" / "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2).

}

// Calculate time until a specific longitude on current orbit
// For now assumes circular orbit

function time_to_long {
    parameter l.
    return ship:orbit:period*mod(720+l-longitude,360)/360.
}

// Access table of transfer values

function get_planet_data {
    parameter dst.
    declare local p to 0.

    for p in transfer_table {
        if ship:orbit:body = p[0] AND dst = p[1] AND prec_01(p[2]*1000,ship:orbit:apoapsis) { return p. }
        if ship:orbit:body = Sun  AND dst = p[1] { return p. }
    }
    print "transfer parameter lookup failed for "+ship:orbit:body+" -> "+dst+" alt: "+km(ship:orbit:apoapsis).
    return list(0,0,0).
}


function calc_phase_angle {
        parameter src.
        parameter dst.        
   
        declare local as to src:obt:lan + src:obt:argumentofperiapsis + src:obt:trueanomaly. 
        declare local ad to dst:obt:lan + dst:obt:argumentofperiapsis + dst:obt:trueanomaly.
        return mod(ad-as+720,360).
}
         
    
// Wait for a transfer window.
    
function wait_transfer_window {

        declare parameter dst.
        declare parameter src to ship:orbit:body. 
        declare parameter warpspeed to 7.
        
        declare local da to calc_phase_angle(src, dst). 
        declare local da_old to da. 
        
        // Wait for a transfer window to another planets
        // Uses precomputed values from transfer calculator
        
        print "waiting for transfer window.".
        declare local tr_data to get_planet_data(dst).
        if tr_data[2] = 0 { return False. }
        
        declare local phase_angle to mod(tr_data[3]+720,360).
        print "target phase angle: "+phase_angle.

        if da > phase_angle-2 AND da < phase_angle+2 {
           print "At the right phase angle already.".
        } else {              

            set warpmode to "rails".
            clr_status().
            p_status("Waiting for Transfer",0).
            p_status("Target:"+round(phase_angle,1),1).
            wait 0.1.
            
            until da > phase_angle-0.5 AND da < phase_angle+0.5 {
                set da_old to da.
                set da to calc_phase_angle(src, dst).           
                p_status("Phase : "+round(da,1),2).
                p_status("ETA   : "+round(mod(720-phase_angle+da,360)/(da_old-da)/10)+" s",3).
                set warp to warpspeed.
                if warpspeed = 7 {wait 10000.}
                else if warpspeed = 6 {wait 1000.}
                else if warpspeed = 5 {wait 100.}
                else if warpspeed = 4 {wait 10.}
                else {wait 1.}
                
            }
            set warp to 0. 
        }
        
        // Warping fast, wait until we are done.
        wait until kuniverse:timewarp:issettled.
        print "Final phase angle: "+round(calc_phase_angle(src, dst),2)+" ("+percent_err(calc_phase_angle(src, dst), phase_angle)+")".
        return True.
}