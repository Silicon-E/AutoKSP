// Uses RCS to maneuver this ship out of the way of nearby vessels.

parameter PATH_DIR.

print "Begin steering clear of nearby vessels.".

local OTHER_VESSELS is -1.
list TARGETS in OTHER_VESSELS.
local OBSTACLE_COUNT is 0.
local OBSTACLES is LIST().
local OBSTACLE_BOXES is LIST().
local SHIP_BOX is SHIP:BOUNDS.

for OBSTACLE in OTHER_VESSELS {
	if OBSTACLE:DISTANCE < 10_000 {
		OBSTACLES:ADD(OBSTACLE).
		OBSTACLE_BOXES:ADD(OBSTACLE:BOUNDS).
		set OBSTACLE_COUNT to OBSTACLE_COUNT+1.
	}
}

if OBSTACLE_COUNT > 0 {
	SAS on.
	set SASMODE to "stability".
	RCS on.

	local DESIRED_POS is -1.
	until OBSTACLES[0]:DISTANCE > 30 {    // DESIRED_POS<>-1 and DESIRED_POS:MAG<1 {
		// Find position with clear path
		// TODO: make it more advanced
		set DESIRED_POS to (OBSTACLES[0]:POSITION:NORMALIZED *-30) + 30*VECTORCROSSPRODUCT(OBSTACLES[0]:POSITION:NORMALIZED, SHIP:UP:VECTOR).
		
		local RELATIVE_VEL is SHIP:VELOCITY:ORBIT - OBSTACLES[0]:VELOCITY:ORBIT.
		// The RCS deadzone is desired here. it is not overridden.
		set SHIP:CONTROL:TRANSLATION to (DESIRED_POS:NORMALIZED-RELATIVE_VEL)*SHIP:FACING:INVERSE.
	}
}
SAS off.
RCS off.
set SHIP:CONTROL:NEUTRALIZE to TRUE.
print "Done.".