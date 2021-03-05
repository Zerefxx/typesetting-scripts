export script_name = "Gradient"
export script_description = "Generates a Gradient in both shape and text, noclip!"
export script_author = "Zeref"
export script_version = "1.0.0"
-- LIB
zf = require "ZF.utils"

gradient_defs = {}
gradient_defs.modes = {
    "Vertical"
    "Horizontal"
}

INTERFACE = {
    {class: "dropdown", name: "mode", items: gradient_defs.modes, value: gradient_defs.modes[1], x: 6, y: 1}
    {class: "label", label: "Gradient Types:                                  ", x: 6, y: 0}
    {class: "label", label: "Gap Size: ", x: 6, y: 2}
    {class: "intedit", name: "px", x: 6, y: 3, min: 1, value: 2}
    {class: "label", label: "Accel: ", x: 6, y: 4}
    {class: "floatedit", name: "ac", x: 6, y: 5, value: 1}
    {class: "checkbox", label: "Save modifications?", name: "sv", x: 6, y: 6, value: false}
    {class: "checkbox", label: "Remove first line?", name: "act", x: 6, y: 7, value: false}
    {class: "label", label: "\nColors: ", x: 6, y: 8}
    {class: "color", name: "color1", x: 6, y: 9, height: 1, width: 1, value: "#FFFFFF"}
    {class: "color", name: "color2", x: 6, y: 10, height: 1, width: 1, value: "#FF0000"}
}

SAVECONFIG = (gui, ck) ->
    cap_GUI = table.copy(gui)
    vals_write = "GRADIENT CONFIG - VERSION #{script_version}\n\n"
    cap_GUI[1].value, cap_GUI[4].value = ck.mode, ck.px
    cap_GUI[6].value, cap_GUI[7].value = ck.ac, ck.sv
    cap_GUI[8].value = ck.act

    c = 1
    for j = 10, #cap_GUI
        cap_GUI[j].value = ck["color#{c}"]
        c += 1

    for k, v in ipairs cap_GUI do vals_write ..= "{#{v.name} = #{v.value}}\n" if v.name
    cfg_save = aegisub.decode_path("?user") .. "\\gradient_config.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!

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
            return SEPLINES(lines), true, #lines
        return _, false
    _, false

LOADCONFIG = (gui) ->
    load_config = aegisub.decode_path("?user") .. "\\gradient_config.cfg"
    read_config, rdn, n = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        new_gui[1].value = read_config.v.mode
        new_gui[4].value = tonumber read_config.v.px
        new_gui[6].value = tonumber read_config.v.ac
        new_gui[7].value = false
        new_gui[7].value = true if read_config.v.sv == "true"
        new_gui[8].value = false
        new_gui[8].value = true if read_config.v.act == "true"
        new_gui[10].value = read_config.v.color1
        new_gui[11].value = read_config.v.color2

        i, j, c = 12, 3, 11
        for k = 6, n
            if read_config.v["color#{j}"]
                new_gui[i] = {class: "color", name: "color#{j}", x: 6, y: c, height: 1, width: 1, value: read_config.v["color#{j}"]}
                i += 1
                j += 1
                c += 1

    new_gui

make_cuts = (shape, pixel, nx, ny, mode) ->
    OFFSET, oft = 10, 2
    shape_width, shape_height = zf.poly\dimension(shape)
    shape_width, shape_height = shape_width + OFFSET, shape_height + OFFSET

    origin = zf.poly\origin(shape)
    pixel = pixel or 2
    mode = mode or "horizontal"

    cap_first_point = (p) ->
        x, y = p\match("(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)")
        tonumber(x), tonumber(y)

    px, py = cap_first_point(shape)
    ox, oy = cap_first_point(origin)
    distx, disty = (px - ox), (py - oy)

    clip, clipping, clipping_fix = {}, {}, {}
    switch mode
        when "horizontal"
            loop = shape_width / pixel
            for k = 1, loop
                mod = (k - 1) / (loop - 1)
                interpol_l = zf.math\interpolation(mod, 0, shape_width - pixel) - oft
                interpol_r = zf.math\interpolation(mod, pixel, shape_width) + oft

                clip[k] = "\\clip(#{(distx + nx) + interpol_l},#{(disty + ny)},#{(distx + nx) + interpol_r},#{(disty + ny) + shape_height})"
                clip[k] = zf.util\clip_to_draw(clip[k])

                clipping[k] = zf.poly\clip(shape, clip[k], nx, ny)
        when "vertical"
            loop = shape_height / pixel
            for k = 1, loop
                mod = (k - 1) / (loop - 1)
                interpol_t = zf.math\interpolation(mod, 0, shape_height - pixel) - oft
                interpol_b = zf.math\interpolation(mod, pixel, shape_height) + oft

                clip[k] = "\\clip(#{(distx + nx)},#{(disty + ny) + interpol_t},#{(distx + nx) + shape_width},#{(disty + ny) + interpol_b})"
                clip[k] = zf.util\clip_to_draw(clip[k])

                clipping[k] = zf.poly\clip(shape, clip[k], nx, ny)

    for k = 1, #clipping
        j = 1
        if clipping[k] != ""
            clipping_fix[#clipping_fix + j] = clipping[k]
            j += 1

    return clipping_fix

gradient = (subs, sel) ->
    inter, add = LOADCONFIG(INTERFACE), 0
    add_colors = (t) ->
        GUI = table.copy(t)
        table.insert(GUI, {class: "color", name: "color#{ (#GUI - 9) + 1 }", x: 6, y: (#GUI - 1) + 1, height: 1, width: 1, value: "#000000"})
        return GUI

    local bx, ck
    while true
        bx, ck = aegisub.dialog.display(inter, {"Run", "Add+", "Reset", "Cancel"}, {close: "Cancel"})
        inter = add_colors(inter) if bx == "Add+"
        inter = INTERFACE if bx == "Reset"
        break if bx == "Run" or bx == "Cancel"

    cap_colors = {}
    for k = 1, #inter
        table.insert(cap_colors, ck["color#{k}"])
        
    for k = 1, #cap_colors
        cap_colors[k] = zf.util\html_color(cap_colors[k])

    SAVECONFIG(inter, ck) unless bx == "Cancel" and ck.sv == true
    if bx == "Run"
        for _, i in ipairs(sel)
            l = subs[i + add]
            l.comment = true

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape_gradient")
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                aegisub.debug.out("shape expected")
                aegisub.cancel!

            if not tags\match("\\pos%b()") and not tags\match("\\move%b()")
                tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})"

            if tags\match("\\pos%b()")
                tags = tags\gsub "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)", (x, y) ->
                    x = zf.math\round(x, 0)
                    y = zf.math\round(y, 0)
                    "\\pos(#{x},#{y}"

            tags = tags\gsub("\\an%d", "\\an7")
            if not tags\match "\\an%d"
                tags ..= "\\an7"

            shape_org = zf.poly\org_points(shape, l.styleref.align)
            cuts = make_cuts(shape_org, ck.px, coords.pos.x, coords.pos.y, ck.mode\lower!)

            line = table.copy(l)
            subs[i + add] = l

            if ck.act == true
                subs.delete(i + add)
                add -= 1

            for k = 1, #cuts
                line.comment = false
                colors = zf.table\interpolation(cap_colors, #cuts, "color", ck.ac, "\\c")[k]
                __tags = zf.tags\clean("{#{tags .. colors}}")
                line.text = "#{__tags}#{cuts[k]}"

                subs.insert(i + add + 1, line)
                add += 1

aegisub.register_macro script_name, script_description, gradient
