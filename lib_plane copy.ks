parameter debug is true.
local newline is char(10).
local AERO_DIR is "0:/dat/ship/aero/".
local AERO_EXT is ".dat".
local rocket_pitch_kp is steeringManager:pitchpid:kp.
local rocket_pitch_ki is steeringManager:pitchpid:ki.
local rocket_pitch_kd is steeringManager:pitchpid:kd.
//see:
//https://www.reddit.com/r/Kos/comments/gemvyh/cooked_controls_sometimes_fail_at_low_speeds_for/

//I never was able to really make the cooked steering work well on an airplane, so I ended up rolling my own attitude controller. I basically copied from mechjeb.
//https://github.com/chrisb128/kOS/blob/master/attitude.ks
//[link does not currently work]

//Cooked control does not try to address all three axis at the same time.
// I think it does pitch then yaw then roll. So if your vector diverges too much,
// it will abandon roll until things are back in order. I keep track of the roll error in my script 
//and fix that when it diverges too much. So if the roll is too far out,
// I set the desired yaw and pitch to what it is currently until the roll vector is right.
// It also helps the script recover from unusual attitudes because it will level the wings first before recovering.
local function PlaneSteering{
    //default pitchpid is kp: 1, ki: 0.1, kd: 0
    //maybe use pitchST (settling time) instead (Default 2 (seconds))
    set steeringManager:pitchpid:kp to 10.
    
    set steeringManager:pitchpid:ki to 1.
} local function RocketSteering{
    set steeringManager:pitchpid:kp to rocket_pitch_kp.
    set steeringManager:pitchpid:ki to rocket_pitch_ki.
    set steeringManager:pitchpid:kd to rocket_pitch_kd.
}
local function diag {
    parameter str.
    if debug{print str.}
}
local function getFileName{
    parameter theshipname is ship:name.
    local s is theshipname:replace(" ","_").//kos uses unicode.
    return s+AERO_EXT.
}
local function getAeroDatDir {
    //local newDir is path():combine(AERO_DIR).
    local newDir is path(AERO_DIR).
    if not exists(newDir){createDir(newDir).}
    return newDir.
    
}
local function getFirstEngine{
    list engines in engs.
    return engs[0].
}
local function getThrustcurveCfg{//dont use, DNW
    parameter eng is getFirstEngine().
    local mod_eng is eng:getModule("ModuleEnginesFX").
    print mod_eng:fields.
    //submodules velCurve, atmCurve
    //entries: mach#/atms thrustmult backtangent fronttangent
    local velCurve is mod_eng:getField("velCurve").
    local atmCurve is mod_eng:getField("atmCurve").
    print velCurve.//I think its a list of lists
    //TODO module has no atm / vel curves; add consts instead


}
local function getCubic {
    parameter var.//atm or mach
    parameter lst1.
    parameter lst2.
    local t is (var-lst1[0])/(lst2[0]-lst1[0]).
    //diag("t: "+t).
    local d1 is (lst1[3])*(lst2[0]-lst1[0]).
    local d2 is (lst2[2])*(lst2[0]-lst1[0]).
    //diag (list(lst1[1],d1,d2,lst2[1])).
    //diag("mult:"+(lst1[1]*(1-t)^3
           // +(d1+3*lst1[1])*t*(1-t)^2
            //-(d2-3*lst2[1])*t^2*(1-t)
           // +lst2[1]*t^3)).
    return lst1[1]*(1-t)^3
            +(d1+3*lst1[1])*t*(1-t)^2
            -(d2-3*lst2[1])*t^2*(1-t)
            +lst2[1]*t^3.//looks good
}
local velcurve_rapier is list(
    list( 0 ,1, 0, 0.08333334),
			list(0.2 , 0.98, 0.42074, 0.42074),
			list(0.7 , 1.8, 2.290406, 2.290406),
			list(1.4 , 4.00, 3.887193, 3.887193),
			list(3.75,  8.5, 0, 0),
			list(4.5 , 7.3, -2.831749, -2.831749),
			list(5.5 , 3, -5.260566, -5.260566),
			list(6, 0 , -0.02420209, 0)
).
local atmCurve_rapier is list(
			// higher thrust at altitude than even TRJ
			list( 0, 0, 0, 0),
			list( 0.018, 0.09, 7.914787, 7.914787),
			list( 0.08, 0.3, 1.051923 ,1.051923),
			list( 0.35, 0.5, 0.3927226, 0.3927226),
			list( 1, 1, 1.055097 ,0)
).
local velCurve_wiplash is list(
			list(0 ,1, 0, 0),
			list(0.2, 0.98, 0, 0),
			list(0.72, 1.716, 2.433527, 2.433527),
			list(1.36, 3.2, 1.986082, 1.986082),
			list(2.15, 4.9 ,1.452677 ,1.452677),
			list(3, 5.8, 0.0005786046, 0.0005786046),
			list(4.5, 3, -4.279616, -4.279616),
			list(5.5, 0, -0.02420209, 0)
            ).
