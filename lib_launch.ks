parameter debug is true.



local function breakpoint{parameter s_.
    if debug{
        //cannot pause from kos but could quicksave and then quickload later.
        print "breakpoint: "+s_+"; press any key to continue".
        terminal:input:clear.
        wait until terminal:input:haschar.
        terminal:input:clear.
    }
}
if(ship:connection:isconnected) 
    //runOncePath("0:/AutoKSP/lib_launch_lob_data_kerbin.ks"). // old
    runOncePath("0:/AutoKSP/generated/lib_launch/lob_data_kerbin.ks").
else print "Error: could not connect to space center to load kinematic data.".


local function exp{
    parameter x. return constant:e^x.
}
local function G_of{
    parameter V is ship.
    return V:body:mu / (V:body:radius + V:altitude) ^ 2.
}
local function get_v_c {
    parameter B is ship:body.
    parameter Rad is B:radius + ship:altitude.
    return sqrt(B:mu/Rad).
}
local function simple_launch {
    function getAsm{
        parameter dv1.
        local hnot is 20000-1000*ship:availablethrust/ship:mass/(ship:body:mu/ship:body:radius^2)
                -2*dv1.
        return 90-arctan(ship:apoapsis/hnot).
    }
    lock throttle to 1.
    stage.
    //list engines in engs.
    local isp is 290.
    local dv_1 is ln(ship:mass/ship:drymass)*isp.
    lock steering to up.
    local second is false.
    when availableThrust=0 then{
        stage.
        set second to true.
        return false.
    }
    local prev_eta_a is eta:apoapsis.
    local asym is 90.
    until apoapsis>75000{
        if not second {
            lock throttle to choose 1 if ship:availableThrust=0 else min(ship:mass*(ship:body:mu/ship:body:radius^2)/ship:availablethrust*2.1,1).//max twr 2.1
            set asym to getAsm(dv_1).
            lock steering to heading(90,asym,0).//dir, pitch roll
        }else {
            lock throttle to 1.
            local vc is sqrt(ship:body:mu/(ship:body:radius+ship:apoapsis)).
            local acceff is ship:availablethrust/(ship:mass+ship:drymass)*2.
            print "eta ratio: "+(eta:apoapsis)/(prev_eta_a-eta:apoapsis)*acceff/abs(ship:velocity:orbit:mag-vc) at(2,2).
            if (not (prev_eta_a-eta:apoapsis<=0)) and ((eta:apoapsis)/(prev_eta_a-eta:apoapsis)*acceff>abs(vc-ship:velocity:orbit:mag)
                    *(0.5+(70000-ship:apoapsis)/(70000))){
                set asym to asym-1.
            }else {
                set asym to asym+1.
            }
            set asym to max(min(45,asym),0).

        }
        set prev_eta_a to eta:apoapsis.
        wait 1.
    }
    lock throttle to 0.
    unlock steering.
    unlock throttle.

}
local function pre_anylizeStages{
    parameter removeStagesWithNoBurnTime is false.
    //thx brekus:  https://pastebin.com/6ga862mt    
    //     from   https://www.reddit.com/r/Kos/comments/3fq4is/a_script_to_get_information_on_stages_in_advance/

    lock throttle to 0.
    wait 0.05.

    // the ultimate product of the program
    // will contain lists of data about each stage
    set stages to list().

    list engines in engineList.
    from {local i is 0.} until i>=engineList:length() step {} do {
        if engineList[i]:tag:contains("srb_sep")  engineList:remove(i).
        else set i to i+1.
    }


    local g is 9.80665.

    // have to activate engines to get their thrusts (for now)
    local activeEngines is list().
    for eng in engineList{
        if eng:tag:contains("srb_sep") {
            //already removed, should not be reached
            print "srb_sep found too late".
        } else if eng:ignition = false{
            eng:activate.
        } else {
            activeEngines:add(eng).
        }
    }
        

    // tagging all decouplers as decoupler by looking at part modules
    for part in ship:parts
        for module in part:modules
            if part:getModule(module):name = "ModuleDecouple" 
            or part:getModule(module):name = "ModuleAnchoredDecoupler"
                set part:tag to "decoupler".

    // sections are groups of parts between decouplers
    // the roots of sections are the ship root and all decouplers
    local sectionRoots is list().

    sectionRoots:add(ship:rootPart).

    for decoupler in ship:partsTagged("decoupler")
        sectionRoots:add(decoupler).

    // lists of (root part, mass, fuelmass, engines, and fuelflow)
    local sections is list().

    // creates a section from the root of each section
    for sectionRoot in sectionRoots{

        local sectionMass is 0.
        local sectionFuelMass is 0.
        local sectionEngineList is list().
        local fuelFlow is 0.
        
        local sectionParts is list().
        sectionParts:add(sectionRoot).
        
        // add all children down part tree from the section root to
        // list of section parts unless they are a decoupler or launch clamp
        local i is 0.
        until i = sectionParts:length{
            if sectionParts[i]:children:empty = false
                for child in sectionParts[i]:children
                    if child:tag = "decoupler" = false and child:name = "LaunchClamp1" = false
                        sectionParts:add(child).
            set i to i + 1.
        }
        
        for part in sectionParts{
            
            set sectionMass to sectionMass + part:mass.
            
            // avoiding adding rcs fuel to fuelmass
            local rcsFlag is false.
            
            if part:resources:empty = false{
                for resource in part:resources
                    if resource:name = "monopropellant"
                        set rcsFlag to true.
            
                if rcsFlag = false
                    set sectionFuelMass to sectionFuelMass + part:mass - part:drymass.
            }
            
            if engineList:contains(part)
                sectionEngineList:add(part).
        }
            
        local section is list(sectionRoot,sectionMass,sectionFuelMass,sectionEngineList,fuelFlow).
        sections:add(section).
    }
    //print sections. breakpoint("sections above").
    local firstStageNum is 0.
    for eng in engineList
        if eng:stage > firstStageNum
            set firstStageNum to eng:stage.

    // counting down from first (highest number) stage
    // to stage 0, creating stage data and
    // updating mass and fuelmass of the sections as it goes
    // essentially "simulating" staging
    local i is firstStageNum.
    until i = -1 {
        
        // the four things really needed
        local stageMass is 0.
        local stageEndMass is 0.
        local stageThrust is 0.
        local stageFuelFlow is 0.
        local stageBurnTime is 987654321. // starts high cause need to find lowest
        
        // other stuff it may as well calculate
        local stageMinA is 0.
        local stageMaxA is 0.
        local stageISP is 0.
        //local stageISP_ASL is 0.
        local stageDeltaV is 0.
        
        local curStage is list().

        local stageThrust_Asl is 0.
        
        // if the section decoupler activates on this stage remove that section
        // except the first section root (not a decoupler)
        local k is sections:length - 1.
        until k = 0{
            
            if sections[k][0]:stage = i
                sections:remove(k).
                    set k to k - 1.
            }
        
        // generating the stage mass, thrust, fuelflow, and burntime 
        // from the sections that make up the stage
        for section in sections{
            
            local sectionMass is section[1].
            local sectionFuelMass is section[2].
            // resetting fuelflow
            set section[4] to 0.
            local sectionBurnTime is 0.
            
            set stageMass to stageMass + sectionMass.
                
            if section[3]:empty = false{
                //print "stage " + i + " has engines".
                for engine in section[3]
                    if engine:stage  >= i{
                        set stageThrust to stageThrust + engine:maxthrustat(0).
                        set stageThrust_Asl to stageThrust_Asl + engine:maxthrustat(1).

                        set stageFuelFlow to stageFuelFlow + engine:maxthrustat(0)/engine:visp.// visp is vaccume-isp
                        set section[4] to section[4] + engine:maxthrustat(0)/engine:visp.
                    }
            }
            // if it has fuelflow (active engines)
            if section[4] > 0{
                set sectionBurnTime to g * section[2] / section[4].
                
                
                // if the section will stage next stage
                // or this if this is the last stage
                //if section[0]: stage = i - 1 or i = 0
                if true //assume burn occurs at first possible stage (opposite of copied code, which assumes last valid stag)
                                //; TODO resolve staging behavior of farings / boosters
                    if sectionBurnTime < stageBurnTime
                        set stageBurnTime to sectionBurnTime.
                
                //TODO edit this so that faring will not stage yet.
            } //else print "stage "+i+" has no fuel flow".
        }
        //print "i=" +i.
        //print sections.
        //breakpoint("sections above").
        
        // only possible if there are no active engines this stage (or god help you)
        if stageBurnTime = 987654321
            set stageBurnTime to 0.
        
        // calculating optional goodies
        if stageBurnTime > 0{
            set stageEndMass to stageMass - stageBurnTime * stageFuelFlow / g.
            set stageMinA to stageThrust / stageMass.
            set stageMaxA to stageThrust/ stageEndMass.
            set stageISP to stageThrust / stageFuelFlow.
            set stageDeltaV to stageISP * g * ln(stageMass / stageEndMass).
        }else {
            //NEW
            set stageEndMass to stageMass. //same wet / dry mass
        }
        
        // take a deep breath
        //THIS IS OUTPUT
        //ORIGINAL:
        //set curStage to list(stageMass,stageISP,stageThrust,stageMinA,stageMaxA,stageDeltaV,stageBurnTime).
        //NEW:activeEngines
        set curStage to lexicon().
            set curStage:wetmass to stageMass.
            set curStage:drymass to stageEndMass.
            set curStage:isp to stageISP.
            set curStage:vsp to stageISP * g.
            if(stageThrust>0) set curStage:vsp_asl to curStage:vsp * stageThrust_Asl/stageThrust. else set curStage:vsp_asl to 0.
            if(stageMinA>0) set curStage:tsp to stageISP * g / stageMinA. else set curStage:tsp to 0.
            set curStage:thrust to stageThrust.
            set curStage:thrust_asl to stageThrust_Asl.
            set curStage:startAcc to stageMinA.
            set curStage:endAcc to stageMaxA.
            set curStage:deltav to stageDeltaV.
            set curStage:burntime to stageBurnTime.
            set curStage:number to i.//Traditional stage number

        stages:add(curStage).

        // reduce the mass and fuel mass of sections with active engines
        // according to the burn time of the stage
        for section in sections{
            set section[1] to section[1]- stageBurnTime * section[4] / g.
            set section[2] to section[2] - stageBurnTime * section[4] / g.
            }
            
        set i to i - 1.
    }
        
    // remove stages with no burn time
    // comment out if you're curious, should look more like KERs' "show all stages" in VAB
    if(removeStagesWithNoBurnTime)//ADDED
    {
        local i is stages:length - 1.
        until i = -1{
            //MODIFIED
            //local burntime is stages[i][6].//ORIG
            local burntime is stages[i]:burnTime.//NEW
            if burntime= 0
                stages:remove(i).
            set i to i - 1.
            }
    }
    // shutting engines back down
    for eng in engineList
        if activeEngines:contains(eng) = false
            eng:shutdown.


    return stages.//ADDED
}
function anylizeStages{
    //ship:stagenum does not exist
    local stages is pre_anylizeStages().
    //NOTE: stages are listed first to last but :number is listed normally
    //stage:number still works.
    local ret is lexicon().
    local a is 0.
    until a >= stages:length() {
        if(stages[a]:thrust>0){
            set ret:first to stages[a].
            print "found first stage num "+ ret:first:number.
            set a to a+1.
            break.
        }
        set a to a+1.
    }
    until a >= stages:length() {
        if(stages[a]:thrust>0){
            set ret:second to stages[a].
            //set ret:second_prev to stages[a+1].
            print "found second stage num "+ ret:second:number.
            set a to a+1.
            break.
        }
        set a to a+1.
    }
    //breakpoint("staging analysis done").
    print ret:first.
    print ret:second.
    //print ret:second_prev. // some stuff lime mass is never set unless there are engines
    //TODO ret:second has all its deltaV given to the faring-sep stage
    //breakpoint("stages above").
    return ret.

}
function mu_sd{
    parameter data.
    local sum is 0.
    for d in data {
        set sum to sum+d.

    }
    local mu is sum / data:length().
    local ssum is 0.
    for d in data {
        set ssum to ssum+(d-mu)^2.
    }
    local sdev is sqrt(ssum/data:length()).
    return list(mu,sdev).
}
function record_Vterm{
    lock throttle to 1.
    unlock steering.
    stage.
    local m_1 is ship:mass.
    wait 3.
    local t0 is time:seconds.
    //local t00 is t0.
    local v0 is ship:velocity:orbit.
    local m0 is ship:mass.
    local vel0 is ship:velocity:surface.
    local pressr0 is ship:body:atm:altitudePressure(ship:altitude).
    wait 1.
    local drags1 is list().
    //local times is list().
    //TODO is mysteriously not working properly
    until drags1:length > 30 {
        local t1 is time:seconds.
        local v1 is ship:velocity:orbit.
        local vel is ship:velocity:surface.
        local m is ship:mass.
        local thrust is ship:availableThrust.
        local thrust_dir is ship:facing:forevector.
        local pressr is ship:body:atm:altitudePressure(ship:altitude).
        local grav is G_of(ship).
        local dragvec is (m+m0)/2*(v1-v0)/(t1-t0) + ship:up:forevector * grav * m - thrust*thrust_dir.
        local drag is dragvec:mag  * 2/ (vel:sqrmagnitude() + vel0:sqrmagnitude())  * 2/ (pressr+pressr0).
        drags1:add(drag).
        //times:add(t1-t00).
        local vterm_asl is sqrt( grav * m / drag).
        //print "maxthrust = " + thrust. // good
        print "v_term_asl  =  "+vterm_asl.
        wait 1.
        set t0 to t1.
        set v0 to v1.
        set m0 to m.
        set vel0 to vel.
        set pressr0 to pressr.
    }
    //runOncePath("0:/src/lib_plot.ks").
    //plot(list(times,drags1),list(0,t0-t00,0,9.8*10/200^2),"#",true,0,1, 5,0.001,true,true).
    lock throttle to 0.
    //if(true) return.
    wait 1.
    stage.
    wait 1.
    lock throttle to 1.
    local m_2 is ship:mass.
    set t0 to time:seconds.
    set v0 to ship:velocity:orbit.
    set vel0 to ship:velocity:surface.
    set pressr0 to ship:body:atm:altitudePressure(ship:altitude).
    wait 1.
    local drags2 is list().
    until drags2:length > 20 {
        local t1 is time:seconds.
        local v1 is ship:velocity:orbit.
        local vel is ship:velocity:surface.
        local m is ship:mass.
        local thrust is ship:availableThrust.
        local thrust_dir is ship:facing:forevector.
        local pressr is ship:body:atm:altitudePressure(ship:altitude).
        local grav is G_of(ship).
        local dragvec is (m+m0)/2*(v1-v0)/(t1-t0) + ship:up:forevector * grav * m - thrust*thrust_dir.
        local drag is dragvec:mag  * 2/ (vel:sqrmagnitude() + vel0:sqrmagnitude())  * 2/ (pressr+pressr0).
        drags2:add(drag).
        local vterm_asl is sqrt( grav * m / drag).
        print "v_term_asl  =  "+vterm_asl.
        wait 1.
        set t0 to t1.
        set v0 to v1.
        set m0 to m.
        set vel0 to vel.
        set pressr0 to pressr.
    }
    local pm is char(241). // ascii 241 // unicode 193
    local d1 is mu_sd(drags1).
    local d2 is mu_sd(drags2).
    print "mass_1 = " + m_1.
    print "drags1 = " + d1[0] + pm + d1[1].
    print "mass_2 = " + m_2.
    print "drags2 = " + d2[0] + pm + d2[1].

}
function getCurve{
    parameter extra_dv1, twr2.
    local a is "None".
    local b is "None".
    local i1a is 0.
    local i1b is 0.
    local i2a is 0.
    local i2b is 0.
    from {local i1 is 0.} until i1>= lib_launch_dv1s:length() step {set i1 to i1+1.} do {
        if lib_launch_dv1s[i1] > extra_dv1 {
            set i1b to i1.
            if(i1>0) {
                set i1a to i1-1.
                set a to (extra_dv1-lib_launch_dv1s[i1-1])/(lib_launch_dv1s[i1]-lib_launch_dv1s[i1-1]).
                break.
            }else {
                set a to 0.
                set i1a to 0.
                break.
            }
        }else if i1 = lib_launch_dv1s:length()-1 {
            print "overpowered extra_dv1".
            set a to 0.
            set i1a to i1.
            set i1b to i1.
            break.
        }
    }
    from {local i1 is 0.} until i1>= lib_launch_twr2s:length() step {set i1 to i1+1.} do {
        if lib_launch_twr2s[i1] > twr2 {
            set i2b to i1.
            if(i1>0) {
                set i2a to i1-1.
                set b to (twr2-lib_launch_twr2s[i1-1])/(lib_launch_twr2s[i1]-lib_launch_twr2s[i1-1]).
                break.
            }else {
                set b to 0.
                set i2b to 0.
                break.
            }
        }else if i1 = lib_launch_twr2s:length()-1 {
            print "overpowered TWR2".
            set b to 0.
            set i2a to i1.
            set i2b to i1.
            break.
        }
    }
    local aa is lib_launch_lob_data[i1a][i2a].
    local ab is lib_launch_lob_data[i1a][i2b].
    local ba is lib_launch_lob_data[i1b][i2a].
    local bb is lib_launch_lob_data[i1b][i2b].
    
    if(debug){
        print "curves for dv1 = "+ extra_dv1 + ";  TWR2 = "+ twr2 + ";".
        print aa.
        print ab.
        print ba.
        print bb.
        print i1a + ","+ i1b + "," + i2a + "," + i2b + ";".
        //breakpoint("press to continue").
    }

    local ax is "".
    local bx is "".
    local xx is "None".
    local bad is 0.
    if (aa="None") {set ax to ab. set bad to bad+1. if(ab ="None") {set bad to bad+1.}} else if(ab ="None") {set bad to bad+1. set ax to aa.}
    else {
        set ax to list(0,0,0,0,0,0).
        from {local i is 0.} until i>= 6 step {set i to i+1.} do {
            set ax[i] to aa[i] * (1-a) + ab[i] * a.
        }
    }
    if (ba="None") {set bx to bb. set bad to bad+1. if(bb ="None") {set bad to bad+1.}} else if(bb ="None") {set bad to bad+1. set ax to ba.}
    else {
        set bx to list(0,0,0,0,0,0).
        from {local i is 0.} until i>= 6 step {set i to i+1.} do {
            set bx[i] to ba[i] * (1-a) + bb[i] * a.
        }
    }
    if (ax="None") {set xx to bx.} else if(bx ="None") {set xx to ax.}
    else {
        set xx to list(0,0,0,0,0,0).
        from {local i is 0.} until i>= 6 step {set i to i+1.} do {
            set xx[i] to ax[i] * (1-b) + bx[i] * b.
        }
    }
    if(bad >=2){
        print "ERROR: rocket thrust / stage 1 deltaV too week ( badness " + bad + " / " + 4 +");".
        print "FIXES: increase thrust of second stage and/or increase delta-V of first stage;".
        return "None".
    }else if (bad=1) {
        print "Warning: rocket may be underpowered ( badness " + bad + " / " + 4 +");".
    }
    return xx.
    
}
local function getAngleOnCurveStage1{
    parameter staging.
    parameter curve.
    parameter deltav1.
    local dvr is staging:first:vsp * ln(ship:mass/staging:first:drymass).
    local exprfrac is (ship:mass/staging:first:drymass) ^ (-staging:first:vsp / lib_launch_typicals[1]).
    local tfov is (1-exp(-deltav1/ lib_launch_typicals[1])).
    local tcurrof is (1-exp(-(deltav1-dvr)/ lib_launch_typicals[1])).
    //local a is (1-exprfrac*(1-tfov)) / tfov .
    local a is tcurrof / tfov .
    print "  a = " + a + ";     " at (0,0).
    print "  dvr = " + dvr + ";     " at (0,1).
    print "  a_~ = " + (1-(ship:mass-staging:first:drymass)/(staging:first:wetmass-staging:first:drymass)) + ";     " at (0,2).
    //print "  exprfrac = " + exprfrac + ";     " at (0,2).
    return (1-a)*curve[0] + a*curve[1] + a*(1-a)*curve[3].
}
local function getAngleOnCurveStage2{
    parameter staging.
    parameter curve.
    parameter deltaV1.
    local dvend is lib_launch_typicals[3] - deltaV1 - curve[5].
    local massEnd is staging:second:wetmass * exp(-dvend/staging:second:vsp).
    //set dv to min(dvend,dv).
    local deltav2 is lib_launch_typicals[3] - deltaV1.
    local burnrat is min(staging:second:wetmass/ship:mass,exp(dvend/staging:second:vsp)).
    local onemint is (burnrat) ^ (-staging:second:vsp / lib_launch_typicals[2]).
    local b is (1-onemint)/(1-exp(-deltav2/ lib_launch_typicals[2])).
    print "  massratio = " + burnrat + ";     " at (0,1).
    //print "  expfact = " + staging:second:vsp / lib_launch_typicals[2] + ";     " at (0,2).
    print "  b= " + b + ";     " at (0,0).
    print "  b_~ = " + (1-(ship:mass-massEnd)/(staging:second:wetmass-massEnd)) + ";     " at (0,2).
    return (1-b)*curve[1] + b*curve[2] + b*(1-b)*curve[4].
}
function launch{
    //TODO the very idea seems broken
    parameter vtermnot is 400.
    parameter targetApoapsis is 75000.
    //set vtermnot to 200.//just pretend
    //TODO ship:stagenum does not exist (yet?)
    //TODO ship:drymass does not account for staging at all.
    local staging is anylizeStages().
    
    //local staging is lexicon().
    // main stage DV, main stage twr, main stage atm loss, second stage twr, drag coeficcient, weather first stage is solid / liquid
    

    //two charactaristic altitudes: altitude to reach v_term and altidude where dv_term / dt > TWR * g
    local altnot is ship:altitude.
    lock throttle to 1.
    stage.
    //set staging:thrust1 to ship:maxThrust. //temporary
    //set staging:tsp1 to ship:mass *265*9.8 / staging:thrust1.// swivel asl
    //set staging:twr2 to 0.7. //temporary
    //set staging:vsp2 to 345.0*9.8. //temporary
    //set staging:vsp1 to 315.0*9.8. //temporary
    wait 1.
    local vterm_asl is vtermnot. //230.0. //TODO must be manually input (otherwize must have sensors onboard)


    //THEOREM: the optimal angle over time function is continuous even under stage switching
        //PROOF: imagine small bits of delta-V (vectors) imediately before and after staging (or any other point). If the angle pointing between these two
        //points does not vanish, then we can increase the total delta-V (magnitude) without changing the direction by making them the same angle; []
    
    //IDEA: start by patching between a const-TWR (use initial TWR) no-drag 
    //then , patch at hterm into a const-velocity const with TWR sampled at t_term, hterm
    //determine ideal angle at hturn (~30 to 45)
    //then plan ahead (assuming weak ATM) to angle stage so that orbit is reached (remember continuity theorem)
    //if TWR of stage 2 is low (~0.3; lower for higher ISP), allow ascent to go ABOVE target orbit if desirable
    local fudge is 2.00.
    local grav is G_of(ship).
    local TWR is staging:first:startAcc / G_of(ship).//this is unusual, stage 2 TWR is defined as frac of const grav kerb
    local h_efold is 5700.//TODO press ~= p0 * exp(-h /h_e) // for kerbin
    local vturn is sqrt(2 * fudge* 9.8 * h_efold). // ~400m/s ~ typical vterm
    local hvturn is vturn^2 /G_of(ship) / (TWR-1)/2.0 - vturn^3 /G_of(ship)^2 / (TWR-1)^2/3.0/staging:first:tsp.
    local tturnapprox is vturn / grav.
    

    local hterm is vterm_asl^2 / G_of(ship) / (TWR-1)/2.0 - vterm_asl.//TODO be more carefull, account for very-low TWR effects (that may never reach vterm)
    local alt_turn is ln(fudge * grav * h_efold / (vterm_asl^2)) *h_efold. //has a fudge factor
    
    local hturn is alt_turn-altnot. //aim to be at ~45deg by this time
    local h is max(hturn,hvturn).
    set h to min(h,10000).
    local tterm is sqrt(2*hterm/grav/(TWR-1)).
    local alt_1atm is 0.0.
    print hturn. // TODO this is negative: -2956; v_terminal typical sim to 400 sim to v_char_atm
    local hto is max(hturn,hterm).
    local TWREFF is TWR /(1-0.5 *tturnapprox / 270.0 ).
    print "TWREFF = " + TWREFF.
    local flag1 is true.
    if (hterm > hturn){
            until ship:altitude > h {
            //there used to be a missing half
            //twr changing and h-changing should cancel out
            local asm is (45.0) * ((ship:altitude-altnot)/h)^(1/2/(TWREFF-1)) .
            lock steering to heading(90,90-asm).
            print asm+ "           " at (3,3).
            if(ship:maxthrust <=0) and flag1 {
                print "Warning: first stage too weak; add more delta-V;".
                set flag1 to false.
            }
            wait 1.
        }
    }else {
        //this case will never happen
        until ship:altitude > h {
            local v0 is vterm_asl.
            local asm_high is exp(logasm_f + g/v0^2/a * (exp(-a * (alt_turn-alt_1atm))-exp(-a * (ship:altitude-alt_1atm)))).

            local asm is (45.0) * ((ship:altitude-altnot)/h)^(1/(TWR-1)) .//multiplier
            lock steering to heading(90,90-asm).
            print asm + "           " at (3,3).
            wait 1.

        }
    }
    local velnot is ship:velocity:surface:mag.
    local remainingdeltaV1 is staging:first:vsp * ln(ship:mass/staging:first:drymass).
    local adjusteddeltaV1 is remainingdeltaV1 + velnot - vturn.
    print "adjusted DV1 = " + adjusteddeltaV1.
    print "acc2 = " + staging:second:startAcc.
    print "TWR2 = " + staging:second:startAcc/constant:g0.
    local curve is getCurve(adjusteddeltaV1,staging:second:startAcc/constant:g0).
    if(curve = "None") {
        print "launch ended due to an error".
        return.
    }
    print "curve is: "+ curve.
    lock shouldStage to (ship:maxthrust <=0) or (ship:mass < staging:first:drymass).
    until shouldStage {
        //follow the curve
        local angle is getAngleOnCurveStage1(staging,curve,adjusteddeltaV1).//multiplier
        lock steering to heading(90,angle).
        print angle + "           " at (3,3).
    }
    stage.
    wait 0.5.
    until ship:maxthrust>0 {
        stage.
        wait 0.5.
    }
    local stage3 is false.
    until (ship:orbit:apoapsis >= targetApoapsis and ship:velocity:orbit:mag > 0.95 * get_v_c(ship:body,ship:body:radius+ship:altitude)) 
    { //TODO refine end condition using U-factor and burn time
        //follow the curve
        local angle is getAngleOnCurveStage2(staging,curve,adjusteddeltaV1).//multiplier
        lock steering to heading(90,angle).
        print angle + "           " at (3,3).
        if ship:maxthrust<=0{
            set stage3 to true.
            break.
        }
    }
    local anglefinal is 10.
    if stage3{
        until ship:maxthrust>0 {
            stage.
            wait 0.5.
        }
        local geff is G_of() * (1-ship:velocity:orbit:sqrmagnitude / get_v_c()^2).
        local twr3eff is ship:maxThrust / ship:mass / max(geff,1.0).
        print twr3eff.

        set anglefinal to arcsin(1/max(twr3eff,1.41)).
        set anglefinal to max(anglefinal,10).
    }else {
        set anglefinal to curve[2].
        set anglefinal to max(anglefinal,10).
            
    }
    lock steering to heading(90,anglefinal).
    wait until ship:orbit:apoapsis >= targetApoapsis.
    lock throttle to 0.
    lock steering to prograde.
    print "second stage remaining deltav = " + staging:second:vsp * ln(ship:mass/staging:second:drymass).
    print "done, for now".
    


}
local function whatExists{
    //TODO copy from brekus.
    //may need to copy from brekus:  https://pastebin.com/6ga862mt    from   https://www.reddit.com/r/Kos/comments/3fq4is/a_script_to_get_information_on_stages_in_advance/
    //print ship:stagenum. //does not exist
    print stage. //should be an object
    print stage:number. //

    //print stage:deltav. //does not exist (everything else is fine)
    list engines in engs.
    for eng in engs{
        //last stage is 0; -1 means unstaged
        //counts 0-1-2-...; on lauchpad is 1 above first stagenumlock throttle to 0.
    }
}
//simple_launch().
//record_Vterm().

if(debug){
launch(430).
}
global launching is lexicon().
set launching:launch to launch@.



//whatExists().
//anylizeStages().

//currently reqires 2 stages, the first must be able to get well above about 10000m;
//TODO create subfolder: ./generators, and ./generator; treat each sub-sub folder as a namespace; 
  //use build task to run a .bat in ${activeFile}../build.bat; this way AutoKSP only needs one build path
//TODO support for faring seperation
///TODO support for SRBS and seperatrons
    //(currently, all engines must be activaded and then deactivated for staging analysis, but SRBs cannot be deactivated)
