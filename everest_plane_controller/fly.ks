runOncePath("0:/AutoKSP/lib_launch.ks").


lock throttle to 1.

lock thepitch to 0.
lock steering to Heading(90,thepitch).

stage.

wait until ship:velocity:surface:mag > 50.0.

lock thepitch to min((ship:velocity:surface:mag/334)^2*25.0 + 2.0,45.0).

wait until ship:altitude>8000.0.
local pitch8000 is  thepitch.
lock thepitch to pitch8000 + (25.0-pitch8000) * (ship:altitude-8000) / 21000.
wait until ship:altitude> 21000.


local twr2 is 60  *1 / 9.0 / 20.
local deltav1eff is ship:velocity:orbit:mag - 400.0.


unlock steering.
unlock throttle.
