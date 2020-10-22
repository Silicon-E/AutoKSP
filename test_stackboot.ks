//header, to prevent anoying yellow squiggly lines in vscode
//if not defined bootstack global bootstack is lexicon().
//if not defined save global function save{}.//may have a problem

//end header
local function warptonode{
    parameter nd.//& ====== a reference, do not read/write from the stack
    parameter entercode is 0.//this is actually unneeded but it is here for example.
    parameter substack is bootstack.
        //the value of warp can be used as an entercode, like in lib_manuver::m_exec()
    if entercode<=0{// or if warp=0; <= is usually preferred to = so it can go up, skipping steps
        print "warptonode: warping".
        //lock steering to np.//TODO steering wont turn with node

        //now we need to wait until the burn vector and ship's facing are aligned
        //wait 5.
        //wait until vang(np, ship:facing:vector) < 0.25
                //or nd:deltav:mag<error.

        //the ship is facing the right direction, let's wait for our burn time

        local w is time:seconds+nd:eta.
        set substack["entercode"] to 1. save().
        warpto(w-1).//====here is where a reboot could occur
    }
    wait until warp=0.
    wait until nd:eta <= 0.
    remove nd.

    print "warptonode: finished+removed".
}
local function foo {
    parameter message1.
    parameter message2.
    parameter entercode is 0.
    parameter substack is bootstack.
    if entercode<=0{
        print message1.
        set substack["entercode"] to 1.save().
    }
    if entercode<=1{
        local n1 is 0.
        if allnodes:length=0{
            set n1 to node(time:seconds+orbit:period,0,0,0).add n1.//new a node
        }else {set n1 to nextNode.}//retrieve reference to a node
        if not substack:haskey("warptonode") {set substack["warptonode"] to lexicon("entercode",0).save().}
        warptonode(n1,substack["warptonode"]["entercode"],substack["warptonode"]).
        set substack["entercode"] to 2.
        set substack["warptonode"] to lexicon("entercode",0).//so we can reuse it in next loop, it resets it
        save().
    }
    if entercode<=2{
        local n1 is 0.
        if allnodes:length=0{
            set n1 to node(time:seconds+orbit:period,0,0,0).add n1.//new a node
        }else {set n1 to nextNode.}//retrieve reference to a node
        //if not substack:haskey("warptonode") {set substack["warptonode"] to lexicon("entercode",0).save().}
        warptonode(n1,substack["warptonode"]["entercode"],substack["warptonode"]).//sub
        set substack["entercode"] to 3.save().//mostly not needed.
    }
    print message2.

}
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
local entercode is choose bootstack["entercode"] if bootstack:haskey("entercode") else 0.
// print bootstack. //print "entercode: "+entercode.
local s is 0.
if entercode <=0{
    print "enter something to remember:".
    set s to input().
    set bootstack["s"] to s.
    set bootstack["entercode"] to 1.
    save().
}else {set s to bootstack["s"].}//load a local var
local s1 is 0. local s2 is 0.
if (entercode <=1) {
    local n1 is 0.
    if allnodes:length=0{
        set n1 to node(time:seconds+orbit:period,0,0,0).add n1.//new a node
    }else {set n1 to nextNode.}//retrieve reference to a node
    if not bootstack:haskey("warptonode") {set bootstack["warptonode"] to lexicon("entercode",0). save().}
    warptonode(n1,bootstack["warptonode"]["entercode"],bootstack["warptonode"]).
    
    set s1 to ship:longitude.
    set s2 to ship:altitude.
    set bootstack["s1"] to s1.
    set bootstack["s2"] to s2.
    set bootstack["entercode"] to 2.
    save().
    print "messages from foo() will be: "+s1+" , "+s2.
    wait 1.
}else {
    set s1 to bootstack["s1"].
    set s2 to bootstack["s2"].
}
if entercode <=2 {
    
    if not bootstack:haskey("foo") {set bootstack["foo"] to lexicon("entercode",0). save().}
    foo(s1,s2,bootstack["foo"]["entercode"],bootstack["foo"]).
    //be warned of functions that write to the global bootstack accidentally
    set bootstack["entercode"] to 3.
    save().
}
print "your input at the start was: "+s.
set bootstack["DONE"] to true. save().
