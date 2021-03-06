// R_TO_ORBITAL_SPEED(Scalar(m) R, Body PLANET, Orbit ORB)
global R_TO_ORBITAL_SPEED is {
	declare parameter R.
	declare parameter PLANET to SHIP:ORBIT:BODY.
	declare parameter ORB to SHIP:ORBIT.
	//declare ASCENDING_NODE_VEC to SOLARPRIMEVECTOR * ANGLEAXIS(LONGITUDEOFASCENDINGNODE, PLANET:UP:VECTOR).
	//declare SHIP_ORBIT_PLANE_VEC to PLANET:UP:VECTOR * ANGLEAXIS(SHIP:ORBIT:INCLINATION, ASCENDING_NODE_VEC).
	//declare PERIAPSIS_VEC to (ASCENDING_NODE_VEC * ANGLEAXIS(SHIP:ORBIT:ARGUMENTOFPERIAPSIS)):NORMALIZED.
	//declare APOAPSIS_VEC to -PERIAPSIS_VEC * SHIP:ORBIT:APOAPSIS.
	// Use the vis-viva equation:
	return SQRT(6.673e-11*PLANET:MASS * (2/R - 1/SHIP:ORBIT:SEMIMAJORAXIS)).
}.

global PERI_APO_TO_ECCENTRICITY is {
	parameter PERI.
	parameter APO.
	return (APO-PERI) / (APO+PERI).
}.

global LOWEST_SAFE_ORBIT_ALT is {
	parameter PLANET.
	
	if PLANET:ATM:EXISTS {
		return PLANET:ATM:HEIGHT + 5_000.
	} else if PLANET=IKE or PLANET=TYLO or PLANET=IKE {
		return 15_000.
	} else if PLANET=BOP {
		return 25_000.
	} else {
		return 10_000.
	}
}.