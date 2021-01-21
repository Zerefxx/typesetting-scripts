export script_name = "Everything For Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author = "Zeref"
export script_version = "2.2.0"
-- LIB
zf = require "ZF.utils"

shape_to_clip = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape_clip")
        detect = zf.tags!\remove("full", l.text)
        iclip_or_clip = "\\clip"
        iclip_or_clip = tags\match("\\i?clip") if tags\match("\\i?clip")

        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            clip = "#{iclip_or_clip}(#{zf.poly\to_clip(shape, l.styleref.align, coords.pos.x, coords.pos.y)})"
            __tags = zf.tags\clean("{#{tags .. clip}}")
            l.text = "#{__tags}#{shape}"
        else
            error("shape expected")

        subs[i] = l

clip_to_shape = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")

        if tags\match "\\i?clip%b()"
            clip = tags\match "\\i?clip%b()"
            tags = tags\gsub "\\i?clip%b()", ""
            clip_to_shape = zf.poly\unclip(clip, l.styleref.align, coords.pos.x, coords.pos.y)
            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{clip_to_shape}"
        else
            error("clip expected")
            
        subs[i] = l

shape_origin = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")
        detect = zf.tags!\remove("full", l.text)

        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape_origin, nx, ny = zf.poly\origin(shape, true)

            if tags\match("\\pos%b()")
                tags = tags\gsub "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)", (x, y) ->
                    x += nx
                    y += ny
                    "\\pos(#{x},#{y})"
            elseif tags\match "\\move%b()"
                tags = tags\gsub "\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)", (x1, y1, x2, y2) ->
                    x1 += nx
                    y1 += ny
                    x2 += nx
                    y2 += ny
                    "\\move(#{x1},#{y1},#{x2},#{y2}"
            else
                tags ..= "\\pos(#{coords.pos.x + nx},#{coords.pos.y + ny})"
            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape_origin}"
        else
            error("shape expected")

        subs[i] = l

shape_poly = (subs, sel) ->
    for _, i in ipairs sel
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")
        detect = zf.tags!\remove("full", l.text)

        shape = nil
        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect
        else
            error("shape expected")

        tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        tags = tags\gsub("\\an%d", "\\an7")
        tags ..= "\\an7" unless tags\match "\\an%d"

        shape_poly = zf.poly\org_points(shape, l.styleref.align)
        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_poly}"

        subs[i] = l

shape_expand = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape_expand")
        detect = zf.tags!\remove("full", l.text)

        shape = nil
        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect
        else
            error("shape expected")

        tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        shape_expanded = zf.poly\expand(shape, l, meta)

        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_expanded}"

        subs[i] = l

shape_clear = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")
        detect = zf.tags!\remove("full", l.text)

        shape = nil
        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect
        else
            error("shape expected")

        tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        shape_clear = zf.poly\simplify(shape)

        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_clear}"

        subs[i] = l

