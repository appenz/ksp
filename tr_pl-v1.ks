// Transfer from 80,000m Kerbin Orbit to Orbit of another planet
print "Planetray Transfer v1.0".


run once libguido.
myinit().

set phase_angle to 0.

declare parameter dst_planet is Duna.

// Departure orbit at 1000 km MSL.

set enc_step to 0.0001.

if dst_planet = Duna {
    set phase_angle to 44.36.
    set ejection_angle to -138.75.
    set ejection_v to 2267.83.
    set target_pe to 200000.
} else if dst_planet = Kerbin {
    if ship:orbit:body = Duna {
      set phase_angle to -75.19+360.
      set ejection_angle to 180-110.7.
      set ejection_v to 1186.75.
      set target_pe to 60000.
    } else {
      print "Unknown departure planet: "+dst_planet.
    }
} else {
  print "Unknown planet: "+dst_planet.
}


function get_pe {
    parameter p_node.
    parameter p_pro.
    parameter p_nor.
    parameter p_rad.
    parameter p_eta.
    
    set p_node:prograde  to p_pro. 
    set p_node:radialout to p_rad.
    set p_node:normal    to p_nor.
    set p_node:eta       to p_eta-time:seconds. 
        
    if NOT mynode:orbit:nextpatch:hasnextpatch  {   
        return 99999999999.
    } else {
        return mynode:orbit:nextpatch:nextpatch:periapsis.
    }
 }
 
 function get_pe2 {
    parameter p_node.
    parameter p_pro.
    parameter p_nor.
    parameter p_rad.
    parameter p_eta.
    
    set p_node:prograde  to p_pro. 
    set p_node:radialout to p_rad.
    set p_node:normal    to p_nor.
    set p_node:eta       to p_eta-time:seconds. 
        
    if NOT mynode:orbit:hasnextpatch  {   
        return 99999999999.
    } else {
        return mynode:orbit:nextpatch:periapsis.
    }
 }

