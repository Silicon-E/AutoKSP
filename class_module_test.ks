
//examle of a library module or singleton class ===================
//lexicon keys can be used as suffixes if they obey varname rules
//actually some other names are allowed too like strait numbers and just underscores
global testlib is lexicon().
//must be a lexocon, cannot be a delagate (unfortunate for classes).
set testlib:libvar to 123.4.
//testlib:libvar is same as testlib["libvar"]
local function printlibVar{
    print "libvar equals "+testlib:libvar.
}
set testlib:printlibVar to printLibVar@.//should work

testlib:printLibVar.
//wont work
set testlib:typename to "class".//this wont crash but also does nothing
//as shown by:
print testLib:typename.
//same result for trying to edit builtin functions like tostring.

local private is "I am a private var".
//accesors - shorthand, can also be local functions
set testlib:getPrivate to {return private.}.
set testlib:setPrivate to {parameter a. set private to "changed".}.

//the following will compile error
//   local testlib:alocal is 123.
//lexicon members cannot be private
//defined / unset statements cannot be used on lexicon suffixes
//================================================================

//example of a non-singleton "class" =========================

local function getx{
    //will be unused
    parameter this.
    return this:x.
}
local vec2d__dimension is 2.
local function pseudostatic{
    print "vec dimension is "+vec2d__dimension.
}
global function vec2d{
    //acts as a constructor
    parameter x. parameter y.
    local this is lexicon().
    set this:x to x.
    set this:y to y.
    //===the following crashes kerbal when this:getX is runned
    ////set this:getx to getx@:bind(this).
    //KOS has no self referemce detection.
    //https://github.com/KSP-KOS/KOS/issues/1598
    //===
    //but this works
    set this:getx to {
        return this:x.
    }.
    set this:setx to {
        parameter a.
        set this:x to a.
    }.
    set this:mult to {
        parameter other.
        return other:x*this:x+other:y*this:y.
    }.
    set this:dim to pseudostatic@.//no self-reference
    return this.
}

local avec is vec2d(1,2).
print avec:getx().//crahses kerbal here if using getx@:bind(this)

//========================