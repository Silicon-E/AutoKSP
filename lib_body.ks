global PRESSURE_TO_ALT is {
	declare parameter PRESS.
	declare parameter ATMOS.
	declare RESULT to ATMOS:HEIGHT / 2.
	// Find the altitude where the pressure is closest to PRESS:
	from {declare I to 0.} until I>=16 step {set I to I+1.} do {
		if ATMOS:ALTITUDEPRESSURE(RESULT) = PRESS {
			return RESULT.
		} else if ATMOS:ALTITUDEPRESSURE(RESULT) > PRESS { // Alt too low
			set RESULT to RESULT + ATMOS:HEIGHT*0.5^(I+2).
		} else { // Alt too high
			set RESULT to RESULT - ATMOS:HEIGHT*0.5^(I+2).
		}
	}
	return RESULT.
}.