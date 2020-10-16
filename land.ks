RUNONCEPATH("0:/AutoKSP/lib_orbit.ks").
RUNONCEPATH("0:/AutoKSP/lib_math.ks").
RUNONCEPATH("0:/AutoKSP/lib_ship.ks").

// This script tries to perform a suicide burn, usually ending up above
// the surface of the Mun. It then runs simple_land.ks.

local SAFETY_ALT_FUDGE is 0. // How far up to bias the target altitude

// ==================== LANDING START ====================
if SHIP:ORBIT:BODY:ATM:EXISTS and SHIP:ORBIT:PERIAPSIS <= SHIP:ORBIT:BODY:ATM:HEIGHT {
	print "Wait for aerocapture.".
	lock STEERING to SHIP:SRFRETROGRADE.
	wait until SHIP:ORBIT:APOAPSIS <= SHIP:ORBIT:BODY:ATM:HEIGHT.
	unlock STEERING.
} else if SHIP:ORBIT:PERIAPSIS > 0 {
	print "FAIL: Cannot begin landing on "+SHIP:ORBIT:BODY:NAME+"; periapsis is greater than 0!".
	print "  Force crash.".
	local ERR is 1/0.
}
print "Begin landing on "+SHIP:ORBIT:BODY:NAME+".".
if not GEAR {
	set GEAR to TRUE.
	wait 2.5.
}
// Decide whether to do a landing burn. Based on whether there are engines and fuel. TODO: If in atmo, determine if engines are needed.
local MY_ENGINES is LIST().
list ENGINES in MY_ENGINES.
local IS_POWERED_DESCENT is MY_ENGINES:LENGTH>0 and SHIP:LIQUIDFUEL>0 and SHIP:OXIDIZER>0.

local SHIP_BOUNDS is SHIP:BOUNDS.
// Add the height of the ship up to its center to the fudge altitude. Z axis is vertical in bounds reference frame.
set SAFETY_ALT_FUDGE to SAFETY_ALT_FUDGE + ((-SHIP_BOUNDS:ABSORIGIN)*SHIP_BOUNDS:FACING:INVERSE):Z - SHIP_BOUNDS:RELMIN:Z.
local BURN_START_TIME is TIME:SECONDS + 10_000.
if IS_POWERED_DESCENT {
	set BURN_START_TIME to ESTIMATE_PATH().
}
unlock STEERING.
SAS on.
wait 1.
set SASMODE to "retrograde".
set NAVMODE to "surface".
local SHOULD_END is FALSE.
if SHIP:ORBIT:BODY:ATM:EXISTS {
	// Gradually deploys chutes as speed drops:
	when (not CHUTESSAFE) then {
		CHUTESSAFE on.
		return (not CHUTES).
	}
}
if IS_POWERED_DESCENT {
	lock THROTTLE to TIME:SECONDS >= BURN_START_TIME.
	when TIME:SECONDS >= BURN_START_TIME then {
		wait until SHIP:VELOCITY:SURFACE:MAG < 10.
		// Cleanup:
		wait 0.
		for N in ALLNODES {
			remove N.
		}
		lock THROTTLE to 0.
		unlock THROTTLE.
		SAS off.
		// Simple Landing:
		runpath("0:/AutoKSP/simple_land.ks").
		set SHOULD_END to TRUE.
	}
	
	local NEW_START_TIME is ESTIMATE_PATH(40).
	if not (TIME:SECONDS >= BURN_START_TIME) {
		set BURN_START_TIME to NEW_START_TIME.
		set KUNIVERSE:TIMEWARP:MODE to "rails".
		KUNIVERSE:TIMEWARP:WARPTO(BURN_START_TIME - 10).
	}
} else {
	wait until SHIP_BOUNDS:BOTTOMALTRADAR < 0.1.
	set SHOULD_END to TRUE.
}
wait until SHOULD_END.
// Final cleanup
wait 0.
for N in ALLNODES {
	remove N.
}
print "  Done.".

