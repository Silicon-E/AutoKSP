RUNONCEPATH("0:/AutoKSP/lib_orbit.ks").

parameter PERI.
parameter APO.
parameter MARGIN.

print "Adjust orbit.".
local ORB is CREATEORBIT(SHIP:ORBIT:INCLINATION, PERI_APO_TO_ECCENTRICITY(PERI,APO), (PERI+APO)/2, SHIP:ORBIT:LAN, SHIP:ORBIT:ARGUMENTOFPERIAPSIS, 0, 0, SHIP:ORBIT:BODY).
local PERI_SPEED is R_TO_ORBITAL_SPEED(PERI+SHIP:ORBIT:BODY:RADIUS, SHIP:ORBIT:BODY, ORB).
local APO_SPEED is R_TO_ORBITAL_SPEED(APO+SHIP:ORBIT:BODY:RADIUS, SHIP:ORBIT:BODY, ORB).
unlock STEERING.
SAS on.
set SASMODE to "prograde".
print SHIP:ORBIT:PERIAPSIS.
print SHIP:ORBIT:APOAPSIS.
print MARGIN.
print ABS(SHIP:ORBIT:PERIAPSIS-PERI).
print ABS(SHIP:ORBIT:APOAPSIS-APO).
until ABS(SHIP:ORBIT:PERIAPSIS-PERI)<MARGIN and ABS(SHIP:ORBIT:APOAPSIS-APO)<MARGIN {
	// Cannot time warp while under acceleration
	lock THROTTLE to 0.
	wait 1.
	// If periapsis is sooner, match periapsis speed. Else, match apoapsis speed.
	if ETA:PERIAPSIS < ETA:APOAPSIS {
		if EST_BURN_TIME_PERI > 0 {
			set SASMODE to "prograde".
		} else {
			set SASMODE to "retrograde".
		}
		KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS+ETA:PERIAPSIS -ABS(EST_BURN_TIME_PERI)).
		wait until KUNIVERSE:TIMEWARP = 0.
		lock THROTTLE to choose 0 if AVAILABLE_ACCEL()=0 else (choose 1 if ETA:PERIAPSIS*1.5 < ABS(EST_BURN_TIME_PERI) else 0).
		wait until ETA:APOAPSIS < ETA:PERIAPSIS.
	} else {
		if EST_BURN_TIME_APO > 0 {
			set SASMODE to "prograde".
		} else {
			set SASMODE to "retrograde".
		}
		KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS+ETA:APOAPSIS -ABS(EST_BURN_TIME_APO)).
		wait until KUNIVERSE:TIMEWARP = 0.
		lock THROTTLE to choose 0 if AVAILABLE_ACCEL()=0 else (choose 1 if ETA:APOAPSIS*1.5 < ABS(EST_BURN_TIME_APO) else 0).
		wait until ETA:PERIAPSIS < ETA:APOAPSIS.
	}
}
lock THROTTLE to 0.
unlock THROTTLE.
print "Done adjusting orbit.".

// The below functions return negative values for retrograde burns.
local function EST_BURN_TIME_PERI {
	return EST_BURN_TIME(PERI_SPEED, R_TO_ORBITAL_SPEED(SHIP:ORBIT:PERIAPSIS+SHIP:ORBIT:BODY:RADIUS, SHIP:ORBIT:BODY, SHIP:ORBIT)).
}
local function EST_BURN_TIME_APO {
	return EST_BURN_TIME(APO_SPEED, R_TO_ORBITAL_SPEED(SHIP:ORBIT:APOAPSIS+SHIP:ORBIT:BODY:RADIUS, SHIP:ORBIT:BODY, SHIP:ORBIT)).
}
local function EST_BURN_TIME {
	parameter DESIRED_SPEED.
	parameter PREDICTED_SPEED.
	return (DESIRED_SPEED-PREDICTED_SPEED) / AVAILABLE_ACCEL().
}