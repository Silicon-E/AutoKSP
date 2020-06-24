global AVAILABLE_ACCEL is {
	return SHIP:AVAILABLETHRUST / SHIP:MASS.
}.
global PRESSURE_TO_AVAILABLE_ACCEL is {
	declare parameter PRESS.
	return SHIP:AVAILABLETHRUSTAT(PRESS) / SHIP:MASS.
}.
// Return: Scalar (t/s)
global PRESSURE_TO_AVAILABLE_FUEL_FLOW is {
	declare parameter PRESS.
	local RESULT is 0.
	list ENGINES in ENGS. // Impossible to directly access the engine list. Have to use this syntax. Uuuuuuuugghh...
	for ENG in ENGS {
		set RESULT to RESULT + ENG:AVAILABLETHRUSTAT(PRESS) / (ENG:ISPAT(PRESS) * 9.80665).
	}
	return RESULT.
}.
// Return: Scalar (t/s)
global AVAILABLE_FUEL_FLOW is {
	local RESULT is 0.
	list ENGINES in ENGS. // Impossible to directly access the engine list. Have to use this syntax. Uuuuuuuugghh...
	for ENG in ENGS {
		set RESULT to RESULT + ENG:AVAILABLETHRUST / (ENG:ISP * 9.80665).
	}
	return RESULT.
}.