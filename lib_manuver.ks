parameter debug is false.
local dquote is char(34).
//ctrl-K-0 to fold all, ctrl_K-J to unfold all (fold is colapse)
//maybe todo find compile directive to turn of parenticeless local function calls.
//math util
//v=v_c*U
//r=R_0*H
//note to self: you can get rid of stock ships by moving the contents of {KSP}/Ships elsewhere.
local function modu {
    //positive branch modulus
    //mod(-0.1,1)=-0.1; not 0.9
    parameter a,b.
    local r is mod(a,b).
    if r<0 {set r to r+b.}.
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
    return sqrt(2+Vf^2/Vc^2).

}
local function Uf{//warning, imag output possible
    parameter Ui.
    return sqrt(Ui^2-2).
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
    parameter overflow is 10.//wont use
    local tan is B:orbit:trueAnomaly.
    local pos is (B:position()-B:body:position()).
    local vel is B:velocity:orbit.
    local l is vcrs(pos,vel):normalized.
    local s is vcrs(pos,l):normalized.
    return (pos:normalized*cos(tan)+s*sin(tan)):normalized.
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
    local vc0 is sqrt(ship:body:mu/(positionat(ship, t) -ship:orbit:BODY:POSITION):mag).
    local U0 is velocityAt(ship,t):orbit:mag/vc0.
    set nd:prograde to vc0*(Ui(Vf,Vc0)-U0).//works well now
    //wait 1.

}
local function getOrbitRadiusAtVec {//returns as vector
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
local function getTransferTime {
    parameter A.//start
    parameter B.//end
    if not (A:body=B:body) {
        print "bodies do not have same center".
        return "none".
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
    local t is time:seconds.
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
        //TODO fine tune based on eccentricity
        local A_trvec is (positionAt(A,t+tto)-A:body:position).
        local t_trans is A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
        local B_trvec is (positionAt(A,t+tto+t_trans)-A:body:position).
        set B_trmag to B_trvec:mag.
        set t_trans to A:orbit:period/2*((B_trmag+A_trvec:mag)/2/A:orbit:semimajoraxis)^1.5.
        set B_trvec to (positionAt(A,t+tto+t_trans)-A:body:position).
        set V_at to -A_trvec:normalized*B_perivec:mag.
        local A_omg to vcrs((positionAt(A,t+tto)-A:body:position),(velocityAt(A,t+tto):orbit)
                )/(positionAt(A,t+tto)-A:body:position):sqrmagnitude.
        local B_omg to vcrs((positionAt(B,t+tto+t_trans)-S:position),(velocityAt(B,t+tto+t_trans):orbit)
                )/(positionAt(B,t+tto+t_trans)-S:position):sqrmagnitude.
        local tht is vcrs(V_at:normalized,B_trvec:normalized)*B_omg:normalized.
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
                set d_e to -min(max(-stepTmax,del_e/del_sq),stepTmax).
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
    parameter rot_t is 5.//charactaristic rotation time
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
    //np is a value copy because the local function node:deltav has "get only" access.
    //all suffixes in kos have a property called "access" which determines whether they returne value or reference.
    lock steering to np.//TODO steering wont turn with node

    //now we need to wait until the burn vector and ship's facing are aligned
    wait 5.
    wait until vang(np, ship:facing:vector) < 0.25
            or nd:deltav:mag<error.

    //the ship is facing the right direction, let's wait for our burn time
    local w is time:seconds+nd:eta-(burn_duration/2)-10.
    warpto(w).
    wait until nd:eta <= (burn_duration/2)-9.
    lock steering to np.//wake up, TODO doesnt work but is ok without it
    wait until nd:eta <= (burn_duration/2).
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
    local norm_t is vectorCrossProduct(B:orbit:position-B:body:orbit:position,B:velocity:orbit-B:body:velocity:orbit).
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
local function m_matchInclination{
    parameter B is target.
    parameter soon is false.//if true, go for first node, else go for higher node.
    local angle is rel_inclination(B).
    local eta_a is etaAscendingNode(B).
    local ttime_a is time:seconds.
    local eta_d is etaDescendingNode(B).
    local ttime_d is time:seconds.
    local ttime_ is 0.
    
    diag ("angle: "+angle).
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
    diag("vflat: "+vflat).
    local nd is node(ttime_+eta_,0,-a_d*vflat*sin(angle),vflat*(cos(angle)-1)).
    
    add nd.
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
local PHICRIT is 0.6.
//to make delagate to anonamous
//global manuverTo is {...}
global correction_time is 0.1.
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
        if rt:mag>D and ((rt:mag/vt:mag>ship:orbit:period*PHICRIT/20)or vt:mag<1){
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
    local tempnode is node(time:seconds+ship:orbit:period*correction_time,0,0,0).
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
        warpto(time:seconds+(etanextpatch-ship:orbit:period*(0.5+correction_time))).
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
        local timetomnv is choose correction_time if B_isBody else 0.2.
        local cnd is node(time:seconds+max(ship:orbit:period*correction_time,etanextpatch*(2*timetomnv)),0,0,0).
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
    local nburns is max(floor(PHI/PHICRIT,0),1).
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
    local tempnode is node(time:seconds+ship:orbit:period*correction_time,0,0,0).
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
        warpto(time:seconds+(etanextpatch-ship:orbit:period*(0.5+correction_time))).
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
        local timetomnv is choose correction_time if B_isBody else 0.2.
        local cnd is node(time:seconds+max(ship:orbit:period*correction_time,etanextpatch*(2*timetomnv)),0,0,0).
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
    parameter B.
    local tm is getTransferTime(ship:body,B).
    //warpto(tm).//TODO timewarp seems to never stop due to loss of power.
    local nd is node(tm,0,0,0).
    add nd.
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
    clearScreen.
    //print "Listmax:="+m_util_max(list(1,2,3,4,5)).
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
    if false{manuverTo(15000,mun,2000).}//works.
    //this one now workes
    if false {//big success
        local nd is nextNode.
        local ht is 30000.
        local function err{
            return nd:orbit:nextpatch:periapsis-ht.
        }
        m_opt(nd,err@).//TODO impose restrictions that work.
        //example: an optimization manuver for  mun encounter may lower periapsis into the planet.
        m_exec(nd,0.01,0.2).
    }
    if FALSE{
        m_matchInclination(minmus).
    }
    if false {
        trim_orbit(300000,200000).
    }
    if false {
        until false{
            print "distance: "+closest_approach().
            wait 1.
        }
    }
    if false {//fail
        until false{
            //print "dist from ascending node:"+closest_approach().
            print "dist from periapsis:"+
            (getPerapsisDirVec(ship:orbit)*(ship:periapsis+body:radius)-body:position):mag at (2,2).
            wait 1.
        }
    }
    if false {manuverto (0,target,10).}
    if false {dockApproach(target,0).}//big succes but should test in unideal situations
    if false {//big success
        until false {
            print getOrbitRadiusAtVec(target,-body:position):mag.
            wait 1.
        }
    }
    if false {m_opt_eta(nextnode,{return nextnode:orbit:apoapsis.},"max").}//big success
    if false {manuverToApsi(20000,mun,2000).}
    if false {plungeTo(20000).}
    if false {getTransferTime(kerbin,eve).}
    //ship is a Vessel, mun is a Body. TODO add support for docking manuvers
}
//even though we dont have to do this, it is a good idea because we can rename then to avoid nameing conflicts
//all of these shoud have a prefix manuver_ (could later change to m_ but m_exec already uses it. maybe mnv_)
global manuver_toInSOI is manuverTo@.//now supports docking
global manuver_plungeFromSOI is plungeTo@.
global manuver_trimOrbit is trim_orbit@.
global manuver_matchInclination is m_matchInclination@.
global manuver_getTransferTime is getTransferTime@.
global manuver_toPlanet is toPlanet@.//UNFINISHED; temporary usage: places manuver node at next transfer window.