shape_merge = (subs, sel) ->
    generate = (subs, sel) ->
        index = {shapes: {}, an: {}, pos: {}, result: {}}
        for _, i in ipairs(sel)
            l = subs[i]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                error("shape expected")

            table.insert(index.an, l.styleref.align)
            table.insert(index.pos, coords.pos)
            table.insert(index.shapes, shape)

        index.final = ""
        for k = 1, #index.shapes
            index.result[k] = zf.poly\to_clip(index.shapes[k], index.an[k], index.pos[k].x, index.pos[k].y)
            index.final ..= index.result[k]

        index.final = zf.poly\simplify(zf.poly\unclip(index.final, index.an[1], index.pos[1].x, index.pos[1].y))
        index

    local line
    for _, i in ipairs(sel)
        l = subs[i]

        l.comment = true
        line = table.copy(l)

        subs[i] = l

    infos_merge = generate(subs, sel)
    line.comment = false

    tags = zf.tags(subs[sel[1]].text)\remove("shape")
    tags ..= "\\pos(#{infos_merge.pos[1].x},#{infos_merge.pos[1].y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")

    __tags = zf.tags\clean("{#{tags}}")
    line.text = "#{__tags}#{infos_merge.final}"
    subs.insert(sel[#sel] + 1, line)

shape_move = (subs, sel) ->
    GUI = {
        {class: "label", label: ":X axis:                                              ", x: 0, y: 0}
        {class: "label", label: "\n:Y axis:                                              ", x: 0, y: 2}
        {class: "floatedit", name: "v1", x: 0, y: 1}
        {class: "floatedit", name: "v2", x: 0, y: 3}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        for _, i in ipairs sel
            l = subs[i]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape")
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                error("shape expected")

            tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            shape_move = zf.poly\displace(shape, ck.v1, ck.v2)
            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape_move}"

            subs[i] = l

shape_round = (subs, sel) ->
    GUI = {
        {class: "label", label: ":Decimal places:                              ", x: 0, y: 0}
        {class: "intedit", name: "v", x: 0, y: 1, value: 0}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        for _, i in ipairs sel
            l = subs[i]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape")
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                error("shape expected")

            tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            shape_round = zf.poly\round(shape, ck.v)
            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape_round}"

            subs[i] = l

shape_clip = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")
        detect = zf.tags!\remove("full", l.text)
        clip, iclip = "", false

        shape = nil
        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect
        else
            error("shape expected")

        if tags\match("\\i?clip%b()")
            iclip = true if tags\match("\\iclip%b()")
            clip = zf.util\clip_to_draw(tags\match("\\i?clip%b()"))
            tags = tags\gsub("\\i?clip%b()", "")
        else
            error("clip expected")

        tags = tags\gsub("\\an%d", "\\an7")
        tags ..= "\\an7" unless tags\match "\\an%d"
        tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")

        shape_clip = zf.poly\clip(zf.poly\org_points(shape, l.styleref.align), clip, coords.pos.x, coords.pos.y, iclip)
        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_clip}" if shape_clip != ""

        subs[i] = l

text_to_shape = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape")
        detect = zf.tags!\remove("full", l.text)

        shape = nil
        unless detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = zf.poly\unclip( zf.text\to_clip(l), l.styleref.align )
            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape}"
        else
            error("text expected")

        subs[i] = l

text_to_clip = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("text_clip")
        detect = zf.tags!\remove("full", l.text)
        iclip_or_clip = "\\clip"
        iclip_or_clip = tags\match("\\i?clip") if tags\match("\\i?clip")

        unless detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            clip = "#{iclip_or_clip}(#{zf.text\to_clip(l, detect, l.styleref.align, coords.pos.x, coords.pos.y)})"
            __tags = zf.tags\clean("{#{tags .. clip}}")
            l.text = "#{__tags}#{detect}"
        else
            error("text expected")

        subs[i] = l
        
aegisub.register_macro "Everything Shape/Shape to Clip", "Move the shape to a value relative to the clip.", shape_to_clip
aegisub.register_macro "Everything Shape/Clip to Shape", "Move the clip to a value relative to the shape.", clip_to_shape
aegisub.register_macro "Everything Shape/Shape Origin", "Move the shape to its original position.", shape_origin
aegisub.register_macro "Everything Shape/Shape Poly", "Moves the shape to positions relative to an7.", shape_poly
aegisub.register_macro "Everything Shape/Shape Expand", "Filters the tags and uses their values to filter the shape points.", shape_expand
aegisub.register_macro "Everything Shape/Shape Clear", "Remove unnecessary vertices from a shape.", shape_clear
aegisub.register_macro "Everything Shape/Shape Merge", "Can merge shapes.", shape_merge
aegisub.register_macro "Everything Shape/Shape (i)Clip", "Cuts the shape from the value of the (i)clip found in the text.", shape_clip
aegisub.register_macro "Everything Shape/Shape Move", "Move your shape.", shape_move
aegisub.register_macro "Everything Shape/Shape Round", "Rounds the shape points according to the \"N\" value.", shape_round
aegisub.register_macro "Everything Shape/Text to Shape", "Transform your text in a shape", text_to_shape
aegisub.register_macro "Everything Shape/Text to Clip", "Transform your text in a clip", text_to_clip