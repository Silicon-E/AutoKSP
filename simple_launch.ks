RUNONCEPATH("0:/AutoKSP/lib_ship.ks").
RUNONCEPATH("0:/AutoKSP/lib_orbit.ks").
RUNONCEPATH("0:/AutoKSP/lib_body.ks").

declare parameter ORBIT_ALT to -1.

print "Start Simple Launch From "+SHIP:ORBIT:BODY:NAME+".".

if ORBIT_ALT = -1 {
	set ORBIT_ALT to LOWEST_SAFE_ORBIT_ALT(SHIP:ORBIT:BODY).
}
print "  Target Orbit Altitude: "+ORBIT_ALT.

declare ORBIT_SPEED to ORBITAL_SPEED_AT_ALTITUDE(ORBIT_ALT, SHIP:ORBIT:BODY).
print "  Target Orbital Speed: "+ORBIT_SPEED.

declare TURN_START_ALT to -1.
if SHIP:ORBIT:BODY:ATM:EXISTS {
	set TURN_START_ALT to PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(2_000), SHIP:ORBIT:BODY:ATM).
} else {
	set TURN_START_ALT to LERP(SHIP:ALTITUDE, LOWEST_SAFE_ORBIT_ALT(SHIP:ORBIT:BODY), 0.02). // 2% the way to low orbit
}
print "  Gravity Turn Start Altitude: "+TURN_START_ALT.

declare TURN_PROGRADE_ALT to -1.
if SHIP:ORBIT:BODY:ATM:EXISTS {
	set TURN_PROGRADE_ALT to PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(10_000), SHIP:ORBIT:BODY:ATM).
} else {
	set TURN_PROGRADE_ALT to LERP(SHIP:ALTITUDE, LOWEST_SAFE_ORBIT_ALT(SHIP:ORBIT:BODY), 0.1). // 10% the way to low orbit
}
print "  Gravity Turn Prograde Altitude: "+TURN_PROGRADE_ALT.

// Staging trigger:
when SHIP:MAXTHRUST = 0 THEN {
	stage.
	return not(STAGE:NUMBER = 0). // Preserve this trigger unless we ran out of stages.
}

// ==================== LAUNCH START ====================
SAS off.
set NAVMODE to "surface".
lock STEERING to SHIP:UP:VECTOR.
lock THROTTLE to 1.
set GEAR to FALSE.
set WARPMODE to "PHYSICS".
set WARP to 3.
wait until SHIP:ALTITUDE >= TURN_START_ALT.
// Begin gravity turn
print "  Begin gravity turn.".
set WARPMODE to "PHYSICS".
set WARP to 2.
until SHIP:ALTITUDE >= TURN_PROGRADE_ALT {
	lock STEERING to HEADING(90, LERP(90, 45, (SHIP:ALTITUDE-TURN_START_ALT)/(TURN_PROGRADE_ALT-TURN_START_ALT))).
}
// Finish gravity turn
set WARPMODE to "PHYSICS".
set WARP to 3.
if SHIP:UP:VECTOR * SHIP:SRFPROGRADE:VECTOR > 0.707 {
	print "  Hold 45 degree pitch.".
	lock STEERING to HEADING(90, 45).
	wait until SHIP:ORBIT:APOAPSIS > ORBIT_ALT-1000  or  SHIP:UP:VECTOR * SHIP:SRFPROGRADE:VECTOR <= 0.707.
}
print "  Turn to prograde.".
when SHIP:ORBIT:APOAPSIS > ORBIT_ALT-5000 then {
	set WARP to 0.
}
lock STEERING to choose SHIP:PROGRADE if NAVMODE="orbit" else SHIP:SRFPROGRADE.
wait until SHIP:ORBIT:APOAPSIS > ORBIT_ALT-1000.
if SHIP:ORBIT:BODY:ATM:EXISTS and SHIP:ALTITUDE <= SHIP:ORBIT:BODY:ATM:HEIGHT {
	print "  Maintain target apoapsis...".
	lock THROTTLE to choose 1 if SHIP:ORBIT:APOAPSIS < ORBIT_ALT-1000 else 0.
}
set WARPMODE to "PHYSICS".
set WARP to 3.
wait until not SHIP:ORBIT:BODY:ATM:EXISTS or SHIP:ALTITUDE>SHIP:ORBIT:BODY:ATM:HEIGHT.
set WARP to 0.
wait until KUNIVERSE:TIMEWARP:RATE = 1.
set KUNIVERSE:TIMEWARP:MODE to "rails".
wait 0.1.
KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:APOAPSIS - (ORBIT_SPEED-SHIP:VELOCITY:ORBIT:MAG)/AVAILABLE_ACCEL() - 30).
wait until KUNIVERSE:TIMEWARP:RATE = 1.
set KUNIVERSE:TIMEWARP:MODE to "physics".
wait 0.1.
set WARPMODE to "PHYSICS".
set WARP to 1.
// Circularize
print "  Begin circularization.".
SAS off.
lock STEERING to HEADING(90, 0).
// Full throttle if we're past apoapsis OR time to apoapsis is less than the circularization burn time.
lock THROTTLE to choose 0 if AVAILABLE_ACCEL()=0 else (choose 1 if ETA:APOAPSIS>ETA:PERIAPSIS or ETA:APOAPSIS*1.5 < (ORBIT_SPEED-SHIP:VELOCITY:ORBIT:MAG)/AVAILABLE_ACCEL() else 0).
wait until SHIP:ORBIT:APOAPSIS>ORBIT_ALT-1000 and SHIP:ORBIT:PERIAPSIS>ORBIT_ALT-1000 and ORBIT_ALT-SHIP:ALTITUDE<1000.
// Done with launch.
print "  Launch complete.".
set WARP to 0.
unlock STEERING.
lock THROTTLE to 0.
unlock THROTTLE.
set SHIP:CONTROL:MAINTHROTTLE to 0.
SAS off.
wait until KUNIVERSE:TIMEWARP:RATE = 1.

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