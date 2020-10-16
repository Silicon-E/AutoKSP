runoncepath("0:/AutoKSP/lib_manuver.ks", false).

parameter desired_vessel is target.

print "Begin rendezvous manuever to "+desired_vessel:name+".".

// Staging trigger:
when SHIP:MAXTHRUST = 0 THEN {
	stage.
	return not(STAGE:NUMBER = 0). // Preserve this trigger unless we ran out of stages.
}

until ship:body = desired_vessel {
	kuniverse:timewarp:warpto(time:seconds + eta:transition).
	wait 1.
	wait until kuniverse:timewarp:rate = 1.
	wait 5.
}

manuver_toInSOI(0, desired_vessel).

print "Done.".