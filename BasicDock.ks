

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

until at_tar:mag < 2 {
	set at_tar to target:position - ship_c:position.
	set g_s to at_tar:mag / 2.
	set rel_v to target_v:velocity:orbit - ship:velocity:orbit.
	set rel_v to rel_v + at_tar:normalized * ((g_s - rel_v:mag) / 2).
	lock steering to at_tar:direction.

	set rel_x to ship_c:facing:rightvector * rel_v.
	if abs(rel_x) < 0.153 and abs(rel_x) > 0.01 {
		set rel_x to 0.153.
	}

	set rel_y to ship_c:facing:upvector * rel_v.
	if abs(rel_y) < 0.153 and abs(rel_y) > 0.01 {
		set rel_y to 0.153.
	}

	set rel_z to ship_c:facing:forevector * rel_v.
	if abs(rel_z) < 0.153 and abs(rel_z) > 0.01 {
		set rel_z to 0.153.
	}

	set ship:control:translation to v(rel_x / 3,rel_y / 3,rel_z / 3).
}

set ship:control:neutralize to true.

print "Coasting...".