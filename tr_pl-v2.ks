// Transfer from 80,000m Kerbin Orbit to Orbit of another planet
print "Planetray Transfer v1.0".


run once libguido.

declare parameter dst_planet is Duna.
declare parameter lib_mode is False.

// Departure orbit at 1000 km MSL.

set enc_step to 0.0001.

if dst_planet = Duna {
    set phase_angle to 44.36.
    set ejection_angle to -138.75.
    set ejection_v to 2267.83.
    set target_pe to 200000.
} else if dst_planet = Eve {
    set phase_angle to -54.13+360.
    set ejection_angle to 180-143.44.
    set ejection_v to 2226.01.
    set target_pe to 200000.
} else if dst_planet = Kerbin {
    if ship:orbit:body = Duna {
      // Duna return orbit 500,000m
      set phase_angle to -75.19+360.
      set ejection_angle to 180-110.7.
      set ejection_v to 1186.75.
      set target_pe to 40000.
    } else if ship:orbit:body = Eve {
      // Eve return orbit 500,000m
      set phase_angle to 36.07.
      set ejection_angle to -159.13.
      set ejection_v to 3754.75.
      set target_pe to 40000.    
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
 

function get_d2 {
    parameter p_node.
    parameter p_pro.
    parameter p_nor.
    parameter p_rad.
    parameter p_eta.
    parameter dst_body.
    
    set p_node:prograde  to p_pro. 
    set p_node:radialout to p_rad.
    set p_node:normal    to p_nor.
    set p_node:eta       to p_eta-time:seconds. 
        
    return find_closest(ship, dst_body).
 }

function my_transfer {
    parameter dst.
    set src to ship:orbit:body.

    print "transfer "+src:name+" -> "+dst:name.
    
    if ship:orbit:body = Sun {
        print "already interplanetary...".
    } else {
    
        print "waiting for transfer window.".
        print "target phase angle: "+phase_angle.

        set a_src to  src:obt:lan + src:obt:argumentofperiapsis + src:obt:trueanomaly. 
        set a_dst  to dst:obt:lan + dst:obt:argumentofperiapsis + dst:obt:trueanomaly.
        set da to mod(a_dst-a_src+720,360).

        if da > phase_angle-2 AND da < phase_angle+2 {
           print "at the right phase angle already.".
        } else {              
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
                wait until KUniverse:CANQUICKSAVE.
                KUniverse:QUICKSAVETO("x3-transfer-window").
        }
        
        // Warping fast, wait until we are done.
        wait until kuniverse:timewarp:issettled.
        
        set a_src to  src:obt:lan + src:obt:argumentofperiapsis + src:obt:trueanomaly. 
        set a_dst  to dst:obt:lan + dst:obt:argumentofperiapsis + dst:obt:trueanomaly.
        set da to mod(a_dst-a_src+720,360).        
        print "final phase angle: "+round(da,2).
        
        // Cross-check
        set v1 to Sun:position-src:position.
        set v2 to Sun:position-dst:position.
        print "cross check angle: "+round(vang(v1,v2),2).

        // Check if we have a maneuver node. If not, create one.

        if hasnode AND ship:orbit:body <> Sun {
            set mynode to nextnode.
        } else {
        
            // Calculate position vs. body prograde
            // dl is zero at prograde, positive in direction of 90 degree rotation
            set v_sun to sun:position-src:position. 
            set v_ship to ship:position-src:position.
            set dd to vcrs(v_sun, v_ship)*v(0,1,0).
            set a_ship to mod(720-vang(v_sun, v_ship)*dd/abs(dd)+90,360).
            set a_eject to mod(ejection_angle+720,360).
            set d_a to mod(a_eject-a_ship+720,360).
    
            print "angles ship/eject/delta: "+round(a_ship,1)+" / "+round(a_eject,1)+" / "+round(d_a,1).
             
            set dt to ship:orbit:period*d_a/360.
            
            // Add the Node
            set n_pro to ejection_v-ship:velocity:orbit:mag.
            set n_eta to time:seconds+dt.
            set n_t0  to time:seconds.
            print "node dt: "+round(n_eta,1)+"  prograde: "+round(n_pro,1).
            set mynode to NODE(n_eta,0,0,n_pro).
            ADD mynode.
            print "maneuver node dv: "+n_pro.
            
            // Try #1 - Vary ETA
            
            set dn_eta to -200.
            set dn_pro to 0.
            set orb1 to mynode:orbit:nextpatch.
            print "#1 trying varying ETA.".
            if NOT (orb1:hasnextpatch and orb1:nextpatch:body = dst) {
                until (orb1:hasnextpatch and orb1:nextpatch:body = dst) OR dn_eta > 200 {
                  set dn_eta to dn_eta+0.5.
                  set mynode:eta to n_eta-time:seconds+dn_eta.
                  set orb1 to mynode:orbit:nextpatch.
                } 
            }
            
            if orb1:hasnextpatch AND orb1:nextpatch:body = dst{
                set n_eta to n_eta+dn_eta.
            } else {
              set mynode:eta to n_eta-time:seconds.
            }
                 
            // Try #2/#3 - Vary Prograde burn     
                 
            if NOT (orb1:hasnextpatch AND orb1:nextpatch:body = dst) {            
                // Try increasing dv to get encounter
                print "#2 trying increasing dv.".
                set mynode:eta to n_eta-time:seconds.
                until (orb1:hasnextpatch and orb1:nextpatch:body = dst) OR dn_pro > n_pro*0.2 {
                  set dn_pro to dn_pro+n_pro*enc_step.
                  set mynode:prograde to n_pro+dn_pro.
                  set orb1 to mynode:orbit:nextpatch.
                }
            }
           
            // If it didn't work, try decreasing
            if NOT (orb1:hasnextpatch AND orb1:nextpatch:body = dst) {
                print "#3 trying increasing dv.".
                set dn_pro to 0.
                until (orb1:hasnextpatch and orb1:nextpatch:body = dst) OR dn_pro < -n_pro*0.2 {
                  set dn_pro to dn_pro-n_pro*0.0001.
                  set mynode:prograde to n_pro+dn_pro.
                  set orb1 to mynode:orbit:nextpatch.
                }
            }
            
            // We give up. Just burn as prescribed and fix it once we in the SOI of the Sun
                           
            if NOT (orb1:hasnextpatch and orb1:nextpatch:body = dst) {
                print "No encounter found. going with default parameters.".
                set mynode:prograde to n_pro.
                set mynode:eta to n_eta-time:seconds+dn_eta.
            } else {    
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
            }
            
            print "executing maneuver.".
            exec_n(mynode).
        }
       
        // Wait until one quarter turn after orbit around the Sun.
        wait_until_in_orbit_of(Sun).
    }

    if NOT ship:orbit:hasnextpatch OR ship:orbit:nextpatch:body <> dst {
        // We are in the SOI of the Sun, but no encounter. 
        if ship:orbit:hasnextpatch {
            print "SOI: "+ship:orbit:body:name+" and next patch body is "+ship:orbit:nextpatch:body:name+". trying again for encounter.".
        } else {
            print "SOI: "+ship:orbit:body:name+" and no next patch. trying again for encounter.".
        }
     
        // How close are we?
        set old_pe to find_closest(ship,eve).
        print "trying to find encounter.".
        print "pre-opt dist: "+km(old_pe).
        
        set n_pro to 0.
        set n_nor to 0.
        set n_rad to 0.
        set pe to old_pe.
        
        set n_eta to time:seconds+ship:orbit:period*0.20.
        set n_t0  to time:seconds.
        set mynode to NODE(n_eta,N_rad,n_nor,n_pro).
        ADD mynode.
        
        // Progressively get more fine grained
        set step to 100.
        
        until step < 0.1 OR (mynode:orbit:hasnextpatch AND mynode:orbit:nextpatch:body = dst) {
            // remember old PE
            
            set old_pe to pe.
            set old_pe2 to pe.
            if get_d2(mynode, n_pro, n_nor+step, n_rad, n_eta, dst ) < old_pe2 {
                set n_nor to n_nor+step.
                set old_pe2 to find_closest(ship,dst).
            } else if get_d2(mynode, n_pro, n_nor-step, n_rad, n_eta, dst  ) < old_pe2 {
                set n_nor to n_nor-step. 
                set old_pe2 to find_closest(ship,dst).
            }               
            if get_d2(mynode, n_pro+step/10, n_nor, n_rad, n_eta, dst ) < old_pe2 {
                set n_pro to n_pro+step/10.
                set old_pe2 to find_closest(ship,dst).
            } else if get_d2(mynode, n_pro-step/10, n_nor, n_rad, n_eta, dst ) < old_pe2 {
                set n_pro to n_pro-step/10. 
                set old_pe2 to find_closest(ship,dst).
            }
            if get_d2(mynode, n_pro, n_nor, n_rad+step, n_eta, dst ) < old_pe2 {
                set n_rad to n_rad+step.
                set old_pe2 to find_closest(ship,dst).
            } else if get_d2(mynode, n_pro, n_nor, n_rad-step, n_eta, dst ) < old_pe2 {
                set n_rad to n_rad-step.
                set old_pe2 to find_closest(ship,dst).
            }  
            set pe to get_d2(mynode, n_pro, n_nor, n_rad, n_eta, dst ).
            print1s("pe: "+round(pe/1000)+" km  pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)+"   ["+round(step,2)+"]" ).
            print "p: "+mynode:orbit:hasnextpatch.
            if old_pe <= pe*1.0001 {
              set step to step*0.5.
            }
        }
        
        print1s("final pe: "+round(pe/1000)+" km  pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)+"   ["+round(step,2)+"]" ).         
        
        if mynode:orbit:hasnextpatch AND mynode:orbit:nextpatch:body = dst {
            print "we have an encounter. executing maneuver.".
            exec_n(mynode).
        }
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
    
    // Progressively get more fine grained
    set step to 10.
    
    until step < 0.1 OR pe < target_pe {
        // remember old PE
        
        set old_pe to mynode:orbit:nextpatch:periapsis.
        set old_pe2 to old_pe.
        if get_pe2(mynode, n_pro, n_nor+step, n_rad, n_eta ) < old_pe2 {
            set n_nor to n_nor+step.
            set old_pe2 to mynode:orbit:nextpatch:periapsis.
        } else if get_pe2(mynode, n_pro, n_nor-step, n_rad, n_eta ) < old_pe2 {
            set n_nor to n_nor-step. 
            set old_pe2 to mynode:orbit:nextpatch:periapsis.            
        } else if get_pe2(mynode, n_pro+step/10, n_nor, n_rad, n_eta) < old_pe2 {
            set n_pro to n_pro+step/10.
            set old_pe2 to mynode:orbit:nextpatch:periapsis.
        } else if get_pe2(mynode, n_pro-step/10, n_nor, n_rad, n_eta) < old_pe2 {
            set n_pro to n_pro-step/10. 
            set old_pe2 to mynode:orbit:nextpatch:periapsis.
        } else if get_pe2(mynode, n_pro, n_nor, n_rad+step, n_eta) < old_pe2 {
            set n_rad to n_rad+step.
            set old_pe2 to mynode:orbit:nextpatch:periapsis.
        } else if get_pe2(mynode, n_pro, n_nor, n_rad-step, n_eta) < old_pe2 {
            set n_rad to n_rad-step.
            set old_pe2 to mynode:orbit:nextpatch:periapsis.
        }  
        set pe to get_pe2(mynode, n_pro, n_nor, n_rad, n_eta).
        print1s("pe: "+round(pe/1000)+" km  pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)+"   ["+round(step,2)+"]" ).
        if old_pe <= pe {
          set step to step*0.5.
        }
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
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x4-dstSOI").
}

function capture {
    print "in SOI of "+body:name.
    print "alt: "+floor(ship:altitude)+"  pe: "+floor(ship:periapsis).

    if ship:periapsis < 0 {
        print "Preiapses < 0. Don't know how to correct. Aborting.".
        KUniverse:PAUSE().
        return.
    }

    if (ship:apoapsis > 0 or ship:periapsis < 200000) AND (ship:periapsis < target_pe) {
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
        wait until KUniverse:CANQUICKSAVE.
        KUniverse:QUICKSAVETO("x5-dstorbit-1").
    }
 
    lock throttle to 0.
    wait 1.
    
    //KUniverse:PAUSE().

    if ship:orbit:inclination > 1 {
      // Try to improve inclination
      run xincl.
      wait until KUniverse:CANQUICKSAVE.
      KUniverse:QUICKSAVETO("x6-dstorbit-2").
    }

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
    wait until KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("x7-dstorbit-3").
    print "AP: "+ship.apoapsis.
}


if NOT lib_mode {
    myinit().
    // Are we in orbit?
    if ship:obt:body <> dst_planet {
        my_transfer(dst_planet).
        if ship:obt:body = dst_planet {
            capture().
        }
    } else {
        if ship:periapsis <0 OR ship:apoapsis <0 or ship:apoapsis > 200000 {
            capture().    
        }
    }

    myexit().
}


