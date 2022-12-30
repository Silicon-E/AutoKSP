runOncePath("0:/AutoKSP/lib_launch.ks",false).


lock throttle to 1.

lock thepitch to 0.
lock steering to Heading(90,thepitch).

stage.

until ship:velocity:surface:mag > 50.0 {
        print "target pitch = "+ thepitch + "           " at (3,3).
}

lock thepitch to min((ship:velocity:surface:mag/334)^2*25.0 + 2.0,45.0).

until ship:altitude>8000.0{
        print "target pitch = "+ thepitch + "           " at (3,3).
}
print "middle altitude ascent".
local pitch8000 is  thepitch.
lock thepitch to pitch8000 + (25.0-pitch8000) * (ship:altitude-8000) / 21000.
until ship:altitude> 21000{
        print "target pitch = "+ thepitch + "           " at (3,3).
}
stage.//activate nervas
print "high altitude ascent (nervas activated)".
lock thepitch to 30.0.
wait until ship:maxthrust < 60 + 2 * 50.//cuttoff when rapiers are only giving 50kn each.
wait until ship:maxthrust < 60 + 2 * 100.//wait until rocket mode activates
print "final ascent using lib_launch".

local staging is lexicon(). set staging:second to lexicon(). set staging:second to lexicon().//TODO
set staging:second:vsp to 800.0 * constant:G.
set staging:second:vsp to 800.0 * constant:G.
set staging:second:vsp to 800.0 * constant:G.
local twr2 is 60  *1 / 9.0 / 20.
local deltav1eff is ship:velocity:orbit:mag - 400.0.


unlock steering.
unlock throttle.
