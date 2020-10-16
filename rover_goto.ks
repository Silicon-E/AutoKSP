runpath("0:/AutoKSP/lib_collections.ks").

parameter destination.
local waypts is list(destination).

local visArrows is list().
local minGridSize is 100.
clearVecDraws().

local arrow is vecdraw(latLng(floor(ship:geoPosition:lat+90/(180/20))*(180/20)-90, floor(ship:geoPosition:lng+180/(180/20))*(180/20)-180):altitudePosition(10000), latlng(90,0):altitudePosition(1000000), rgb(0.5,0.5,0.5)).
until false { set arrow:show to true. }

// Calculate path
//from {local gridSize is ship:body:radius/4.} until gridSize*10<minGridSize step {set gridSize to gridSize/10.} do {
//	refinePath(gridSize).
//}
drawAStar(  a_star(ship:geoPosition, destination, 20, 90, -500, false, true, true)  ).
//wait 5.
//drawPath().

until false {
	redrawPath().
	wait 5.
}

// Follow path
set pid to pidLoop(1, 0, 0, -1, 1).
lock wheelThrottle to 1.
brakes off.

until destination:distance < 1 {
	set ship:control:wheelSteer to abs(destination:bearing)/180 * pid:update(time:seconds, destination:bearing).
}
lock wheelThrottle to 0.
unlock wheelThrottle.
set ship:control:wheelSteer to 0.
brakes on.

