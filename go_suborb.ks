// Suborbital Flight Controls

CLEARSCREEN.
PRINT "Suborbital Flight Controls v1.0".
FROM {local c is 3.} UNTIL c = 0 STEP {SET c to c - 1.} DO {
    PRINT "..." + c.
    WAIT 1. // pauses the script here for 1 second.
}

// [0] is liquid fuel, [1] is solid state
list engines in e.

// Launch
print "Launching.".
stage.
lock throttle to 1.0.
lock steering to up.

// Wait until booster is done, decouple and start main engine
wait until ship:altitude > 10000.
print "alt: > 10,000".
wait until e[1]:maxthrust = 0.
print "Solid booster exhausted. Staging.".
stage.

// Wait until solid fuel is empty and decouple
wait 10.
lock throttle to 0.2.
lock steering to up.
wait until e[0]:maxthrust = 0.
print "Liquid fuel engine exhausted. Decoupling.".
stage. 

// Wait to open Parachute
unlock throttle.
print "waiting for 10,000".
wait until ship:altitude < 10000.
print "alt: < 10,000.".
wait until ship:airspeed < 255.
stage.
print "Control completed.".