function transfer {
    parameter dst.
    set src to ship:orbit:body.

    print "transfer "+src:name+" -> "+dst:name.

    
    if ship:orbit:body = Sun {
        print "already interplanetary...".
    } else {
        print "waiting for transfer window.".
        print "target phase angle: "+phase_angle.
        set da to 999.
        set warpmode to "rails".
    
        until da > phase_angle-0.5 AND da < phase_angle+0.5 {
          set a_src to  src:obt:lan + src:obt:argumentofperiapsis + src:obt:trueanomaly. 
          set a_dst  to dst:obt:lan + dst:obt:argumentofperiapsis + dst:obt:trueanomaly.
          set da to mod(a_dst-a_src+720,360).
          set warp to 7.
          //print da.      
          wait 0.1.
        }
        set warp to 0.     

        print "final phase angle: "+round(da,2).
        
        // Cross-check
        set v1 to Sun:position-src:position.
        set v2 to Sun:position-dst:position.
        print "cross check angle: "+round(vang(v1,v2),2).

        // Check if we have a maneuver node. If not, create one.

        if hasnode AND ship:orbit:body <> Sun {
            set mynode to nextnode.
        } else {
            // Wait until we are between Kerbin and Sun
            set dl to 999.
            until dl < 0.1 {
                set v_sun to src:position-sun:position.
                set v_ship to src:position-ship:position.
                set dl to vang(v_sun, v_ship).
                set_warp_for_t(ship:orbit:period*dl/360).
                wait 0.1.
                //print dl.
            }
            
            print "between kerbin and sun. dl: "+round(dl,3).
            set dt to ship:orbit:period*MOD(270+ejection_angle+720,360)/360.
            
            // Add the Node
            set n_pro to ejection_v-ship:velocity:orbit:mag.
            set n_eta to time:seconds+dt.
            set n_t0  to time:seconds.
            set mynode to NODE(n_eta,0,0,n_pro).
            ADD mynode.
            print "maneuver node dv: "+n_pro.
            
            // Try to get encounter
            
            set dn_pro to 0.

            // Try increasing dv to get encounter
            set orb1 to mynode:orbit:nextpatch.
            if NOT orb1:hasnextpatch {
                until orb1:hasnextpatch OR dn_pro > n_pro*0.1 {
                  set dn_pro to dn_pro+n_pro*enc_step.
                  set mynode:prograde to n_pro+dn_pro.
                  set orb1 to mynode:orbit:nextpatch.
                  wait 0.1.
                }
            }
                
            // If it didn't work, try decreasing
            if NOT orb1:hasnextpatch {
                set dn_pro to 0.
                until orb1:hasnextpatch OR dn_pro < -n_pro*0.1 {
                  set dn_pro to dn_pro-n_pro*0.0001.
                  set mynode:prograde to n_pro+dn_pro.
                  set orb1 to mynode:orbit:nextpatch.
                  wait 0.1.
                }
            }
                
            if NOT orb1:hasnextpatch {
                print "Can't find encounter. Aborting.".
                wait 1.
                KUniverse:PAUSE().
                return.
            }
            
            // We have an encounter. Hillclimb.
            
            set old_pe to 99999999999.
            set n_pro to n_pro+dn_pro.
            set n_nor to 0.
            set n_rad to 0.
            set pe to mynode:orbit:nextpatch:nextpatch:periapsis.
            print "pre-opt pe : "+round(pe/1000)+" km".
            print "optimizing...".

            
            until old_pe <= pe OR pe < target_pe {
                // remember old PE
                
                set old_pe to mynode:orbit:nextpatch:nextpatch:periapsis.
                set old_pe2 to old_pe.
                if get_pe(mynode, n_pro, n_nor+0.1, n_rad, n_eta ) < old_pe2 {
                    set n_nor to n_nor+0.1.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.
                } else if get_pe(mynode, n_pro, n_nor-0.1, n_rad, n_eta ) < old_pe2 {
                    set n_nor to n_nor-0.1.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.                    
                } 
                if get_pe(mynode, n_pro+0.01, n_nor, n_rad, n_eta) < old_pe2 {
                    set n_pro to n_pro+0.01.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.
                } else if get_pe(mynode, n_pro-0.01, n_nor, n_rad, n_eta) < old_pe2 {
                    set n_pro to n_pro-0.01.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.
                }
                if get_pe(mynode, n_pro, n_nor, n_rad+0.1, n_eta) < old_pe2 {
                    set n_rad to n_rad+0.1.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.
                } else if get_pe(mynode, n_pro, n_nor, n_rad-0.1, n_eta) < old_pe2 {
                    set n_rad to n_rad-0.1.
                    set old_pe2 to mynode:orbit:nextpatch:nextpatch:periapsis.  
                }  
                set pe to get_pe(mynode, n_pro, n_nor, n_rad, n_eta).
                // print1s("pe: "+round(pe)+" ETA/pro/nor/rad : "+round(n_eta-n_t0)+" / "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)).
                wait 0.1.
            }
            
            print "post-opt pe: "+round(pe/1000)+" km  ETA/pro/nor/rad : "+round(n_eta-n_t0)+" / "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2).
            print "executing maneuver.".

            exec_n(mynode).

        }
       
        // Wait until one day after orbit around the Sun.
        wait_until_in_orbit_of(Sun).
        rwait(24*3600).
    }
 
    // Make sure we have an encounter
    if NOT ship:orbit:hasnextpatch {
        print "No encounter. Aborting.".
        KUniverse:PAUSE().
        return.
    }

 
    // Now that we are in Sun Orbit, re-tune for precision.
    // Add a node in 5 minutes and hillclimb.
    set dt to 300.
    set n_eta to time:seconds+dt.
    set mynode to NODE(n_eta,0,0,0).
    ADD mynode.
        
    // We have an encounter. Hillclimb.
    print "orbiting Sun. optimizing trajectory.".
    set old_pe to 99999999999.
    set n_pro to 0.
    set n_nor to 0.
    set n_rad to 0.
    set pe to mynode:orbit:nextpatch:periapsis.
    print "pre-opt pe : "+round(pe/1000)+" km".
    
    until old_pe <= pe OR pe < target_pe {
        // remember old PE
        
        set old_pe to mynode:orbit:nextpatch:periapsis.
        if get_pe(mynode, n_pro, n_nor+0.1, n_rad, n_eta ) < old_pe {
            set n_nor to n_nor+0.1.
        } else if get_pe2(mynode, n_pro, n_nor-0.1, n_rad, n_eta ) < old_pe {
            set n_nor to n_nor-0.1.         
        } else if get_pe2(mynode, n_pro+0.01, n_nor, n_rad, n_eta) < old_pe {
            set n_pro to n_pro+0.01.
        } else if get_pe2(mynode, n_pro-0.01, n_nor, n_rad, n_eta) < old_pe {
            set n_pro to n_pro-0.01. 
        } else if get_pe2(mynode, n_pro, n_nor, n_rad+0.1, n_eta) < old_pe {
            set n_rad to n_rad+0.1.
        } else if get_pe2(mynode, n_pro, n_nor, n_rad-0.1, n_eta) < old_pe {
            set n_rad to n_rad-0.1.
        }  
        set pe to get_pe2(mynode, n_pro, n_nor, n_rad, n_eta).
        print1s("pe: "+round(pe)+" pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)).
        wait 0.1.
    }
    
    print "post-opt pe: "+round(pe/1000)+" km  pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2).
 
    if mynode:deltav:mag < 0.001 {
      print "no change needed.".
    } else {
        print "executing maneuver.".
        wait 3.    
        exec_n(mynode).
    }
    
    wait_until_in_orbit_of(dst).
    
    print "arrived in orbit of "+dst:name.
}

