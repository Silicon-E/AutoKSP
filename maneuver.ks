//a copy of code for manuvering to the mun. No good for anything else.
//and still not all that good

parameter desired_height.
parameter desired_body.
parameter height_margin.

local debug is true.
local dquote is char(34).
//maybe todo find compile directive to turn of parenticeless function calls.
//math util
//v=v_c*U
//r=R_0*H
function U{
    parameter H_.
    return sqrt(2*H_/(1+H_)).
}
function U_e{
    parameter E_.
    return U((1+E_)/(1-E_)).//ecentricity for lowified orbits will be negative
}
function H{
    parameter U_.
    return U_^2/(2-U_^2).
}
function diag{parameter s_.
    if debug{
        print s_.
    }
}
function getDvEjectMoonDirect{//reversible
    //all velocities are critical velocities, except v_f
    parameter V_MP.//of moon around planet, corre. to R_m
    parameter V_M.//of spacecraft around moon
    parameter v_f.
    //R\propto 1/v^2
    //u_p=sqrt(2+(v_f/v_MP)^2)
    //v_fp=v_MP (U_p-1)
    //U_m=sqrt(2+(v_f/v_m)^2)
    return (sqrt(2*V_M^2+V_MP^2*(sqrt(2+(v_f/V_M)^2)-1)^2)-V_M).
        //=V_M*(U_m-1)
}
function getDvEjectMoonPlunge{//reversible
    //all velocities are critical velocities, except v_f
    parameter V_MP.//of moon around planet, corre. to R_m
    parameter V_M.//of spacecraft around moon
    parameter V_P.//at target plunge orbit
    parameter v_f.
    //R\propto 1/v^2
    //u_fp=sqrt(2+(v_f/v_P)^2)
    //u_ip=sqrt(2R_m/(R_p+R_m))
    //u_MP=sqrt(2R_p/(R_m+R_p))
    //u_mf=sqrt(2+(vfm/v_M)^2)
    local vfm is v_MP*(1-sqrt(2*V_MP^2/(V_P^2+V_MP^2))).
        //=v_MP*(1-U_MP)
    return sqrt(2*V_M^2+vfm^2)-V_M
        +V_P*(sqrt(2-(v_f/V_P)^2)-sqrt(2*V_P^2/(V_MP^2+V_P^2))).
        //=V_M*(U_mf-1)+v_P*(U_fp-U_ip) 
}
//next patch util.
//see: https://github.com/KSP-KOS/KOS/issues/2295  for someone else who is having this problem
local shipnextpatch is "null".
local shipnextpatchtimeout is 10.
local shipnextpatchtime is 0.
local shipnextpatchisvalid is false.
local shipnextpatchissearching is false.
local shipnextpatchtimestamp is "null".

