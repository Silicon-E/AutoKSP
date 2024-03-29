parameter debug is true.
//ctrl-K-0 to fold all, ctrl_K-J to unfold all (fold is colapse)
local dquote is char(34).
global manuver is lexicon().//pseudo singlton-class

//the lowest safe orbital height with a buffer zone; lowest that lib_manuver will plan to go
//old name: manuver_LowestSafeOrbitWithBuffer
set manuver:LowestSafeOrbitWithBuffer to lexicon(//https://forum.kerbalspaceprogram.com/index.php?/topic/31128-lowest-orbit/
    kerbin:name,80_000,
    mun:name,10_000,//terain feature at 3,335
    minmus:name,7_000,//terain at 5,725
    duna:name,46_000, //atm at 69_079
    ike:name,15_000, //terrain at 12,446
    Eve:name,110_000,//atm at 96,709
    Gilly:name,8_000,//terraiin 6,400
    Moho:name,9_000,//terrain 6,753
    dres:name,8_000,//terain 5,670
    eeloo:name,5_500,//terrain 3,869
    jool:name,160_000,//atm 138,200
    laythe:name,65_000,//atm 55,262
    vall:name,10_000,//terrain 7,976
    tylo:name,17_000,//terrain 12,695
    bop:name,24_000,//terrain 21,749
    pol:name,7_000//terrain 5,585
    ).//underscores can be freely added to scalars
