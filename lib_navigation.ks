RUNONCEPATH("0:/AutoKSP/lib_ship.ks").
RUNONCEPATH("0:/AutoKSP/lib_orbit.ks").
RUNONCEPATH("0:/AutoKSP/lib_body.ks").

global AUTOKSP_CANAEROBRAKE is false. // Set by scripts using AutoKSP

// Takes this ship from wherever it currently is in the solar system to a target orbit around a specified body.
global GO_TO_ORBIT is {
	declare parameter PLANET is SHIP:ORBIT:BODY.
	declare parameter PERI is LOWEST_SAFE_ORBIT_ALT(PLANET).
	declare parameter APO is LOWEST_SAFE_ORBIT_ALT(PLANET).
	parameter MARGIN is 1000.
	parameter SHOULD_CIRCULARIZE is TRUE.
	
	print "Begin going to orbit around "+PLANET:NAME+".".
	print "  Target periapsis: "+PERI.
	print "  Target apoapsis: "+APO.
	until SHIP:ORBIT:BODY=PLANET and ABS(SHIP:ORBIT:PERIAPSIS-PERI)<MARGIN and ABS(SHIP:ORBIT:APOAPSIS-APO)<MARGIN {
		local ON_GROUND is SHIP:BOUNDS:BOTTOMALTRADAR < 100.
		// Of on ground, launch to orbit:
		if ON_GROUND { // ON_GROUND behaves poorly because radar altitude doesn't recognize the launchpad
			if SHIP:VELOCITY:SURFACE:MAG<0.1 {
				if SHIP:ORBIT:BODY=PLANET {
					RUNPATH("0:/AutoKSP/simple_launch.ks", PERI).
				} else {
					RUNPATH("0:/AutoKSP/simple_launch.ks").
				}
			} else {
				print "  Brake.".
				BRAKES on.
				wait until SHIP:VELOCITY:SURFACE:MAG<0.1.
			}
		}
		// If in orbit, adjust orbit or transfer:
		else if SHIP:ORBIT:PERIAPSIS>0 and SHIP:ORBIT:APOAPSIS>0 {
			if SHIP:ORBIT:BODY = PLANET {
				// RUNPATH("0:/AutoKSP/adjust_orbit.ks", PERI, APO, MARGIN). // Deprecated script
				print "In a non-ideal orbit. No orbit adjustment script is working; continuing without adjusting orbit...".
				break.
			} else {
				RUNPATH("0:/AutoKSP/maneuver.ks", APO, PLANET, MARGIN, SHOULD_CIRCULARIZE).
			}
		}
	}
	lock THROTTLE to 0.
	unlock THROTTLE.
	unlock STEERING.
	SAS off.
	print "Done.".
}.

// Takes this ship from wherever it currently is in the solar system to being landed on a specified body.
global GO_TO_SURFACE is {
	declare parameter PLANET.
	
	print "Begin going to the surface of "+PLANET:NAME+".".
	until SHIP:ORBIT:BODY=PLANET and SHIP:BOUNDS:BOTTOMALTRADAR < 0.1 {
		if NOT(SHIP:ORBIT:BODY=PLANET) {
			// If going to the surface of our current body's parent AND the parent has an atmosphere, perform an aerocapture.
			if PLANET = SHIP:BODY:BODY and PLANET:ATM:EXISTS and AUTOKSP_CANAEROBRAKE {
				print "Aim for aerocapture.".
				local ORBIT_ALT is PRESSURE_TO_ALT(KERBIN:ATM:ALTITUDEPRESSURE(30_000), PLANET:ATM).
				GO_TO_ORBIT(PLANET, ORBIT_ALT, ORBIT_ALT, 1000, FALSE). // Don't circularize
			} else { // Otherwise, do a normal orbital insertion
				local ORBIT_ALT is LOWEST_SAFE_ORBIT_ALT(PLANET).
				GO_TO_ORBIT(PLANET, ORBIT_ALT, ORBIT_ALT).
			}
		} else if SHIP:ORBIT:PERIAPSIS>0 and SHIP:ORBIT:APOAPSIS>0 {
			runpath("0:/AutoKSP/goto_clear_path.ks", SHIP:RETROGRADE:VECTOR).
			// Only perform a deorbit burn if there is no atmosphere OR our periapsis is above the atmosphere
			if (not(SHIP:ORBIT:BODY:ATM:EXISTS)) or SHIP:PERIAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT {
				runpath("0:/AutoKSP/deorbit.ks").
			}
			runpath("0:/AutoKSP/land.ks").
		} else { // Either periapsis or apoapsis is below sea level; use simple landing.
			print "Collision course detected. Use emergency landing procedure.".
			runpath("0:/AutoKSP/simple_land.ks").
		}
	}
	BRAKES on.
	print "Done.".
}.