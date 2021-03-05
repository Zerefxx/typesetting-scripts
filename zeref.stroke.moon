export script_name = "Stroke Panel"
export script_description = "A stroke panel"
export script_author = "Zeref"
export script_version = "1.5.2"

-- LIB
zf = require "ZF.utils"

stroke = {}
stroke.corner = {
    "Miter"
    "Round"
    "Square"
}

stroke.align = {
    "Center"
    "Inside"
    "Outside"
}

hints = {}
hints.arctolerance = "The default ArcTolerance is 0.25 units. \nThis means that the maximum distance \nthe flattened path will deviate from the \n\"true\" arc will be no more than 0.25 units \n(before rounding)."
hints.stroke_size = "Stroke Size."
hints.miterlimit = "The default value for MiterLimit is 2 (ie twice delta). \nThis is also the smallest MiterLimit that's allowed. \nIf mitering was unrestricted (ie without any squaring), \nthen offsets at very acute angles would generate \nunacceptably long \"spikes\"."
hints.only_offset = "Return only the offseting text."

INTERFACE = (subs, sel) ->
    local GUI
    for _, i in ipairs(sel)
        l = subs[i]
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        GUI = {
            {class: "label", label: "Stroke Corner:", x: 0, y: 0},
            {class: "label", label: "Align Stroke:", x: 0, y: 3},
            {class: "label", label: "Stroke Weight:", x: 8, y: 0},
            {class: "label", label: "Miter Limit:", x: 8, y: 3},
            {class: "label", label: "Arc Tolerance:", x: 8, y: 6},
            {class: "label", label: "Primary Color:                ", x: 0, y: 9},
            {class: "label", label: "Stroke Color:                     ", x: 8, y: 9},
            {class: "dropdown", name: "crn", items: stroke.corner, x: 0, y: 1, width: 2, height: 2, value: stroke.corner[2]},
            {class: "dropdown", name: "alg", items: stroke.align, x: 0, y: 4, width: 2, height: 2, value: stroke.align[3]},
            {class: "floatedit", name: "ssz", x: 8, y: 1, width: 2, hint: hints.stroke_size, height: 2, value: l.styleref.outline},
            {class: "floatedit", name: "mtl", x: 8, y: 4, width: 2, hint: hints.miterlimit, height: 2, value: 2},
            {class: "floatedit", name: "atc", x: 8, y: 7, hint: hints.arctolerance, width: 2, height: 2, min: 0, value: 0.25},
            {class: "coloralpha", name: "color1", x: 0, y: 10, width: 1, height: 2, value: l.styleref.color1},
            {class: "coloralpha", name: "color3", x: 8, y: 10, width: 1, height: 2, value: l.styleref.color3},
            {class: "checkbox", label: "Remove first line?", name: "act", x: 0, y: 12, value: true},
            {class: "checkbox", label: "Only Offset?", name: "olf", x: 8, y: 12, hint: hints.only_offset, value: false}
        }
    GUI

SAVECONFIG = (subs, sel, val_GUI, ck) ->
    cap_GUI = table.copy(val_GUI)
    vals_write = "STROKE CONFIG - VERSION #{script_version}\n\n"
    cap_GUI[8].value, cap_GUI[9].value = ck.crn, ck.alg
    cap_GUI[11].value, cap_GUI[12].value = ck.mtl, ck.atc
    cap_GUI[15].value, cap_GUI[16].value = ck.act, ck.olf
    for k, v in ipairs cap_GUI
        if v.name == "crn" or v.name == "alg" or v.name == "mtl" or v.name == "atc" or v.name == "act" or v.name == "olf"
            vals_write ..= "{#{v.name} = #{v.value}}\n"
    cfg_save = aegisub.decode_path("?user") .. "\\stroke_config.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!
    aegisub.log "Congratulations, you saved your configuration. XD"

READCONFIG = (filename) ->
    SEPLINES = (val) ->
        sep_vals = {n: {}, v: {}}
        for k = 1, #val
            sep_vals.n[k] = val[k]\gsub "(.+) %= .+", (vls) ->
                vls\gsub "%s+", ""
            rec_names = sep_vals.n[k]
            sep_vals.v[rec_names] = val[k]\gsub ".+ %= (.+)", (vls) ->
                vls\gsub "%s+", ""
        sep_vals
    if filename
        arq = io.open filename, "r"
        if arq != nil
            read = arq\read "*a"
            io.close arq
            lines = [k for k in read\gmatch "(%{[^\n]+%})"]
            for j = 1, #lines do lines[j] = lines[j]\sub(2, -2)
            return SEPLINES(lines), true
        return _, false
    _, false

LOADCONFIG = (gui) ->
    load_config = aegisub.decode_path("?user") .. "\\stroke_config.cfg"
    read_config, rdn = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        new_gui[8].value = read_config.v.crn
        new_gui[9].value = read_config.v.alg
        new_gui[11].value = tonumber read_config.v.mtl
        new_gui[12].value = tonumber read_config.v.atc
        new_gui[15].value = false
        new_gui[15].value = true if read_config.v.act == "true"
        new_gui[16].value = false
        new_gui[16].value = true if read_config.v.olf == "true"
    new_gui

stroke_panel = (subs, sel) ->
    inter, add = LOADCONFIG(INTERFACE(subs, sel)), 0
    local bx, ck
    while true
        bx, ck = aegisub.dialog.display(inter, {"Run", "Save Mods", "Reset", "Cancel"}, {close: "Cancel"})
        inter = INTERFACE(subs, sel) if bx == "Reset"
        break if bx == "Run" or bx == "Save Mods" or bx == "Cancel"

    aegisub.progress.task("Generating Stroke...")
    switch bx
        when "Run"
            for _, i in ipairs sel
                aegisub.progress.set((i - 1) / #sel * 100)
                l = subs[i + add]
                l.comment = true
                subs[i + add] = l

                if ck.act == true
                    subs.delete(i + add)
                    add -= 1

                meta, styles = zf.util\tags2styles(subs, l)
                karaskel.preproc_line(subs, meta, styles, l)
                coords = zf.util\find_coords(l, meta)
                tags = zf.tags(l.text)\remove("out")
                tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")

                detect = zf.tags!\remove("full", l.text)
                out_shape, out_offset = "", ""
                detect = zf.poly\unclip(zf.text\to_clip(l), l.styleref.align) unless detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") and detect != "" and detect != detect\match("%s+")
                
                if ck.olf
                    out_shape = zf.poly\offset(zf.poly\org_points(detect, l.styleref.align), ck.ssz, ck.crn\lower!, nil, ck.mtl, ck.atc)
                    l.comment = false
                    __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(ck.color1)}}")
                    l.text = "#{__tags}#{out_shape}"
                    subs.insert(i + add + 1, l)
                    add += 1
                else
                    out_shape, out_offset = zf.poly\to_outline(zf.poly\org_points(detect, l.styleref.align), ck.ssz, ck.crn, ck.alg, ck.mtl, ck.atc)
                    colors = {ck.color3, ck.color1}
                    shapes = {out_shape, out_offset}
                    for k = 1, 2
                        l.comment = false
                        __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(colors[k])}}")
                        l.text = "#{__tags}#{shapes[k]}"
                        subs.insert(i + add + 1, l)
                        add += 1
            aegisub.progress.set(100)
        when "Save Mods"
            SAVECONFIG(subs, sel, inter, ck)

aegisub.register_macro "Stroke Panel", script_description, stroke_panel