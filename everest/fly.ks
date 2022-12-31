runOncePath("0:/AutoKSP/lib_launch.ks",false).


lock throttle to 1.

lock thepitch to 0.

intakes on.
stage.
print "takeoff".
until ship:velocity:surface:mag > 15.0 {
        print "target pitch = "+ thepitch + "           " at (3,3).wait 0.
}

lock steering to Heading(90,thepitch).
until ship:velocity:surface:mag > 75.0 {
        print "target pitch = "+ thepitch + "           " at (3,3).wait 0.
}
print "low altitude ascent".

//rapier thrust mult sim 1 + (mach-1/3)^2 * 2.0 

lock lowaltpitch to min(max(ship:velocity:surface:mag/334-0.3,0)^2*15.0 - ship:altitude/10000 * 3 + 3.0,45.0).
//TODO angle down when around the sound barrier or drag will rise a lot
lock thepitch to max(lowaltpitch, 90-ship:prograde:forevector:vang(ship:up:forevector)).//never curve down
until ship:altitude>75.0{
        print "target pitch = "+ thepitch + "           " at (3,3).wait 0.
}
gear off.
until ship:altitude>8000.0{
        print "target pitch = "+ thepitch + "           " at (3,3).wait 0.
}
print "turning".
local t0 is time:seconds.
//lock a to (time:seconds - t0)/7.
lock midaltpitch to min((ship:velocity:surface:mag/334/3)*20.0 - (ship:altitude-13000)/10000 * 3 + 2.0,45.0).
//lock thepitch to 
//    (1.0-a) * lowaltpitch
//    +a*midaltpitch.

//until ship:altitude>11000.0{ print "target pitch = "+ thepitch + "           " at (3,3).wait 0. }
unlock lowaltpitch.
unlock a.
print "middle altitude ascent".
lock thepitch to max(midaltpitch, 90-ship:prograde:forevector:vang(ship:up:forevector)).//never curve down
//lock thepitch to pitch8000 + (25.0-pitch8000) * (ship:altitude-8000) / 21000.
until ship:altitude> 21000{
        print "target pitch = "+ thepitch + "           " at (3,3).wait 0.
}
stage.//activate nervas
print "high altitude ascent (nervas activated)".
local rocketpitch is 20.0 + max(-ship:velocity:surface:mag+1100,-0)/ 300 * 5.
lock thepitch to 20.0 + max(-ship:velocity:surface:mag+1100,0)/ 300 * 5.
wait until ship:maxthrust < 60 + 2 * 50.//cuttoff when rapiers are only giving 50kn each.
wait until ship:maxthrust > 60 + 2 * 100.//wait until rocket mode activates
intakes off.
print "final ascent using lib_launch".
wait until ship:apoapsis>75000.

unlock steering.
unlock throttle.
