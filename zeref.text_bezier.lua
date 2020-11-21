zeref = require 'lib-zeref.zeref-utils'

script_name = "Text Bezier"
script_description = "Create curves from vector coordinates or from clip vectors from your line."
script_version = "1.2"

-- Some functions used were done by Kara Effector, thanks --> https://github.com/KaraEffect0r
local frame_dur, msa, msb = 41.708, aegisub.ms_from_frame(1), aegisub.ms_from_frame(101)
if msb then frame_dur = zeref.rd((msb - msa) / 100, 3) end

local modes = {"Center", "Left", "Right", "Around", "Animated - Start to End", "Animated - End to Start"}
local GUI = {
    {class = "label", label = ":Modes:", x = 0, y = 0},
    {class = "label", label = ":Offset:", x = 2, y = 0},
    {class = "label", label = ":Alternative Shape(Mask):", x = 0, y = 2},
    {class = "dropdown", name = "vmodes", items = modes, hint = "Select the final axis of the text :)", x = 0, y = 1, value = modes[1]},
    {class = "intedit", name = "voff", hint = "How much \"offset\" do you need?\nIn case of using the animation modes\nthis will become the step :)", x = 2, y = 1, value = 0},
    {class = "textbox", name = "vshape", hint = "Type an alternative shape :)", x = 0, y = 3, width = 4, height = 4, text = ""},
    {class = "checkbox", name = "vftl", label = ":Remove first line:", x = 0, y = 7, value = false},
}

local KE = {text = {}}