local function a_star {
	parameter startCoords.
	parameter endCoords.
	parameter gridDivisions.
	set gridDivisions to max(gridDivisions, 2).
	parameter maxSlopeDegrees is 30.
	parameter imaginarySeaLevel is 0. // Used to make pathfinding at large scales more permissive of thin isthmuses
	parameter canTraverseSea is false.
	parameter canTraverseLand is true.
	parameter allowMixedTerrain is false. // Allows traversal of sectors with land AND sea if the craft can only traverse one.
	parameter isBuoyant is true.
	local gridSizeDegrees is 180/gridDivisions.
	local maxSlope is tan(min(89.99, maxSlopeDegrees)).
	// The internal array of sectors has horizontal size = gridDivisions*2 and vertical size = gridDivisions.
	// Sector indices are always positive. The defining corner of sector (0,0) is at the south pole, on the prime meridian.
	local maxX is gridDivisions*2 - 1.
	local maxY is gridDivisions - 1.
	
	local sectorCorners is lexicon().
	local getSectorCorner is {
		parameter x.
		parameter y.
		if not sectorCorners:hasKey(x) {
			sectorCorners:add(x, lexicon()).
		}
		if not sectorCorners[x]:hasKey(y) {
			sectorCorners[x]:add(y, lexicon()).
			set sectorCorners[x][y]:geoCoords to latLng(y*gridSizeDegrees-90, x*gridSizeDegrees-180).
			set sectorCorners[x][y]:isLand to sectorCorners[x][y]:geoCoords:terrainHeight>=imaginarySeaLevel.
			set sectorCorners[x][y]:isSea to not sectorCorners[x][y]:isLand.
		}
		return sectorCorners[x][y].
	}.
	
	// Conditions: all corners of the sector are above/below sea level as needed AND the slope between any two corners is within maxSlope.
	local sectors is lexicon().
	local getSector is {
		parameter x.
		parameter y.
		if not sectors:hasKey(x) {
			sectors:add(x, lexicon()).
		}
		if not sectors[x]:hasKey(y) {
			sectors[x]:add(y, lexicon()).
			
			// Setup sector properties:
			set sectors[x][y]:x to x.
			set sectors[x][y]:y to y.
			set sectors[x][y]:center to latLng((y+0.5)*gridSizeDegrees-90, (x+0.5)*gridSizeDegrees-180).
			local sw is getSectorCorner(x,   y).
			local nw is getSectorCorner(x,   y+1).
			local se is getSectorCorner(x+1, y).
			local ne is getSectorCorner(x+1, y+1).
			// The following 2 flags are NOT mutually exclusive; sectors bordering oceans will be both.
			set sectors[x][y]:hasLand to false.
			set sectors[x][y]:hasSea to false.
			for pos in list(sw,nw,se,ne) {
				if pos:isSea {
					set sectors[x][y]:hasSea to true.
				} else {
					set sectors[x][y]:hasLand to true.
				}
			}
			// Determine whether the sector is passable:
			set sectors[x][y]:isPassable to true.
			if allowMixedTerrain and ((sectors[x][y]:hasSea and canTraverseSea) or (sectors[x][y]:hasLand and canTraverseLand)) {
				// Sector has at least one suitable terrain type, and this iteration is allowed to traverse such sectors.
				// Leave isPassable as true.
			} else {
				if sectors[x][y]:hasSea and not canTraverseSea {
					set sectors[x][y]:isPassable to false.
				} else if sectors[x][y]:hasLand and not canTraverseLand {
					set sectors[x][y]:isPassable to false.
				} else {
					// Test slope between each pair of corners:
					for pos1 in list(sw,nw,se,ne) {
						for pos2 in list(sw,nw,se,ne) {
							local lateralDist is geoDist(ship:body:radius, pos1:geoCoords, pos2:geoCoords).
							// Ignore max slope for entirely-ocean tiles if this craft is buoyant.
							// At the poles, corners can have identical positions. Ignore corners with identical positions.
							if        false and        pos1<>pos2 and (sectors[x][y]:hasLand or not isBuoyant) and lateralDist>0
									and abs(pos1:geoCoords:terrainHeight-pos2:geoCoords:terrainHeight)/lateralDist > maxSlope {
								set sectors[x][y]:isPassable to false.
							}
						}
					}
				}
			}
			
			// Setup sector pathfinding parameters:
			set sectors[x][y]:distFromStart to -1.
			set sectors[x][y]:distFromEndGuess to geoDist(ship:body:radius, sectors[x][y]:center, endCoords).
			set sectors[x][y]:totalDistGuess to -1.
			set sectors[x][y]:previousSector to -1.
			set sectors[x][y]:compareTo to {parameter other. return sectors[x][y]:totalDistGuess - other:totalDistGuess.}.
		}
		return sectors[x][y].
	}.
	local coordsToSector is {
		parameter geoCoords.
		return getSector(clamp(floor(geoCoords:lng+180/gridSizeDegrees), 0, maxX), clamp(floor(geoCoords:lat+90/gridSizeDegrees), 0, maxY)).
	}.
	
	// Given a sector and an x/y index offset, gets the correct neighbor sector. Accounts for "wrapping around" the planet's seams
	local function getSectorNeighbor {
		parameter sector.
		parameter dx.
		parameter dy.
		local boundlessY is sector:y + dy.
		local flipXComponent is choose gridDivisions if boundlessY>maxY else 0.
		local yWithFlip is choose maxY+1 - (boundlessY-maxY) if boundlessY>maxY else boundlessY.
		return getSector(unsignedMod(sector:x+dx, gridDivisions*2), yWithFlip).
	}
	
	// --------------------------------- BEGIN A-STAR ALGORITHM -----------------------------------
	print "a_star start".
	local openSet is simplePriorityQueue().
	local start is coordsToSector(startCoords).
	local end is coordsToSector(endCoords).
	set start:distFromStart to 0.
	set start:totalDistGuess to start:distFromStart + start:distFromEndGuess.
	openSet:push(start).
	
	until openSet:contents:length = 0 {
		local current is openSet:pop().
		if current = end {
			break.
		}
		local neighbors is list().
		neighbors:add(getSectorNeighbor(current,  0,  1)). // N
		neighbors:add(getSectorNeighbor(current,  0, -1)). // S
		neighbors:add(getSectorNeighbor(current,  1,  0)). // E
		neighbors:add(getSectorNeighbor(current, -1,  0)). // W
		neighbors:add(getSectorNeighbor(current, -1, -1)). // SW
		neighbors:add(getSectorNeighbor(current, -1,  1)). // NW
		neighbors:add(getSectorNeighbor(current,  1, -1)). // SE
		neighbors:add(getSectorNeighbor(current,  1,  1)). // NE
		// If we are on a pole, add all polar sectors as neighbors:
		if current:y=0 or current:y=maxY {
			from {local i is 1.} until i>=gridDivisions*2 step {set i to i+1.} do {
				local neighbor is getSectorNeighbor(current, i, 0).
				if not neighbors:contains(neighbor) {
					neighbors:add(neighbor).
				}
			}
		}
		if neighbors:contains(end) { // Need this shortcut because 'endCoords' don't exacly match the center of 'end'
			break.
		}
		for neighbor in neighbors {
			if neighbor:isPassable {
				local tentativeDistFromStart is current:distFromStart + geoDist(ship:body:radius, current:center, neighbor:center).
				if neighbor:distFromStart=-1 or tentativeDistFromStart<neighbor:distFromStart {
					set neighbor:previousSector to current.
					set neighbor:distFromStart to tentativeDistFromStart.
					set neighbor:totalDistGuess to neighbor:distFromStart + neighbor:distFromEndGuess.
					if not openSet:contents:contains(neighbor) {
						openSet:push(neighbor).
					}
				}
			}
		}
	}
	print "a_star end".
	// If the end sector was assigned a previous sector on the path;
	// that is, a path was found:
	if end:previousSector <> -1 {
		waypts:clear().
		waypts:add(endCoords).
		local sector is end:previousSector.
		until sector = start {
			waypts:insert(0, sector:center).
			set sector to sector:previousSector.
		}
	} else {
		print "Pathing unsuccessful.".
	}
	return sectors. // Return the collection of sectors for use in the heuristic function of future iterations.
}

