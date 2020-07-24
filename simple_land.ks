print "Begin simple landing on "+SHIP:ORBIT:BODY:NAME+".".

if not GEAR {
	set GEAR to TRUE.
	wait 2.5.
}

// Maintain an applicable copy of this ship's bounding box
local SHIP_BOUNDS to SHIP:BOUNDS.
on STAGE:NUMBER {
	set SHIP_BOUNDS to SHIP:BOUNDS.
	return TRUE.
}

function AVAILABLE_ACCEL
{
	return SHIP:AVAILABLETHRUST / SHIP:MASS.
}

function TIME_TO_TOUCHDOWN {
	declare A to -SHIP:SENSORS:GRAV:MAG.
	declare V0 to SHIP:VELOCITY:SURFACE * SHIP:UP:VECTOR.
	declare X0 to SHIP_BOUNDS:BOTTOMALTRADAR.
	return (-V0 - SQRT(V0^2 - 2*A*X0)) / A.
	//return SHIP_BOUNDS:BOTTOMALTRADAR / (SHIP:VELOCITY:SURFACE * -SHIP:UP:VECTOR).
}
function DIST_TO_TOUCHDOWN {
	return SHIP:VELOCITY:SURFACE:MAG * TIME_TO_TOUCHDOWN. // This is inaccurate, because it does not account for gravity
}

set NAVMODE to "surface".
until SHIP_BOUNDS:BOTTOMALTRADAR < 0.1 {
	local IS_DESCENDING is SHIP:VELOCITY:SURFACE*SHIP:UP:VECTOR<0.
	if SHIP:VELOCITY:SURFACE:MAG > 0.5 and IS_DESCENDING {
		lock STEERING to SHIP:SRFRETROGRADE:VECTOR.
	} else {
		lock STEERING to SHIP:FACING.
	}
	
	//declare BURN_TIME to (SHIP:VELOCITY:SURFACE:MAG + SHIP:SENSORS:GRAV:MAG*TIME_TO_TOUCHDOWN) / AVAILABLE_ACCEL. // Lands successfully, but not with a suicide burn.
	declare BURN_TIME to SHIP:VELOCITY:SURFACE:MAG / (AVAILABLE_ACCEL - SHIP:SENSORS:GRAV:MAG).
	declare STOPPING_DIST to SHIP:VELOCITY:SURFACE:MAG^2 / (2*(AVAILABLE_ACCEL - SHIP:SENSORS:GRAV:MAG)).
	lock THROTTLE to choose 1 if IS_DESCENDING and TIME_TO_TOUCHDOWN*1.5 <= BURN_TIME else 0. // "*1.5": The higher abive 1 this factor, the later the craft will begin its burn. 1.5 Seems to be a safe value.
	
	print "Time to Touchdown: "+TIME_TO_TOUCHDOWN at(0, 0).
	print "Burn Time: "+BURN_TIME at(0, 1).
}
lock THROTTLE to 0.
unlock THROTTLE.
print "  Settle.".
local SETTLE_TIME is 0.
until SETTLE_TIME>4 {
	lock STEERING to SHIP:UP.
	wait 0.1.
	unlock STEERING.
	wait 0.1.
	if SHIP:ANGULARVEL:MAG<0.1 {
		set SETTLE_TIME to SETTLE_TIME + 0.2.
	} else {
		set SETTLE_TIME to 0.
	}
}
print "  Done.".