local atmCurve_wiplash is list(
			// definite 'kink' to the curve at high altitude, compared to flatter BJE curve
			list(0, 0, 0 ,0),
			list(0.045, 0.166, 4.304647, 4.304647),
			list(0.16, 0.5, 0.5779132, 0.5779132),
			list(0.5, 0.6, 0.4809403, 0.4809403),
			list(1, 1, 1.013946, 0)
            ).
//velCurve
//		{
//			key = 0 1 0 0
//			key = 0.2 0.98 0 0
//			key = 0.72 1.716 2.433527 2.433527
//			key = 1.36 3.2 1.986082 1.986082
//			key = 2.15 4.9 1.452677 1.452677
//			key = 3 5.8 0.0005786046 0.0005786046
//			key = 4.5 3 -4.279616 -4.279616
//			key = 5.5 0 -0.02420209 0
//		}
local velMap is lexicon(
    "RAPIER",velcurve_rapier,
    "turboFanEngine",velCurve_wiplash
).
local atmMap is lexicon(
    "RAPIER",atmcurve_rapier,
    "turboFanEngine",atmCurve_wiplash
).
//other engines not yet supported
//but heres there NAMES
//Rapier -> RAPIER
//Whiplash -> turboFanEngine  //I know, very confusing
//Wheesly -> JetEngine
//Panther -> turboJet
//Juno -> miniJetEngine
//Goliath -> turboFanSize2
local function getThrustAt{
    parameter eng.
    parameter mach.
    parameter atms.
    local atmCurve is atmMap[eng:name].
    local velcurve is velMap[eng:name].
    //print atmcurve.
    local machmult is -1.
    if mach<velcurve[0][0]{
        set machmult to velcurve[0][1]+(mach-velcurve[0][0])*velcurve[0][2].
    }else from {local i is 0.}until i>=velcurve:length step {set i to i+1.} do{
        if i-1=velcurve:length {
            set machmult to velcurve[velcurve:length-1][1]+(mach-velcurve[velcurve:length-1][0])*velcurve[velcurve:length-1][3].
            break.
        }
        else if mach>=velcurve[i][0] and (mach<=velcurve[i+1][0]){
            set machmult to getCubic(mach,velcurve[i],velcurve[i+1]).
            break.
        }
    }local atmmult is -1.
    if atms<atmcurve[0][0]{
        set atmmult to atmcurve[0][1]+(atms-atmcurve[0][0])*atmcurve[0][2].
    }else from {local i is 0.}until i>=atmcurve:length step {set i to i+1.} do{
        if i-1=atmcurve:length {
            set atmmult to atmcurve[atmcurve:length-1][1]+(atms-atmcurve[atmcurve:length-1][0])*atmcurve[atmcurve:length-1][3].
            break.
        }
        else if atms>=atmcurve[i][0] and (atms<=atmcurve[i+1][0]){
            set atmmult to getCubic(atms,atmcurve[i],atmcurve[i+1]).
            break.
        }
    }
    //return eng:MAXTHRUSTAT(1)*atmmult*machmult.//engine must be active, no limiter
    return eng:POSSIBLETHRUSTAT(1)*atmmult*machmult.//accounts for thrust limiter
}
local function p_getCurrThrust {
    local th is V(0,0,0).
    list engines in engs.
    for eng in engs{
        set th to th+eng:thrust*eng:FACING:FOREVECTOR.
    }return th.
}
local function p_aeroforce {
    local f is ship:sensors:acc*ship:mass-ship:mass*ship:sensors:grav-p_getCurrThrust().
    
    return f.
}
local function vec_radialout_surface {
    return (ship:up:forevector-(ship:up:forevector*ship:velocity:surface)/ship:velocity:surface:sqrmagnitude*ship:velocity:surface):normalized.
}
local aoa is "none".
local function p_lock_aoa {
    parameter aoa_arg.//not an actual lock; is in degrees.
    set aoa to aoa_arg.
    if aoa="none"{
        unlock steering.
    }else{
        local v_h is ship:velocity:surface.
        lock steering to lookDirUp(ship:velocity:surface:normalized*cos(aoa)+vec_radialout_surface()*sin(aoa),up:forevector).

    }
}
local function p_get_aoa{
    local sgn is vectorExclude(ship:velocity:surface,ship:facing:vector)*ship:up:forevector.
    set sgn to choose 1 if sgn=0 else sgn/abs(sgn).
    return Vang(ship:facing:vector,ship:velocity:surface)*sgn.
}
local aero is "none".
local function recordAero{
    parameter retro is false.
    parameter aoamax is 5.
    parameter d_aoa is 0.3.
    local aoa2 is choose 180 if retro else 0.
    local paoa is -d_aoa.
    local dat is list().//list of rows
    set steeringManager:pitchpid:kp to steeringManager:pitchpid:kp*10.//proportional gain factor
    until false {
        p_lock_aoa(aoa2).//not pulling up fast enough
        wait 1.
        local caoa is p_get_aoa().
        if retro and caoa<0 {set caoa to caoa+360.}
        diag("caoa: "+caoa).
        local f is p_aeroforce().
        diag ("f: "+f).
        local v is ship:velocity:surface:mag.
        local sng is vectorExclude(ship:velocity:surface,f)*ship:up:forevector.
        local atm is ship:sensors:pres/Constant:atmtokpa.//pres is in kpa
        //but sealevelpressure is in atm, WTF!
        //1 atm =101.325 KPa. same as real life; use the Constant:...
        if atm=0 {
            print "no atmosphere".
            return false.
        } if v=0 {
            print "no velocity".
            return false.
        }
        set sng to choose 1 if sng=0 else sng/abs(sng).
        diag ("atm: "+atm).
        diag ("v: "+v).
        dat:add(list(p_get_aoa(),
                vectorExclude(ship:velocity:surface,f):mag*sng/atm/v^2,//lift
                -(f*ship:velocity:surface:normalized)/atm/v^2)).//drag (both +);relative to velocity
        diag(dat[dat:length-1]).
        if abs(caoa-paoa)<d_aoa*0.1{
            print "can't turn any higher".
            break.
        }
        if choose (caoa<(180-aoamax)) if retro else (caoa>aoamax) {
            break.
        }
        set paoa to caoa.
        set aoa2 to aoa2+d_aoa*(choose -1 if retro else 1).
        

    }
    set steeringManager:pitchpid:kp to steeringManager:pitchpid:kp/10.
    set aero to dat:copy.
    print dat.
    local fpath is getAeroDatDir():combine(getFileName(ship:name)).
    print "saving to:  "+fpath.
    if not exists(fpath) {create(fpath).}
    local fdat is open(fpath).
    fdat:clear().
    for row in dat {
        //log (row[0]+" "+row[1]+" "+row[2]) to fdat.
         if not fdat:writeLn((row[0]+" "+row[1]+" "+row[2])) {
             print "out of space".
             return false.
         }
    }
    return true.
    //dont need to close
    //maybe todo lib_plot.




}
local function loadAero {
    parameter fpath is getAeroDatDir():combine(getFileName(ship:name)).
    print "loading aero data from: "+fpath.
    if not exists(fpath) {
        print "file not found.".
        return false.
    }
    set aero to list().
    local dat is open(fpath):readAll().
    //print dat:string():split(newline).
    for line in (dat:string():split(newline)){
        local row is line:split(" ").
        if row:length=1 and row[0]="" {break.}
        //print row:typename.//is ListValue'1 instead of List
        //https://github.com/KSP-KOS/KOS/issues/2590
        //print row.
        local nrow is list().
        from {set a to 0.}until a>=row:length step {set a to a+1.} do {
            //print row[a].//string
            nrow:add(row[a]:tonumber()).
            //local asdf is "1234":tonumber().
        }
        aero:add(nrow).
    }
    //print aero.
    return true.

}
loadAero().//attempt on lib load