local function getLowestSafeOrbit{
    parameter B.
    //old: return manuver_LowestSafeOrbitWithBuffer[B:name].
    return manuver:LowestSafeOrbitWithBuffer[B:name].
}
//maybe todo find compile directive to turn of parenticeless local function calls.
//math util
//v=v_c*U
//r=R_0*H
//note to self: you can get rid of stock ships by moving the contents of {KSP}/Ships elsewhere.
local function determinent{
    //maybe make global
    parameter v1.
    parameter v2.
    parameter v3.
    return vcrs(v1,v2)*v3.//v1 cross v2 dot v3;
}
local function modu {
    //positive branch modulus
    //mod(-0.1,1)=-0.1; not 0.9
    parameter a,b.
    local r is mod(a,b).
    if r<0 {set r to r+b.}.
    return r.
}
local function modsym {
    //symetric branch modulus
    //mod(-0.1,1)=-0.1; not 0.9
    parameter a,b.
    local r is mod(a,b).
    if r<0 {set r to r+b.}.
    if (r>b/2) {set r to r-b.}
    return r.
}
local function get_v_c {
    parameter B.
    parameter Rad.
    return sqrt(B:mu/Rad).
}
local function get_v_e {
    parameter B.
    parameter Rad.
    return get_v_c(B,Rad)*sqrt(2).
}
local function get_v_c_const{
    parameter B.
    return get_v_c(B,B:orbit:semimajoraxis).
}
local function orbradiusAt {
    parameter B.
    parameter tm.
    return (positionAt(B,tm)-positionAt(B:body,tm)):mag.
}
local function get_v_c_at{
    parameter B.
    parameter tm.
    return get_v_c(B,(positionAt(B,tm)-positionAt(B:body,tm)):mag).
}
local function U{
    parameter H_.
    return sqrt(2*H_/(1+H_)).
}
local function U_e{
    parameter E_.
    return U((1+E_)/(1-E_)).//ecentricity for lowified orbits will be negative
}
local function H{
    parameter U_.
    return U_^2/(2-U_^2).
}
local function Ui{
    parameter Vf.
    parameter Vc.
    parameter Hf is "none".//take into account finite SOI
    if(Hf="none" or Hf<1)return sqrt(2+Vf^2/Vc^2).//infinite SOI
    else return sqrt(2-2/Hf+Vf^2/Vc^2).

}
local function Ui_of_Uvf{
    parameter U_f.
    parameter Hf is "none".//take into account finite SOI
    if(Hf="none" or Hf<1)return sqrt(2+U_f^2).//infinite SOI
    else return sqrt(2-2/Hf+U_f^2).

}
local function Uf{//warning, imag output possible
    parameter Ui.
    return sqrt(Ui^2-2).
}
local function anomalyConvert{
    //TODO BROKEN
    //off by 30deg for some angles sub munar
    //of by 50deg for super minmusar
    parameter ang1.
    parameter e.//ecentricity
    parameter sgn. //+1: true -> mean (geometry -> time)
    if e=0 return ang1. //same for circle
    //wikipedia has an approximation in case assumption is not true
    //assums that mean anomaly is the same as angle from Virtual focus; this seems to be WRONG
    ///sympy failed to confirm or deny; but is true for apo / peri
    local r is (1-e^2)/(1+sgn*e*cos(ang1)).
    //other r is (1-e^2)/(1-sgn*e*cos(angr))
    local thecos is -sgn*(-1-e^2+r)/(2-r)/e.
    local angr is arccos(thecos). 
    if sin(ang1)<0 set angr to -angr.
    set angr to angr + 360*round((ang1-angr)/360).
    return angr.
}
local function TimeOfNextPeriapsis{
    parameter orb.
    //True anomaly is the geometric angle from Periapsis
    //Mean Anomaly is the time from periapsis (360/period)
    //planets have epoch of time=0;
    return orb:epoch+orb:period*(360-orb:meananomalyatepoch)/360.
}
local function orbitVelocityAt{
    ///Dont USE
    parameter BV.
    parameter time.
    //TODO figure out
    //velocityAt(obj,time):orbit gives its velocity relitive to its own body right now
    //velocityAt(kerbin,time)=~9700
    //velocityAt(ship,nextPatchEta+1):orbit gives velocity around NEW body
    //

}
local function orbitPolar{
    parameter orb.
    parameter tanm.//true anomaly
    return orb:semimajoraxis*(1-orb:eccentricity^2)/(1+orb:eccentricity*cos(tanm)).
    
}
local function orbitTimeToAng{
    parameter orb.
    parameter tan_i.//true anomalies
    parameter tan_f.
    diag("tan_i: "+tan_i).
    diag("tan_f: "+tan_f).
    local tanimod is modu(tan_i,360).
    diag("tanimod: "+tanimod).
    set tan_f to tan_f+tanimod-tan_i.
    set tan_i to tanimod.//modness tan_i
    diag("tan_i: "+tan_i).
    diag("tan_f: "+tan_f).
    //local L is vCrs(orb:position()-orb:body:position,orb:velocity:orbit-orb:body:velocity:orbit).
    local F is v(2*orb:semimajoraxis*orb:eccentricity,0,0).
    local Ar is orbitPolar(orb,tan_i).
    local A is v(-cos(tan_i)*Ar,-sin(tan_i)*Ar,0).
    local Br is orbitPolar(orb,tan_f).
    local B is v(-cos(tan_f)*Br,-sin(tan_f)*Br,0).
    local t0 is vang((A-F),(B-F))/360*orb:period.
    diag ("vang_F: "+vang((A-F),(B-F))).//problem
    diag ("vang_Body: "+vang((A),(B))).//problem
    diag("t0: "+t0).
    //local tan_c is 0.
    local sgn is 1.
    if (Vectorexclude((A-F),B)*A)>(Vectorexclude((A-F),A)*A){
        if tan_i>180 {set sgn to -1.}
    } else if tan_i<180 {set sgn to -1.}
    if tan_i=180 {set sgn to (tan_f-tan_i)/abs(tan_f-tan_i).}
    local nobs is (tan_f-tan_i-modu(tan_f-tan_i,360))/360.
    diag("sgn: "+sgn).
    diag("nobs: "+nobs).
    breakpoint("timetoTan").
    return nobs*orb:period+modu(t0*sgn,orb:period).

}
local function diag{parameter s_.
    if debug{
        print s_.
    }
}
local function breakpoint{parameter s_.
    if debug{
        //cannot pause from kos but could quicksave and then quickload later.
        print "breakpoint: "+s_+"; press any key to continue".
        terminal:input:clear.
        wait until terminal:input:haschar.
        terminal:input:clear.
    }
}
local function getPerapsisDirVec_broken_dontuse {//this is impossible, dont use
    parameter orb is ship:orbit.
    local n_asc is V(cos(orb:lan),0,sin(orb:lan)).//i am guessing somewhat about chirality
    local L is Vcrs((orb:position-orb:body:position),orb:velocity:orbit):normalized.
    local gen is Vcrs(L,n_asc):normalized.
    local omg is orbit:argumentofperiapsis.
    return n_asc*cos(omg)+gen*sin(omg).//TODO fix
    //try https://kos.fandom.com/wiki/XYZ_system_of_KSP
    //orb:vstatevector and orb:rstatevector are for kos debug only
    //z axis is 90 deg east of x axis.
    //However, it’s hard to predict exactly where the X and Z axes will be. They keep moving depending on where you are,
    // to the point where it’s impossible to get a fix on just which direction they’ll point.

}
local function getPerapsisDirVecOld{//can work but is bad
    parameter B.
    parameter overflow is 10.
    if B=ship {
        return (positionAt(ship,time:seconds+eta:periapsis)-ship:body:position).
    }
    local orb is B:orbit.
    if orb:eccentricity=0{return orb:position-orb:body:position.}
    local tht to orb:trueanomaly.
    local tnot is time:seconds.
    local theU is U((orb:apoapsis+orb:body:radius)/(orb:periapsis+orb:body:radius)).
    local dotmult is theU^2/(theU^2-1).
    local eta is -orb:period/360*tht.//be carefull with the name, but it does work
    local prevdt is "none".
    from {local a is 0.} until 
            abs(vectorDotProduct((positionat(B, tnot +eta) -orb:BODY:POSITION):normalized,velocityat(B, tnot +eta):ORBIT:normalized))<1/10000 
            or a>=overflow
        step {set a to a+1.} do {
        local rp is positionat(B, tnot +eta) -orb:BODY:POSITION.
        local vp is velocityat(B, tnot +eta):ORBIT.
        if vp:mag=0 {break.}
        local dot is rp*vp.
        local de is -dot/vp:sqrmagnitude*dotmult.
        if (positionat(B, tnot +eta) -orb:BODY:POSITION):mag<(positionat(B, tnot +eta+de) -orb:BODY:POSITION):mag
            from {local ab is 0.}
            until (positionat(B, tnot +eta) -orb:BODY:POSITION):mag>=(positionat(B, tnot +eta+de) -orb:BODY:POSITION):mag or ab>5
            step {set ab to b+1.} do { set de to de/2.}
        diag ("perivec deta: "+de).
        set eta to eta+de.

        //diag("eta->"+eta).
    }
    //diag("").
    //could also support eta return
    if (positionat(B, tnot +eta) -orb:BODY:POSITION):mag>orb:semimajoraxis {
        return -(positionat(B, tnot +eta) -orb:BODY:POSITION).
    }
    return positionat(B,tnot+eta)-orb:body:position.

}
local function getPerapsisDirVec{
    parameter B.
    //parameter overflow is 10.//depricated and unused
    local tan is B:orbit:trueAnomaly.//uses geometric angle
    //could possibly have used positionAt
    local pos is (B:position()-B:body:position()).
    local vel is B:velocity:orbit.
    local l is vcrs(pos,vel):normalized.
    local s is vcrs(pos,l):normalized.
    return (pos:normalized*cos(tan)+s*sin(tan)):normalized.
}
local function getPerapsisDirVecOfLaterPatch{
    parameter B.
    parameter orb is B:orbit.//future orbit of B
    //should be capable of replacing getPerapsisDirVec due to default argument and no use of overflow
    //parameter overflow is 10.//depricated and unused
    local tan is orb:trueAnomaly.//uses geometric angle
    //could possibly have used positionAt
    local tp is TimeOfNextPeriapsis(orb).
    return (positionAt(B,tp)-positionAt(orb:body,tp)):normalized.
}
local function getApproxBurnTo {
    parameter B.
    parameter nd is nextnode.//edits
    parameter B_pvec is getPerapsisDirVec(B).//can do once outside and save for all runs.
    //parameter prevorb is ship:orbit.//TODO incompadible with multinodes
    //parameter multinode is list(nd).//nd should be the last node
    local dv0 is 0.
    // for n in multinode {
    //     set dv0 to dv0+n:prograde.
    // }
    //local dvnd0 is nd:prograde.
    local t is time:seconds+nd:eta.
    set nd:prograde to 0.
    set nd:normal to 0.
    set nd:radialout to 0.
    local tht is vang(-(positionat(ship, t) -ship:orbit:BODY:POSITION),B_pvec).
    local vc0 is sqrt(ship:body:mu/(positionat(ship, t) -ship:orbit:BODY:POSITION):mag).
    local U0 is velocityAt(ship,t):orbit:mag/vc0.//gets just beore node, dont acutally need multinode parameter
    local Hf is orbitPolar(B:orbit,tht)/((positionat(ship, t)-ship:orbit:BODY:POSITION):mag).
    //diag ("Orb polar: "+orbitPolar(B:orbit,tht)).//looks good but dv is wrong
    //set nd:prograde to vc0*(U(Hf)-U0).//works well now
    local dvtot is vc0*(U(Hf)-U0).
    //diag("dvnd0"+dvnd0).
    //diag("dvtot"+dvtot).
    //diag("dv0"+dv0).
    set nd:prograde to dvtot.
    return nd:prograde.
    //wait 1.

}
local function getApproxBurnToVelocity {
    parameter Vf.
    parameter nd is nextnode.//edits
    local t is time:seconds+nd:eta.
    set nd:prograde to 0.
    set nd:normal to 0.
    set nd:radialout to 0.
    //https://github.com/KSP-KOS/KOS/issues/1304
    //positionat(ship) is in moon frame
    //positionat(moon) is in planet frame
    local rc0 is (positionat(ship, t) -ship:orbit:BODY:POSITION //wrong:: positionat(ship:body, t)
        ):mag.
    local vc0 is sqrt(ship:body:mu/rc0).
    local U0 is velocityAt(ship,t):orbit:mag/vc0.
    Local HSOI is ship:body:soiradius/rc0.
    diag("vc0,HSOI,U0"+vc0+" , "+HSOI+" , "+U0).
    set nd:prograde to vc0*(Ui(Vf,Vc0,HSOI)-U0).//works well now
    //wait 1.

}
local function getApproxBurnsToVelocityDive {
    parameter Vf.
    parameter nd1 is nextnode.//edits
    parameter nd2 is "none".//edits
    if nd2="none" {getApproxBurnToVelocity(Vf,nd1). return. }
    local t is time:seconds+nd1:eta.
    set nd1:prograde to 0.
    set nd1:normal to 0.
    set nd1:radialout to 0.
    local rc1 is (positionat(ship, t) -ship:orbit:BODY:POSITION):mag.//YES, this is correct due to frame choice
    local Vc1 is sqrt(ship:body:mu/rc1).
    local rc2 is (positionat(ship:body, t) -ship:orbit:BODY:BODY:POSITION):mag.
    local Vc2 is sqrt(ship:body:body:mu/rc2).
    local rcd is getLowestSafeOrbit(ship:body:body)+ship:body:body:radius.
    local vcd is sqrt(ship:body:body:mu/rcd).
    local U10 is velocityAt(ship,t):orbit:mag/Vc1.
    local U20 is velocityAt(ship:body,t):orbit:mag/Vc2.
    local vf1 is vc2*(U20-U(rcd/rc2)).
    local U21 is U(rc2/rcd).

    Local HSOI1 is ship:body:soiradius/rc1.
    Local HSOI2 is ship:body:body:soiradius/rcd.
    diag("Vc1,HSOI1,U10 :"+Vc1+" , "+HSOI1+" , "+U10+","+getLowestSafeOrbit(ship:body:body)).
    set nd1:prograde to Vc1*(Ui(Vf1,Vc1,HSOI1)-U10).
    //wait 0.
    //local tp is TimeOfNextPeriapsis(nd1:orbit:nextpatch).//this is done later
    //set nd2:eta to tp-time:seconds.//...periapsis
    set nd2:prograde to vcd*(Ui(Vf,vcd,HSOI2)-U21).
    //wait 1.

}
local function getApproxBurnToVelocityRet {
    parameter Vf.
    parameter moon is ship:body.
    parameter t is time:seconds+nextnode:eta.
    //local rc0 is (positionat(ship, t) -ship:orbit:BODY:POSITION):mag.//old code, wrong
    local rc0 is (positionat(moon, t) -positionat(moon:body, t)):mag.
    local vc0 is sqrt(moon:body:mu/rc0).
    Local HSOI is moon:body:soiradius/rc0.
    local U0 is velocityAt(moon,t):orbit:mag/vc0.
    diag("vc0,HSOI,U0"+vc0+" , "+HSOI+" , "+U0).
    return  vc0*(Ui(Vf,Vc0,HSOI)-U0).
    //velocity relative to moon
    //wait 1.

}
local function shouldDive{
    parameter v_f.//=v_f/v_moon
    parameter moon.
    //Time independant, can be checked before entering a function
    //parameter t is time:seconds+nextnode:eta.//unused
    //seems to be (approximately) correct now
    local rc1 is ship:orbit:semimajoraxis.//(positionat(ship, t) -positionat(moon, t)):mag.
    local vc1 is sqrt(moon:mu/rc1).
    local rc2 is moon:orbit:semimajoraxis.//(positionat(moon, t) -positionat(moon:body, t)):mag.
    local vc2 is sqrt(moon:body:mu/rc2).
    local U_f is v_f/vc2.
    local HSOI_planet is moon:body:soiradius/rc2.//take into account finite SOI
    local HSOI_moon is moon:soiradius/rc1.//take into account finite SOI
    local Hmin is (moon:body:radius+getLowestSafeOrbit(moon:body))/rc2.//lowest safe orbit H, is always the optimal one
    //TODO fine tune (dnw for bop, tylo, etc)
    local M is get_v_c(moon:body,moon:orbit:semimajoraxis)/get_v_c(moon,ship:orbit:semimajoraxis).//=v_moon / v_ship
    //direct: sym.sqrt(2+M**2*(sym.sqrt(2+Uf**2)-1)**2)-1
    //dive: M*(sym.sqrt(2/H+Uf**2)-sym.sqrt(2/(H*(H+1))))+sym.sqrt(2+M**2*(1-sym.sqrt(2*H/(H+1)))**2)-1
    local direct is Ui_of_Uvf(M*(Ui_of_Uvf(U_f,HSOI_planet)-1),HSOI_moon)-1.
    local dive is M/sqrt(Hmin)*(Ui_of_Uvf(U_f*sqrt(Hmin),HSOI_planet/Hmin)-U(1/Hmin))+Ui_of_Uvf(M*U(Hmin),HSOI_moon)-1.
    print "params: "+list(vc1,vc2,v_f,M,U_f,Hmin,HSOI_moon,HSOI_planet).//params check out
    print "direct: "+direct*vc1.
    print "dive:"+dive*vc1.
    return (dive<direct).
}
local function lockEtaToParallelEjection{
    parameter nd is nextNode.
    parameter psgn is 1.0.
    local t is time:seconds+nd:eta.//initial eta time, stay within a period/2 of this
    local lship is vcrs(ship:position-ship:body:position,ship:velocity:orbit).
    from {local i is 0.} until i>=3 step {set i to i+1.} do{//works now
            //no moon moons
            local Ang0 is vang(velocityAt(ship,time:seconds+nd:orbit:nextpatcheta-0.1):orbit,
                psgn*velocityAt(ship:body,time:seconds+nd:orbit:nextpatcheta-0.1):orbit).
            if vcrs(velocityAt(ship,time:seconds+nd:orbit:nextpatcheta-0.1):orbit,
                psgn*velocityAt(ship:body,time:seconds+nd:orbit:nextpatcheta-0.1):orbit)*lship<0 {
                    set Ang0 to -Ang0.
            }
            diag("Ang0: "+Ang0).
            //local deta is choose ship:orbit:period*Ang0/360 if dvf>0 else ship:orbit:period*(Ang0-180)/360.
            local deta is ship:orbit:period*Ang0/360.
            set nd:eta to nd:eta+deta.
            if nd:eta<=0 {set nd:eta to nd:eta+ship:orbit:period.}
            wait 0.
        }

}
local function getOrbitRadiusAtVecOld {//returns as vector
    //"To travel the stars, you must learn that you are not the center of the cosmos...
    //to write a kos script, you must unlearn this lie."
    parameter B.//cannot just use orbit because {italic} positionat needs an orbitablllle...
    parameter vec.
    parameter overflow is 10.
    local orb is B:orbit.
    local tnot is time:seconds.
    local norm_o is vectorCrossProduct(orb:position-orb:body:position,orb:velocity:orbit):normalized.
    local vecto is vectorExclude(norm_o,vec):normalized.//project arg 2 onto arg 1
    local eta is 0.//be carefull with the name, but it does work
    local prevcrs is "none".
    from {local a is 0.} until vectorCrossProduct(vecto,positionat(B, tnot +eta) -orb:BODY:POSITION):mag<
        vecto:mag*(positionat(B, tnot +eta) -orb:BODY:POSITION):mag/10000 or a>=overflow
        step {set a to a+1.} do {
        local rp is positionat(B, tnot +eta) -orb:BODY:POSITION.
        local vp is velocityat(B, tnot +eta):ORBIT.
        if rp*vecto<0{
            set eta to eta+B:orbit:period*0.323456789.
            set eta to modu(eta,B:orbit:period).
        } else if vectorCrossProduct(vp,vecto):mag=0{
            set eta to eta+B:orbit:period*0.223456789.//pseudoirrational
            set eta to modu(eta,B:orbit:period).
        }else{
            //newtons method
            local ddeta is -vectorCrossProduct(rp,vecto)*vectorCrossProduct(vp,vecto)/vectorCrossProduct(vp,vecto):mag^2.
            set eta to eta+ddeta.
            set eta to modu(eta,B:orbit:period).
            if not prevcrs="none" from {local b is 0.} until b>5 or vectorCrossProduct(rp,vecto):mag<prevcrs step {set b to b+1.} do{
                set ddeta to ddeta/2.
                set eta to eta-ddeta.
                set eta to modu(eta,B:orbit:period).
            }
            
        }
        

        //diag("eta->"+eta).
    }
    //diag("").
    return positionat(B,tnot+eta)-orb:body:position.

}
local function getOrbitRadiusAtVec {//returns as vector
    //"To travel the stars, you must learn that you are not the center of the cosmos...
    //to write a kos script, you must unlearn this lie."
    parameter B.//cannot just use orbit because {italic} positionat needs an orbitablllle...
    parameter vec.
    //parameter overflow is 10.//wont use
    local orb is B:orbit.
    local tnot is orb:epoch.
    local norm_o is vectorCrossProduct(positionAt(B,tnot)-positionAt(B:body,tnot),velocityAt(B,tnot):orbit):normalized.
    local vecto is vectorExclude(norm_o,vec):normalized.//project arg 2 onto arg 1
    local pvec is getPerapsisDirVec(B).
    local tanAtvec is vang(vecto,pvec).
    if determinent(pvec,vecto,norm_o)<0{
        set tanAtvec to -tanAtvec.//has no effect
    }
    if 1-B:orbit:eccentricity*cos(tanAtVec) =0{return "none".}//infinite
    //diag("getOrbitRadiusAtVec:"+tanAtvec+","+B:orbit:semimajoraxis*(1.0-B:orbit:eccentricity^2)/(1-B:orbit:eccentricity*cos(tanAtVec))
    //        +","+B:orbit:periapsis+B:body:radius+","+B:orbit:apoapsis+B:body:radius).

    return B:orbit:semimajoraxis*(1.0-B:orbit:eccentricity^2)/(1+B:orbit:eccentricity*cos(tanAtVec)).//may be negative

}
local function getRadAtVec_nowork{
    parameter orb.
    parameter vec.
    return orbitPolar(orb,vang(vec,getPerapsisDirVec(orb))).
}
local function getDvEjectMoonDirect{//reversible
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
local function getDvEjectMoonPlunge{//reversible
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
local function getIncomingResolutionCoefficient{
    parameter A.//start
    parameter B.//end
    parameter dt.//period of possible ejection times
    if not (A:body=B:body) {
        print "bodies do not have same center".
        return "none".
    }
    local S is A:body.//short for sun
    //return Ang.//answers look reasonable
    local t is time:seconds.
    local rA0 is positionAt(A,t)-S:position().
    local rB0 is positionAt(B,t)-S:position().
    local Lb is vcrs(rB0,velocityAt(B,t):orbit).//if needed, use B as l ref
    local A_retro is ((vcrs(rA0,velocityAt(A,t):orbit)*Lb)<0).
    diag("A_retro: "+A_retro).
    local omg_r is choose (360/B:orbit:period + 360/A:orbit:period) if A_retro else 
            (360/B:orbit:period - 360/A:orbit:period).//=-d Ang/dt
    diag("omega: "+omg_r).
    if omg_r=0 {
        print "can't transfer, Bodied have same period.".
        return "none".
    }
    local dr is dt * omg_r * B:orbit:semimajoraxis.
    return dr / B:soiradius.
}
local function getTransferTime {
    parameter A.//start
    parameter B.//end
    parameter number is 1.//find multiple consecutive windows
    parameter t is time:seconds.
    if not (A:body=B:body) {
        print "bodies do not have same center".
        return "none".
    }
    if number>1 {
        local prevTime is t.
        local times is list().
        local buffer is -1.
        from {local index is 1.} until index >=number step {set index to index+1.} do{
            local newtime is getTransferTime(A,B,1,prevTime).
            times:add(newtime).
            if buffer<0{
                set buffer to (newTime-prevTime)*0.7.
            }
            set prevTime to newtime+buffer.
        }
        return times.
    } 
    local S is A:body.//short for sun
    parameter A_perivec is getPerapsisDirVec(A).
    parameter B_perivec is getPerapsisDirVec(B).
    //circular noninclined approx
    local Ang is ((A:orbit:semimajoraxis+B:orbit:semimajoraxis)/2/B:orbit:semimajoraxis)^(1.5)*180.
    set Ang to modu(Ang,360).
    //angle of B from anti-A
    diag("Ang: "+Ang).
    //return Ang.//answers look reasonable
    local rA0 is positionAt(A,t)-S:position().
    local rB0 is positionAt(B,t)-S:position().
    local Lb is vcrs(rB0,velocityAt(B,t):orbit).//if needed, use B as l ref
    local Ang_0 is vang(-rA0,RB0).
    if Lb*vcrs(rA0,rB0)<0 {set Ang_0 to 360-Ang_0.}.
    diag("Ang_0: "+Ang_0).
    local A_retro is ((vcrs(rA0,velocityAt(A,t):orbit)*Lb)<0).
    diag("A_retro: "+A_retro).
    local omg_r is choose (360/B:orbit:period + 360/A:orbit:period) if A_retro else 
            (360/B:orbit:period - 360/A:orbit:period).//=-d Ang/dt
    diag("omega: "+omg_r).
    if (omg_r>0) and (Ang_0<Ang) {set Ang_0 to Ang_0+360.}
    if (omg_r<0) and (Ang_0>Ang) {set Ang_0 to Ang_0-360.}
    if omg_r=0 {
        print "can't transfer, Bodied have same period.".
        return "none".
    }
    diag("modded Ang_0="+Ang_0).
    //TODO sometimes give the wrong time.
    local tto is (Ang_0-Ang)/omg_r.
    diag ("tto: "+tto).
    local ptto is "none".
    local rA1 is positionAt(A,t+tto)-S:position().
    local rB1 is positionAt(B,t+tto)-S:position().
    local Ang_1 is vang(-rA1,RB1).
    if Lb*vcrs(rA1,rB1)<0 {set Ang_1 to 360-Ang_1.}.
    set tto to tto+ (Ang_1-Ang)/omg_r.
    diag ("tto_1: "+tto).

    local B_trmag is B:orbit:semimajoraxis.
    from {local i is 0.} until ((i>=5) or (ptto=tto)) step {set i to i+1.} do {
        
        local A_trvec is (positionAt(A,t+tto)-A:body:position).
        local t_trans is A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
        local B_trvec is (positionAt(B,t+tto+t_trans)-A:body:position).
        set B_trmag to B_trvec:mag.
        set t_trans to A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
        set B_trvec to (positionAt(B,t+tto+t_trans)-A:body:position).
        set V_at to -A_trvec:normalized*B_perivec:mag.
        local A_omg to vcrs((positionAt(A,t+tto)-A:body:position),(velocityAt(A,t+tto):orbit)
                )/(positionAt(A,t+tto)-A:body:position):sqrmagnitude.
        local B_omg to vcrs((positionAt(B,t+tto+t_trans)-S:position),(velocityAt(B,t+tto+t_trans):orbit)
                )/(positionAt(B,t+tto+t_trans)-S:position):sqrmagnitude.
        local tht is vcrs(B_trvec:normalized,V_at:normalized)*B_omg:normalized.
        diag("tht: "+tht).
        if vang(V_at,B_trvec)>90 {set tht to (180-abs(tht))*tht/abs(tht).}
        set omg_r to B_omg:mag-A_omg*B_omg:normalized. if omg_r=0 {
        print "can't transfer, Bodied have same period.".
        return "none".
        }
        set ptto to tto.
        set tto to tto+tht/omg_r.
        diag("tht: "+tht).
        diag("tto: "+tto).

    }

    return t+tto.
    
}
local function getBurnToPlanet{
    parameter A.//start
    parameter B.//end
    parameter tm.
    if not (A:body=B:body) {
        print "bodies do not have same center".
        return "none".
    }
    local S is A:body.//short for sun
    local B_trmag is B:orbit:semimajoraxis.
    local A_trvec is (positionAt(A,tm)-A:body:position).
    local t_trans is A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
    local B_trvec is (positionAt(B,tm+t_trans)-A:body:position).
    set B_trmag to B_trvec:mag.
    set t_trans to A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
    set B_trvec to (positionAt(B,tm+t_trans)-A:body:position).
    set B_trmag to B_trvec:mag.
    //diag("B_trmag: ")
    local Hf0 is B_trmag/A_trvec:mag.
    diag("HF0: "+HF0).//BUG
    local Uf0 is U(B_trmag/A_trvec:mag).
    diag("Uf0: "+Uf0).
    local vc is sqrt(S:mu/A_trvec:mag).
    diag("vc: "+vc).
    local Ui0 is velocityAt(A,tm):orbit:mag/vc.
    diag("Ui0: "+Uf0).
    local dv is vc*(Uf0-Ui0).
    diag("dv: "+dv).
    return dv.
}
local function getOptimalInclinationPortions{
    parameter rel_inc.
    parameter residual_inc.
    parameter burnTo.
    parameter burnAt.
    parameter vcfrom.//ship orbit
    parameter vcat.
    parameter vcpfrom, vcpat. //planet orbit
    local pnt_inc is choose sqrt(rel_inc^2-residual_inc^2) if abs(rel_inc)>abs(residual_inc) else 0.
    //parameter targetApoapsis. //not needed
    //U = sqrt (2+ ufv^2)
    //dv (theta) = dvflat*e_x + (e_theta-e_x)*PLANET_vc
    //inclination approx hypot (residual_inc,zeroed_inclination)
    //mayassume small angles
    local function thedv {
        //after ejecting
        parameter dv,vc,vcp,dth.
        //dv is signed prograde
        return vc*(sqrt(2+(dv+(vcp+dv)/vc*(cos(dth)-1))^2+(vcp+dv)^2/vc^2*sin(dth)^2)). //-vc
        // p=vcp/vc
        // f = vf/vc
        //approx dv* sqrt (  2+ (f+(p+f)(-dth^2/2))^2+((p+f) dth)^2))
        //approx dv* sqrt (  2+ f^2 (1+(p/f+1)(-dth^2))+((p+f) dth)^2))
        //approx dv* sqrt (  2+f^2+(p^2+pf)( dth)^2))
        ///approx good within <3%
    }
    local function dv_coeffs{
        parameter dv,vc,vcp,dth.
        // v=sqrt (a^2 + b^2 dth^2)
        return list(2*vc^2+dv^2,vcp^2+vcp*dv).
    }
    //dth2 = rel_inc - 
    //0 = b_1^2 dth_1/v_1 - b_2^2 dth_2 /v_2
    //0 = b_1^2 dth_1*v2 - b_2^2 dth_2 *v1
    //0 = b_1^4 dth_1^2 * v_2^2 - b_2^4 dth_2 *v_1^2
    //0 = b_1^4 dth_1^2 * (a_2^2+b_2^2 (inc-dth_1)^2) - b_2^4 (inc-dth_1) *(a_1^2+b_1^2 dth_1^2)
    //exact solution exists but is pages long
    local dth1 is pnt_inc/2.
    local dth2 is pnt_inc/2.
    local dth is pnt_inc/1000.
    from {local a is 0.} until a>10 step {set a to a+1.} do {
        local dv0 is thedv(burnTo,vcfrom,vcpfrom,dth1)+thedv(burnAt,vcat,vcpat,dth2).
        local dvplus is thedv(burnTo,vcfrom,vcpfrom,dth1+dth)+thedv(burnAt,vcat,vcpat,dth2-dth).
        local dvminus is thedv(burnTo,vcfrom,vcpfrom,dth1-dth)+thedv(burnAt,vcat,vcpat,dth2+dth).
        local d is (dvplus-dvminus)/2/dth.
        if d=0 break.
        local dd is (dvplus+dvminus-2*dv0)/dth^2.
        
        local cth1 is -d/abs(d)*pnt_inc/10.
        if not dd=0 set cth1 to -d/dd.
        set dth1 to dth1+cth1.
        set dth2 to dth2-cth1.
    }

}
local function m_util_min{//list version of min
    parameter ns.//will be destroyed
    if ns:length=2{
        return min(ns[0],ns[1]).
    }else{
        local a is ns[0].
        ns:remove(0).
        return min(a,m_util_min(ns)).
    }
}
local function m_util_max{//list version of min
    parameter ns.//will be destroyed
    if ns:length=2{
        return max(ns[0],ns[1]).
    }else{
        local a is ns[0].
        ns:remove(0).
        return max(a,m_util_max(ns)).
    }
}
local function m_opt {
    parameter node.
    parameter opt.
    parameter tgt is 0.//usage: "min", "max", or Scalar Value
    parameter stepVmax is 10.
    parameter dv is 0.001.
    parameter overflow is 100.
    parameter supressOverflow is {return false.}.
    local function farness {
        parameter optval.
        if tgt="min"{
            return optval.
        }
        else if tgt="max"{
            return -optval.
        }else{
            return abs(tgt-optval).
        }
    }
    from {local a is 0.} until (a>=overflow) and not supressOverflow() step {set a to a+1.} do {
        local opt_ is opt().
        local optopt is farness(opt_).
        set node:prograde to node:prograde+dv.
        wait 0.
        local opt_p is opt().
        local optopt is min(optopt,farness(opt_p)).
        set node:prograde to node:prograde-dv.
        set node:prograde to node:prograde-dv.
        wait 0.
        local opt_r is opt().
        local optopt is min(optopt,farness(opt_r)).
        set node:prograde to node:prograde+dv.

        set node:radialout to node:radialout+dv.
        wait 0.
        local opt_o is opt().
        local optopt is min(optopt,farness(opt_o)).
        set node:radialout to node:radialout-dv.
        set node:radialout to node:radialout-dv.
        wait 0.
        local opt_i is opt().
        local optopt is min(optopt,farness(opt_i)).
        set node:radialout to node:radialout+dv.

        set node:normal to node:normal+dv.
        wait 0.
        local opt_n is opt().
        local optopt is min(optopt,farness(opt_n)).
        set node:normal to node:normal-dv.
        set node:normal to node:normal-dv.
        wait 0.
        local opt_a is opt().
        local optopt is min(optopt,farness(opt_a)).
        set node:normal to node:normal+dv.

        set node:prograde to node:prograde+dv.
        set node:radialout to node:radialout+dv.
        wait 0.
        local opt_p_o is opt().
        local optopt is min(optopt,farness(opt_p_o)).
        set node:radialout to node:radialout-dv.
        set node:prograde to node:prograde-dv.

        set node:prograde to node:prograde+dv.
        set node:normal to node:normal+dv.
        wait 0.
        local opt_p_n is opt().
        local optopt is min(optopt,farness(opt_p_n)).
        set node:normal to node:normal-dv.
        set node:prograde to node:prograde-dv.

        set node:radialout to node:radialout+dv.
        set node:normal to node:normal+dv.
        wait 0.
        local opt_o_n is opt().
        local optopt is min(optopt,farness(opt_o_n)).
        set node:normal to node:normal-dv.
        set node:radialout to node:radialout-dv.
        wait 0.
        //diag(list(opt_p,opt_,opt_r)).
        if optopt=farness(opt_){break.}//Nabla approx 0.
        local del_p is (opt_p-opt_r)/2/dv.
        local del_o is (opt_o-opt_i)/2/dv.
        local del_n is (opt_n-opt_a)/2/dv.
        local del_mag is sqrt(del_p^2+del_o^2+del_n^2).
        //assert del_mag!=0
        local del_pp is (opt_p+opt_r-2*opt_)/dv^2.
        local del_oo is (opt_i+opt_o-2*opt_)/dv^2.
        local del_nn is (opt_n+opt_a-2*opt_)/dv^2.
        local del_po is (opt_p_o+opt_-opt_p-opt_o)/dv^2.
        local del_pn is (opt_p_n+opt_-opt_p-opt_n)/dv^2.
        local del_on is (opt_o_n+opt_-opt_o-opt_n)/dv^2.
        local del_sq is m_util_max(list(del_pp,del_oo,del_nn,del_po,del_pn,del_on))*3^(0.333).//not as good
        //diag(list(del_pp,del_oo,del_nn,del_po,del_pn,del_on)).//cross terms where faulty
        //local del_sq is del_
        local d_p is 0.
        local d_o is 0.
        local d_n is 0.
        //for a 3x3 matrix with element max s, the largest eigenvalue musbe have abs(eigen)<=s*3^0.333  (by sauruss's rule)
        //components of form: radialout, normal, prograde; if vectorized
        
        if tgt="max"{
            if del_sq=0 {
                set d_p to del_p/del_mag*stepVmax.
                set d_o to del_o/del_mag*stepVmax.
                set d_n to del_n/del_mag*stepVmax.
            } else{
                set d_p to min(max(-stepVmax,del_p/del_sq),stepVmax).
                set d_o to min(max(-stepVmax,del_o/del_sq),stepVmax).
                set d_n to min(max(-stepVmax,del_n/del_sq),stepVmax).
            }

        } else if tgt="min"{
            if del_sq=0 {
                set d_p to -del_p/del_mag*stepVmax.
                set d_o to -del_o/del_mag*stepVmax.
                set d_n to -del_n/del_mag*stepVmax.
            } else{
                set d_p to -min(max(-stepVmax,del_p/del_sq),stepVmax).
                set d_o to -min(max(-stepVmax,del_o/del_sq),stepVmax).
                set d_n to -min(max(-stepVmax,del_n/del_sq),stepVmax).
            }

        }else{
            if del_sq=0 or abs((tgt-opt_)*del_p/del_mag^2)<=abs(del_p/del_sq){
                set d_p to (tgt-opt_)*del_p/del_mag^2.
                set d_o to (tgt-opt_)*del_o/del_mag^2.
                set d_n to (tgt-opt_)*del_n/del_mag^2.
                diag("zerolike").
            }else{
                local sgn to choose 1 if tgt>opt_ else -1.
                set d_p to sgn*min(max(-stepVmax,del_p/del_sq),stepVmax).
                set d_o to sgn*min(max(-stepVmax,del_o/del_sq),stepVmax).
                set d_n to sgn*min(max(-stepVmax,del_n/del_sq),stepVmax).
                diag("minmaxlike: "+del_p/del_sq).
            }
        }
        set node:prograde to node:prograde+d_p.
        set node:radialout to node:radialout+d_o.
        set node:normal to node:normal+d_n.
        local d_mag is sqrt(d_p^2+d_o^2+d_n^2).
        wait 0.
        local b is 0.//not the problem
        //used to be until b>=5
        if not (farness(opt())<=farness(opt_)) and d_mag<dv and d_mag>0{
            set node:prograde to node:prograde-d_p.
            set node:radialout to node:radialout-d_o.
            set node:normal to node:normal-d_n.

            set d_p to d_p*dv/d_mag.
            set d_o to d_o*dv/d_mag.
            set d_n to d_n*dv/d_mag.

            set node:prograde to node:prograde+d_p.
            set node:radialout to node:radialout+d_o.
            set node:normal to node:normal+d_n.
            wait 0.
        }
        if not (farness(opt())<=farness(opt_)) from {set b to 0.} until b>=3 or farness(opt())<=farness(opt_) step {set b to b+1.} do {
            set d_p to d_p/2.
            set d_o to d_o/2.
            set d_n to d_n/2.
            set node:prograde to node:prograde-d_p.
            set node:radialout to node:radialout-d_o.
            set node:normal to node:normal-d_n.
            wait 0.
        }
        diag("Optimizing: "+opt()+" DDV: "+sqrt(d_p^2+d_o^2+d_n^2)).
    }
}
local function m_opt_pro {
    parameter node.
    parameter opt.
    parameter tgt is 0.//usage: "min", "max", or Scalar Value
    parameter stepVmax is 10.
    parameter dv is 0.001.
    parameter overflow is 100.
    parameter supressOverflow is {return false.}.
    local function farness {
        parameter optval.
        if tgt="min"{
            return optval.
        }
        else if tgt="max"{
            return -optval.
        }else{
            return abs(tgt-optval).
        }
    }
    from {local a is 0.} until (a>=overflow) and not supressOverflow() step {set a to a+1.} do {
        local opt_ is opt().
        local optopt is farness(opt_).
        set node:prograde to node:prograde+dv.
        wait 0.
        local opt_p is opt().
        local optopt is min(optopt,farness(opt_p)).
        set node:prograde to node:prograde-dv.
        set node:prograde to node:prograde-dv.
        wait 0.
        local opt_r is opt().
        local optopt is min(optopt,farness(opt_r)).
        set node:prograde to node:prograde+dv.

        wait 0.
        //diag(list(opt_p,opt_,opt_r)).
        if optopt=farness(opt_){break.}//Nabla approx 0.
        local del_p is (opt_p-opt_r)/2/dv.
        local del_mag is sqrt(del_p^2).
        //assert del_mag!=0
        local del_pp is (opt_p+opt_r-2*opt_)/dv^2.
        local del_sq is abs(del_pp).//not as good
        //diag(list(del_pp,del_oo,del_nn,del_po,del_pn,del_on)).//cross terms where faulty
        //local del_sq is del_
        local d_p is 0.
        //for a 3x3 matrix with element max s, the largest eigenvalue musbe have abs(eigen)<=s*3^0.333  (by sauruss's rule)
        //components of form: radialout, normal, prograde; if vectorized
        
        if tgt="max"{
            if del_sq=0 {
                set d_p to del_p/del_mag*stepVmax.
            } else{
                set d_p to min(max(-stepVmax,del_p/del_sq),stepVmax).
            }

        } else if tgt="min"{
            if del_sq=0 {
                set d_p to -del_p/del_mag*stepVmax.
            } else{
                set d_p to -min(max(-stepVmax,del_p/del_sq),stepVmax).
            }

        }else{
            if del_sq=0 or abs((tgt-opt_)*del_p/del_mag^2)<=abs(del_p/del_sq){
                set d_p to (tgt-opt_)*del_p/del_mag^2.
                diag("zerolike").
            }else{
                local sgn to choose 1 if tgt>opt_ else -1.
                set d_p to sgn*min(max(-stepVmax,del_p/del_sq),stepVmax).
                diag("minmaxlike: "+del_p/del_sq).
            }
        }
        set node:prograde to node:prograde+d_p.
        local d_mag is sqrt(d_p^2).
        wait 0.
        local b is 0.//not the problem
        //used to be until b>=5
        if not (farness(opt())<=farness(opt_)) and d_mag<dv and d_mag>0{
            set node:prograde to node:prograde-d_p.
            set d_p to d_p*dv/d_mag.

            set node:prograde to node:prograde+d_p.
            wait 0.
        }
        if not (farness(opt())<=farness(opt_)) from {set b to 0.} until b>=3 or farness(opt())<=farness(opt_) step {set b to b+1.} do {
            set d_p to d_p/2.
            set node:prograde to node:prograde-d_p.
            wait 0.
        }
        diag("Optimizing: "+opt()+" DDV: "+sqrt(d_p^2)).
    }
}
local function m_opt_eta {
    parameter node.
    parameter opt.
    parameter tgt is 0.//usage: "min", "max", or Scalar Value
    parameter updt is "none".//runs each time node is changed
    parameter stepTmax is 100.
    parameter dt is 0.1.//anything lower than 0.01 and del_sq becomes inconsistant
    parameter overflow is 100.
    local doUpdate is not (updt="none").
    local function farness {
        parameter optval.
        if tgt="min"{
            return optval.
        }
        else if tgt="max"{
            return -optval.
        }else{
            return abs(tgt-optval).
        }
    }
    from {local a is 0.} until a>=overflow step {set a to a+1.} do {
        local opt_ is opt().
        local optopt is farness(opt_).
        set node:eta to node:eta+dt.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_l is opt().
        local optopt is min(optopt,farness(opt_l)).
        set node:eta to node:eta-dt.
        set node:eta to node:eta-dt.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_s is opt().
        local optopt is min(optopt,farness(opt_s)).
        set node:eta to node:eta+dt.
        
        wait 0.
        if doUpdate {updt().wait 0.}
        diag(list(opt_l,opt_,opt_s)).
        if optopt=farness(opt_){break.}//Nabla approx 0.
        local del_e is (opt_l-opt_s)/2/dt.
        local del_mag is abs(del_e).
        //assert del_mag!=0
        local del_ee is (opt_l+opt_s-2*opt_)/dt^2.
        local del_sq is abs(del_ee).
        //local del_sq is del_
        local d_e is 0.
        //for a 3x3 matrix with element max s, the largest eigenvalue musbe have abs(eigen)<=s*3^0.333  (by sauruss's rule)
        //components of form: radialout, normal, prograde; if vectorized
        diag ("dele="+del_e).diag ("delsq="+del_sq).

        if tgt="max"{
            if del_sq=0 {
                set d_e to del_e/del_mag*stepTmax.
                diag("del_sq=0").
            } else{
                set d_e to min(max(-stepTmax,del_e/del_sq),stepTmax).
            }

        } else if tgt="min"{
            if del_sq=0 {
                set d_e to -del_e/del_mag*stepTmax.
            } else{
                set d_e to -min(max(-stepTmax,-del_e/del_sq),stepTmax).
            }

        }else{
            if del_sq=0 or abs((tgt-opt_)*del_e/del_mag^2)<=abs(del_e/del_sq){
                set d_e to (tgt-opt_)*del_e/del_mag^2.
                diag("zerolike").
            }else{
                local sgn to choose 1 if tgt>opt_ else -1.
                set d_e to sgn*min(max(-stepTmax,del_e/del_sq),stepTmax).
                diag("minmaxlike: "+del_e/del_sq).
            }
        }
        set node:eta to node:eta+d_e.
        if node:eta<=0 {set node:eta to node:eta+ship:orbit:period.}
        wait 0.
        if doUpdate {updt().wait 0.}
        local b is 0.//not the problem
        from {set b to 0.} until b>=5 or farness(opt())<=farness(opt_) step {set b to b+1.} do {
            set d_e to d_e/2.
            set node:eta to node:prograde-d_e.
            wait 0.
            if doUpdate {updt().wait 0.}
        }
        diag("Optimizing: "+opt()+" DEt: "+d_e).

    }

}
local function m_opt_pro_eta {
    parameter node.
    parameter opt.
    parameter tgt is 0.//usage: "min", "max", or Scalar Value
    parameter updt is "none".//runs each time node is changed
    parameter stepTmax is 100.
    parameter stepVmax is 10.
    parameter dt is 0.1.//anything lower than 0.01 and del_sq becomes inconsistant
    parameter dv is 0.001.
    parameter overflow is 100.
    local doUpdate is not (updt="none").
    local function farness {
        parameter optval.
        if tgt="min"{
            return optval.
        }
        else if tgt="max"{
            return -optval.
        }else{
            return abs(tgt-optval).
        }
    }
    from {local a is 0.} until a>=overflow step {set a to a+1.} do {
        local opt_ is opt().
        local optopt is farness(opt_).
        set node:eta to node:eta+dt.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_l is opt().
        local optopt is min(optopt,farness(opt_l)).
        set node:eta to node:eta-dt.
        set node:eta to node:eta-dt.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_s is opt().
        local optopt is min(optopt,farness(opt_s)).
        set node:eta to node:eta+dt.

        set node:prograde to node:prograde+dv.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_p is opt().
        local optopt is min(optopt,farness(opt_p)).
        set node:prograde to node:prograde-dv.
        set node:prograde to node:prograde-dv.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_r is opt().
        local optopt is min(optopt,farness(opt_r)).
        set node:prograde to node:prograde+dv.

        set node:prograde to node:prograde+dv.
        set node:eta to node:eta+dt.
        wait 0.
        if doUpdate {updt().wait 0.}
        local opt_pl is opt().
        local optopt is min(optopt,farness(opt_pl)).
        set node:eta to node:eta-dt.
        set node:prograde to node:prograde-dv.
        
        wait 0.
        if doUpdate {updt().wait 0.}
        diag(list(opt_l,opt_,opt_s)).
        if optopt=farness(opt_){break.}//Nabla approx 0.
        local del_p is (opt_p-opt_r)/2/dv.
        local del_e is (opt_l-opt_s)/2/dt.
        local del_mag is sqrt(del_P^2+del_e^2).
        //assert del_mag!=0
        local del_ee is (opt_l+opt_s-2*opt_)/dt^2.
        local del_pp is (opt_p+opt_r-2*opt_)/dv^2.
        local del_pe is (opt_+opt_pl-opt_p-opt_r)/dv/dt.//looks good
        
        local del_sq is m_util_max(list(del_pp,del_ee,del_pe))*2.//not as good
        //local del_sq is del_
        local d_e is 0.
        local d_p is 0.
        //for a 2x2 matrix max lambda is leq 2*star
        diag ("dele="+del_e).diag ("delsq="+del_sq).

        if tgt="max"{
            if del_sq=0 {
                set d_e to del_e/del_mag*stepTmax.
                set d_p to del_p/del_mag*stepVmax.
                diag("del_sq=0").
            } else{
                set d_e to min(max(-stepTmax,del_e/del_sq),stepTmax).
                set d_p to min(max(-stepVmax,del_p/del_sq),stepVmax).
            }

        } else if tgt="min"{
            if del_sq=0 {
                set d_e to -del_e/del_mag*stepTmax.
                set d_p to -del_p/del_mag*stepVmax.
            } else{
                set d_e to -min(max(-stepTmax,-del_e/del_sq),stepTmax).
                set d_p to -min(max(-stepVmax,-del_p/del_sq),stepVmax).
            }

        }else{
            if del_sq=0 or abs((tgt-opt_)*del_e/del_mag^2)<=abs(del_e/del_sq){
                set d_e to (tgt-opt_)*del_e/del_mag^2.
                set d_p to (tgt-opt_)*del_p/del_mag^2.
                diag("zerolike").
            }else{
                local sgn to choose 1 if tgt>opt_ else -1.
                set d_e to sgn*min(max(-stepTmax,del_e/del_sq),stepTmax).
                set d_p to sgn*min(max(-stepTmax,del_p/del_sq),stepTmax).
                diag("minmaxlike: "+del_e/del_sq).
            }
        }
        set node:eta to node:eta+d_e.
        set node:prograde to node:eta+d_p.
        if node:eta<=0 {set node:eta to node:eta+ship:orbit:period.}
        wait 0.
        if doUpdate {updt().wait 0.}
        local b is 0.//not the problem
        from {set b to 0.} until b>=5 or farness(opt())<=farness(opt_) step {set b to b+1.} do {
            set d_e to d_e/2.
            set d_p to d_p/2.
            set node:eta to node:eta-d_e.
            set node:prograde to node:prograde-d_p.
            wait 0.
            if doUpdate {updt().wait 0.}
        }
        diag("Optimizing: "+opt()+" DEt: "+d_e+" Dpro: "+d_p).

    }

}
//next patch util.
//see: https://github.com/KSP-KOS/KOS/issues/2295  for someone else who is having this problem
local shipnextpatch is "null".
local shipnextpatchtimeout is 10.
local shipnextpatchtime is 0.
local shipnextpatchisvalid is false.
local shipnextpatchissearching is false.
local shipnextpatchtimestamp is "null".

local function invalidateNextPatch{
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
local function getshipnextpatch{
    parameter timeout is 10.
    if not shipnextpatchissearching and not shipnextpatchisvalid{
        invalidateNextPatch(timeout).
    }
    wait until shipnextpatchisvalid.
    return shipnextpatch.

}
local function m_exec {
    parameter nd is nextNode.
    parameter error is 0.1.
    parameter throttle_limiter is 1.
    parameter dophyswarp is true.
    parameter timewarpif is {return true.}.
    parameter endif is {return false.}.//ends the burn early if a condition is met and phys timewarp is off.
    //parameter rebootfunc is {print "m_exec: no reboot function given.".return.}.//have the running func do this
    parameter rot_t is 5.//charactaristic rotation time
    local reboot is false.//unused
    set throttle_limiter to min(1,throttle_limiter).
    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    
    local time_before_node is 0.
    local mdot is 0.0.//mass flow rate
    LIST ENGINES IN myVariable.
    FOR eng IN myVariable {
        set mdot to mdot + eng:AVAILABLETHRUST/(eng:ISP*constant:g0).
    }.
    local vsp is ship:availableThrust / mdot.
    local tsp is ship:mass / mdot.
    local t_total is tsp * (1 - Constant:E ^ (-nd:deltav:mag / vsp)).
    //print "t_sp = "+tsp.
    print "Exact burn duration:  "+t_total.
    local lnttmt is ln(tsp/(tsp-t_total)). // == vsp / deltav
    set time_before_node to tsp - t_total / lnttmt.
    print "Start early by:  "+time_before_node.
    

    local np to nd:deltav. //points to node, don't care about the roll direction.
    //np is a value copy because the local function node:deltav has "get only" access.
    //all suffixes in kos have a property called "access" which determines whether they returne value or reference.
    if warp=0{
        
        lock steering to np.

        //now we need to wait until the burn vector and ship's facing are aligned
        wait 5.
        wait until vang(np, ship:facing:vector) < 0.25
                or nd:deltav:mag<error.

        //the ship is facing the right direction, let's wait for our burn time
        local w is time:seconds+nd:eta-(time_before_node)-10.
        unlock steering.
        warpto(w).
    }else set reboot to true.
    wait until nd:eta <= (time_before_node)+8.
    set np to nd:deltav.
    lock steering to np.//wake up
    diag("m_exec: steering relocked").
    wait until nd:eta <= (time_before_node).
    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    local tset to 0.
    lock throttle to tset*throttle_limiter.

    local done to False.
    local breakflag is false.
    //initial deltav
    local dv0 to nd:deltav.
    local dvcurr to nd:deltav.
    until done
    {
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to ship:maxthrust/ship:mass.
        if (nd:deltav:mag/max_acc)>max(15,rot_t) and nd:deltav:mag>=1
                and dophyswarp and timewarpif(){
            set warpmode to "PHYSICS".
            set warp to 3.
        }else{
            set warp to 0.
            set warpmode to "RAILS".
            if endif(){
                lock throttle to 0.
                print "Burn ended prematurely as perscribed by endif condition.".
                set done to true.
                set breakflag to true.
            }
        }
        if (nd:deltav:mag/max_acc)>rot_t and nd:deltav:mag>=1{
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
    
    if (not breakflag) and (not nd:deltav:mag=0) {
        lock steering to nd:deltav.
        local ttime is time:seconds.
        wait until vang(np, ship:facing:vector) < 1.00 or (time:seconds-ttime)>5*rot_t.
        local ftime is 1.0.
        local th is nd:deltav:mag*ship:mass/ship:maxthrust/ftime.
        lock throttle to th.
        wait ftime.
        lock throttle to 0.
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
    //if reboot {}
    
}
local function m_multexec {
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
local function multnode_changeEta{
    //changes the eta for each node in a list (structs and structs only are passed by reference).
    //if classes existed, we would make a multinode class for this but we cant (yet?).
    parameter mnode.//reference
    parameter det.//value
    for nds in mnode {
        set nds:eta to nds:eta+det.
    }

}
local function etaNormalNode{
    parameter B is target.
    parameter a_d is +1.//+1 for ascending, -1 for descending.
    parameter returnangle is false.//dont use, use m_rel_inclination() instead
    local tnot is time:seconds.
    local norm_s is vectorCrossProduct(ship:orbit:position-ship:body:position,ship:velocity:orbit).
    set norm_s to norm_s/norm_s:mag.
    //local norm_t is vectorCrossProduct(B:orbit:position-B:body:orbit:position,B:velocity:orbit-B:body:velocity:orbit).
    //sun:orbit:... cause NullReferenceException on c# side
    local norm_t is vectorCrossProduct(B:orbit:position-B:body:position,B:velocity:orbit-B:body:velocity:orbit).
    diag (norm_t).//TODO nan later
    set norm_t to norm_t/norm_t:mag.
    local vecto is -vectorCrossProduct(norm_t,norm_s)*a_d.
    diag (norm_s).//bugged. should be approx V(0,1,0) or minus
    diag (norm_t).//TODO nan
    diag (vecto:mag).
    local angle is arcSin(vecto:mag). diag("Angle: "+angle).//TODO return
    if(returnangle) return angle.
    if vecto:mag=0 {return "None".}
    local eta is 0.//be carefull with the name, but it does work
    from {local a is 0.} until vectorCrossProduct(vecto,positionat(SHIP, tnot +eta) -BODY:POSITION):mag<
        vecto:mag*(positionat(SHIP, tnot +eta) -BODY:POSITION):mag/10000 or a>=100
        step {set a to a+1.} do {
        local rp is positionat(SHIP, tnot +eta) -BODY:POSITION.
        local vp is velocityat(SHIP, tnot +eta):ORBIT.
        if rp*vecto<0{
            set eta to eta+ship:orbit:period*0.123456789.
            set eta to modu(eta,ship:orbit:period).
        } else if vectorCrossProduct(vp,vecto):mag=0{
            set eta to eta+ship:orbit:period*0.123456789.//pseudoirrational
            set eta to modu(eta,ship:orbit:period).
        }else{
            //newtons method
            set eta to eta-vectorCrossProduct(rp,vecto)*vectorCrossProduct(vp,vecto)/vectorCrossProduct(vp,vecto):mag^2.
            set eta to modu(eta,ship:orbit:period).
            
        }
        diag("eta->"+eta).
    }
    diag("").
    return eta-(time:seconds-tnot).
    
}local function etaAscendingNode{parameter B is target. return etaNormalNode(B,+1).}
local function etaDescendingNode{parameter B is target. return etaNormalNode(B,-1).}
local function rel_inclination{
    parameter B is target.
    return etaNormalNode(B,1,true).

}

local function closest_approach{
    parameter T is target.
    parameter nd is nextnode.//dummy node
    parameter overflow is 10.
    from {local a is 0.} until a>overflow step {set a to a+1.} do{
        local dr is positionAt(ship,time:seconds+nd:eta)-positionAt(T,time:seconds+nd:eta).
        local dv is velocityAt(ship,time:seconds+nd:eta):orbit-velocityAt(T,time:seconds+nd:eta):orbit.
        if dr*dv=0 or dr:mag<50 {break.}
        set nd:eta to nd:eta-(dr*dv)/dv:sqrmagnitude.
        if nd:eta<=0 {set nd:eta to nd:eta+ship:orbit:period.}
    }
    return (positionAt(ship,time:seconds+nd:eta)-positionAt(T,time:seconds+nd:eta)):mag.
    //it may seem to not work but it seems to be better than the stock closest approach (it finds closer approaches)


}
local function closest_approach_flat{
    parameter T is target.
    parameter nd is nextnode.//dummy node
    parameter overflow is 10.
    local l is vcrs(T:position-T:body:position,T:velocity:orbit).
    from {local a is 0.} until a>overflow step {set a to a+1.} do{
        local dr is vectorExclude(L, positionAt(ship,time:seconds+nd:eta)-positionAt(T,time:seconds+nd:eta)).
        local dv is vectorExclude(L,velocityAt(ship,time:seconds+nd:eta):orbit-velocityAt(T,time:seconds+nd:eta):orbit).
        if dr*dv=0 or dr:mag<50 {break.}
        set nd:eta to nd:eta-(dr*dv)/dv:sqrmagnitude.
        if nd:eta<=0 {set nd:eta to nd:eta+ship:orbit:period.}
    }
    return vectorExclude(L,(positionAt(ship,time:seconds+nd:eta)-positionAt(T,time:seconds+nd:eta))):mag.
    //it may seem to not work but it seems to be better than the stock closest approach (it finds closer approaches)


}
local function m_matchInclination{
    parameter B is target.
    parameter soon is false.//if true, go for first node, else go for higher node.
    parameter before_exec is {parameter nod. return.}.
    local angle is rel_inclination(B).
    local eta_a is etaAscendingNode(B).
    local ttime_a is time:seconds.
    local eta_d is etaDescendingNode(B).
    local ttime_d is time:seconds.
    local ttime_ is 0.
    local LB is vcrs(B:position-B:body:position,B:orbit:velocity:orbit).
    local LS is vcrs(ship:position-ship:body:position,ship:orbit:velocity:orbit).
    diag ("angle: "+angle).
    //breakpoint("match incline."). //fixed
    local eta_ is 0.
    local a_d is 0.//not set yet
    //pick node
    local dva is 2*sin(angle/2)*velocityAt(ship,ttime_a+eta_a):orbit:mag.
    local dvd is 2*sin(angle/2)*velocityAt(ship,ttime_d+eta_d):orbit:mag.
    if soon {
        
        if eta_a<eta_d {
            if eta_a>dva*ship:mass/ship:maxThrust{
                set a_d to +1.set eta_ to eta_a. set ttime_ to ttime_a.
            }else {
                set a_d to -1.set eta_ to eta_d. set ttime_ to ttime_d.
            }
        }else if eta_d>dvd*ship:mass/ship:maxThrust {
            set a_d to -1.set eta_ to eta_d. set ttime_ to ttime_d.
        }else {
            set a_d to +1.set eta_ to eta_a. set ttime_ to ttime_a.
        }
    } else {
        if (positionat(ship,ttime_a+eta_a)-body:position):mag>
                (positionat(ship,ttime_d+eta_d)-body:position):mag {
            if eta_a>dva*ship:mass/ship:maxThrust{
                set a_d to +1.set eta_ to eta_a. set ttime_ to ttime_a.
            }else {
                set a_d to -1.set eta_ to eta_d. set ttime_ to ttime_d.
            }
        }else if eta_d>dvd*ship:mass/ship:maxThrust {
            set a_d to -1.set eta_ to eta_d. set ttime_ to ttime_d.
        }else {
            set a_d to +1.set eta_ to eta_a. set ttime_ to ttime_a.
        }
    }
    local vat is velocityAt(ship,ttime_+eta_):orbit.
    diag ("a_d: "+a_d).
    diag("vat: "+vat).
    local t_up is (positionAt(ship,ttime_+eta_)-ship:body:position):normalized.
    local vflat is (vat-t_up*(t_up*vat)):mag.
    //new code below
    local vf is vectorExclude(LB,vat):normalized*vat:mag.
    local rout is vcrs(vat,LS):normalized.
    diag("vflat: "+vflat).
    diag("LB:"+LB). //works for inSoi object
    diag("relVang:"+vang(vf,vat)).
    //local nd is node(ttime_+eta_,0,-a_d*vflat*sin(angle),vflat*(cos(angle)-1)*cos(asym)).
    local nd is node(ttime_+eta_,(vf-vat)*rout,-(vf-vat)*LS:normalized,(vf-vat)*vat:normalized).
    //left handed coords, normal is neg. L
    add nd.
    before_exec(nd).
    m_exec(nd).

}
local function trim_orbit {
    parameter apo.
    parameter per.
    parameter soon is false.
    local H_i_p is (ship:apoapsis+ship:body:radius)/(ship:periapsis+ship:body:radius).
    local H_i_a is 1/H_i_p.
    local H_f_p is (apo+ship:body:radius)/(per+ship:body:radius).
    local H_f_a is 1/H_f_p.
    local U_i_a is U(H_i_a).
    local U_i_p is U(H_i_p).

    //try pa-burn first
    local H_f_pa is (apo+ship:body:radius)/(ship:periapsis+ship:body:radius).
    local dv_pa is get_v_c(ship:body,ship:body:radius+periapsis)*abs(U(H_f_pa)-U_i_p)
            +get_v_c(ship:body,ship:body:radius+apo)*abs(U(H_f_a)-U(1/H_f_pa)).
    //try ap-burn next
    local H_f_ap is (per+ship:body:radius)/(ship:apoapsis+ship:body:radius).
    local dv_ap is get_v_c(ship:body,ship:body:radius+apoapsis)*abs(U(H_f_ap)-U_i_a)
            +get_v_c(ship:body,ship:body:radius+per)*abs(U(H_f_p)-U(1/H_f_ap)).
    local do_pa is (dv_pa<dv_ap).
    if soon {
        set do_pa to (eta:periapsis<eta:apoapsis).
    }
    if do_pa{
        local n1 is node(time:seconds+eta:periapsis,0,0,get_v_c(ship:body,ship:body:radius+periapsis)*(U(H_f_pa)-U_i_p)).
        add n1.
        add node(time:seconds+n1:eta+n1:orbit:period/2,0,0,get_v_c(ship:body,ship:body:radius+apo)*(U(H_f_a)-U(1/H_f_pa))).
    }else{
        local n1 is node(time:seconds+eta:apoapsis,0,0,get_v_c(ship:body,ship:body:radius+apoapsis)*(U(H_f_ap)-U_i_a)).
        add n1.
        add node(time:seconds+n1:eta+n1:orbit:period/2,0,0,get_v_c(ship:body,ship:body:radius+per)*(U(H_f_p)-U(1/H_f_ap))).
    }
    m_exec().m_exec().

}
set manuver:PHICRIT to 0.6.
//to make delagate to anonamous
//global manuverTo is {...}
set manuver:correction_time to 0.1.
local function dockApproach {
    parameter B.//is not a body
    parameter t.//encounter time
    parameter D is 100.//buffer arround craft

    print "docking approach".
    //breakpoint("docking_approach").
    local dv is velocityAt(ship,t):orbit-velocityAt(B,t):orbit.
    local dr is positionAt(ship,t)-positionAt(B,t).
    if dr:mag>2000 {
        //second correction
        local timeto is 0.
        local timetomnv is 0.7.
        local cnd is node((time:seconds*(1-timetomnv)+t*timetomnv),0,0,0).
        add cnd.
        local tempnode is Node(t,0,0,0).
        add tempnode.
        wait 0.
        m_opt(cnd,{return closest_approach(B,tempnode).}).
           //PULL extra args
            //TODO for a small moon like minmus, encounter can be easily lost, 
        m_exec(cnd,0.01,0.2).
        //set approach to closest_approach(B,tempnode).
        set t to tempnode:eta+time:seconds.
        diag("timeto-time: "+(timeto-time:seconds)).
        remove tempnode.
    
    }
    
    set dv to velocityAt(ship,t):orbit-velocityAt(B,t):orbit.
    set dr to positionAt(ship,t)-positionAt(B,t).
    diag("dtto: "+(t-time:seconds)).
    diag("dv: "+(dv:mag)).
    local ts is ship:mass/ship:maxThrust*dv:mag/2+
        (choose 0 if dr:mag>=D else sqrt(D^2-dr:sqrmagnitude))/dv:mag.
    diag("ts: "+ts).
    lock steering to -dv.
    local turnt is time:seconds.
    wait until vang(ship:facing:vector,dv)<0.1 or dv:mag<1 or time:seconds>turnt+10.
    warpto(t-ts-5).
    wait until time:seconds>t-ts-4.
    diag("dtto2: "+(t-time:seconds)).
    wait until warp=0.
    local quit is false.
    local tset is 0.
    local max_acc to ship:maxthrust/ship:mass.
    until quit {
        local rt is ship:position-B:position.
        local vt is ship:velocity:orbit-B:velocity:orbit.
        local rc is vectorexclude(vt,rt).
        local ts is ship:mass/ship:maxThrust*vt:mag/2+
        (choose 0 if rc:mag>=D else sqrt(D^2-rc:sqrmagnitude))/dv:mag.
        set max_acc to ship:maxthrust/ship:mass.
        set tset to min(vt:mag/max_acc, 1).
        local stop to (choose 1 if ts*vt:mag>(rt:mag-D-rc:mag) else 0).
        if rt:mag>D and ((rt:mag/vt:mag>ship:orbit:period*manuver:PHICRIT/20)or vt:mag<1){
            local crs is vectorExclude(rt,vt):mag/max(vt:mag,0.1).
            lock steering to -rt:normalized-rc:normalized*min(0.5,crs).
            lock throttle to tset.
        }
        else if (rc:mag>=D){
            local acrs is 2*rc:mag/max(ts*2,1)^2.
            if acrs>max_acc/2 {set acrs to max_acc/2.}
            lock steering to -vt:normalized-rc:normalized*(acrs/max_acc).
            lock throttle to min(tset*stop*sqrt(1+acrs^2/max_acc^2),1).
        }else {
            lock steering to -vt.
            lock throttle to tset*stop.
        } if (vt:mag<0.1 or ship:facing:vector*vt>0) and rt:mag<=D{
            set quit to true.
        }
        if vang(steeringManager:target:vector,ship:facing:vector)>10{
            lock throttle to 0.
        }

    }
    local vt to ship:velocity:orbit-B:velocity:orbit.
    lock steering to -vt.
    wait 10.
    local th is vt:mag/ship:maxThrust*ship:mass.
    if vt:mag>1{lock throttle to min(th,1).}
    wait until (ship:facing:vector*(ship:velocity:orbit-B:velocity:orbit)>0).
    lock throttle to 0.
    wait 1.
    unlock steering.
    unlock throttle.
    wait 1.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    set warpmode to "RAILS".
    set warp to 0.
    print "docking approach finished.".
    return true.
}
local ECC_CRIT is 0.3.//point where manuverTo chooses a new strategy for encounter
local function manuverTo{
    if hasnode until not hasNode{remove nextNode.}//clean slate
    //NODE(utime, radial, normal, prograde)
    //manuver into a circular orbit of height ht around body B
    parameter ht.
    parameter B is target.
    parameter d_ht is 2000.//uncertainty of 2km
    //set target to B.
    local B_isBody is (B:typename="Body").
    if (rel_inclination(B)>0.1){
        m_matchInclination(B).//TODO efficiency improvements
    }
    local v_ci is sqrt(ship:body:mu/ship:orbit:semimajoraxis).
    diag("v_ci="+v_ci).
    //ignore ecentricity and inclination and sphere changes
    local Hgt is (B:orbit:semimajoraxis)/ship:orbit:semimajoraxis.
    local dv is v_ci*(U(Hgt)-1).
    local burn_dur_est to dv/(ship:maxthrust/ship:mass).
    local PHI is ship:velocity:orbit:mag*burn_dur_est/ship:orbit:semimajoraxis.
    local nburns is max(floor(PHI/manuver:PHICRIT,0),1).
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
    
    local tempnode is Node(time:seconds+nd:eta+nd:orbit:period/2,0,0,0).
    add tempnode.//used as a dummy to find closest approach
    local function hasNext{//to prevent tempnode from messing this up
        return nd:orbit:transition="ENCOUNTER" or tempnode:orbit:transition="ENCOUNTER".
    }
    //T^2=4 pi^2 /mu * a^3
    //TODO split burn into parts
    local trans is (ship:orbit:semimajoraxis)^3/4/ship:body:mu*constant:pi^2.//approx
    local approach is "none".
    local deta is {
        //set approach to closest_approach(B,tempnode).
        set approach to (positionAt(ship,time:seconds+nd:eta+nd:orbit:period/2)
                -positionAt(B,time:seconds+nd:eta+nd:orbit:period/2)):mag.//apoapsis only
        local rad is max(choose B:soiradius if B_isBody else B:orbit:semimajoraxis/20,approach).
        
        return ship:orbit:period*(rad/B:orbit:semimajoraxis/10).
    }.//old: local deta is ship:orbit:period/1000.
    
    local break1 is {
        if not B_isBody {
            return choose false if approach="none" else (approach<B:orbit:semimajoraxis/20).
        }
        return (hasNext() and nd:orbit:nextpatch:body=B and nd:orbit:nextpatcheta<nd:orbit:period).
    }.
    local i_deta is 0.
    local radatvec is B:orbit:semimajoraxis.
    // local apo_op is {
    //     wait 0.
    //     local tovec is -(positionat(ship,time:seconds+nd:eta)-ship:body:position).
    //     set radatvec to getOrbitRadiusAtVec(B,tovec):mag.
    //     return nd:orbit:apoapsis+nd:orbit:body:radius-radatvec.
    // }.//TODO is slow and not really working, try using H,U local functions
    //m_opt(nd,apo_op,0,10,0.001,10).//TODO chaotic and not working
    local B_perivec is getPerapsisDirVec(B).//do this once, valid until coords change
    getApproxBurnTo(B,nd,B_perivec).//is very fast, no loops
    until break1()
    //and nd:orbit:nextpatch:periapsis>0 
    {
        multnode_changeEta(nds,deta()).
        set i_deta to i_deta +deta().
        getApproxBurnTo(B,nd,B_perivec).
        set tempnode:eta to nd:eta+nd:orbit:period/2.
        if i_deta>nd:orbit:period*0.1{
            set i_deta to 0.
            //m_opt(nd,apo_op,0,10,0.001,10).
        }
        //diag("deta: "+deta()).
    }
    
    if B_isBody {
        remove tempnode.
        //unset tempnode.
        wait 0.
        if not nd:orbit:hasnextpatch {
            print "Lost encouter on tempnode removal".
        }
    }
    
    print "Target perapsis: "+(ht).
    local pp is abs(nd:orbit:nextpatch:periapsis-ht).
    local ppsgn is nd:orbit:nextpatch:periapsis-ht.//perapsis is an altitude above sea level
    local loop is 0.
    local first is true.
    local function deta_2 {
        if B_isBody and nd:orbit:hasnextpatch{
            local rad is max(d_ht,min(B:soiradius,nd:orbit:nextpatch:periapsis-ht)).
            return ship:orbit:period*(rad/radatvec)/30.
        } else {
            set approach to closest_approach(B,tempnode).
        local rad is max(choose B:soiradius if B_isBody else B:orbit:semimajoraxis/200,
            approach).
        return ship:orbit:period*(rad/B:orbit:semimajoraxis/30).
        }
        
    }.
    local function farness{
        return choose (nd:orbit:nextpatch:periapsis-ht) if B_isBody and nd:orbit:hasnextpatch
                else approach.
    }
    until not nd:orbit:hasnextpatch
        //and nd:orbit:nextpatcheta<nd:orbit:period
    {
        if not B_isBody {
            set approach to closest_approach(B,tempnode).//maybe change
        }
        if abs(farness())>=pp and not first{
            diag("turnaround").
            //new code using m_opt()
            m_opt(nd,{return farness().}).
            break.
        }else if  abs(farness())<=d_ht
            or (farness())*(ppsgn)<0{
            diag("target perapsis hit.").
            break.
        }
        set pp to abs(farness()).
        set ppsgn to farness().
        
        //if(loop=0){diag("perapsis: "+nd:orbit:nextpatch:periapsis).wait 0.1.}
        //if(loop=0 and debug){print ("  perapsis: "+nd:orbit:nextpatch:periapsis)+"   " at(0,3).}
        multnode_changeEta(nds,deta_2()).
        set loop to Mod(loop+1,10).
        set first to false.
    }
    local prevpari is "null".
    local function stop {
        if not ship:orbit:hasnextpatch{return false.}
        //if not ship:orbit:transition="ENCOUNTER"{return false.}
        //ship:orbit:nextpatch is for the case of no manuver nodes, appearently
        diag("has encounter").
        local patch is ship:orbit:nextpatch.
        if (not prevpari="null") and (patch:periapsis-ht-d_ht>0) and (patch:periapsis>prevpari) {
            return true.
        }
        if abs(patch:periapsis-ht)<d_ht {return true.}
        if patch:periapsis<ht {return true.}//a bit more aggressive, maybe comment
        set prevpari to patch:periapsis.
        return false.
    }
    local function timewarp {
        return  not ship:orbit:hasnextpatch.
    }
    m_multexec(nds,timewarp@,choose stop@ if B_isBody else {return false.}).
    //if orbit is after a period or more, ksp will change its mind each frame whether it exists. check many frames
    //RAILS timewarp can freeze nextnode existance even if just activated for a little bit
    local apprtime is tempnode:eta+time:seconds.
    local etanextpatch is "none".
    local dv is 0.001.
    if not B_isbody {
        set approach to closest_approach(B,tempnode).
        remove tempnode. set etanextpatch to tempnode:eta.}
        //set dv to 0.0001.
    
    unset tempnode.
    local tempnode is node(time:seconds+ship:orbit:period*manuver:correction_time,0,0,0).
    add tempnode.
    local orbitmax is 10.
    print "docking used to diverge here".//it works up to this point
    if B_isbody from {local a is 0.} until tempnode:orbit:hasnextpatch step {set a to a+1.} do {
        set tempnode:eta to tempnode:eta+ship:orbit:period.
        if a>orbitmax {
            print "Loss of Encounter, could not recover in "+orbitmax+" orbits".
            return false.
        }
    }

    if B_isBody {set etanextpatch to ship:orbit:nextpatcheta.}//this is the correct form
    if etanextpatch>ship:orbit:period
    {
        warpto(time:seconds+(etanextpatch-ship:orbit:period*(0.5+manuver:correction_time))).
        wait until warp=0.
    }
    remove tempnode.
    unset tempnode.
    local nextpatch is "none".
    if B_isBody{set nextpatch to ship:orbit:nextpatch.}
    if B_isbody and not (nextpatch:body=B){
        local t is time:seconds+eta:transition.
        warpto(t).
        wait until time:seconds>t+1.
        set t to time:secods+eta:transition.
        warpto(t).
        wait until time:seconds>t+1.
    }
    local timeto is 0.
    if (choose (abs(nextpatch:periapsis-ht)>d_ht) if B_isBody else (approach>d_ht)){
        local timetomnv is choose manuver:correction_time if B_isBody else 0.2.
        local cnd is node(time:seconds+max(ship:orbit:period*manuver:correction_time,etanextpatch*(2*timetomnv)),0,0,0).
        add cnd.
        local tempnode is Node(time:seconds+eta:apoapsis,0,0,0).
        add tempnode.
        wait 0.
        local sovf is choose {
            if cnd:orbit:transition="ENCOUNTER" {
                //muns highest point is 7061m
                return (cnd:orbit:nextpatch:periapsis<7500).
            }return false.
        } if B_isBody else {return false.}.
        m_opt(cnd,{return choose cnd:orbit:nextpatch:periapsis-ht if cnd:orbit:transition="ENCOUNTER"//encounter what?
                else closest_approach(B,tempnode).},0,10,dv,100,sovf).
            //TODO for a small moon like minmus, encounter can be easily lost, 
        m_exec(cnd,0.01,0.2).
        set approach to closest_approach(B,tempnode).
        set timeto to tempnode:eta+time:seconds.
        diag("timeto-time: "+(timeto-time:seconds)).
        remove tempnode.
    }
    if not B_isBody {
        diag("time: "+time:seconds).
        diag("just timeto: "+timeto).
        return dockApproach(B,timeto).
    }
    breakpoint("encounter_user_override").
    //important: warpto does not also wait in program.
    warpto(time:seconds+ship:orbit:nextpatcheta).
    wait until warp=0.
    diag ("Target body: "+B:tostring()).
    diag ("Current body: "+ship:body:tostring()).
    wait until ship:orbit:body:tostring()=B:tostring().
    //cannot find eta's for a later patch
    local vi2 is velocityat(SHIP, time:seconds +eta:periapsis):orbit:mag.
    diag ("Entry eccentricity:="+ship:orbit:eccentricity).
    local Ul is U_e(ship:orbit:eccentricity).
    local nd2 is node(time:seconds+eta:periapsis,0,0,(1/Ul-1)*vi2).
    add nd2.
    m_exec().//(parameter is nd2)
    wait 3.
    diag("ht-dht: "+ (ht-d_ht)).
    diag("periapsis: "+ ship:periapsis).
    breakpoint("pre trim.").
    
    if ship:orbit:periapsis<(ht-d_ht) {
        print "correcting periapsis".
        if ship:orbit:trueanomaly<150 {
            warpto(time:seconds+eta:apoapsis).
            wait until eta:apoapsis>orbit:period()*0.7.
        }else if eta:periapsis<eta:apoapsis{
            lock steering to up.
            wait 10.
            lock throttle to 0.2.
            wait until eta:periapsis>eta:apoapsis.
            lock throttle to 0.
        }
        lock steering to prograde.
        
        wait 10.
        lock throttle to 0.2.
        wait until ship:orbit:periapsis>(ht-d_ht) or ((ship:periapsis+ship:apoapsis)>(2*ht+4*d_ht)).
        lock throttle to 0.
        if ship:orbit:periapsis<(ht-d_ht){
            warpto(time:seconds+eta:apoapsis).
            wait until eta:apoapsis>orbit:period()*0.7.
            lock steering to prograde.
            wait 10.
            lock throttle to 0.2.
            wait until ship:orbit:periapsis<(ht-d_ht) or ((ship:periapsis+ship:apoapsis)>(2*ht+10*d_ht)).
            lock throttle to 0.
        }
    }
    print "Manuvering to orbit arround "+dquote +B:tostring+dquote+" is finished.".
    return true.

}
local function manuverToApsi{
    //similar to manuverTo for eccentric initial orbits
    if hasnode until not hasNode{remove nextNode.}//clean slate
    //NODE(utime, radial, normal, prograde)
    //manuver into a circular orbit of height ht around body B
    parameter ht.
    parameter B is target.
    parameter d_ht is 2000.//uncertainty of 2km
    //set target to B.
    local B_isBody is (B:typename="Body").
    if (rel_inclination(B)>0.1){
        m_matchInclination(B).//TODO efficiency improvements
    }
    local v_ci is sqrt(ship:body:mu/(ship:orbit:periapsis+ship:body:radius)).
    diag("v_ci="+v_ci).
    //ignore ecentricity and inclination and sphere changes
    local tempnode is node(time:seconds+eta:periapsis,0,0,0).
    add tempnode.
    wait 0.
    local B_perivec is getPerapsisDirVec(B).
    local dv is getApproxBurnTo(B,tempnode,B_perivec).//good
    remove tempnode.
    wait 0.
    unset tempnode.
    local burn_dur_est to dv/(ship:maxthrust/ship:mass).
    local PHI is ship:velocity:orbit:mag*burn_dur_est/ship:orbit:semimajoraxis.
    local nburns is max(floor(PHI/manuver:PHICRIT,0),1).
    print ("making tangent burn in "+nburns+" sub burns.").
    local nds is list().//<node>; turns out kos does not use templates
    from {local i is 0. local et is eta:periapsis.} until (i>=nburns) step {set i to i+1.} do {
        diag("subburn:"+i).
        nds:add(node(time:seconds+et,0,0,dv/nburns)).
        add nds[i].
        set et to et+nds[i]:orbit:period.

    }
    diag(nds).
    
    local nd to nds[nds:length-1].//this does set by reference
    
    print "Target perapsis: "+(ht).
    
    m_multexec(nds).
    local apprtime is time:seconds+eta:apoapsis.
    if not (B_isbody and (ship:orbit:transition="ENCOUNTER") and (eta:transition<ship:orbit:period)){
        local maxOrbits is 5.
        //Perivec is unreliable if eccentricity = 0.
        local avec is positionAt(ship,time:seconds+eta:apoapsis)-ship:body:position.
        local tansgn is vcrs(B:orbit:position-B:orbit:body:position,B:orbit:velocity:orbit)
                *vcrs(B_perivec,avec).
        set tansgn to choose 1 if tansgn=0 else tansgn/abs(tansgn).
        local tan is tansgn*vang(B_perivec,avec).
        diag("tan:"+tan).
        local tap is time:seconds+modu(orbitTimeToAng(B:orbit,B:orbit:trueanomaly,tan),B:orbit:period).
        diag("tap:"+tap).
        //TODO if there is an early encounter
        local tms is list().
        local nmin is "none".
        from {local n is 0.}until n>=maxOrbits step {set n to n+1.} do{
            tms:add(modu(tap-time:seconds-eta:apoapsis-(n+1)*ship:orbit:period,B:orbit:period)).
            diag("tms").
            if nmin="none"{set nmin to n.}
            else if tms[nmin]>tms[n] {set nmin to n.}
        }
        diag(tms).
        local dp is tms[nmin]/(nmin+1).
        diag("dp:"+dp).
        local da is ((1+dp/ship:orbit:period)^(2/3)-1)*ship:orbit:semimajoraxis.
        local perf is ship:orbit:periapsis+2*da.
        //diag("perf:"+perf).
        local H0 is (ship:orbit:periapsis+ship:orbit:body:radius)/(ship:orbit:apoapsis+ship:orbit:body:radius).
        local Hf is (perf+ship:orbit:body:radius)/(ship:orbit:apoapsis+ship:orbit:body:radius).
        local vc0 is sqrt(ship:body:mu/(ship:orbit:apoapsis+ship:orbit:body:radius)).
        local anode is node(time:seconds+eta:apoapsis,0,0,vc0*(U(Hf)-U(H0))).
        add anode.
        m_exec(anode).
        //remove anode.//already removed
        set apprtime to time:seconds+ship:orbit:period*(nmin+1).
        warpto(apprtime-ship:orbit:period*(0.6)).//TODO one of the formulas is probably wrong
        wait 1.
        wait until time:seconds>apprtime-ship:orbit:period*(0.6).
        diag("orbsto: "+(apprtime-time:seconds)/ship:orbit:period).
        breakpoint("perimanuver_timewarp").

    }
    //if orbit is after a period or more, ksp will change its mind each frame whether it exists. check many frames
    //RAILS timewarp can freeze nextnode existance even if just activated for a little bit
    //local apprtime is tempnode:eta+time:seconds.
    
    local etanextpatch is "none".
    local dv is 0.001.
    if not B_isbody {
        //set approach to closest_approach(B,tempnode).
        //remove tempnode. set etanextpatch to tempnode:eta.}
        //set dv to 0.0001.
    }
    //unset tempnode.
    local tempnode is node(time:seconds+ship:orbit:period*manuver:correction_time,0,0,0).
    add tempnode.
    local orbitmax is 10.
    print "docking used to diverge here".//it works up to this point
    if B_isbody from {local a is 0.} until tempnode:orbit:hasnextpatch step {set a to a+1.} do {
        set tempnode:eta to tempnode:eta+ship:orbit:period.
        if a>orbitmax {
            print "Loss of Encounter, could not recover in "+orbitmax+" orbits".
            return false.
        }
    }

    if B_isBody {set etanextpatch to ship:orbit:nextpatcheta.}//this is the correct form
    //but bug: nextpatch may not exist
    if etanextpatch>ship:orbit:period
    {
        warpto(time:seconds+(etanextpatch-ship:orbit:period*(0.5+manuver:correction_time))).
        wait until warp=0.
    }
    remove tempnode.
    unset tempnode.
    local nextpatch is "none".
    if B_isBody{set nextpatch to ship:orbit:nextpatch.}
    if B_isbody and not (nextpatch:body=B){
        local t is time:seconds+eta:transition.
        warpto(t).
        wait until time:seconds>t+1.
        set t to time:secods+eta:transition.
        warpto(t).
        wait until time:seconds>t+1.
    }
    local timeto is 0.
    //TODO fix approach
    //local approach is "infinity".///========NEW
    if (choose (abs(nextpatch:periapsis-ht)>d_ht) if B_isBody else (approach>d_ht)){
        local timetomnv is choose manuver:correction_time if B_isBody else 0.2.
        local cnd is node(time:seconds+max(ship:orbit:period*manuver:correction_time,etanextpatch*(2*timetomnv)),0,0,0).
        add cnd.
        local tempnode is Node(time:seconds+eta:apoapsis,0,0,0).
        add tempnode.
        wait 0.
        local sovf is choose {
            if cnd:orbit:transition="ENCOUNTER" {
                //muns highest point is 7061m
                return (cnd:orbit:nextpatch:periapsis<7500).
            }return false.
        } if B_isBody else {return false.}.
        m_opt(cnd,{return choose cnd:orbit:nextpatch:periapsis-ht if cnd:orbit:transition="ENCOUNTER"//encounter what?
                else closest_approach(B,tempnode).},0,10,dv,100,sovf).
            //TODO for a small moon like minmus, encounter can be easily lost, 
        m_exec(cnd,0.01,0.2).
        set approach to closest_approach(B,tempnode).
        set timeto to tempnode:eta+time:seconds.
        diag("timeto-time: "+(timeto-time:seconds)).
        remove tempnode.
    }
    if not B_isBody {
        diag("time: "+time:seconds).
        diag("just timeto: "+timeto).
        return dockApproach(B,timeto).
    }
    breakpoint("encounter_user_override").
    //important: warpto does not also wait in program.
    warpto(time:seconds+ship:orbit:nextpatcheta).
    wait until warp=0.
    diag ("Target body: "+B:tostring()).
    diag ("Current body: "+ship:body:tostring()).
    wait until ship:orbit:body:tostring()=B:tostring().
    //cannot find eta's for a later patch
    local vi2 is velocityat(SHIP, time:seconds +eta:periapsis):orbit:mag.
    diag ("Entry eccentricity:="+ship:orbit:eccentricity).
    local Ul is U_e(ship:orbit:eccentricity).
    local nd2 is node(time:seconds+eta:periapsis,0,0,(1/Ul-1)*vi2).
    add nd2.
    m_exec().//(parameter is nd2)
    wait 3.
    print "Manuvering to orbit around "+dquote +B:tostring+dquote+" is finished.".
    return true.
}
local function plungeTo {//works, including changes to normalnode which now work SOI independantly
    if hasnode until not hasNode{remove nextNode.}//clean slate
    parameter ht.
    parameter d_ht is 2000.//uncertainty of 2km
    parameter circularize is false.
    
    local B is ship:body.
    local B_isBody is true.
    
    if (rel_inclination(B)>0.1){m_matchInclination(B).}//should work even for bodies not in same soi.
    local t is time:seconds+ship:orbit:period.
    local v_B is (B:velocity:orbit-B:body:velocity:orbit):mag.//orbit vel of moon around body
    local R_i is (B:position-B:body:position):mag.
    local sgn is (ht-R_i)/abs(ht-R_i).
    local v_B_c is sqrt(B:body:mu/(B:position-B:body:position):mag).
    local vf is v_B_c*(U((B:body:radius+ht)/R_i)-(V_B/v_B_c)).
    local nd is node(time:seconds+orbit:period,0,0,0).
    add nd.
    local upd is {
        getApproxBurnToVelocity(vf,nd).
    }.
    local opt is {
        return choose nd:orbit:nextpatch:periapsis if nd:orbit:transition="ESCAPE"
                else (B:soiradius-nd:orbit:apoapsis)*sgn+R_i.//not good but lets see
    }.
    
    upd().
    m_opt_eta(nd,opt,ht,upd).
    if not (nd:orbit:transition="ESCAPE") until (nd:orbit:transition="ESCAPE") {
        set nd:eta to nd:eta+ship:orbit:period.
        wait 0.
    }
    m_exec(nd).
    local t is time:seconds+eta:transition.
    warpto(t).
    wait until time:seconds>t+1.
    if (ship:orbit:transition="ENCOUNTER") and  (eta:transition<=eta:periapsis){
        until not(ship:orbit:transition="ENCOUNTER") and  not(eta:transition<=eta:periapsis){
            local tt is time:seconds+eta:transition.
            warpto(t).
            wait until time:seconds>t+1.
            set tt to time:seconds+eta:transition.
            warpto(t).
            wait until time:seconds>t+1.
        }
    }
    local cnd is node(time:seconds+eta:periapsis/2,0,0,0).
    add cnd.
    local opt2 is {return cnd:orbit:periapsis.}.
    wait 0.
    m_opt(cnd,opt2,ht).
    if cnd:deltav:mag<0.01 or abs(ship:orbit:periapsis-ht)<d_ht{remove cnd.}
    else {
        m_exec(cnd,0.01,0.2).
    }
    wait 0.
    if circularize {
        local vi2 is velocityat(SHIP, time:seconds +eta:periapsis):orbit:mag.
        diag ("Entry eccentricity:="+ship:orbit:eccentricity).
        local Ul is U_e(ship:orbit:eccentricity).
        local nd2 is node(time:seconds+eta:periapsis,0,0,(1/Ul-1)*vi2).
        add nd2.
        m_exec(nd2).//(parameter is nd2)
        wait 3.
    }
    print "plunge manuver from "+B:name+" to periapsis of "+ship:orbit:periapsis+" above "+ship:body:name+" complete.".

}
local function toPlanet {
    ///now depends on smartboot; bootlex["toPlanet"]=entercode
    //set lex["new"] to 123. can create new index
    //writeJson overwrites old elements so try:
    parameter B.
    parameter ht is 80000.
    parameter dht is 5000.
    parameter JustGetTime is false.
    parameter entercode is -1.//-1 will serialize args
    parameter targetApoRad is (B:radius+ht).
    parameter targetPlane is "None".
        //can be: string (None), body (moon), scalar (inclination degrees)
    //print time:seconds+min(etaAscendingNode(B),etaDescendingNode(B)).
    parameter bootlex is readJson("1:/bootstrap.json").
    //function serializes args
    local argsModif is true.
    if entercode<=-1{
        set entercode to 0.
        if argsModif {
            if (B:body <> ship:body:body) and 
            (B:body:body = ship:body:body){
                print "target is a moon.".
                print "targeting orbital plane of: "+B.
                set targetPlane to B.
                set B to B:body.
                set targetApoRad to max(B:radius+targetPlane:orbit:periapsis,targetApoRad).
                set targetApoRad to min(B:radius+targetPlane:orbit:apoapsis,targetApoRad).
                //set targetApoRad to B.//needs additional snippet at end
            }
        }
        set bootlex["toPlanet_ht"] to ht.
        set bootlex["toPlanet_B"] to B.
        set bootlex["toPlanet_dht"] to dht.
        set bootlex["toPlanet_targetApoRad"] to targetApoRad.
        set bootlex["toPlanet"] to entercode.
        set bootlex["toPlanet_targetPlane"] to targetPlane.
        //writeJson(bootlex,"1:/bootstrap.json").
        //TODO NEW
        set entercode to -0.5.
        set bootlex["toPlanet"] to entercode.
        save().
    }else{
        set ht to bootlex["toPlanet_ht"].
        set B to bootlex["toPlanet_B"].
        set dht to bootlex["toPlanet_dht"].
        //dont set retcode
        set targetApoRad to bootlex["toPlanet_targetApoRad"].
        set targetPlane to bootlex["toPlanet_targetPlane"].
    }
    //diag(targetPlane).
    //diag(targetPlane:typename).
    local planeFlag is 0.
    if (targetPlane:typename="Body"){
        set planeFlag to 1.
        diag("targetPlane body").
        if((targetPlane:body <> B) and (targetPlane <> B)){
            print "body: "+targetPlane+" is not, or not a moon of: "+B.
            return.
        }
    }
    else if (targetPlane:typename <> "String"){
        diag("targetPlane inclination").
        set planeFlag to 2.
    }
    if entercode<=-0.5{
        //correct inclination
        local inc_critical is 0.5.
        //  check if inclination is off by more than this angle, but may be retrograde
        local relinc is abs(rel_inclination(ship:body)).
        if abs(180-relinc)<relinc {set relinc to abs(180-relinc).}
        print "inclination is off by: "+relinc.
        if (abs(rel_inclination(ship:body))>0.5){
            print "   (off enough to correct)".
            m_matchInclination(ship:body).
        }else {print "   (negligable)".}
        set entercode to 0.
        set bootlex["toPlanet"] to entercode.
        save().
    }
    if entercode<=0{
    
    //set bootlex["toPlanet_ht"] to ht.
    //set bootlex["toPlanet_dht"] to dht.
    //set bootlex["toPlanet_targetApoRad"] to targetApoRad.
    //set bootlex["toPlanet"] to entercode.
    //set bootlex["toPlanet_targetPlane"] to targetPlane.
    //writeJson(bootlex,"1:/bootstrap.json").
    save().
    local tm is getTransferTime(ship:body,B).
    local nd is 0.
    if hasNode and not JustGetTime{
        set nd to nextNode.
        set tm to nextnode:eta+time:seconds.
    }else {
        set nd to node(tm,0,0,0).
        add nd.
    }
    if JustGetTime {
        return true.//for use by humans
    }
    wait until warp=0.
    if time:seconds<tm {warpto(tm). wait until time:seconds>tm.}//depends on boot planet_test.
    diag("ready to eject from planet").
    local S is ship:body:body.
    local dvf is getBurnToPlanet(ship:body,B,tm).
    local psgn is dvf/abs(dvf).
    local lship is vcrs(ship:position-ship:body:position,ship:velocity:orbit).
    diag("dvf: "+dvf).
    getApproxBurnToVelocity(dvf,nd).
    from {local i is 0.} until i>=3 step {set i to i+1.} do{//works now
        if not nd:orbit:transition="ESCAPE" until nd:orbit:transition="ESCAPE"{//avoid moon encounters
            diag("skiporbit.").
            set nd:eta to nd:eta+ship:orbit:period. wait 0.
        }
        local Ang0 is vang(velocityAt(ship,time:seconds+nd:orbit:nextpatcheta-0.1):orbit,
            psgn*velocityAt(ship:body,time:seconds+nd:orbit:nextpatcheta-0.1):orbit).
        if vcrs(velocityAt(ship,time:seconds+nd:orbit:nextpatcheta-0.1):orbit,
            psgn*velocityAt(ship:body,time:seconds+nd:orbit:nextpatcheta-0.1):orbit)*lship<0 {
                set Ang0 to -Ang0.
        }
        diag("Ang0: "+Ang0).
        //local deta is choose ship:orbit:period*Ang0/360 if dvf>0 else ship:orbit:period*(Ang0-180)/360.
        local deta is ship:orbit:period*Ang0/360.
        set nd:eta to nd:eta+deta.
        if nd:eta<=0 {set nd:eta to nd:eta+ship:orbit:period.}
        wait 0.
    }
    //exit first, optimize later

    m_exec(nd).
    if not (ship:orbit:transition="FINAL") until (ship:orbit:transition="ESCAPE") and (orbit:nextpatch:body=B:body) {
        warpTo(time:seconds+orbit:nextpatcheta+1).
    }else {
        print "failed to escape".
        return 1.
    }
    warpTo(time:seconds+orbit:nextpatcheta+1).
    wait until warp=0.
    wait until ship:body=B:body.
    
    unset nd.
    }
    local nd is Node(time:seconds+1000,0,0,0).
    local dnd is 0.
    if entercode<=0{
    add nd.
    set dnd to node(time:seconds+ship:orbit:period/2,0,0,0).
    add dnd.
    }else if allnodes:length=2{
        set nd to allNodes[0].
        set dnd to allNodes[1].
    }else if allnodes:length>=1{
        set dnd to nextnode.
    }else {
        //entering from other manuvering function
        set dnd to node(time:seconds+ship:orbit:period/2,0,0,0).
        add dnd.
    }
    
    if entercode<=0 {
    //writeJson(lexicon("toPlanet",1),"1:/bootstrap.json").
    closest_approach_flat(B,dnd).
    local opt is {
        if nd:orbit:transition="ENCOUNTER"{
            return (nd:orbit:nextpatch:periapsis-ht)^2.
            //ignore inclination here
        }else{
            return (closest_approach_flat(B,dnd)-B:radius-ht)^2.
        }
    }.
    m_opt_pro(nd,opt,"min",1).
    m_exec(nd,0.01,0.5).
    diag("B:"+B).
    //begin new code TODO test ===
    //TODO may want to consider having this before closest_approach_flat
    set entercode to 0.5.
    set bootlex["toPlanet"] to entercode.
    save().
    //====end new
    }
    

    local opt2 is {
        parameter nd.//can also bind ship!!! yay
        if nd:orbit:transition="ENCOUNTER"{
            //TODO test inclination: try +(vang((nextpatch:inclination-tgtinc)/60)*(nextpatch:periapsis+B:radius))^2
            // or +((nextpatch angular momentum) cross (target ang momentum))^2
            local o is (nd:orbit:nextpatch:periapsis-ht)^2.
            
            if(planeFlag=1){
                local dang is 30.//old 50
                local tim is nd:orbit:nextpatcheta+time:seconds+5.
                
                local l1 is vcrs(targetPlane:position-targetPlane:body:position,
                    targetPlane:velocity:orbit-targetPlane:body:velocity:orbit):normalized().
                local angmin is 90-vang(velocityAt(ship,tim):orbit,
                    l1). set angmin to abs(angmin).
                //local lp is vcrs(positionAt(ship,tim)-positionAt(B,tim),
                //    velocityAt(ship,tim):orbit):normalized().
                local lp is v(cos(nd:orbit:nextpatch:lan)*sin(nd:orbit:nextpatch:inclination),
                sin(nd:orbit:nextpatch:lan)*sin(nd:orbit:nextpatch:inclination),
                cos(nd:orbit:nextpatch:inclination)).
                local l is v(cos(targetPlane:orbit:lan)*sin(targetPlane:orbit:inclination),
                sin(targetPlane:orbit:lan)*sin(targetPlane:orbit:inclination),
                cos(targetPlane:orbit:inclination)).
                set o to o+(max(0,vang(l,lp)-angmin)/dang)^2*(nd:orbit:nextpatch:periapsis+B:radius)^2.
            }else if(planeFlag=2){
                local dang is 30.
                local tim is nd:orbit:nextpatcheta+time:seconds+5.
                
                local ang is 90-vang(velocityAt(ship,tim):orbit,
                    v(0,1,0)). set ang to abs(ang).
                if (targetPlane>ang){set ang to targetPlane.}
                set o to o+(nd:orbit:nextpatch:periapsis+B:radius)^2
                *((modsym(ang-nd:orbit:nextpatch:inclination,360))/dang)^2.
                //is a problem for 
            }
            return o.
        }else{
            return (closest_approach(B,dnd)-B:radius-ht)^2.
        }
    }.
    //https://github.com/KSP-KOS/KOS/issues/2087
    //seem to be getting a C# error here
    //Object reference does not set to an instance of an object
    //At: 1079:    local norm_t is ..... B:body:orbit:position,...
    //FIXED      
    //NEW code TODO test =====
    
    if entercode<=0.5 {
    
    //end new, begin OLD
    //if entercode<=0 { 
    //end OLD
    //writeJson(lexicon("toPlanet",1),"1:/bootstrap.json").
    local normtime is time:seconds+min(etaAscendingNode(B),etaDescendingNode(B)).
    if normtime<(choose orbit:nextpatcheta if (orbit:transition="ENCOUNTER") else (time:seconds+dnd:eta)) {
        //TODO on m_exec, power is lost and reboot is done wrong.
        m_matchInclination(B,true,{parameter nod.
            m_opt(nod,opt2:bind(nod),"min",1).
            set bootlex["toPlanet"] to 1.
            //writeJson(bootlex,"1:/bootstrap.json").
            save().
        }).
    }
    }
    if entercode=1 {
    //writeJson(lexicon("toPlanet",1),"1:/bootstrap.json").
        m_exec(nextNode).
        if entercode<=0.5 {//NEW 0.0 -> 0.5
            set bootlex["toPlanet"] to 2.
            //writeJson(bootlex,"1:/bootstrap.json").
            save().
    }
    }
    if (entercode<=2) and (allNodes:length=2){
        m_exec(nextnode,0.01,0.3).
    }
    if (entercode<2) {
        set bootlex["toPlanet"] to 2.
        //writeJson(bootlex,"1:/bootstrap.json").
        save().
    }
    if (entercode<=2) until (ship:orbit:transition="ENCOUNTER") and (opt2:bind(ship)()<dht^2){
        local cnd is node(time:seconds+
            (choose ship:orbit:nextpatcheta if ship:orbit:transition="ENCOUNTER" else dnd:eta)
            *0.7,0,0,0).
        add cnd.
        m_opt(cnd,opt2:bind(cnd),"min",0.3).//BOOKMARK last crash, from not adding node
        m_exec(cnd,0.01,0.3).
    }
    set bootlex["toPlanet"] to 3.
    //writeJson(bootlex,"1:/bootstrap.json").
    save().
    if (warp=0) warpTo(time:seconds+orbit:nextpatcheta+1).
    wait until warp=0.
    wait until ship:body=B.
    remove dnd.
    local vi2 is velocityat(SHIP, time:seconds +eta:periapsis):orbit:mag.
    diag ("Entry eccentricity:="+ship:orbit:eccentricity).
    local Ul is U_e(ship:orbit:eccentricity).
    local U_f is U(targetApoRad/(B:radius+ship:periapsis)).//1.0 for a circle
    local nd2 is node(time:seconds+eta:periapsis,0,0,(U_f/Ul-1)*vi2).
    add nd2.
    m_exec().//(parameter is nd2)
    //TODO correct for moon encounters
    //maybe add another powerout check here
    //now correct soon: ~14 m/s

}
local function toPlanetFromMoon {
    //will run toPlanet with a high enter code at some point
    parameter B.
    parameter ht is 80000.
    parameter dht is 5000.
    parameter JustGetTime is false.
    parameter entercode is -1.//-1 will serialize args
    parameter targetApoRad is (B:radius+ht).
    parameter targetPlane is "None".
        //can be: string (None), body (moon), scalar (inclination degrees)
    //print time:seconds+min(etaAscendingNode(B),etaDescendingNode(B)).
    parameter bootlex is readJson("1:/bootstrap.json").
    //TODO, chech eccentricity and see if it is better to enter a parking orbit instead.
    local argsModif is true.
    if entercode<=-1{
        set entercode to 0.

        if argsModif {
            if (B:body = ship:body:body) {
                //ship is not orbiting a moon
                print "function toPlanetFromMoonDirect used wrongly when orbiting a planet".
                return.
            }else if (B:body <> SUN) if((B:body:body = ship:body:body)){
                //ship is not orbiting a moon
                print "function toPlanetFromMoonDirect used wrongly when orbiting a planet".
                return.
            }
            if (B:body <> ship:body:body:body) and 
            (B:body:body = ship:body:body:body){
                print "target is a moon.".
                print "targeting orbital plane of: "+B.
                set targetPlane to B.
                set B to B:body.
                set targetApoRad to max(B:radius+targetPlane:orbit:periapsis,targetApoRad).
                set targetApoRad to min(B:radius+targetPlane:orbit:apoapsis,targetApoRad).
                //set targetApoRad to B.//needs additional snippet at end
            }
        }
        set bootlex["toPlanet_ht"] to ht.
        set bootlex["toPlanet_B"] to B.
        set bootlex["toPlanet_dht"] to dht.
        set bootlex["toPlanet_targetApoRad"] to targetApoRad.
        set bootlex["toPlanet"] to entercode.
        set bootlex["toPlanet_targetPlane"] to targetPlane.
        //writeJson(bootlex,"1:/bootstrap.json").
        set entercode to -0.5.
        set bootlex["toPlanet"] to entercode.
        
        save().
    }else{
        set ht to bootlex["toPlanet_ht"].
        set B to bootlex["toPlanet_B"].
        set dht to bootlex["toPlanet_dht"].
        //dont set retcode
        set targetApoRad to bootlex["toPlanet_targetApoRad"].
        set targetPlane to bootlex["toPlanet_targetPlane"].
    }
    //diag(targetPlane).
    //diag(targetPlane:typename).
    local planeFlag is 0.
    if (targetPlane:typename="Body"){
        set planeFlag to 1.
        diag("targetPlane body").
        if((targetPlane:body <> B) and (targetPlane <> B)){
            print "body: "+targetPlane+" is not, or not a moon of: "+B.
            return.
        }
    }
    else if (targetPlane:typename <> "String"){
        diag("targetPlane inclination").
        set planeFlag to 2.
    }
    if entercode<=-0.5{
        //correct inclination
        local inc_critical is 0.5.
        //  check if inclination is off by more than this angle, but may be retrograde
        local relinc is abs(rel_inclination(ship:body)).
        if abs(180-relinc)<relinc {set relinc to abs(180-relinc).}
        print "inclination is off by: "+relinc.
        if (abs(rel_inclination(ship:body))>0.5){
            print "   (off enough to correct)".
            m_matchInclination(ship:body).
        }else {print "   (negligable)".}
        set entercode to 0.
        set bootlex["toPlanet"] to entercode.
        save().
    }
    if entercode=0{
        local A is ship:body:body.//the planet ejecting from
        save().
        if (not hasNode){
            print "matching moon's orbital plane".
            //m_matchInclination(ship:body).//skip for now
        }
        local eject_angle_resolution is ship:orbit:period / ship:body:orbit:period * 360.0.
        local tm is getTransferTime(A,B) -ship:body:orbit:period.
        local incoming_resolution_factor is 
            getIncomingResolutionCoefficient(A,B,ship:orbit:period).
        print "outgoing angle: +-"+eject_angle_resolution+" deg".
        print "incoming approach / soiradius: +-"+incoming_resolution_factor.
        if hasNode{
            set nd to nextNode.
            set tm to nextnode:eta+time:seconds.
        }else {
            set nd to node(tm,0,0,0).
            add nd.
        }
        wait until warp=0.
        local warttotime is tm.
        //set warttotime to tm-ship:body:orbit:period/2.//definetly breaks things for mysterious reasons
        //ignore, works fine without above line
        if time:seconds<warttotime {warpto(warttotime). wait until time:seconds>warttotime.}//depends on boot planet_test.
        diag("ready to eject from planet").
        //tweak node
        local S is A:body.
        local M is ship:body.//moon
        local dvf is getBurnToPlanet(A,B,tm).
        local psgn is dvf/abs(dvf).
        local lmoon is vcrs(A:position-A:body:position,A:velocity:orbit).
        diag("dvf: "+dvf).
        local willDive is shouldDive(dvf,M).
        diag ("shouldDive: "+willDive).
        local divesign is choose -1.0 if willDive else 1.0.
        local  divenode is "none".
        set  divenode to choose node(time:seconds+M:orbit:period/5,0,0,0) if willDive else "none".
        if not willDive {
            local vfmoon is getApproxBurnToVelocityRet(dvf,ship:body,tm).
            //eject velocity from moon
            getApproxBurnToVelocity(vfmoon,nd).//from orbit around moon
            lockEtaToParallelEjection(nd,divesign).
        }else {
            getApproxBurnsToVelocityDive(dvf,nd,divenode).
            lockEtaToParallelEjection(nd,divesign).
            if allNodes:length <2 {add divenode.}
            else {set divenode to allNodes[1]. }
            if divenode:orbit:body = M {set divenode:eta to divenode:eta+M:orbit:period/5. }
            local tp is TimeOfNextPeriapsis(nd:orbit:nextpatch).
            set divenode:eta to tp-time:seconds.

            //TODO pre-optimize periapsis as it is quite a bit off usually. resulting angle changes a lot
        }
        
        //TODO ecentricity corrections, but test first
        local effectivePeriod is (ship:orbit:period*M:orbit:period)/(M:orbit:period-ship:orbit:period).//planetary period, analogous to sidereal day -> solar day
        local effectivePeriodMoon is (M:orbit:period*A:orbit:period)/(A:orbit:period-M:orbit:period).//planetary period, analogous to sidereal day -> solar day
        local optDive is {
                //will neeed changes if plunging
                if not nd:orbit:transition="ESCAPE"{
                    return M:soiradius-nd:orbit:apoapsis.
                }
                if not nd:orbit:nextpatch:hasNextPatch{
                    return M:soiradius-nd:orbit:apoapsis.
                }if nd:orbit:nextPatch:transition="CAPTURE"{
                    //just ignore and hope.
                }
                return nd:orbit:nextpatch:periapsis.
                //return velocityAt(ship,nd:orbit:nextpatch:nextpatch:epoch-1):orbit
                //*velocityAt(A,nd:orbit:nextpatch:nextpatch:epoch-1):orbit:normalized.//component
            }.
        if willdive {m_opt_pro(nd,optDive,getLowestSafeOrbit(A),2,0.001,10). }
        from {local i is 0.} until i>=10 step {set i to i+1.} do{//works now
            //breakpoint("angle opt").
            if nd:orbit:nextpatch:transition="CAPTURE" until not nd:orbit:nextPatch:transition="CAPTURE"{//avoid moon encounters
                diag("skiporbit.").
                //should maintain a lock
                set nd:eta to nd:eta+effectivePeriod. wait 0.
                lockEtaToParallelEjection(nd,divesign).
                if willDive {
                    m_opt_pro(nd,optDive,getLowestSafeOrbit(A),2,0.001,10). 
                    if divenode:orbit:body = M {set divenode:eta to divenode:eta+M:orbit:period/5. }
                    local tp is TimeOfNextPeriapsis(nd:orbit:nextpatch). set divenode:eta to tp-time:seconds. }
            }
            local Ang0 is choose vang(velocityAt(ship,time:seconds+divenode:orbit:nextpatcheta-0.1):orbit,
                psgn*velocityAt(A,time:seconds+divenode:orbit:nextpatcheta-0.1):orbit)
                if willDive else
                vang(velocityAt(ship,time:seconds+nd:orbit:nextpatch:nextpatcheta-0.1):orbit,
                psgn*velocityAt(A,time:seconds+nd:orbit:nextpatch:nextpatcheta-0.1):orbit).
            
            if vcrs(velocityAt(ship,time:seconds+nd:orbit:nextpatch:nextpatcheta-0.1):orbit,
                psgn*velocityAt(A,time:seconds+nd:orbit:nextpatch:nextpatcheta-0.1):orbit)*lmoon<0 {
                    set Ang0 to -Ang0.
            }
            diag("Ang0: "+Ang0).
            //local deta is choose ship:orbit:period*Ang0/360 if dvf>0 else ship:orbit:period*(Ang0-180)/360.
            local deta is M:orbit:period*Ang0/360.
            //keep orbit locked
            set deta to round(deta/effectivePeriod)*effectivePeriod*(-psgn).
            if deta=0 {break.}//or
            set nd:eta to nd:eta+deta.
            if willDive { 
                m_opt_pro(nd,optDive,getLowestSafeOrbit(A),2,0.001,10). 
                if divenode:orbit:body = M {set divenode:eta to divenode:eta+M:orbit:period/5. }
                local tp is TimeOfNextPeriapsis(nd:orbit:nextpatch). set divenode:eta to tp-time:seconds. }
            diag("eta: "+nd:eta).
            if nd:eta<=0 {
                //commmented lines could break it
                //something always goes wrong when eta is in future
                //works when this is gone and no alternate timewarp
                //set nd:eta to nd:eta+ship:orbit:period.//TODO is wrong
                
                set deta to round(effectivePeriodMoon/effectivePeriod)*effectivePeriod.
                set nd:eta to nd:eta+deta.
                if willDive {
                    m_opt_pro(nd,optDive,getLowestSafeOrbit(A),2,0.001,10). 
                    if divenode:orbit:body = M {set divenode:eta to divenode:eta+M:orbit:period/5. }
                    local tp is TimeOfNextPeriapsis(nd:orbit:nextpatch). set divenode:eta to tp-time:seconds. }
                //works
            }
            wait 0.
        }
        //for hyperbolic orbits, meanAnomaly seems to behave analytically (como de sine to sinh);
        //exit moon first, optimize later
        //local nextOrbitPeriapsisTime is TimeOfNextPeriapsis(nd:orbit:nextPatch).//use for plunge next eta
        //IMPORTANT: trueAnomaly is angle-based, meanAnomaly is time based (out of 360)
        //sould optimize first
        print "target vf:"+dvf.
        print "achieved vf magnitude"+velocityAt(ship,nd:orbit:nextpatch:nextpatch:epoch-1):orbit:mag.
        print "achieved vf component"+velocityAt(ship,nd:orbit:nextpatch:nextpatch:epoch-1):orbit
            *velocityAt(A,nd:orbit:nextpatch:nextpatch:epoch-1):orbit:normalized.
            //a small difference (both): seems to be off both ways depending on run, sometimes a lot.
            //delta vv 
        //breakpoint("eject soon").
        if not willDive {
            local optEject is {
                if not nd:orbit:transition="ESCAPE"{
                    return M:soiradius-nd:orbit:apoapsis.
                }
                if not nd:orbit:nextpatch:hasNextPatch{
                    return M:soiradius-nd:orbit:apoapsis.
                }if nd:orbit:nextPatch:transition="CAPTURE"{
                    //return velocityAt(ship,nd:orbit:nextpatch:nextpatch:nextpatch:nextpatch:epoch-1):orbit
                //*velocityAt(A,nd:orbit:nextpatch:nextpatch:nextpatch:nextpatch:epoch-1):orbit:normalized.//component
                    return choose getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch))
                    -nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch:periapsis-nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch:body:radius
                        if psgn<0 else
                        getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch))
                    -nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch:apoapsis-nd:orbit:nextPatch:nextPatch:nextPatch:nextPatch:body:radius.
                }
                return choose getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,nd:orbit:nextPatch:nextPatch))
                    -nd:orbit:nextPatch:nextPatch:periapsis-nd:orbit:nextPatch:nextPatch:body:radius
                    If psgn<0 else
                    getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,nd:orbit:nextPatch:nextPatch))
                    -nd:orbit:nextPatch:nextPatch:apoapsis-nd:orbit:nextPatch:nextPatch:body:radius.
                //return velocityAt(ship,nd:orbit:nextpatch:nextpatch:epoch-1):orbit
                //*velocityAt(A,nd:orbit:nextpatch:nextpatch:epoch-1):orbit:normalized.//component
            }.
            //m_opt_pro(nd,optEject,dvf).//a good start, but doesn't account for periapsis dir-vec.
            m_opt_pro(nd,optEject,0,30).
        } else {
            
            m_opt_pro(nd,optDive,getLowestSafeOrbit(A),5).
        }
        

        //TODO add orbitHeightInDirVec using trueAnomaly / mean Anomaly, change optEject
        m_exec(nd).
        //breakpoint("moon ejecting").
        warpTo(time:seconds+eta:transition).
        wait until ship:body=M:body.
        wait 2.
        if willDive {
            local inc_critical is 0.5.
            //  check if inclination is off by more than this angle, but may be retrograde
            local relinc is abs(rel_inclination(ship:body)).
            if abs(180-relinc)<relinc {set relinc to abs(180-relinc).}
            print "inclination is off by: "+relinc.
            if (abs(rel_inclination(ship:body))>0.5){
                print "   (off enough to consider correcting, TODO)".
                //m_matchInclination(ship:body). //TODO
            }else {print "   (negligable)".}
            //inclination adjusting on exit is beyond this scripts pay grade
            print "correcting divenode".
            set divenode:eta to eta:periapsis.
            local optEjectDive is {
                if divenode:orbit:transition="CAPTURE"{
                    //return velocityAt(ship,nd:orbit:nextpatch:nextpatch:nextpatch:nextpatch:epoch-1):orbit
                //*velocityAt(A,nd:orbit:nextpatch:nextpatch:nextpatch:nextpatch:epoch-1):orbit:normalized.//component
                    return choose getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,divenode:orbit:nextPatch:nextPatch:nextPatch))
                    -divenode:orbit:nextPatch:nextPatch:nextPatch:periapsis-divenode:orbit:nextPatch:nextPatch:nextPatch:body:radius
                        if psgn<0 else
                        getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,divenode:orbit:nextPatch:nextPatch:nextPatch))
                    -divenode:orbit:nextPatch:nextPatch:nextPatch:apoapsis-divenode:orbit:nextPatch:nextPatch:nextPatch:body:radius.
                }
                if not divenode:orbit:transition="ESCAPE"{
                    return A:soiradius-divenode:orbit:apoapsis.
                }
                if not divenode:orbit:hasNextPatch{
                    return A:soiradius-divenode:orbit:apoapsis.
                }
                return choose getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,divenode:orbit:nextPatch))
                    -divenode:orbit:nextPatch:periapsis-divenode:orbit:nextPatch:body:radius
                    If psgn<0 else
                    getOrbitRadiusAtVec(B,-psgn*getPerapsisDirVecOfLaterPatch(ship,divenode:orbit:nextPatch))
                    -divenode:orbit:nextPatch:apoapsis-divenode:orbit:nextPatch:body:radius.
                //return velocityAt(ship,nd:orbit:nextpatch:nextpatch:epoch-1):orbit
                //*velocityAt(A,nd:orbit:nextpatch:nextpatch:epoch-1):orbit:normalized.//component
            }.
            //m_opt_pro(nd,optEject,dvf).//a good start, but doesn't account for periapsis dir-vec.
            m_opt_pro(divenode,optEjectDive,0,30).
            m_exec(divenode).
        }

        warpTo(time:seconds+eta:transition).
        wait until ship:body=A:body.
        wait 1.
        //new enter code
        //set entercode to 1.//TODO tweak
        //set bootlex["toPlanet"] to 1.
        //save().
        //TOOD invoke ToPlanet with enter code 0, but skip to m_matchInclination step,
        // may need to add a new entercode of 1.5 to toPlanet
        set entercode to 0.5.
        set bootlex["toPlanet"] to entercode.
        save().
        
    }
    //entercode >=0.5
    //call with same bootlex, behave as if same functionp
    toPlanet(B,ht,dht,JustGetTime,entercode,targetApoRad,targetPlane,bootlex).
}
local function testpatch {
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
    //clearScreen.
    //print "Listmax:="+m_util_max(list(1,2,3,4,5)).
    
    //ship is a Vessel, mun is a Body. TODO add support for docking manuvers
}
//even though we dont have to do this, it is a good idea because we can rename then to avoid nameing conflicts
//all of these shoud have a prefix manuver_ (could later change to m_ but m_exec already uses it. maybe mnv_)
//below will soon be depricated
local function depricate{
    parameter old.
    parameter new.
    parameter dummy1 is 0.
    parameter dummy2 is 0.
    parameter dummy3 is 0.
    parameter dummy4 is 0.
    parameter dummy5 is 0.
    parameter dummy6 is 0.
    parameter dummy7 is 0.
    parameter dummy8 is 0.
    parameter dummy9 is 0.
    parameter dummy10 is 0.
    parameter dummy11 is 0.
    print "===function "+old+" is no longer valid, use "+new+" instead===".
    print 1/0.//force crash    
}
global manuver_toInSOI is depricate@:bind("manuver_toInSOI","manuver:toInSOI").
global manuver_plungeFromSOI is depricate@:bind("manuver_plungeFromSOI","manuver:plungeFromSOI").
global manuver_trimOrbit is depricate@:bind("manuver_trimOrbit","manuver:trimOrbit").
global manuver_matchInclination is depricate@:bind("manuver_matchInclination","manuver:matchInclination").
global manuver_getTransferTime is depricate@:bind("manuver_getTransferTime","manuver:getTransferTime").
global manuver_toPlanet is depricate@:bind("manuver_toPlanet","manuver:toPlanet").
global manuver_toPlanetFromMoonDirect is depricate@:bind("manuver_toPlanetFromMoonDirect","manuver:toPlanetFromMoonDirect").

//already declared manuver and set manuver:LowestSafeOrbitWithBuffer;
set manuver:toInSOI to manuverTo@.//now supports docking
set manuver:toInSOIFromApsi to manuverToApsi@.//now supports docking
set manuver:plungeFromSOI to plungeTo@.
set manuver:trimOrbit to trim_orbit@.
set manuver:matchInclination to m_matchInclination@.
set manuver:getTransferTime to getTransferTime@.
set manuver:toPlanet to toPlanet@.//UNFINISHED; temporary usage: places manuver node at next transfer window.
set manuver:toPlanetFromMoon to toPlanetFromMoon@.
set manuver:executeManuerNode to m_exec@.

//TODO test manuverToApsi(...) targeting a non-body; fix bugged code with "approach", spelling is not the problem.