KE.text.bezier = function(line, Shape, Char_x, Char_y, Mode, Offset)
    local pyointa = {}
    function pyointa.tangential2P(Pnts, t_)
        local tanVec, XY, dpos = {}, {}, {}
        XY = pyointa.difference(Pnts)
        dpos = pyointa.tDifferential(XY, t_)
        for i = 1, 2 do
            tanVec[i] = dpos[2][i] / math.sqrt(dpos[2][1] ^ 2 + dpos[2][2] ^ 2)
        end
        return tanVec
    end

    function pyointa.normal2P(Pnts, t_)
        local normalVec = {}
        normalVec = pyointa.tangential2P(Pnts, t_)
        normalVec[1], normalVec[2] = normalVec[2], -normalVec[1]
        return normalVec
    end

    function pyointa.difference(Pnts)
        local DVec, XY = {}, {}
        -- 1st step difference
        DVec[1] = {
            [1] = Pnts[2][1] - Pnts[1][1],
            [2] = Pnts[2][2] - Pnts[1][2]
        }
        DVec[2] = {
            [1] = Pnts[3][1] - Pnts[2][1],
            [2] = Pnts[3][2] - Pnts[2][2]
        }
        DVec[3] = {
            [1] = Pnts[4][1] - Pnts[3][1],
            [2] = Pnts[4][2] - Pnts[3][2]
        }
        -- 2nd step difference
        DVec[4] = {
            [1] = DVec[2][1] - DVec[1][1],
            [2] = DVec[2][2] - DVec[1][2]
        }
        DVec[5] = {
            [1] = DVec[3][1] - DVec[2][1],
            [2] = DVec[3][2] - DVec[2][2]
        }
        -- 3rd step difference
        DVec[6] = {
            [1] = DVec[5][1] - DVec[4][1],
            [2] = DVec[5][2] - DVec[4][2]
        }
        XY[1] = {
            [1] = Pnts[1][1],
            [2] = Pnts[1][2]
        }
        XY[2] = {
            [1] = DVec[1][1],
            [2] = DVec[1][2]
        }
        XY[3] = {
            [1] = DVec[4][1],
            [2] = DVec[4][2]
        }
        XY[4] = {
            [1] = DVec[6][1],
            [2] = DVec[6][2]
        }
        return XY
    end

    function pyointa.tDifferential(XY, ta)
        local dPos = {}
        dPos[1] = {
            [1] = XY[4][1] * ta ^ 3 + 3 * XY[3][1] * ta ^ 2 + 3 * XY[2][1] * ta + XY[1][1],
            [2] = XY[4][2] * ta ^ 3 + 3 * XY[3][2] * ta ^ 2 + 3 * XY[2][2] * ta + XY[1][2]
        }
        dPos[2] = {
            [1] = 3 * (XY[4][1] * ta ^ 2 + 2 * XY[3][1] * ta + XY[2][1]),
            [2] = 3 * (XY[4][2] * ta ^ 2 + 2 * XY[3][2] * ta + XY[2][2])
        }
        dPos[3] = {
            [1] = 6 * (XY[4][1] * ta + XY[3][1]),
            [2] = 6 * (XY[4][2] * ta + XY[3][2])
        }
        return dPos
    end

    function pyointa.getBezierLength(p, ta, tb, nN)
        local XY, dpos, t_ = {}, {}, {}
        for i = 1, 2 * nN + 1 do
            t_[i] = ta + (i - 1) * (tb - ta) / (2 * nN)
        end
        XY = pyointa.difference(p)
        dpos = pyointa.tDifferential(XY, t_[1])
        local Ft1 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        dpos = pyointa.tDifferential(XY, t_[2 * nN + 1])
        local Ft2 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        local SFt1 = 0
        for i = 1, nN do
            dpos = pyointa.tDifferential(XY, t_[2 * i])
            SFt1 = SFt1 + (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        end
        local SFt2 = 0
        for i = 1, nN - 1 do
            dpos = pyointa.tDifferential(XY, t_[2 * i + 1])
            SFt2 = SFt2 + (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        end
        local SimpLength = ((tb - ta) / (2 * nN) / 3) * ((Ft1 + Ft2) + (4 * SFt1) + (2 * SFt2))
        return SimpLength
    end

    function pyointa.length2t(Pnts, Ltarget, nN)
        local ll = {
            [1] = 0
        }
        local ni, tb, t_ = 1.0 / nN, 0, 0
        for i = 2, nN + 1 do
            tb = tb + ni
            ll[i] = pyointa.getBezierLength(Pnts, 0, tb, nN * 2)
        end
        if Ltarget > ll[nN + 1] then
            t_ = false
            return t_
        end
        for i = 1, nN do
            if ((Ltarget >= ll[i]) and (Ltarget <= ll[i + 1])) then
                t_ = (i - 1) / nN + (Ltarget - ll[i]) / (ll[i + 1] - ll[i]) * (1 / nN)
                break
            end
        end
        return t_
    end

    function pyointa.length2PtNo(Pnts, Ltarget, nN)
        local bl, cpoint = {}, {}
        local leng
        for h = 1, #Pnts do
            bl = {}
            bl[1] = 0
            for i = 2, #Pnts[h] + 1 do
                bl[i] = bl[i - 1] + pyointa.getBezierLength(Pnts[h][i - 1], 0, 1.0, nN)
            end
            if Ltarget > bl[#bl] then
                Ltarget = Ltarget - bl[#bl]
            else
                for k = 1, #Pnts[h] do
                    if ((Ltarget >= bl[k]) and (Ltarget <= bl[k + 1])) then
                        cpoint = Pnts[h][k]
                        leng = Ltarget - bl[k]
                        break
                    end
                end
            end
            if leng then
                break
            end
        end
        if leng then
            return cpoint, leng
        end
        return false
    end

    function pyointa.getBezierPos(Pnts, t_)
        local XY, pos_Bzr = {}, {}
        XY = pyointa.difference(Pnts)
        for i = 1, 2 do
            pos_Bzr[i] = XY[4][i] * t_ ^ 3 + 3 * XY[3][i] * t_ ^ 2 + 3 * XY[2][i] * t_ + XY[1][i]
        end
        return pos_Bzr
    end

    function pyointa.shape2coord(Shape)
        local coord, xy, k = {}, {}, 0
        for c in Shape:gmatch("%S+") do
            table.insert(xy, c)
        end
        repeat
            k = k + 1
        until xy[k] == "m" or k > #xy
        if k > 1 then
            aegisub.debug.out("invalid drawing command")
        end
        local d_comm = "m"
        local i = 1
        k = k + 3
        coord[i] = {}
        while k < #xy do
            if xy[k] == "m" then
                k = k + 3
                i = i + 1
                coord[i] = {}
                d_comm = "m"
            elseif xy[k] == "b" then
                cp1x, cp1y = xy[k - 2], xy[k - 1]
                cp2x, cp2y = xy[k + 1], xy[k + 2]
                cp3x, cp3y = xy[k + 3], xy[k + 4]
                cp4x, cp4y = xy[k + 5], xy[k + 6]
                k = k + 7
                d_comm = "b"
                table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
            elseif xy[k] == "l" then
                cp1x, cp1y = xy[k - 2], xy[k - 1]
                cp2x = xy[k - 2] + ((xy[k + 1] - xy[k - 2]) * (1 / 3))
                cp2y = xy[k - 1] + ((xy[k + 2] - xy[k - 1]) * (1 / 3))
                cp3x = xy[k - 2] + ((xy[k + 1] - xy[k - 2]) * (2 / 3))
                cp3y = xy[k - 1] + ((xy[k + 2] - xy[k - 1]) * (2 / 3))
                cp4x, cp4y = xy[k + 1], xy[k + 2]
                k = k + 3
                d_comm = "l"
                table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
            elseif string.match(xy[k], "%d+") ~= nil then
                if d_comm == "b" then
                    cp1x, cp1y = xy[k - 2], xy[k - 1]
                    cp2x, cp2y = xy[k + 0], xy[k + 1]
                    cp3x, cp3y = xy[k + 2], xy[k + 3]
                    cp4x, cp4y = xy[k + 4], xy[k + 5]
                    k = k + 6
                    table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
                elseif d_comm == "l" then
                    cp1x, cp1y = xy[k - 2], xy[k - 1]
                    cp2x = xy[k - 2] + ((xy[k + 0] - xy[k - 2]) * (1 / 3))
                    cp2y = xy[k - 1] + ((xy[k + 1] - xy[k - 1]) * (1 / 3))
                    cp3x = xy[k - 2] + ((xy[k + 0] - xy[k - 2]) * (2 / 3))
                    cp3y = xy[k - 1] + ((xy[k + 1] - xy[k - 1]) * (2 / 3))
                    cp4x, cp4y = xy[k], xy[k + 1]
                    k = k + 2
                    table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
                end
            else
                aegisub.debug.out("unkown drawing command")
            end
        end
        return coord
    end
    local l_width, l_left = line.width, line.left
    local pos_Bezier, vec_Bezier, cont_point, PtNo = {}, {}, {}, {}
    local nN, Blength, lineoffset = 8, 0, 0
    cont_point = pyointa.shape2coord(Shape)
    for i = 1, #cont_point do
        for k = 1, #cont_point[i] do
            Blength = Blength + pyointa.getBezierLength(cont_point[i][k], 0, 1.0, nN)
        end
    end
    local Offset = Offset or 0
    if Mode == 2 then
        lineoffset = Offset
    elseif Mode == 3 then
        lineoffset = Blength - l_width - Offset
    elseif Mode == 4 then
        lineoffset = (Blength - l_width) * Offset
    elseif Mode == 5 then
        lineoffset = (Blength - l_width) * (1 - Offset)
    else
        lineoffset = (Blength - l_width) / 2 + Offset
    end
    targetLength, rot_Bezier = 0, 0
    PtNo, targetLength = pyointa.length2PtNo(cont_point, lineoffset + Char_x - l_left, nN)
    if PtNo ~= false then
        tb = pyointa.length2t(PtNo, targetLength, nN)
        if tb ~= false then
            pos_Bezier = pyointa.getBezierPos(PtNo, tb)
            vec_Bezier = pyointa.normal2P(PtNo, tb)
            rot_Bezier = -math.deg(math.atan2(vec_Bezier[2], vec_Bezier[1])) - 90
        end
    else
        pos_Bezier[1] = Char_x
        pos_Bezier[2] = Char_y
        rot_Bezier = 0
    end
    bezier_angle = zeref.rd((rot_Bezier < -180 and rot_Bezier + 360 or rot_Bezier), 3)
    return string.format("\\pos(%s,%s)\\frz%s", zeref.rd(pos_Bezier[1], 3), zeref.rd(pos_Bezier[2], 3), bezier_angle)
end

local remove_tags = function(tags)
    tags = tags:gsub("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)", "")
    :gsub("\\pos%b()", ""):gsub("\\move%b()", "")
    :gsub("\\fr[z]*[%s+]*%-?%d+[%.%d+]*", "")
    :gsub("\\fsp[%s+]*%-?%d+[%.%d+]*", "")
    return tags
end

local master = function(subs, sel)
    local bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"})
    --------------------------
    GUI[4].value = ck.vmodes
    GUI[5].value = ck.voff
    GUI[6].value = ck.vshape
    GUI[7].value = ck.vftl
    --------------------------
    local add, shape = 0, ""
    aegisub.progress.task("Processing...")
    if bx == "Run" then
        for _, i in ipairs(sel) do
            aegisub.progress.set((i - 1) / #sel * 100)
            local l = subs[i + add]
            local meta, style = zeref.tags2style(subs, l.text)
            karaskel.preproc_line(subs, meta, style, l)
            local line = table.copy(l)
            local vals_char = zeref.char_metrics(line)
            --
            local raw_txt, tags = line.text, ""
            local shp, mds, offst = GUI[6].value, GUI[4].value, GUI[5].value
            if raw_txt:match("%b{}") then
                tags = raw_txt:match("%b{}")
                if tags:match("\\i?clip%(([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)") then
                    shape = raw_txt:match("\\i?clip%(([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
                    tags = remove_tags(tags)
                else
                    if shp ~= "" then
                        if shp:match("[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)") then
                            shape = shp
                        else
                            error("Well, this is not a shape!")
                        end
                    else
                        shape = ""
                    end
                end
            else
                if shp ~= "" then
                    shape = shp
                else
                    shape = ""
                end
            end
            --
            l.comment = true
            subs[i + add] = l
            if GUI[7].value == true then
                subs.delete(i + add)
                add = add - 1
            end
            --
            if mds == "Center" then mds = 1 elseif mds == "Left" then mds = 2 elseif mds == "Right" then mds = 3 end
            for k = 1, #vals_char do
                line.comment = false
                local char = vals_char[k]
                local vx, vy = 0, 0
                if line.styleref.align == 1 then vx, vy = char.left, line.bottom
                    elseif line.styleref.align == 2 then vx, vy = char.center, line.bottom
                    elseif line.styleref.align == 3 then vx, vy = char.right, line.bottom
                    elseif line.styleref.align == 4 then vx, vy = char.left, line.middle
                    elseif line.styleref.align == 5 then vx, vy = char.center, line.middle
                    elseif line.styleref.align == 6 then vx, vy = char.right, line.middle
                    elseif line.styleref.align == 7 then vx, vy = char.left, line.top
                    elseif line.styleref.align == 8 then vx, vy = char.center, line.top
                    elseif line.styleref.align == 9 then vx, vy = char.right, line.top
                end
                local curve = KE.text.bezier(line, shape, vx, vy, mds, offst)
                local li, ld = char.start_time, char.duration
                if mds == "Around" then
                    curve = KE.text.bezier(line, shape, vx, vy, 4, (k - 1)/(#vals_char - 1))
                    line.text = string.format("{%s}%s", curve .. tags:sub(2, -2), char.text_stripped)
                    subs.insert(i + add + 1, line)
                    add = add + 1
                elseif mds == "Animated - Start to End" then
                    if offst <= 0 then offst = 1 end
                    local loop = zeref.rd(line.duration/(frame_dur * offst), 3)
                    for j = 1, loop do
                        curve = KE.text.bezier(line, shape, vx, vy, 4, (j - 1)/(loop - 1))
                        line.start_time = li + ld * (j - 1) / loop
                        line.end_time = li + ld * j / loop
                        line.text = string.format("{%s}%s", curve .. tags:sub(2, -2), char.text_stripped)
                        subs.insert(i + add + 1, line)
                        add = add + 1
                    end
                elseif mds == "Animated - End to Start" then
                    if offst <= 0 then offst = 1 end
                    local loop = zeref.rd(line.duration/(frame_dur * offst), 3)
                    for j = 1, loop do
                        curve = KE.text.bezier(line, shape, vx, vy, 5, (j - 1)/(loop - 1))
                        line.start_time = li + ld * (j - 1) / loop
                        line.end_time = li + ld * j / loop
                        line.text = string.format("{%s}%s", curve .. tags:sub(2, -2), char.text_stripped)
                        subs.insert(i + add + 1, line)
                        add = add + 1
                    end
                else
                    line.text = string.format("{%s}%s", curve .. tags:sub(2, -2), char.text_stripped)
                    subs.insert(i + add + 1, line)
                    add = add + 1
                end
            end
        end
    end
    aegisub.progress.set(100)
end

aegisub.register_macro(string.format("Zeref Macros/%s", script_name), script_description, master)