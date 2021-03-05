export script_name = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author = "Zeref"
export script_version = "1.1.5"
-- LIB
zf = require "ZF.utils"

shape_to_clip = (subs, sel) ->
    aegisub.progress.task("Generating Clip...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

clip_to_shape = (subs, sel) ->
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

shape_origin = (subs, sel) ->
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

shape_poly = (subs, sel) ->
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs sel
        aegisub.progress.set((i - 1) / #sel * 100)
        l = subs[i]

        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        tags = zf.tags(l.text)\remove("shape_poly")
        detect = zf.tags!\remove("full", l.text)

        shape = nil
        if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = detect
        else
            error("shape expected")

        tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        shape_poly = zf.poly\org_points(shape, l.styleref.align)
        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_poly}"

        subs[i] = l
    aegisub.progress.set(100)

shape_expand = (subs, sel) ->
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

shape_smooth_edges = (subs, sel) ->
    GUI = {
        {class: "label", label: ":Smooth Size:                                   ", x: 0, y: 0}
        {class: "intedit", name: "v", x: 0, y: 1, value: 2}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        aegisub.progress.task("Generating Shape...")
        for _, i in ipairs(sel)
            aegisub.progress.set((i - 1) / #sel * 100)
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
            shape_smooth_edges = zf.poly\smooth_edges(shape, ck.v)

            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape_smooth_edges}"

            subs[i] = l
        aegisub.progress.set(100)
    else
        aegisub.cancel!

shape_simplify = (subs, sel) ->
    GUI = {
        {class: "label", label: ":Simplify Mode:", x: 0, y: 0}
        {class: "dropdown", name: "vf", items: {"Line Only", "Line and Bezier"}, x: 0, y: 1, width: 9, height: 1, value: "Line Only"}
        {class: "label", label: ":Tolerance:", x: 0, y: 2}
        {class: "floatedit", name: "n", x: 0, y: 3, width: 9, height: 1, min: 0, value: 1}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        aegisub.progress.task("Generating Shape...")
        for _, i in ipairs(sel)
            aegisub.progress.set((i - 1) / #sel * 100)
            l = subs[i]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape_poly")
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                error("shape expected")
            shape = zf.poly\org_points(shape, l.styleref.align)

            tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            shape_simplify = (ck.vf == "Line Only") and zf.poly\simplify(shape, nil, (ck.n > 50) and 50 or ck.n) or zf.poly\simplify(shape, true, ck.n)

            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape_simplify}"

            subs[i] = l
        aegisub.progress.set(100)
    else
        aegisub.cancel!

shape_split = (subs, sel) ->
    GUI = {
        {class: "label", label: ":Split Mode:", x: 0, y: 0}
        {class: "dropdown", name: "spt", items: {"Full", "Only Line", "Only Bezier"}, x: 0, y: 1, width: 9, height: 1, value: "Full"}
        {class: "label", label: ":Split Size:", x: 0, y: 2}
        {class: "floatedit", name: "n", x: 0, y: 3, width: 9, height: 1, min: 0, value: 2}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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

        if bx == "Run"
            switch ck.spt
                when "Full"
                    shape_split = zf.shape(shape)\redraw(ck.n).code
                when "Only Line"
                    shape_split = zf.shape(shape)\redraw(ck.n, "line").code
                when "Only Bezier"
                    shape_split = zf.shape(shape)\redraw(ck.n, "bezier").code
        else
            aegisub.cancel!

        __tags = zf.tags\clean("{#{tags}}")
        l.text = "#{__tags}#{shape_split}"

        subs[i] = l
    aegisub.progress.set(100)

shape_merge = (subs, sel) ->
    generate = (subs, sel) ->
        index = {shapes: {}, an: {}, pos: {}, result: {}}
        line = {}
        for _, i in ipairs(sel)
            l = subs[i]

            l.comment = true
            line = table.copy(l)

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

            subs[i] = l

        index.final = ""
        for k = 1, #index.shapes
            index.result[k] = zf.poly\to_clip(index.shapes[k], index.an[k], index.pos[k].x, index.pos[k].y)
            index.final ..= index.result[k]

        index.final = zf.poly\simplify(zf.poly\unclip(index.final, index.an[1], index.pos[1].x, index.pos[1].y))
        return index, line

    aegisub.progress.task("Generating Shape...")
    aegisub.progress.set(100)

    infos_merge, line = generate(subs, sel)
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
        aegisub.progress.task("Generating Shape...")
        for _, i in ipairs sel
            aegisub.progress.set((i - 1) / #sel * 100)
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
        aegisub.progress.set(100)

shape_round = (subs, sel) ->
    GUI = {
        {class: "label", label: ":Decimal places:                              ", x: 0, y: 0}
        {class: "intedit", name: "v", x: 0, y: 1, value: 0}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        aegisub.progress.task("Generating Shape...")
        for _, i in ipairs sel
            aegisub.progress.set((i - 1) / #sel * 100)
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
        aegisub.progress.set(100)
    else
        aegisub.cancel!

shape_clip = (subs, sel) ->
    aegisub.progress.task("Generating Clip...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

text_to_shape = (subs, sel) ->
    aegisub.progress.task("Generating Shape...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

text_to_clip = (subs, sel) ->
    aegisub.progress.task("Generating Clip...")
    for _, i in ipairs(sel)
        aegisub.progress.set((i - 1) / #sel * 100)
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
    aegisub.progress.set(100)

aegisub.register_macro "#{script_name}/Shape to Clip", "Move the shape to a value relative to the clip.", shape_to_clip
aegisub.register_macro "#{script_name}/Clip to Shape", "Move the clip to a value relative to the shape.", clip_to_shape
aegisub.register_macro "#{script_name}/Shape Origin", "Move the shape to its original position.", shape_origin
aegisub.register_macro "#{script_name}/Shape Poly", "Moves the shape to positions relative to an7.", shape_poly
aegisub.register_macro "#{script_name}/Shape Expand", "Filters the tags and uses their values to filter the shape points.", shape_expand
aegisub.register_macro "#{script_name}/Shape Smooth Edges", "Smooths the edges of a shape.", shape_smooth_edges
aegisub.register_macro "#{script_name}/Shape Simplify", "Remove unnecessary vertices from a shape.", shape_simplify
aegisub.register_macro "#{script_name}/Shape Merge", "Can merge shapes.", shape_merge
aegisub.register_macro "#{script_name}/Shape (i)Clip", "Cuts the shape from the value of the (i)clip found in the text.", shape_clip
aegisub.register_macro "#{script_name}/Shape Move", "Move your shape.", shape_move
aegisub.register_macro "#{script_name}/Shape Round", "Rounds the shape points according to the \"N\" value.", shape_round
aegisub.register_macro "#{script_name}/Shape Split", "Splits the shape into small parts.", shape_split
aegisub.register_macro "#{script_name}/Text to Shape", "Transform your text in a shape", text_to_shape
aegisub.register_macro "#{script_name}/Text to Clip", "Transform your text in a clip", text_to_clip