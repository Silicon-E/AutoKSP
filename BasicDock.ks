RUNONCEPATH("0:/AutoKSP/lib_rcs.ks").

print "Dock to "+target.

sas off.
rcs on.


set ship_c to ship:controlpart.
if target:typename <> "Vessel" {
	set target_v to target:ship.
} else {
	set target_v to target.
}

target_v:connection:sendmessage("dock").

set at_tar to target:position - ship_c:position.
set rel_v to target_v:velocity:orbit - ship:velocity:orbit.

until not hastarget {
	set at_tar to target:position - ship_c:position.
	set g_s to at_tar:mag / 2.
	set rel_v to target_v:velocity:orbit - ship:velocity:orbit.
	set rel_v to rel_v + at_tar:normalized * ((g_s - rel_v:mag) / 2).
	lock steering to at_tar:direction.
	
	local rcs_translation is RCS_ALTERNATE_DEADZONE((rel_v * ship:facing:inverse) / 3).
	
	set ship:control:translation to rcs_translation.
}

set ship:control:neutralize to true.
rcs off.
unlock steering.
print "Done.".