local function ESTIMATE_PATH {
	declare parameter SEGMENTS to 10.
	declare parameter MARGIN to 1.
	local START_TIME is TIME:SECONDS + (ETA:PERIAPSIS - SHIP:ORBIT:PERIOD/4).
	local STEP is SHIP:ORBIT:PERIOD/8.
	local NEW_FINAL_RADAR_ALT is MARGIN+0.54321.
	
	from {local ITERATION to 0.} until ABS(NEW_FINAL_RADAR_ALT)<=MARGIN or ITERATION>=20 step {set ITERATION to ITERATION+1.} do {
		// Plan new manuever nodes.
		local BURN_TIME is SHIP:VELOCITY:SURFACE:MAG / (AVAILABLE_ACCEL() - SHIP:SENSORS:GRAV:MAG). // Slight overestimate of burn time. This is good.
		local FUEL_FLOW is AVAILABLE_FUEL_FLOW().
		local FOUND_STOP is FALSE.
		local SEGMENT_TIME is -1.
		until FOUND_STOP {
			set SEGMENT_TIME to BURN_TIME/SEGMENTS.
			// Clear manuever nodes.
			for N in ALLNODES {
				remove N.
			}
			wait 0. // Need ALLNODES to refresh.
			// Add new nodes.
			from {local I to 0.} until (ALLNODES:LENGTH>=1 and VERT_SPEED_AT(SHIP, TIME(TIME:SECONDS+ALLNODES[ALLNODES:LENGTH-1]:ETA +0.001)) >= 0) or I>=SEGMENTS*1.5 step {set I to I+1.} do {
				local T is SEGMENT_TIME*(I+0.5).
				// Ship available acceleration = maxThrust / (mass accounting for fuel burned)
				add NODE(START_TIME+T, 0, 0, -(SHIP:AVAILABLETHRUST / MAX(SHIP:DRYMASS, SHIP:MASS-FUEL_FLOW*T))*SEGMENT_TIME).
				wait 0. // Need ALLNODES to refresh.
			}
			if VERT_SPEED_AT(SHIP, TIME(TIME:SECONDS+ALLNODES[ALLNODES:LENGTH-1]:ETA +0.001)) >= 0 {
				set FOUND_STOP to TRUE.
			} else {
				set BURN_TIME to BURN_TIME*2. // 1.5*BURN_TIME wasn't enough; increase simulation time.
			}
			
			if(TIME:SECONDS >= BURN_START_TIME) { return. }
		}
		
		if TRUE or VERT_SPEED_AT(SHIP, TIME(TIME:SECONDS+ALLNODES[ALLNODES:LENGTH-1]:ETA +0.001)) >= 0 { // TODO: this check should be unnecessary. Disabled it for now.
			local ZERO_TIME is -1.
			if ALLNODES:LENGTH=1 {
				set ZERO_TIME to TIME:SECONDS + ALLNODES[0]:ETA.
			} else {
				local T1 is TIME:SECONDS + ALLNODES[ALLNODES:LENGTH-2]:ETA +0.001.
				local T2 is TIME:SECONDS + ALLNODES[ALLNODES:LENGTH-1]:ETA +0.001.
				set ZERO_TIME to LERP(T1, T2, (0-VERT_SPEED_AT(SHIP, TIME(T1))) / (VERT_SPEED_AT(SHIP, TIME(T2))-VERT_SPEED_AT(SHIP, TIME(T1)))) +SEGMENT_TIME/2.
			}
			local FUTURE_POS is POSITIONAT(SHIP, TIME(ZERO_TIME)).
			local FUTURE_ALT is SHIP:ORBIT:BODY:ALTITUDEOF(FUTURE_POS).
			local TERRAIN_ALT is SHIP:ORBIT:BODY:GEOPOSITIONOF(FUTURE_POS):TERRAINHEIGHT.
			// Fudge the target altitude up by 100m:
			if FUTURE_ALT-SAFETY_ALT_FUDGE > TERRAIN_ALT { // Too high; postpone burn
				set START_TIME to START_TIME + STEP.
			} else if FUTURE_ALT-SAFETY_ALT_FUDGE < TERRAIN_ALT { // Too low; expedite burn
				set START_TIME to START_TIME - STEP.
			}
			
			set NEW_FINAL_RADAR_ALT to FUTURE_ALT-TERRAIN_ALT.
		} else {
			print "Critical Problem! Simulated path is not long enough to stop!". // This line should never run.
		}
		
		set STEP to STEP/2.
		
		if(TIME:SECONDS >= BURN_START_TIME) { return. }
	}
	
	print "  Final Radar Alt: "+NEW_FINAL_RADAR_ALT.
	return START_TIME.
}

function VERT_SPEED_AT {
	declare parameter PARAM_ORBITABLE.
	declare parameter PARAM_TIME.
	return VELOCITYAT(PARAM_ORBITABLE, PARAM_TIME):SURFACE * (POSITIONAT(PARAM_ORBITABLE, PARAM_TIME)-PARAM_ORBITABLE:ORBIT:BODY:POSITION):NORMALIZED.
}