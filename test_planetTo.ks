runOncePath("./lib_manuver.ks",true).//has no scoping effect.
local function input{
    local s is "".
    local c is "".
    //does not need an entercode/substack becuase no reboots occure here
    //a function needs entercode/substack args if and only if:
        //it can cause a reboot, usually because of timewarp (unless it has a workaround like m_exec())
        //it runs another method that needs entercode/substack args
    terminal:input:clear.
    until c = terminal:input:enter {
        set s to s+c.
        set c to terminal:input:getchar().//impossible to print input without a gui.
        //Read the next character of terminal input. If the user hasn’t typed anything in that 
        //is still waiting to be read, then this will “block” (meaning it will pause the execution of 
        //the program) until there is a character that has been typed that can be processed.
    }
    terminal:input:clear.
    return s.
}
local function stringToBody{
    parameter s.
    //print "stringToBody: "+s.
    if (s="kerbin") {return kerbin.}
    if (s="mun") {return mun.}
    if (s="minmus") {return minmus.}
    if (s="moho") {return moho.}
    if (s="eve") {return eve.}
    if (s="gilly") {return gilly.}
    if (s="duna") {return duna.}
    if (s="ike") {return ike.}
    if (s="dres") {return dres.}
    if (s="eeloo") {return eeloo.}
    
    if (s="jool") {return jool.}
    
    if (s="laythe") {return laythe.}
    if (s="tylo") {return tylo.}
    if (s="vall") {return vall.}
    if (s="bop") {return bop.}
    if (s="pol") {return pol.}
    if (s="sun") {return sun.}
    if (s="kerbol") {return sun.}
    return "None".

}
//turns out functions are local by default
local entercode is choose bootstack["entercode"] if bootstack:haskey("entercode") else 0.
local ht is 120000.
local dht is 5000.
local inc is "None".
local ecode is -1.
if entercode<=0 {
    set target to sun.
    print "choose target (other than sun)".
    wait until target <> sun.//<> is not equal to (!= crashes)
    print "enter target periapsis".
    local s is input().
    set ht to s:tonumber().//is a string method
    print "target inclination".
    set s to input().
    set b to stringToBody(s).
    if s="None"{
        set inc to "None".
    }else if (b="None"){
        set inc to s:tonumber().
    }else{
        set inc to b.
    }
    //set bootstack["ht"] to ht.
    //set bootstack["inc"] to inc.
    set bootstack["entercode"] to 1.
    //toPlanet does this locally
    set bootstack["toPlanet"] to lexicon("toPlanet",-1).
    save().
    print "starting manuver:toPlanet".
    print "ht= "+ht.
    print "inc=  "+inc.


}else{
    //set ht to bootstack["ht"].
    //set inc to bootstack["inc"].
    set ecode to bootstack["toPlanet"]["toPlanet"].
    //may want to replace with a line in toPlanet:
    //local entercode is choose bootstack["entercode"] if bootstack:haskey("entercode") else 0.


}
manuver:toPlanet(target,ht,5000,false,ecode,(target:radius+ht)*3,inc,bootstack["toPlanet"]).
//print H(3).//functions default to global but can be prefixed like vars
//manuver:getTransferTime(mun,minmus).
