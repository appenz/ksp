// Transfer from 80,000m Kerbin Orbit to Orbit of another planet
print "Planetray Transfer v1.0".

run once libguido.
run once libtransfer.
run once libcapture.

parameter dst_planet.
parameter dst_alt is -1.
parameter fix_incl is True.

set enc_step to 0.0001.

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
    
    set dst_min_pe to 100000.
    set dst_max_pe to 200000.

    print "planetary transfer "+src:name+" -> "+dst:name.
    
    set tr_data to get_planet_data(dst).
    if tr_data[2] = 0 { panic("Unknown Transfer"). return False. }
    set ejection_angle to -tr_data[4].
    set ejection_v to tr_data[5].
    
    if ship:orbit:body = Sun {
        print "already interplanetary.".
    } else {   
        // Wait for a transfer window between planets
        if NOT wait_transfer_window(dst) {
          print "wait_transfer_window() failes. Aborting.".
          return False.
        }
        myquicksave("x3-transfer-window").  

        // Check if we have a maneuver node. If not, create one.

        if hasnode AND src <> Sun {
            print "found existing maneuver node.".
            set mynode to nextnode.
            optimize_pe(dst_min_pe,dst_max_pe,dst).
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
                // Run the optimizer
                optimize_pe(dst_min_pe,dst_max_pe,dst).
            }
            

        }
       
        print "executing maneuver.".
        exec_n(mynode).
        wait_until_in_orbit_of(Sun).
    }
    
    print "In the orbit of "+ship:orbit:body:name.
    if ship:orbit:body <> Sun {
        panic("I should be in orbit of Sun!?!").
    }

    if ship:orbit:hasnextpatch AND ship:orbit:nextpatch:body <> dst {
      print "encounter ok.".
    } else if HASNODE {
      print "No encounter. Node found. Delete to re-try for encounter.".
    } else {
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
        set original_pe to old_pe.
        clr_status().
        
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
            p_status("PE:  "+km(pe)+" ("+percent(pe, original_pe)+")",1).
            p_status("ETA: "+round(n_eta-time:seconds)+"  step: "+round(step,2),2).
            p_status("Pro: "+round(n_pro,2),3).
            p_status("Nor: "+round(n_nor,2),4).
            p_status("Rad: "+round(n_rad,2),5).
            if old_pe <= pe*1.0001 {
              set step to step*0.5.
            }
        }
        
        print1s("final pe: "+round(pe/1000)+" km  pro/nor/rad : "+round(n_pro,2)+" / "+round(n_nor,2)+" / "+round(n_rad,2)+"   ["+round(step,2)+"]" ).         
        
        if mynode:orbit:hasnextpatch AND mynode:orbit:nextpatch:body = dst {
            // We have an encounter.
            print "Encounter with "+mynode:orbit:nextpatch:body:name.
        } else {
            panic("No encounter. Aborting.").
            return False.
        }
    } 

    // Optimize the encounter, and burn.   
    optimize_pe(dst_min_pe,dst_max_pe,dst).
    myquicksave("x4-encounter").
    exec_n(nextnode).
    
    wait_until_in_orbit_of(dst).
    print "arrived in orbit of "+dst:name.
    myquicksave("x5-dstSOI").
}


myinit().
// Are we in orbit?
if ship:obt:body <> dst_planet {
    my_transfer(dst_planet).
}
capture(dst_planet,dst_alt,fix_incl).    
myexit().



