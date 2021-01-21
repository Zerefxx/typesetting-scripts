export script_name = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author = "Zeref"
export script_version = "1.2.0"
-- LIB
zf = require "ZF.utils"

BEZIER = (line, Shape, Char_x, Char_y, Mode, Offset) ->
    pyointa = {}
    pyointa.tangential2P = (Pnts, t_) ->
        tanVec, XY, dpos = {}, {}, {}
        XY = pyointa.difference(Pnts)
        dpos = pyointa.tDifferential(XY, t_)
        for i = 1, 2 do tanVec[i] = dpos[2][i] / math.sqrt(dpos[2][1] ^ 2 + dpos[2][2] ^ 2)
        tanVec

    pyointa.normal2P = (Pnts, t_) ->
        normalVec = {}
        normalVec = pyointa.tangential2P(Pnts, t_)
        normalVec[1], normalVec[2] = normalVec[2], -normalVec[1]
        normalVec

    pyointa.difference = (Pnts) ->
        DVec, XY = {}, {}
        DVec[1] = {Pnts[2][1] - Pnts[1][1], Pnts[2][2] - Pnts[1][2]}
        DVec[2] = {Pnts[3][1] - Pnts[2][1], Pnts[3][2] - Pnts[2][2]}
        DVec[3] = {Pnts[4][1] - Pnts[3][1], Pnts[4][2] - Pnts[3][2]}
        DVec[4] = {DVec[2][1] - DVec[1][1], DVec[2][2] - DVec[1][2]}
        DVec[5] = {DVec[3][1] - DVec[2][1], DVec[3][2] - DVec[2][2]}
        DVec[6] = {DVec[5][1] - DVec[4][1], DVec[5][2] - DVec[4][2]}
        XY[1]   = {Pnts[1][1], Pnts[1][2]}
        XY[2]   = {DVec[1][1], DVec[1][2]}
        XY[3]   = {DVec[4][1], DVec[4][2]}
        XY[4]   = {DVec[6][1], DVec[6][2]}
        XY

    pyointa.tDifferential = (XY, ta) ->
        dPos = {}
        dPos[1] = {XY[4][1] * ta ^ 3 + 3 * XY[3][1] * ta ^ 2 + 3 * XY[2][1] * ta + XY[1][1], XY[4][2] * ta ^ 3 + 3 * XY[3][2] * ta ^ 2 + 3 * XY[2][2] * ta + XY[1][2]}
        dPos[2] = {3 * (XY[4][1] * ta ^ 2 + 2 * XY[3][1] * ta + XY[2][1]), 3 * (XY[4][2] * ta ^ 2 + 2 * XY[3][2] * ta + XY[2][2])}
        dPos[3] = {6 * (XY[4][1] * ta + XY[3][1]), 6 * (XY[4][2] * ta + XY[3][2])}
        dPos

    pyointa.getBezierLength = (p, ta, tb, nN) ->
        XY, dpos, t_ = {}, {}, {}
        for i = 1, 2 * nN + 1 do t_[i] = ta + (i - 1) * (tb - ta) / (2 * nN)

        XY = pyointa.difference(p)
        dpos = pyointa.tDifferential(XY, t_[1])
        Ft1 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        dpos = pyointa.tDifferential(XY, t_[2 * nN + 1])
        Ft2 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt1 = 0

        for i = 1, nN
            dpos = pyointa.tDifferential(XY, t_[2 * i])
            SFt1 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt2 = 0
        for i = 1, nN - 1
            dpos = pyointa.tDifferential(XY, t_[2 * i + 1])
            SFt2 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        ((tb - ta) / (2 * nN) / 3) * ((Ft1 + Ft2) + (4 * SFt1) + (2 * SFt2))

    pyointa.length2t = (Pnts, Ltarget, nN) ->
        ll = {[1]: 0}
        ni, tb, t_ = 1.0 / nN, 0, 0
        for i = 2, nN + 1
            tb += ni
            ll[i] = pyointa.getBezierLength(Pnts, 0, tb, nN * 2)
        return false if Ltarget > ll[nN + 1]
        for i = 1, nN
            if ((Ltarget >= ll[i]) and (Ltarget <= ll[i + 1]))
                t_ = (i - 1) / nN + (Ltarget - ll[i]) / (ll[i + 1] - ll[i]) * (1 / nN)
                break
        t_

    pyointa.length2PtNo = (Pnts, Ltarget, nN) ->
        local leng
        bl, cpoint = {}, {}
        for h = 1, #Pnts
            bl = {}
            bl[1] = 0
            for i = 2, #Pnts[h] + 1 do bl[i] = bl[i - 1] + pyointa.getBezierLength(Pnts[h][i - 1], 0, 1.0, nN)
            if Ltarget > bl[#bl]
                Ltarget -= bl[#bl]
            else
                for k = 1, #Pnts[h]
                    if ((Ltarget >= bl[k]) and (Ltarget <= bl[k + 1]))
                        cpoint = Pnts[h][k]
                        leng = Ltarget - bl[k]
                        break
            if leng
                break
        if leng
            return cpoint, leng
        false

    pyointa.getBezierPos = (Pnts, t_) ->
        XY, pos_Bzr = {}, {}
        XY = pyointa.difference(Pnts)
        for i = 1, 2 do pos_Bzr[i] = XY[4][i] * t_ ^ 3 + 3 * XY[3][i] * t_ ^ 2 + 3 * XY[2][i] * t_ + XY[1][i]
        pos_Bzr

    pyointa.shape2coord = (Shape) ->
        coord, k = {}, 0
        xy = [c for c in Shape\gmatch "%S+"]
        while true
            k += 1
            break if xy[k] == "m" or k > #xy
        aegisub.debug.out("invalid drawing command") if k > 1

        d_comm = "m"
        i = 1
        k += 3
        coord[i] = {}

        while k < #xy
            if xy[k] == "m"
                k += 3
                i += 1
                coord[i] = {}
                d_comm = "m"
            elseif xy[k] == "b"
                cp1x, cp1y = xy[k - 2], xy[k - 1]
                cp2x, cp2y = xy[k + 1], xy[k + 2]
                cp3x, cp3y = xy[k + 3], xy[k + 4]
                cp4x, cp4y = xy[k + 5], xy[k + 6]
                k += 7
                d_comm = "b"
                table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
            elseif xy[k] == "l"
                cp1x, cp1y = xy[k - 2], xy[k - 1]
                cp2x = xy[k - 2] + ((xy[k + 1] - xy[k - 2]) * (1 / 3))
                cp2y = xy[k - 1] + ((xy[k + 2] - xy[k - 1]) * (1 / 3))
                cp3x = xy[k - 2] + ((xy[k + 1] - xy[k - 2]) * (2 / 3))
                cp3y = xy[k - 1] + ((xy[k + 2] - xy[k - 1]) * (2 / 3))
                cp4x, cp4y = xy[k + 1], xy[k + 2]
                k += 3
                d_comm = "l"
                table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
            elseif string.match(xy[k], "%d+") != nil
                switch d_comm
                    when "b"
                        cp1x, cp1y = xy[k - 2], xy[k - 1]
                        cp2x, cp2y = xy[k + 0], xy[k + 1]
                        cp3x, cp3y = xy[k + 2], xy[k + 3]
                        cp4x, cp4y = xy[k + 4], xy[k + 5]
                        k += 6
                        table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
                    when "l"
                        cp1x, cp1y = xy[k - 2], xy[k - 1]
                        cp2x = xy[k - 2] + ((xy[k + 0] - xy[k - 2]) * (1 / 3))
                        cp2y = xy[k - 1] + ((xy[k + 1] - xy[k - 1]) * (1 / 3))
                        cp3x = xy[k - 2] + ((xy[k + 0] - xy[k - 2]) * (2 / 3))
                        cp3y = xy[k - 1] + ((xy[k + 1] - xy[k - 1]) * (2 / 3))
                        cp4x, cp4y = xy[k], xy[k + 1]
                        k += 2
                        table.insert(coord[i], {{cp1x, cp1y}, {cp2x, cp2y}, {cp3x, cp3y}, {cp4x, cp4y}})
            else
                aegisub.debug.out("unkown drawing command")
        coord

    l_width, l_left = line.width, line.left
    pos_Bezier, vec_Bezier, cont_point, PtNo = {}, {}, {}, {}
    nN, Blength, lineoffset = 8, 0, 0
    cont_point = pyointa.shape2coord(Shape)
    for i = 1, #cont_point
        for k = 1, #cont_point[i]
            Blength += pyointa.getBezierLength(cont_point[i][k], 0, 1.0, nN)

    Offset = Offset or 0
    lineoffset = switch Mode
        when 2
            Offset
        when 3
            Blength - l_width - Offset
        when 4
            (Blength - l_width) * Offset
        when 5
            (Blength - l_width) * (1 - Offset)
        else
            (Blength - l_width) / 2 + Offset

    targetLength, rot_Bezier = 0, 0
    PtNo, targetLength = pyointa.length2PtNo(cont_point, lineoffset + Char_x - l_left, nN)
    if PtNo != false
        tb = pyointa.length2t(PtNo, targetLength, nN)
        if tb != false
            pos_Bezier = pyointa.getBezierPos(PtNo, tb)
            vec_Bezier = pyointa.normal2P(PtNo, tb)
            rot_Bezier = -math.deg(math.atan2(vec_Bezier[2], vec_Bezier[1])) - 90
    else
        pos_Bezier[1] = Char_x
        pos_Bezier[2] = Char_y
        rot_Bezier = 0
    bezier_angle = zf.math\round((rot_Bezier < -180 and rot_Bezier + 360 or rot_Bezier), 3)
    "\\pos(#{zf.math\round(pos_Bezier[1], 3)},#{zf.math\round(pos_Bezier[2], 3)})\\frz#{bezier_angle}"

text_char = (line) ->
    c_char = [c for c in unicode.chars(line.text_stripped)]
    char, char_nob, left = {}, {}, line.left
    char.n = #c_char

    for k = 1, char.n
        char[k] = {}
        char[k].text_stripped = c_char[k]
        char_nob[#char_nob + 1] = char[k] if char[k].text_stripped != " "
        char[k].width      = aegisub.text_extents line.styleref, c_char[k]
        char[k].left       = left
        char[k].center     = left + char[k].width / 2
        char[k].right      = left + char[k].width
        char[k].start_time = line.start_time
        char[k].end_time   = line.end_time
        char[k].duration   = char[k].end_time - char[k].start_time
        left              += char[k].width

    char_nob
    
list = {}
list.modes = {"Center", "Left", "Right", "Around", "Animated - Start to End", "Animated - End to Start   "}
list.hints = {modes: "Select a mode", offset: "Enter a offset value. \nIn cases of animation, \nthis will be the step."}

INTERFACE = {
    {class: "label", label: "                     :[Modes]:", x: 0, y: 0}
    {class: "dropdown", name: "mds", items: list.modes, hint: list.hints.modes, x: 0, y: 1, width: 3, value: list.modes[1]}
    {class: "label", label: "\n                    :[Offset]:", x: 0, y: 2}
    {class: "intedit", name: "off", hint: list.hints.offset, x: 0, y: 3, width: 3, value: 0}
    {class: "checkbox", name: "chk", label: "Remove first line?", x: 0, y: 4, value: true}
}

text_in_clip = (subs, sel) ->
    add, mds = 0, 1
    bx, ck = aegisub.dialog.display(INTERFACE, {"Run", "Cancel"}, {close: "Cancel"})
    frame_dur, msa, msb = 41.708, aegisub.ms_from_frame(1), aegisub.ms_from_frame(101)
    frame_dur = zf.math\round((msb - msa) / 100, 3) if msb

    aegisub.progress.task("Generating...")
    if bx == "Run"
        for _, i in ipairs(sel)
            aegisub.progress.set((i - 1) / #sel * 100)
            l = subs[i + add]
            l.comment = true
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            shape = zf.util\clip_to_draw(l.text)
            tags = zf.tags(l.text)\find!
            error("clip expected") unless tags\match("\\clip%b()")
            error("text expected") if zf.tags!\remove("full", l.text)\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            tags = zf.tags!\remove("bezier_text", tags)
            line = table.copy(l)
            subs[i + add] = l

            if ck.chk == true
                subs.delete(i + add)
                add -= 1

            switch ck.mds
                when "Center"
                    mds = 1
                when "Left"
                    mds = 2
                when "Right"
                    mds = 3
            chars = text_char(line)
            for c = 1, #chars
                line.comment = false
                char = chars[c]
                px, py = switch line.styleref.align
                    when 1 then char.left, line.bottom
                    when 2 then char.center, line.bottom
                    when 3 then char.right, line.bottom
                    when 4 then char.left, line.middle
                    when 5 then char.center, line.middle
                    when 6 then char.right, line.middle
                    when 7 then char.left, line.top
                    when 8 then char.center, line.top
                    when 9 then char.right, line.top
                bez = BEZIER(line, shape, px, py, mds, ck.off)
                cs, cd = char.start_time, char.duration
                switch ck.mds
                    when "Around"
                        bez = BEZIER(line, shape, px, py, 4, (c - 1) / (#chars - 1))
                        __tags = zf.tags\clean("{#{bez .. tags}}")
                        line.text = "#{__tags}#{char.text_stripped}"
                        subs.insert(i + add + 1, line)
                        add += 1
                    when "Animated - Start to End"
                        ck.off = 1 if ck.off <= 0
                        loop = zf.math\round(line.duration / (frame_dur * ck.off), 3)
                        for k = 1, loop
                            bez = BEZIER(line, shape, px, py, 4, (k - 1) / (loop - 1))

                            line.start_time = cs + cd * (k - 1) / loop
                            line.end_time = cs + cd * k / loop

                            __tags = zf.tags\clean("{#{bez .. tags}}")
                            line.text = "#{__tags}#{char.text_stripped}"
                            subs.insert(i + add + 1, line)
                            add += 1
                    when "Animated - End to Start   "
                        ck.off = 1 if ck.off <= 0
                        loop = zf.math\round(line.duration / (frame_dur * ck.off), 3)
                        for k = 1, loop
                            bez = BEZIER(line, shape, px, py, 5, (k - 1) / (loop - 1))

                            line.start_time = cs + cd * (k - 1) / loop
                            line.end_time = cs + cd * k / loop

                            __tags = zf.tags\clean("{#{bez .. tags}}")
                            line.text = "#{__tags}#{char.text_stripped}"
                            subs.insert(i + add + 1, line)
                            add += 1
                    else
                        __tags = zf.tags\clean("{#{bez .. tags}}")
                        line.text = "#{__tags}#{char.text_stripped}"
                        subs.insert(i + add + 1, line)
                        add += 1
            aegisub.progress.set(100)

aegisub.register_macro script_name, script_description, text_in_clip