function invalidateNextPatch{
    parameter timeout is 10.
    set shipnextpatchtimeout to 10.
    set shipnextpatchisvalid to false.
    set shipnextpatchisvalid to "null".
    set shipnextpatchtime to time:seconds.
    when ship:orbit:hasnextpatch or time:seconds>=shipnextpatchtime+timeout then{
        set shipnextpatch to (choose ship:orbit:nextpatch if ship:orbit:hasnextpatch else "null").
        set shipnextpatchisvalid to true.
        return false.//do not PRESERVE
    }

}
function getshipnextpatch{
    parameter timeout is 10.
    if not shipnextpatchissearching and not shipnextpatchisvalid{
        invalidateNextPatch(timeout).
    }
    wait until shipnextpatchisvalid.
    return shipnextpatch.

}
function m_exec {
    parameter nd is nextNode.
    parameter error is 0.1.
    parameter throttle_limiter is 1.
    parameter dophyswarp is true.
    parameter timewarpif is {return true.}.
    parameter endif is {return false.}.//ends the burn early if a condition is met and phys timewarp is off.
    set throttle_limiter to min(1,throttle_limiter).
    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    //calculate ship's max acceleration
    local max_acc to ship:maxthrust/ship:mass.
    // Please note, this is not exactly correct... mass change
    //
    local burn_duration to nd:deltav:mag/max_acc.
    print "Crude Estimated burn duration: " + round(burn_duration) + "s".
    local np to nd:deltav. //points to node, don't care about the roll direction.
    //avobe np does not act as a reference. mysterious.
    lock steering to np.//TODO steering wont turn with node

    //now we need to wait until the burn vector and ship's facing are aligned
    wait until vang(np, ship:facing:vector) < 0.25
            or nd:deltav:mag<0.1.

    //the ship is facing the right direction, let's wait for our burn time
    local w is time:seconds+nd:eta-(burn_duration/2)-10.
    warpto(w).
    wait until nd:eta <= (burn_duration/2).
    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    local tset to 0.
    lock throttle to tset*throttle_limiter.

    local done to False.
    //initial deltav
    local dv0 to nd:deltav.
    local dvcurr to nd:deltav.
    until done
    {
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to ship:maxthrust/ship:mass.
        if (nd:deltav:mag/max_acc)>15 and nd:deltav:mag>=1
                and dophyswarp and timewarpif(){
            set warpmode to "PHYSICS".
            set warp to 3.
        }else{
            set warp to 0.
            set warpmode to "RAILS".
            if endif(){set done to true.}
        }
        if (nd:deltav:mag/max_acc)>10 and nd:deltav:mag>=5{
            lock steering to nd:deltav.
            set dvcurr to nd:deltav.

        }else{
            lock steering to dvcurr.
        }
        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/max_acc, 1).

        //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
        //this check is done via checking the dot product of those 2 vectors
        if vdot(dv0, nd:deltav) < 0
        {
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            lock throttle to 0.
            break.
        }

        //we have very little left to burn, less then 0.1m/s
        if nd:deltav:mag < error
        {
            print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            //we burn slowly until our node vector starts to drift significantly from initial vector
            //this usually means we are on point
            wait until vdot(dv0, nd:deltav) < 0.5.

            lock throttle to 0.
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            set done to True.
        }
        print "   delta-V remaining: "+nd:deltav:mag+"   " at(0,2).
        
    }
    unlock steering.
    unlock throttle.
    wait 1.

    //we no longer need the maneuver node
    remove nd.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    set warpmode to "RAILS".
    set warp to 0.
    
}
function m_multexec {
    parameter nds.
    parameter timewarpif is {return true.}.
    parameter endif is {return false.}.//only for last one
    local i is 0.
    for nd in nds{
        set i to i+1.
        if i>=nds:length{
            m_exec(nd,0.1,1,true,timewarpif,endif).
        }else{
            m_exec(nd).
        }
    }
}
function multnode_changeEta{
    //changes the eta for each node in a list (structs and structs only are passed by reference).
    //if classes existed, we would make a multinode class for this but we cant (yet?).
    parameter mnode.//reference
    parameter det.//value
    for nds in mnode {
        set nds:eta to nds:eta+det.
    }

}
function etaAscendingNode{orbit:period.
    local norm_s is vectorCrossProduct(ship:orbit:position,ship:orbit:velocity).
    set norm_s to norm_s/norm_s:mag.
    local norm_t is vectorCrossProduct(target:orbit:position,target:orbit:velocity).
    set norm_t to norm_t/norm_t:mag.
    local vecto is vectorCrossProduct(norm_t,norm_s).
    if vecto:mag=0{return "None".}
    local eta is 0.
    until vectorCrossProduct(vecto,positionat(SHIP, TIME +eta) -BODY:POSITION):mag<
        vecto:mag*(positionat(SHIP, TIME +eta) -BODY:POSITION):mag/10000 {
        local rp is positionat(SHIP, TIME +eta) -BODY:POSITION.
        local vp is velocityat(SHIP, TIME +eta):ORBIT.
        if rp*vecto<0{
            set eta to eta+ship:orbit:period*0.1.
            set eta to mod(eta,ship:orbit:period).
        } else if vectorCrossProduct(vp,vecto):mag=0{
            set eta to eta+ship:orbit:period*0.123456789.//pseudoirrational
            set eta to mod(eta,ship:orbit:period).
        }else{
            //newtons method
            set eta to eta-vectorCrossProduct(rp,vecto)*vectorCrossProduct(vp,vecto)/vectorCrossProduct(vp,vecto):mag^2.
            
        }
        diag("eta->"+eta).
    }
    
}
local PHICRIT is 0.6.
//to make delagate to anonamous
//global manuverTo is {...}
global correction_time is 0.1.
function manuverTo{
    until not hasNode{remove nextNode.}//clean slate
    //NODE(utime, radial, normal, prograde)
    //manuver into a circular orbit of height ht around body B
    parameter ht.
    parameter B is target.
    parameter d_ht is 2000.//uncertainty of 2km
    //set target to B.
    local v_ci is sqrt(ship:body:mu/ship:orbit:semimajoraxis).
    diag("v_ci="+v_ci).
    //ignore ecentricity and inclination and sphere changes
    local Hgt is (B:orbit:semimajoraxis)/ship:orbit:semimajoraxis.
    local dv is v_ci*(U(Hgt)-1).
    local burn_dur_est to dv/(ship:maxthrust/ship:mass).
    local PHI is ship:velocity:orbit:mag*burn_dur_est/ship:orbit:semimajoraxis.
    local nburns is max(floor(PHI/PHICRIT,0),1).
    print ("making exit burn in "+nburns+" sub burns.").
    local nds is list().//<node>; turns out kos does not use templates
    from {local i is 0. local et is burn_dur_est.} until (i>=nburns) step {set i to i+1.} do {
        diag("subburn:"+i).
        nds:add(node(time:seconds+et,0,0,dv/nburns)).
        add nds[i].
        set et to et+nds[i]:orbit:period.

    }
    diag(nds).
    local nd to nds[nds:length-1].//this does set by reference
    //T^2=4 pi^2 /mu * a^3
    //TODO split burn into parts
    local trans is (ship:orbit:semimajoraxis)^3/4/ship:body:mu*constant:pi^2.//approx
    until nd:orbit:hasnextpatch and nd:orbit:nextpatch:periapsis>0 {
        multnode_changeEta(nds,ship:orbit:period/1000).
    }
    print "Target perapsis: "+(ht).
    local pp is abs(nd:orbit:nextpatch:periapsis-ht).
    local ppsgn is nd:orbit:nextpatch:periapsis-ht.//perapsis is an altitude above sea level
    local loop is 0.
    local first is true.
    until not nd:orbit:hasnextpatch
        and nd:orbit:nextpatcheta<nd:orbit:period {
        if abs(nd:orbit:nextpatch:periapsis-ht)>=pp and not first{
            diag("turnaround").
            set nd:prograde to nd:prograde +0.1.
            local dpro is 0.
            if abs(nd:orbit:hasnextpatch and nd:orbit:nextpatch:periapsis-ht)<pp{
                set dpro to 0.1.
            } else{
                set dpro to -0.1.
            }
            until false{
                //tweak prograde
                
                if abs(nd:orbit:nextpatch:periapsis-ht)>=pp or abs(nd:orbit:nextpatch:periapsis-ht)<=d_ht{
                    break.
                }
                set nd:prograde to nd:prograde+dpro.
                set pp to abs(nd:orbit:nextpatch:periapsis-ht).
                 wait 0.

            }
            break.
        }else if  abs(nd:orbit:nextpatch:periapsis-ht)<=d_ht
            or (nd:orbit:nextpatch:periapsis-ht)*(ppsgn)<0{
            diag("target perapsis hit.").
            break.
        }
        set pp to abs(nd:orbit:nextpatch:periapsis-ht).
        set ppsgn to nd:orbit:nextpatch:periapsis-ht.
        
        //if(loop=0){diag("perapsis: "+nd:orbit:nextpatch:periapsis).wait 0.1.}
        if(loop=0 and debug){print ("  perapsis: "+nd:orbit:nextpatch:periapsis)+"   " at(0,3).}
        multnode_changeEta(nds,ship:orbit:period/30000).
        set loop to Mod(loop+1,10).
        set first to false.
    }
    local prevpari is "null".
    function stop{
        if not nds[nds:length-1]:orbit:hasnextpatch{return false.}
        local patch is nds[nds:length-1]:orbit:nextpatch.
        if not prevpari="null" and patch:periapsis-ht-d_ht>0 and patch:periapsis>prevpari {
            return true.
        }
        set prevpari to patch:periapsis.
        return false.
    }
    function timewarp{
        return  not ship:orbit:hasnextpatch.
    }
    m_multexec(nds,timewarp@,stop@).
    //if orbit is after a period or more, ksp will change its mind each frame whether it exists. check many frames
    print "Testing for encounter.".
    local frame_out is "".
    local nframe is 100.
    local dt is 0.02.
    local npatch is 0.
    local nextpatch is "null".//access is getOnly.
    local etanextpatch is -1.
    from {local a is 0.} until a>=nframe step {set a to a+1.} do{
        if ship:orbit:hasnextpatch{
            set nextpatch to ship:orbit:nextpatch.
            set etanextpatch to ship:orbit:nextpatcheta.//hopefully fast enough
            set npatch to npatch+1.
            set frame_out to frame_out+"1".
            break.

        }else {
            set frame_out to frame_out+"0".
        }
    }
    diag(frame_out).
    unset frame_out.
    if npatch>0 and npatch<nframe and nextpatch="null"{
        print "Encounter Lost partially, warping to recover.".
        warpto(time:seconds+ship:orbit:period*(1-correction_time)).
        if not ship:orbit:hasnextpatch{
            print  "Could not recover. Terminating execution.".
            return.
        }

    }else if npatch=0 and false{
        print "Encounter Lost, warping to recover.".
        warpto(time:seconds+ship:orbit:period*(1-correction_time)).
        if not ship:orbit:hasnextpatch{
            print  "Could not recover. Terminating execution.".
            return.
        }
    } else if etanextpatch>ship:orbit:period
    {
        warpto(time:seconds+(ship:orbit:nextpatcheta-ship:orbit:period*(0.5+correction_time))).
    } 
    if abs(nextpatch:periapsis-ht)>d_ht{
        local cnd is node(time:seconds+ship:orbit:period*correction_time,0,0,0).
        add cnd.
        local ddv is 0.01.
        local ddvrad is 0.002.
        local lock herr to abs(cnd:orbit:nextpatch:periapsis-ht).
        //this trick did not work. still no next cnd:patch
        until herr<d_ht or cnd:orbit:hasnextpatch{//TODO infinite loop
            local change is false.
            local ppc is herr.//prograde test
            set cnd:prograde to cnd:prograde+ddv. wait 0.
            if(herr>ppc){set cnd:prograde to cnd:prograde-ddv. wait 0.}//undo if
            else{set change to true.}
            local ppc is herr.//retrograde test
            set cnd:prograde to cnd:prograde-ddv. wait 0.
            if(herr>ppc){set cnd:prograde to cnd:prograde+ddv. wait 0.}//undo if
            local ppc is herr.//rad out test
            set cnd:radialout to cnd:radialout+ddvrad. wait 0.
            if(herr>ppc){set cnd:radialout to cnd:radialout-ddvrad. wait 0.}//undo if
            else{set change to true.}
            local ppc is herr.//rad in test
            set cnd:radialout to cnd:radialout-ddvrad. wait 0.
            if(herr>ppc){set cnd:radialout to cnd:radialout+ddvrad. wait 0.}//undo if
            else{set change to true.}
            if not change {break.}
        }
        m_exec(cnd,0.01,0.2).
    }
    //important: warpto does not also wait in program.
    warpto(time:seconds+ship:orbit:nextpatcheta).
    wait 5.
    print ("Target body: "+B:tostring()).
    print ("Current body: "+ship:body:tostring()).
    wait until ship:orbit:body:tostring()=B:tostring().
    //cannot find eta's for a later patch
    local vi2 is velocityat(SHIP, time:seconds +eta:periapsis):orbit:mag.
    diag ("Entry eccentricity:="+ship:orbit:eccentricity).
    local Ul is U_e(ship:orbit:eccentricity).
    local nd2 is node(time:seconds+eta:periapsis,0,0,(1/Ul-1)*vi2).
    add nd2.
    m_exec().//(parameter is nd2)
    wait 3.
    print "Manuvering to orbit arround "+dquote +B:tostring+dquote+" is finished.".

}
function testpatch {
    local frame_out is "".
    local nframe is 100.
    local dt is 0.02.
    local npatch is 0.
    local nextpatch is "null".//access is getOnly.
    local etanextpatch is -1.
    from {local a is 0.} until a>=nframe step {set a to a+1.} do{
        if ship:orbit:hasnextpatch{
            set nextpatch to ship:orbit:nextpatch.
            set etanextpatch to ship:orbit:nextpatcheta.//hopefully fast enough
            set npatch to npatch+1.
            set frame_out to frame_out+"1".
            break.

        }else {
            set frame_out to frame_out+"0".
        }
    }
    print frame_out.
}
if debug{
    if false{
        until false{
            wait 1.0.
            invalidateNextPatch().
            local patch is getshipnextpatch().
            //still cannot consistantly retrieve a next patch
            diag(patch).
            if not (patch="null"){
                diag("periapsis: "+patch:periapsis).
            }
        }
    }
    if false {until false{
        testpatch().
    }}
    //set target to mun.
    //delagate conversion
    //same name not allowed
    //global manuverTo is manuverTo@.
    manuverTo(desired_height, desired_body, height_margin). // manuverTo(25000,mun,5000).
    //this one now workes
}

