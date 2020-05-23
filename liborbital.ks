//
// Library for orbital mechanics helper functions
//

// Helper functions for orbital maneuvers

function change_ap_at_pe {
    parameter new_ap.
    // Calculate length of burn at PE.
    local t_pe to eta:periapsis.
    local pe to ship:periapsis.
    local v_pe to vv_alt(pe).
    local v_new to vv_axis(ship:periapsis,(ship:periapsis+2*body:radius+new_ap)/2).
    local dv to v_new-v_pe.
    local mynode to NODE(time:seconds+t_pe,0,0,dv).
    return mynode.
}

function change_pe_at_ap {
    parameter new_pe.
    // Calculate length of burn at AP.
    local t_ap to eta:apoapsis.
    local ap to ship:apoapsis.
    local v_ap to vv_alt(ap).
    local v_new to vv_axis(ship:apoapsis,(ship:apoapsis+2*body:radius+new_pe)/2).
    local dv to v_new-v_ap.
    local mynode to NODE(time:seconds+t_ap,0,0,dv).
    return mynode.
}

function circularize_at_pe {
    // Calculate length of burn at PE.
    local t_pe to eta:periapsis.
    local pe to ship:periapsis.
    local v_pe to vv_alt(pe).
    local v_new to vv_circular(pe).
    local dv to v_new-v_pe.

    local mynode to NODE(time:seconds+t_pe,0,0,dv).
    return mynode.
}

function circularize_at_ap {
    // Calculate length of burn at AP.
    local t_ap to eta:apoapsis.
    local ap to ship:apoapsis.
    local v_ap to vv_alt(ap).
    local v_new to vv_circular(ap).
    local dv to v_new-v_ap.

    local mynode to NODE(time:seconds+t_ap,0,0,dv).
    return mynode.
}

// Time needed for Hohmann transfer from alt1->alt2

function t_hohmann {
  parameter alt1.
  parameter alt2.
  return constant:pi*( (alt1+alt2+2*body:radius)^3/(8*body:mu) )^0.5.
}

// Velocity at a specific altitude for current orbit.

function vv_alt {
  parameter r.
  declare local gm to body:mu.
  return (gm*(2/(r+body:radius)-1/ship:orbit:semimajoraxis))^0.5.
}

// Velocity at a specific altitude for an arbitrary orbit

function vv_axis {
  parameter r.
  parameter axis.
  declare local gm to body:mu.
  return (gm*(2/(r+body:radius)-1/axis))^0.5.
}

// Velocity for a circular orbit at a given altitude AGL

function vv_circular {
  parameter r.
  return vv_axis(r, r+body:radius).
}