cd("0:/src/").
if exists("1:/mastercompile.ks"){
    runOncePath ("1:/mastercompile.ks").
}
else {
    runOncePath ("0:/src/mastercompile.ks").
}
wait until warp=0.
import("lib_manuver").
if not exists("1:/bootstrap.json"){
    local boot is lexicon("toPlanet",0).
    writeJson(boot,"1:/bootstrap.json").
}
//switch to 1.
//sun is correct, kerbol is wrong (in the game; the auto-highlight has it wrong)
//if (ship:body=sun) //and exists("1:/bootstrap.ks")
//  {}
else if ship:body:atm:height<ship:altitude {
    //ship is in an orbit
    local entercode is 0.
    local ht is 80000.
    local dht is 5000.
    local targetApoRad is (target:radius+ht).
    if exists("1:/bootstrap.json"){
        local boot is readJson("1:/bootstrap.json").
        set entercode to boot["toPlanet"].
        set ht to boot["toPlanet_ht"].
        set dht to boot["toPlanet_dht"].
        set targetApoRad to boot["toPlanet_targetApoRad"].
        //note on json: type serialization does work
        //for more general use, manuver_toPlanet [toPlanet] may need two more args
        //  the full boot lexicon; to write to json with
        //  the subdir in the lex to put all the args for toPlanet, to modify args
        //Together the bootstrap.json (name is changable, i (JB) dont know what a bootstrap is) can store key parts of the stack.
        //Note, reals in dicts pass by value only; 
        //  vectors (and whatnot) pass by reference but cannot be newed by reference;
        //  nested lexicons also pass by reference, just be carefull not to new them;
    }

    manuver_toPlanet(target,ht,dht,false,entercode,targetApoRad).
}