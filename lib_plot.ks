
local newline is char(10).
//local BOX_PLUS is char(9547).//can be printed by KOS


//https://en.wikipedia.org/wiki/List_of_Unicode_characters#Box_Drawing
local function FiletoArray{//of scalars
    parameter fpath.
    print "loading aero data from: "+fpath.
    if not exists(fpath) {
        print "file not found.".
        return "none".
    }
    local arr to list().
    local dat is open(fpath):readAll().
    //print dat:string():split(newline).
    for line in (dat:string():split(newline)){
        local row is line:split(" ").
        if row:length=1 and row[0]="" {break.}
        //print row:typename.//is ListValue'1 instead of List
        //https://github.com/KSP-KOS/KOS/issues/2590
        //print row.
        local nrow is list().
        from {set a to 0.}until a>=row:length step {set a to a+1.} do {
            //print row[a].//string
            nrow:add(row[a]:tonumber()).
            //local asdf is "1234":tonumber().
        }
        arr:add(nrow).
    }
    //print arr.
    return arr.
}

local function plotTWR_ISP {
    parameter atms is 0.
    parameter marker is "#".
    parameter new is true.
    list engines in es.
    local dat is list().
    //e:isp is current
    //use e:ispat(atm).
    for e in es{
        //print e:name.
        //mass of puff is zero
        if not (e:name="omsEngine")//the puff
        {
            //print "row".
            dat:add(list(e:ispAt(atms),e:maxthrustat(atms)/e:mass)).
        }
    }
    //print dat.
    plot(dat,list(0,400,0,300),marker,new).
    
}

global function plot{
    parameter pnts.
    parameter limits is list(0,400,0,300).//ISP,acc
    parameter marker is "#".
    parameter new is true.
    parameter ix is 0.
    parameter iy is 1.
    local xw is limits[1]-limits[0].
    local yw is limits[3]-limits[2].
    parameter xticks is 100.
    parameter yticks is 100.
    parameter invert is true.//up is positive for true
    if new {    clearScreen.
        //draw axes
        //Terminal:width and height can be get/set
        local prevxt is 0.
        local h_of_xax is round((terminal:height-1)*(-limits[2]/yw)).
        local char_xax is "-".
        local char_xax_tick is "+".
        if h_of_xax<0{
            set h_of_xax to 0.
            set char_xax to " ".
            set char_xax_tick to "|".

        }if h_of_xax>=terminal:height{
            set h_of_xax to terminal:height.
            set char_xax to " ".
            set char_xax_tick to "|".

        }
        if invert {set h_of_xax to terminal:height-1-h_of_xax.}
        from {local a is 0.} until a>=terminal:width-1 step {set a to a+1.} do {
            if floor(((a/(terminal:width-1))*xw-limits[0])/xticks)>prevxt {
                print char_xax_tick at (a,h_of_xax).
            }else {
                print char_xax at (a,h_of_xax).
            }
            set prevxt to floor(((a/(terminal:width-1))*xw-limits[0])/xticks).
        }

        local prevyt is 0.
        local w_of_yax is round((terminal:width-1)*(-limits[0]/xw)).
        local char_yax is "|".
        local char_yax_tick is "+".
        if w_of_yax<0{
            set w_of_yax to 0.
            set char_yax to " ".
            set char_yax_tick to "-".

        }if w_of_yax>=terminal:width{
            set w_of_yax to terminal:width.
            set char_yax to " ".
            set char_yax_tick to "-".

        }
        //if invert {set w_of_yax to terminal:height-1-w_of_yax.}
        from {local a is 0.} until a>=terminal:height-1 step {set a to a+1.} do {
            if (choose (terminal:height-1-a) if invert else a)=h_of_xax{
                print "+" at (w_of_yax,choose (terminal:height-1-a) if invert else a).
            }
            else if floor(((a/(terminal:height-1))*yw-limits[2])/yticks)>prevyt {
                print char_yax_tick at (w_of_yax,choose (terminal:height-1-a) if invert else a).
            }else {
                print char_yax at (w_of_yax,choose (terminal:height-1-a) if invert else a).
            }
            set prevyt to floor(((a/(terminal:height-1))*yw-limits[2])/yticks).
        }
    }
    //data
    for r in pnts {
        local w is round((r[ix]-limits[0])/xw*(terminal:width-1)).
        local h is round((r[iy]-limits[2])/yw*(terminal:height-1)).
        if invert {
            set h to terminal:height-1-h.
        }
        print marker at (w,h).
    }

}
//plotTWR_ISP(0,"#",true).
//plotTWR_ISP(1,"@",false).//Big SUCCESS