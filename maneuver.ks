runoncepath("0:/AutoKSP/lib_manuver.ks").

parameter desired_height.
parameter desired_body is target.
parameter height_margin is 2000.

print "Begin transfer manuever to "+desired_body:name+".".
print "  Desired altitude: "+desired_height.
print "  Altitude margin: "+height_margin.

// Staging trigger:
when SHIP:MAXTHRUST = 0 THEN {
	stage.
	return not(STAGE:NUMBER = 0). // Preserve this trigger unless we ran out of stages.
}

if desired_body = -1 {
	manuverTo(desired_height).
} else if height_margin = -1 {
	manuverTo(desired_height, desired_body).
} else {
	manuverTo(desired_height, desired_body, height_margin).
}

until ship:body = desired_body {
	kuniverse:timewarp:warpto(time:seconds + eta:transition).
	wait 1.
	wait until kuniverse:timewarp:rate = 1.
	wait 5.
}

print "Done.".