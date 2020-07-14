parameter subdirs is true.//subdirs are good for old versions of files
parameter isGit is true.
//compiles entire directory to a place determined by symbol bin
//compile shrinks files to ~40% original size
//compiles entire dirrectory and adds compiled copies to subdir ./bin/*
local bin is "../bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
local bintext is "bin".
if isGit {
    set bin to "./bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
}else {
    cd("0:/src/").
    //local root is "1:".//may not want to debug this in archive.
    set bin to "../bin/".//for my use: "../bin/"; for auto ksp: "./bin/"
}

local cwd is path().//will stay unchanged

local comp_ext is "ksm".
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
local function comp{
    parameter dir.
    parameter subds is list().//parrent of dir
    for f in dir:list:values {//dir:list is a lexicon now
        if f:typename="VolumeDirectory"{
            if subdirs and not(f:tostring=bintext){
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

//types will be VolumeFile or VolumeDirectory
//COMPILE "myprog1.ks" to "myprog1.ksm".
//COPYPATH( "0:/myprog1.ksm", "1:/" ).

//COMPILE "myprog2". // If you leave the arguments off, it assumes you are going from .ks to .ksm
//COPYPATH( "0:/myprog2.ksm", "1:/" ).\
//Movepath(...)
//deletepath(...)
//create()
//createDir()