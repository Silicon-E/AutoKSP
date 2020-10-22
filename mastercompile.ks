parameter isGit is false.
///DEFINE VDisk: to refer to all Volumes other than Archive(0). default number is 1.

//compiles entire directory to a place determined by symbol bin
//compile shrinks files to ~40% original size
//compiles entire dirrectory and adds compiled copies to subdir ./bin/*
local bin is "../bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
local bintext is "bin".
local root is "0:/src/".
local this is "mastercompile".
if isGit {
    cd("0:/AutoKSP/").
    set root to "0:/AutoKSP/".
    set bin to "./bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
}else {
    cd("0:/src/").
    set root to "0:/src/".
    //local root is "1:".//may not want to debug this in archive.
    set bin to "../bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
}

local cwd is path().//will stay unchanged

local script_ext is "ks".
local comp_ext is "ksm".

global function compile_dir {
    parameter subdirs is true.//subdirs are good for old versions of files
        //print path().
    list files in fls.
    for f in fls {
        print f:tostring + "======"+scriptPath():name.
        if f:typename="VolumeDirectory"{
            if subdirs and not(f:tostring=bintext) {comp(f).}
        } else if f:extension="ks" and not (f:tostring=scriptPath():name+".ks"){
            local newDir is cwd:combine(bin).
            if not exists(newDir){createDir(newDir).}
            compile f to newDir:combine(f:tostring):changeextension(comp_ext).
        }
    }
}
local function comp{
    parameter dir.//subdirs is true
    parameter subds is list().//parrent of dir
    for f in dir:list:values {//dir:list is a lexicon now
        if f:typename="VolumeDirectory"{
            if true and not(f:tostring=bintext){
                local nsubds is subds:copy.
                nsubds:add(dir:tostring).
                comp(f,nsubds).
                }
        } else if f:extension="ks" and not (f:tostring=scriptPath():name+".ks"){
            local newDir is cwd:combine(bin).
            //combine() does not accept a list of strings, only strings
            for sub in subds {
                set newDir to newDir:combine(sub).
            }
            set newDir to newDir:combine(dir:tostring).
            if not exists(newDir){createDir(newDir).}
            compile f to newDir:combine(f:tostring):changeextension(comp_ext).
        }
}
}
global libs is list().//may need to reload libs if power is lost.

global function import {
    parameter lib.//no extension. relative to root dir
    parameter first is true.//add to lib list
    parameter runit is true.//dont use, use 
    local canArxiv is ship:connection:isconnected.
    //note: can use ship:messages to respond to messages ->auto deorbit landers

    list processors in processorList.//I guess they are in number order? 1,2,3...
    local Vdisks is processorList:length.
    local success is false.
    local didcopy is false.
    local fsize is 0.
    local maxfree is 0.
    local thepath is "0:/".
    if canArxiv {
        if exists(root+lib+"."+script_ext){
                if runit{runOncePath(root+lib+"."+script_ext).}
                set success to true.
                set thepath to root+lib+"."+script_ext.
                if first {libs:add(lib).}
            }else if exists(root+bin+lib+"."+comp_ext){
                if runit {runOncePath(root+lib+"."+comp_ext).}
                set thepath to root+bin+lib+"."+comp_ext.
                set success to true.
                if first {libs:add(lib).}
            }
            if exists(root+bin+lib+"."+comp_ext){
                set thepath to root+bin+lib+"."+comp_ext.
            }
            if success{
                //copy to first Vdisk with enough space.
                set fsize to open(thepath):size.//should be closed auto.
                
                from {local i is 1.} until i>Vdisks step {set i to i+1.} do {
                    if Volume(i):freespace>maxfree {set maxfree to Volume(i):freespace.}
                    if Volume(i):freespace>=fsize{
                        set didcopy to true.
                        local newpath is thepath:replace(root,i+":/"):replace(bin,"").
                        copyPath(thepath,newpath).
                    }
                }
            }
    }else {
        set thepath to "1:/".//helps diagnose problems
        from {local i is 1.} until i>Vdisks step {set i to i+1.} do {
            if volume(i):exists(lib+"."+script_ext){
                if runit {runOncePath(i+":/"+lib+"."+script_ext).}
                set thepath to (i+":/"+lib+"."+script_ext).
                set success to true.
                if first {libs:add(lib).}
                break.
            }else if volume(i):exists(lib+"."+comp_ext){
                if runit {runOncePath(i+":/"+lib+"."+comp_ext).}
                set thepath to (i+":/"+lib+"."+comp_ext).
                set success to true.
                if first {libs:add(lib).}
                break.

            }
        }
    }
    if success{
        print (choose "loaded library:  " if runit else "loaded program:  ")+lib.
        if canArxiv and not didcopy {
            print "     failed to copy to Ldisk. Lib size: "+fsize+"; Max Freespace: "+maxfree.
        }
        if runit {return true.}
        else {return thepath.}
    }else{
        print (choose "failed to load library:  " if runit else "failed to load program:  ")+lib.
        if runit {return false.}
        else {return thepath.}
    }//TODO test
    //boot scripts are automatically copied to ship Volume
    ///used to find libs, copy them to non-archive, and runonce them.

}
global function import_program {
    //adds to the rock but does not run. best for programs
    parameter lib.//no extension. relative to root dir
    parameter first is true.//add to lib list
    return import(lib,first,false).
}
if true {//copy over self
    local i is 1.
    local thepath is scriptPath():tostring.
    if true{//fsize
                        //set didcopy to true.
                        local newpath is thepath:replace(root,i+":/"):replace(bin,"").
                        copyPath(thepath,newpath).
    }
    
}

//types will be VolumeFile or VolumeDirectory
//COMPILE "myprog1.ks" to "myprog1.ksm".
//COPYPATH( "0:/myprog1.ksm", "1:/" ).

//COMPILE "myprog2". // If you leave the arguments off, it assumes you are going from .ks to .ksm
//COPYPATH( "0:/myprog2.ksm", "1:/" ).\
//Movepath(...)
//deletepath(...)
//create()
//createDir()