local function drawPath {
	local i is 0.
	local arrowStart is v(0,0,0).
	for waypt in waypts {
		local subArrowCount is ceiling((waypt:position-arrowStart):mag / (ship:body:radius/10)).
		from {local j is 0.} until j>=subArrowCount step {set j to j+1.} do {
			// Get existing arrow or make a new one:
			local arrow is -1.
			if visArrows:length<=i {
				set arrow to vecdraw().
				visArrows:add(arrow).
			} else {
				set arrow to visArrows[i].
			}
			
			set arrow:start to ship:body:geopositionof(lerp(arrowStart, waypt:position, j/subArrowCount)):position.
			set arrow:vec to ship:body:geopositionof(lerp(arrowStart, waypt:position, (j+1)/subArrowCount)):position - arrow:start.
			set arrow:width to 1. // ship:body:radius/60.
			set arrow:show to true.
			set arrow:color to rgb(0.5,0.5,0.5).
			
			set i to i+1.
		}
		
		set arrowStart to waypt:position.
	}
	until i>= visArrows:length {
		set visArrows[i]:show to false.
		visArrows:remove(i).
	}
}

local function redrawPath {
	for arrow in visArrows {
		set arrow:show to true.
	}
}

local function drawAStar {
	parameter sectors.
	
	local i is 0.
	for sectorList in sectors:values {
		for sector in sectorList:values {
			if sector:previousSector<>-1 {
				local start is sector:center:position.
				local end is sector:previousSector:center:position.
				local subArrowCount is 1. // ceiling((end-start):mag / (ship:body:radius/10)).
				from {local j is 0.} until j>=subArrowCount step {set j to j+1.} do {
					// Get existing arrow or make a new one:
					local arrow is -1.
					if visArrows:length<=i {
						set arrow to vecdraw().
						visArrows:add(arrow).
					} else {
						set arrow to visArrows[i].
					}
					
					set arrow:start to ship:body:geopositionof(lerp(start, end, j/subArrowCount)):altitudePosition(50_000).
					set arrow:vec to ship:body:geopositionof(lerp(start, end, (j+1)/subArrowCount)):altitudePosition(50_000) - arrow:start.
					set arrow:width to 1. // ship:body:radius/6.
					set arrow:show to true.
					set arrow:color to rgb(0.5,0.5,0.5).
				}
				
				set i to i+1.
			}
		}
	}
	until i>= visArrows:length {
		set visArrows[i]:show to false.
		visArrows:remove(i).
	}
}

local function lerp {
	parameter a.
	parameter b.
	parameter t.
	return a + (b-a)*t.
}

local function clamp {
	parameter a.
	parameter min.
	parameter max.
	return max(min, min(max, a)).
}

local function unsignedMod {
	parameter a.
	parameter max. // Exclusive
	until a>=0 {
		set a to a+max.
	}
	return mod(a,max).
}

// "Haversine formula" https://www.movable-type.co.uk/scripts/latlong.html
local function geoDist {
	parameter r.
	parameter geoCoords1.
	parameter geoCoords2.
	local lat1 is geoCoords1:lat.
	local lat2 is geoCoords2:lat.
	local dLat is lat2 - lat1.
	local dLon is geoCoords2:lng - geoCoords1:lng.

	local a is sin(dLat/2) * sin(dLat/2) +
			  cos(lat1) * cos(lat2) *
			  sin(dLon/2) * sin(dLon/2).
	local c is 2 * arctan2(sqrt(a), sqrt(1-a)).

	return R * c. // in metres
}