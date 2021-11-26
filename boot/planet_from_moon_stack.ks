
//=================
//edit here for implimentation
local theprogram is "test_planetToFromMoon".
//=================
// may in the future be able to overwrite the boot script by runing stackboot from another script w args

if warp>0{
    wait until warp=0.
    //bug, does not wait for warp to fully stop; using a code loop fails
    //https://github.com/KSP-KOS/KOS/issues/1790
    wait until ship:unpacked.//should work but still doesn't
    wait 3.
}
wait until ship:unpacked.
if(ship:connection:isconnected) {cd("0:/src/").}
if exists("1:/mastercompile.ks"){
    runOncePath ("1:/mastercompile.ks").
}
else {
    runOncePath ("0:/src/mastercompile.ks").
}
local bootstrapname is "1:/bootstrap.json".//there will always be a disk 1.

global bootstack is lexicon().//GLOBAL======gives the stack (not an actual stack but a tree json)
//===========================================also can contain mission objectives that have been/not been met.

global isFirst is false.//GLOBAL======gives if this is not a restart
global function save{
    writeJson(bootstack,bootstrapname).
}
if not exists(bootstrapname){
    set isFirst to true.
    writeJson(bootstack,bootstrapname).
}else{
    set bootstack to readJson(bootstrapname).
}
//switch to 1.
//sun is correct, kerbol is wrong (in the game; the auto-highlight has it wrong)
//if (ship:body=sun) //and exists("1:/bootstrap.ks")
//  {}
global reboots is 0.
if isFirst{
    //(ship:body:atm:height<ship:altitude) and (body=kerbin){
    print "initialize ship for execution then press any key to start".
    terminal:input:clear.
    wait until terminal:input:haschar.
    terminal:input:clear.
    set bootstack["reboots"] to reboots. save().
}else {
    set bootstack["reboots"] to (bootstack["reboots"]+1) . save().
    set reboots to bootstack["reboots"] .//diagnostic for afterward
}
print "reboot number: "+reboots.
if (not bootstack:haskey("DONE")) and (isFirst) {set bootstack["DONE"] to false. save().}
if not bootstack["DONE"]{
    local program is import_program(theprogram).
    runoncePath(program).
    //can bypass if is first, if desired, it will still work
}else {
    print "*******ALREADY DONE******".
    //proccessor:bootfile does pass by reference so it may be possible to change the boot file from code
    //The filename for the boot file on this processor. This may be set to an empty string
    // “” or to “None” to disable the use of a boot file.
}
