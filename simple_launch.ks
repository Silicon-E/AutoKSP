declare parameter ORBIT_ALT to -1.

print "Start Simple Launch From "+SHIP:ORBIT:BODY+".".

declare LOWEST_SAFE_ORBIT_ALT to -1.
if SHIP:ORBIT:BODY:ATM:EXISTS {
		set LOWEST_SAFE_ORBIT_ALT to SHIP:ORBIT:BODY:ATM:HEIGHT + 5_000.
} else if SHIP:ORBIT:BODY=IKE or SHIP:ORBIT:BODY=TYLO or SHIP:ORBIT:BODY=IKE {
	set LOWEST_SAFE_ORBIT_ALT to 15_000.
} else if SHIP:ORBIT:BODY=BOP {
	set LOWEST_SAFE_ORBIT_ALT to 25_000.
} else {
	set LOWEST_SAFE_ORBIT_ALT to 10_000.
}

if ORBIT_ALT = -1 {
	set ORBIT_ALT to LOWEST_SAFE_ORBIT_ALT.
}
print "  Target Orbit Altitude: "+ORBIT_ALT.

declare ORBIT_SPEED to ORBITAL_SPEED_AT_ALTITUDE(ORBIT_ALT, SHIP:ORBIT:BODY).
print "  Target Orbital Speed: "+ORBIT_SPEED.

declare TURN_START_ALT to -1.
if SHIP:ORBIT:BODY:ATM:EXISTS {
	set TURN_START_ALT to PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(2_000), SHIP:ORBIT:BODY:ATM).
} else {
	set TURN_START_ALT to LERP(SHIP:ALTITUDE, LOWEST_SAFE_ORBIT_ALT, 0.03). // 3% the way to low orbit
}
print "  Gravity Turn Start Altitude: "+TURN_START_ALT.

declare TURN_PROGRADE_ALT to -1.
if SHIP:ORBIT:BODY:ATM:EXISTS {
	set TURN_PROGRADE_ALT to PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(10_000), SHIP:ORBIT:BODY:ATM).
} else {
	set TURN_PROGRADE_ALT to LERP(SHIP:ALTITUDE, LOWEST_SAFE_ORBIT_ALT, 0.2). // 20% the way to low orbit
}
print "  Gravity Turn Prograde Altitude: "+TURN_PROGRADE_ALT.

// Staging trigger:
when SHIP:MAXTHRUST = 0 THEN {
	stage.
	return TRUE. // Preserve this trigger.
}

// ==================== LAUNCH START ====================
SAS off.
lock STEERING to SHIP:UP:VECTOR.
lock THROTTLE to 1.
set GEAR to FALSE.
wait until SHIP:ALTITUDE >= TURN_START_ALT.
// Begin gravity turn
print "  Begin gravity turn.".
until SHIP:ALTITUDE >= TURN_PROGRADE_ALT {
	lock STEERING to HEADING(90, LERP(90, 45, (SHIP:ALTITUDE-TURN_START_ALT)/(TURN_PROGRADE_ALT-TURN_START_ALT))).
}
// Finish gravity turn
print "  Turn to prograde.".
unlock STEERING.
SAS on.
wait 0.
set SASMODE to "prograde".
wait until SHIP:ORBIT:APOAPSIS > ORBIT_ALT-1000.
if SHIP:ORBIT:BODY:ATM:EXISTS and SHIP:ALTITUDE <= SHIP:ORBIT:BODY:ATM:HEIGHT {
	print "  Maintain target apoapsis...".
	lock THROTTLE to choose 1 if SHIP:ORBIT:APOAPSIS < ORBIT_ALT-1000 else 0.
}
wait until not SHIP:ORBIT:BODY:ATM:EXISTS or SHIP:ALTITUDE>SHIP:ORBIT:BODY:ATM:HEIGHT.
// Circularize
print "  Begin circularization.".
SAS off.
lock STEERING to HEADING(90, 0).
// Full throttle if we're past apoapsis OR time to apoapsis is less than the circularization burn time.
lock THROTTLE to choose 0 if AVAILABLE_ACCEL=0 else (choose 1 if ETA:APOAPSIS>ETA:PERIAPSIS or ETA:APOAPSIS*1.5 < (ORBIT_SPEED-SHIP:VELOCITY:ORBIT:MAG)/AVAILABLE_ACCEL else 0).
wait until SHIP:ORBIT:APOAPSIS>ORBIT_ALT-1000 and SHIP:ORBIT:PERIAPSIS>ORBIT_ALT-1000 and ABS(SHIP:ALTITUDE-ORBIT_ALT)<1000.
// Done with launch.
print "  Launch complete.".
unlock STEERING.
unlock THROTTLE.
set SHIP:CONTROL:MAINTHROTTLE to 0.
SAS off.

function PRESSURE_TO_ALT {
	declare parameter PRESS.
	declare parameter ATMOS.
	declare RESULT to ATMOS:HEIGHT / 2.
	// Find the altitude where the pressure is closest to PRESS:
	from {declare I to 0.} until I>=8 step {set I to I+1.} do {
		if SHIP:ORBIT:BODY:ATM:ALTITUDEPRESSURE(RESULT) = PRESS {
			return RESULT.
		} else if SHIP:ORBIT:BODY:ATM:ALTITUDEPRESSURE(RESULT) > PRESS { // Alt too low
			set RESULT to RESULT + ATMOS:HEIGHT*0.5^(I+1).
		} else { // Alt too high
			set RESULT to RESULT - ATMOS:HEIGHT*0.5^(I+1).
		}
	}
	return RESULT.
}

function LERP {
	declare parameter A.
	declare parameter B.
	declare parameter T.
	return A + T*(B-A).
}

function ORBITAL_SPEED_AT_APOAPSIS {
	declare ASCENDING_NODE_VEC to SOLARPRIMEVECTOR * ANGLEAXIS(LONGITUDEOFASCENDINGNODE, SHIP:ORBIT:BODY:UP:VECTOR).
	declare SHIP_ORBIT_PLANE_VEC to SHIP:ORBIT:BODY:UP:VECTOR * ANGLEAXIS(SHIP:ORBIT:INCLINATION, ASCENDING_NODE_VEC).
	declare PERIAPSIS_VEC to (ASCENDING_NODE_VEC * ANGLEAXIS(SHIP:ORBIT:ARGUMENTOFPERIAPSIS)):NORMALIZED.
	declare APOAPSIS_VEC to -PERIAPSIS_VEC * SHIP:ORBIT:APOAPSIS.
	// Use the vis-viva equation:
	return SQRT(6.673e-11*SHIP:ORBIT:BODY:MASS * (2/SHIP:ORBIT:BODY:POSITION:MAG - 1/SHIP:ORBIT:SEMIMAJORAXIS)).
}

function ORBITAL_SPEED_AT_ALTITUDE {
	declare parameter ALT.
	declare parameter PLANET.
	// Use the vis-viva equation:
	return SQRT(6.673e-11*PLANET:MASS * 1/(ALT+PLANET:RADIUS)).
}

function AVAILABLE_ACCEL
{
	return SHIP:AVAILABLETHRUST / SHIP:MASS.
}