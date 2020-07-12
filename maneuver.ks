runoncepath("0:/AutoKSP/lib_manuver.ks", false).

parameter desired_height.
parameter desired_body is target.
parameter height_margin is 2000.
parameter should_circularize is true.

print "Begin transfer manuever to "+desired_body:name+".".
print "  Desired altitude: "+desired_height.
print "  Altitude margin: "+height_margin.

// Staging trigger:
when SHIP:MAXTHRUST = 0 THEN {
	stage.
	return not(STAGE:NUMBER = 0). // Preserve this trigger unless we ran out of stages.
}

// If going to current body's parent
if desired_body = ship:body:body {
	manuver_plungeFromSOI(desired_height, height_margin, should_circularize).
} else { // Else, perform a transfer
	if desired_body = -1 {
		manuver_toInSOI(desired_height).
	} else if height_margin = -1 {
		manuver_toInSOI(desired_height, desired_body).
	} else {
		manuver_toInSOI(desired_height, desired_body, height_margin).
	}
}

until ship:body = desired_body {
	kuniverse:timewarp:warpto(time:seconds + eta:transition).
	wait 1.
	wait until kuniverse:timewarp:rate = 1.
	wait 5.
}

print "Done.".