function capture {
    print "in SOI of "+body:name.
    print "alt: "+floor(ship:altitude)+"  pe: "+floor(ship:periapsis).

    if ship:periapsis < 0 {
        print "Preiapses < 0. Don't know how to correct. Aborting.".
        KUniverse:PAUSE().
        return.
    }

    // Slow down to capture
    wait_turn(ship:retrograde).
    print "breaking for capture.".
    until (ship:apoapsis > 0 AND ship:periapsis < 200000) OR (ship:periapsis < target_pe) {
        lock throttle to 1.

        if maxthrust = 0 {
          print "Fuel exhausted. Staging.".
          stage.
        }  
        wait 0.1.
    }
 
    lock throttle to 0.
    wait 1.
    run xincl.

    // Wait for PE and break to get us into orbit.

    print "time to PE: "+floor(eta:periapsis).
    set warpmode to "rails".
    warpto(time:seconds+eta:periapsis-30). 
    wait eta:periapsis-30.
    print "turning for burn.".
    wait_turn(ship:retrograde).
    print "lowering AP.".
    until (ship:apoapsis > 0 AND ship:apoapsis < target_pe*2) OR ship:periapsis < target_pe*0.75 {
        if eta:periapsis > 10 AND eta:periapsis < 200 {
            lock throttle to 005.
        } else if eta:periapsis > 5 AND eta:periapsis < 200 {
            lock throttle to 0.1.
        } else {
            lock throttle to 1.0.
        }
    
        if ship:apoapsis <0 {
            lock throttle to 1.0.
        }
        wait 0.1.
    }
    print "AP: "+ship.apoapsis.
}

// Are we in orbit?
if ship:obt:body <> dst_planet {
    transfer(dst_planet).
    capture().  
} else {
    if ship:periapsis <0 OR ship:apoapsis <0 or ship:apoapsis > 200000 {
        capture().    
    }
}

myexit().



