local debug is true.
function diag {
    parameter str.
    if debug{print str.}
}
function getFirstEngine{
    list engines in engs.
    return engs[0].
}
function getThrustcurveCfg{//dont use, DNW
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
function getCubic {
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
function getThrustAt{
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
function p_getCurrThrust {
    local th is V(0,0,0).
    list engines in engs.
    for eng in engs{
        set th to th+eng:thrust*eng:FACING:FOREVECTOR.
    }return th.
}
function p_aeroforce {
    local f is ship:sensors:acc*ship:mass-ship:mass*ship:sensors:grav-p_getCurrThrust().
    
    return f.
}
function vec_radialout_surface {
    return (ship:up:forevector-(ship:up:forevector*ship:velocity:surface)/ship:velocity:surface:sqrmagnitude*ship:velocity:surface):normalized.
}
local aoa is "none".
function p_lock_aoa {
    parameter aoa_arg.//not an actual lock; is in degrees.
    set aoa to aoa_arg.
    if aoa="none"{
        unlock steering.
    }else{
        local v_h is ship:velocity:surface.
        lock steering to lookDirUp(ship:velocity:surface:normalized*cos(aoa)+vec_radialout_surface()*sin(aoa),up:forevector).

    }
}
local asymuth is "none".//velocity pitch
local do_asymuth is false.
local t_asy is -1.
//TODO get jet engine thrust at velocity. 
function p_lock_asymuth {
    parameter asy.
    set asymuth to asy.
    if asy="none"{
        p_lock_aoa("none").
        set do_asymuth to false.
    }
    else {
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
if debug{
    clearscreen.
    clearVecDraws().
    if true{
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
    if false {
        //works enough
        p_lock_asymuth(5).
        wait until not do_asymuth.
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
}
