RUNONCEPATH("0:/AutoKSP/lib_body.ks").

// Performs a deorbit burn, aiming for an aerocapture if SHIP:BODY has an atmosphere or for a collision course if it doesn't.

// Execute deorbit burn at apoapsis:
print "Begin deorbit sequence.".
if SHIP:ORBIT:ECCENTRICITY > 0.3 {
	print "  Warp to apoapsis.".
	KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:APOAPSIS).
	wait 1.
	wait until KUNIVERSE:TIMEWARP:RATE = 1.
}

print "  Face retrograde.".
SAS on.
wait 1.
set SASMODE to "retrograde".
wait until SHIP:FACING:VECTOR*SHIP:RETROGRADE:VECTOR > 0.99.

local DESIRED_PERI is choose PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(30_000), SHIP:ORBIT:BODY:ATM) if SHIP:ORBIT:BODY:ATM:EXISTS else MAX(-SHIP:ORBIT:BODY:RADIUS +100, -50_000).
print "  Begin burn. Desired periapsis: "+DESIRED_PERI.
lock THROTTLE to 1.
until SHIP:ORBIT:PERIAPSIS <= DESIRED_PERI or STAGE:NUMBER = 0 {
	if SHIP:AVAILABLETHRUST = 0 {
		stage.
	}
}
wait until SHIP:ORBIT:PERIAPSIS <= DESIRED_PERI.

lock THROTTLE to 0.
unlock THROTTLE.
SAS off.
print "Done.".