local function getLiftAt{
    parameter aoatk.
    parameter v.
    parameter atms.
    parameter index is 1.//end user do not use
    parameter indexnot is 0.//end user do not use
    //must be monatomic increasing on indexnot
    if aero = "none"{
        return 0.
    }
    local di is ceiling(aero:length()/4).
    local i is ceiling(aero:length()/2)-1.
    local pi is 0.
    local paoa is -90.
    local sgn is 1.
    until false {
        local taoa is aero[i][indexnot].
        diag("taoa"+taoa).
        diag("di"+di).
        diag("i"+i).
        if taoa=aoatk {return aero[i][index]*v^2*atms.}
        if ((taoa-aoatk)*(paoa-aoatk)<0) and (di=1) {
            diag("av").
            local tw is abs((paoa-aoatk)/(paoa-taoa)).
            local pw is abs((taoa-aoatk)/(paoa-taoa)).
            return (tw*aero[i][index]+pw*aero[pi][index])*v^2*atms.
        }
        set di to ceiling(di/2).
        set sgn to (aoatk-taoa)/abs(taoa-aoatk).
        if (i+sgn*di=pi) {//would be infinite loop
            diag("loop").
            return aero[i][index]*v^2*atms.
        }
        set pi to i.
        set i to i+sgn*di.
        set paoa to taoa.
        if i<0 {
            if di=1 {return aero[0][index]*v^2*atms.}
            else {
                set di to 1. set i to 0.
            }}
        if (i>aero:length()-1) {
            if di=1 {return aero[aero:length-1][index]*v^2*atms.}
            else {
                set di to 1. set i to aero:length-1.
            }}

    }
}
local function getDragAt{
    parameter aoatk.
    parameter v.
    parameter atms.
   return getLiftAt(aoatk,v,atms,2).
}
local aoa_lift_1g is "TODO".//record some params in advance
local function getAsymuthAt{
    parameter v.
    parameter atms.
    //approx thrust is in -V dir.

}
local asymuth is "none".//velocity pitch
local do_asymuth is false.
local t_asy is -1.
//TODO get jet engine thrust at velocity. 
local function p_lock_asymuth_old {
    parameter asy.
    set asymuth to asy.
    if asy="none"{
        p_lock_aoa("none").
        set do_asymuth to false.
    }
    else {
        if aoa="none" {
            //starting aoa
            set aoa to 1.
        }
        set do_asymuth to true.
        set t_asy to time:seconds.
        local prevang is vang(ship:up:forevector,ship:velocity:surface).
        when time:seconds>t_asy+1 then {//backgroud thread execs each second
            
            set t_asy to time:seconds.
            if(vang(ship:up:forevector,ship:velocity:surface)+asy<90){
                p_lock_aoa(aoa-1).
            }else if(vang(ship:up:forevector,ship:velocity:surface)+asy>90){
                p_lock_aoa(aoa+1).
            }
            p_lock_aoa(aoa-(prevang-vang(ship:up:forevector,ship:velocity:surface))/2).
            set prevang to vang(ship:up:forevector,ship:velocity:surface).
            print "target aoa: "+aoa.
            return do_asymuth.//works OK but not good
        }.
    }
}
local function p_lock_asymuth_simple {
    ///actually locks pitch
    parameter asy is 3.//good cruising asymuth
    local restart is asymuth="none".
    set asymuth to asy.
    //maybe add a small bonus angle
    //TODO smooth turn
    //lock steering to vectorExclude(ship:up:forevector*cos(asymuth)-ship:velocity:surface:normalized*sin(asymuth),ship:velocity:surface).
    //lock steering to heading(90,asymuth,0).//TODO remove heading
    unlock steering.
    //direct
    local RD is 1/20.
    local YD is 1/10.
    local PD is 1/10.
    local bank is 0.5.
    //integral
    local RI is 1/20/5.
    local YI is 1/10/5.
    local PI is 1/10/5.

    local RIntv is 0.
    local YIntv is 0.
    local PIntv is 0.
    local tprev is time:seconds.
    local bankmax is 45.//TODO
    if restart when true then {
        //other function already does this
        local t is time:seconds.
        local dt is t-tprev.
        set RIntv to RIntv+dt*(ship:direction:roll).
        set YIntv to YIntv+dt*0.
        set PIntv to PIntv+dt*(ship:direction:pitch-asymuth).
        //numbers from -1 to 1
        //https://ksp-kos.github.io/KOS/commands/flight/raw.html
        set ship:control:pitch to PD*(asymuth-ship:direction:pitch) -PI*PIntv .
        set ship:control:yaw to -YD*(0)-YI*YIntv.
        set ship:control:yaw to 0.
        set ship:control:roll to -RD*ship:direction:roll-RI*RIntv.
        set tprev to t.
        if not (asymuth = "none"){
            return true.
        }
        return false.
    }.
}
local function p_lock_asymuth {
    //TODOUNSTABLE
    parameter asy.
    if false{
        p_lock_asymuth_simple(asy).
        return.
    }
    if asy="none"{
        set do_asymuth to false.
        wait 0.//let thread end.
        set asymuth to asy.
        p_lock_aoa("none").
    }
    else {
        local loop is (asymuth="none") or true.
        set asymuth to asy.
        //for steering, torqe = DD. for asymuth, torqe = DDD
        set aoa to "none".//use seperate lock
        set do_asymuth to true.
        local lock input to 90-vang(ship:velocity:surface,up:forevector).//current asymuth
        local pid is pidLoop(0.1,0.01,0.001   ,-1,1).//works for testplane 1
        local sgn_yaw is 1.//is negative for velocity yaw or for heading>180 deg
        local yawpid is pidLoop(sgn_yaw*0.1,sgn_yaw*0.1,sgn_yaw*0.1   ,-1,1). set yawpid:setpoint to 90.
        //relative to velocity


        local rollpid is pidLoop(-0.01,-0.02,-0.03  ,-1,1). set rollpid:setpoint to 0.
        //beware the pd term responds to a velocity so is chaotic.
        set pid:setpoint to asymuth.
        //SET currentYaw TO ANGLEAXIS(SHIP:FACING:YAW, SHIP:UP) * NORTH. would be heading
        //could use aerodatao to target pitch instead
        //local prevang is vang(ship:up:forevector,ship:velocity:surface).
        local pyaw is 0.
        if loop when true then {//backgroud thread execs each frame
            if not do_asymuth {
                set ship:control:neutralize to true.//disable raw controls
                unlock input.
            } else {
                set ship:control:pitch to pid:update(time:seconds,input).
                set ship:control:roll to rollpid:update(time:seconds,90 - vectorangle(vectorExclude(ship:velocity:surface,ship:up:forevector),ship:facing:starvector)).
                
                //set ship:control:yaw to yawpid:update(time:seconds,90 - vectorangle(ship:velocity:surface,ship:facing:starvector)).
                set ship:control:yaw to yawpid:update(time:seconds,(vectorangle(ship:north:forevector,ship:facing:forevector))).
                local dyaw to (vectorangle(ship:north:forevector,ship:facing:forevector)-pyaw).
                set pyaw to vectorangle(ship:north:forevector,ship:facing:forevector).
                set theRoll to -sgn_yaw*(yawpid:setpoint-vectorangle(ship:north:forevector,ship:facing:forevector)-dyaw*10).
                //set rollpid:setpoint to MAX(MIN(theRoll*1,15),-15).//experimental, works sometimes
                //TODO cross terms: example, reinforce roll to fix yaw
            }
            return do_asymuth.//works OK but not good
        }.
    }
}
if debug{
    //clearscreen.
    clearVecDraws().
    if false{
        local arrowsize is 0.2.
        local arrowwidth is 1.0.
        clearVecDraws().
        vecdraw(V(0,0,0),{return ship:sensors:grav*ship:mass.},green,"grav",arrowsize,true,arrowwidth).
        vecdraw(V(0,0,0),{return p_getCurrThrust().},red,"thrust",arrowsize,true,arrowwidth).
        vecdraw(V(0,0,0),{return p_aeroforce().},blue,"aero",arrowsize,true,arrowwidth).
        //functions work OK (no gimbals)
        p_lock_aoa(5).
        until true{
            print "Thrust: "+p_getCurrThrust():mag at (3,3).
        }
        //TODO method to recorde a .dat file for thrust profile and for drag/lift from aoa.
    }
    if true {
        //works enough
        clearscreen.
        set startAlt to ship:altitude.
        PlaneSteering().
        lock throttle to 1.
        stage.
        p_lock_asymuth(5).
        when (altitude>startAlt+50) then {set gear to false. return false.}
        until ship:velocity:surface:mag>200 {
            //print "Aoa: "+p_getCurrThrust():mag at (3,3).
            print "Asymuth: "+(90-vang(ship:velocity:surface,up:forevector)) at (3,3).
            print "roll: "+(90 - vectorangle(vectorExclude(ship:velocity:surface,ship:up:forevector),ship:facing:starvector)) at (3,5).//up is 270?
            //print "yaw: "+ship:facing:yaw at (3,7).
            print "yaw: "+(90 - vectorangle(ship:velocity:surface,ship:facing:starvector)) at (3,7).
            print "heading: "+(vectorangle(ship:north:forevector,ship:facing:forevector)) at (3,9).//below
            print "PHASE 1" at (3,11).
            wait 0.3.
        }.
        p_lock_asymuth(10).
        wait 2.
        until altitude>10000 {
            //print "Aoa: "+p_getCurrThrust():mag at (3,3).
            print "Asymuth: "+(90-vang(ship:velocity:surface,up:forevector)) at (3,3).
            print "roll: "+(90 - vectorangle(vectorExclude(ship:velocity:surface,ship:up:forevector),ship:facing:starvector)) at (3,5).//up is 270?
            //print "yaw: "+ship:facing:yaw at (3,7).
            print "yaw: "+(90 - vectorangle(ship:velocity:surface,ship:facing:starvector)) at (3,7).
            print "heading: "+(vectorangle(ship:north:forevector,ship:facing:forevector)) at (3,9).//below
            print "PHASE 2" at (3,11).
            wait 0.3.
            local asym is ship:velocity:surface:mag/20-altitude/1000.
            p_lock_asymuth(Min(Max(10,asym),30)).
        }.
        p_lock_asymuth(15).
        until altitude>20000 {
            //print "Aoa: "+p_getCurrThrust():mag at (3,3).
            print "Asymuth: "+(90-vang(ship:velocity:surface,up:forevector)) at (3,3).
            print "roll: "+(90 - vectorangle(vectorExclude(ship:velocity:surface,ship:up:forevector),ship:facing:starvector)) at (3,5).//up is 270?
            //print "yaw: "+ship:facing:yaw at (3,7).
            print "yaw: "+(90 - vectorangle(ship:velocity:surface,ship:facing:starvector)) at (3,7).
            print "heading: "+(vectorangle(ship:north:forevector,ship:facing:forevector)) at (3,9).//below
            print "PHASE 3" at (3,11).
            wait 0.3.
        }.
        p_lock_asymuth("none").
        RocketSteering().
    }
    if false{//now works for rapier and whiplash
        global getJetThrust is getThrustAt@:bind(getFirstEngine()).
        print "mach".
        print getJetThrust(0,1).
        print getJetThrust(1,1).
        print getJetThrust(2,1).
        print getJetThrust(3,1).
        print getJetThrust(4,1).
        print getJetThrust(5,1).
        print "Atm:".
        print getJetThrust(0,1).
        print getJetThrust(0,0.5).
        print getJetThrust(0,0.25).
        print getJetThrust(0,0.125).
        print getJetThrust(0,0.0625).
        //delegate is killed when back in terminal
    }
    if false {//big success
        until false {
            print ("AOA: "+p_get_aoa()) at (2,2).
            wait 0.
        }
    } if false {
        recordAero().
    }
    if false {
        runOncePath("0:/src/lib_plot.ks").
        plot(aero,list(0,5,0,0.01),"^",true,0,1).
        plot(aero,list(0,5,0,0.01),"<",false,0,2).
    }if false {//big success
        print getDragAt(0,ship:velocity:surface:mag,ship:sensors:pres/constant:atmtokpa).wait 10.
        print getDragAt(1,ship:velocity:surface:mag,ship:sensors:pres/constant:atmtokpa).wait 10.
        print getDragAt(3,ship:velocity:surface:mag,ship:sensors:pres/constant:atmtokpa).wait 10.
        print getDragAt(5,ship:velocity:surface:mag,ship:sensors:pres/constant:atmtokpa).
    }
}
global plane_loadAero is loadAero@.
global plane_recordAero is recordAero@.
global plane_getBallisticDragK is {
    local p is 0.
    local pd is 0.
    for ln in aero {
        //print ln.
        if ln[0]<p {return pd.}
        set pd to ln[2].
        set p to ln[0].

    }
}.
