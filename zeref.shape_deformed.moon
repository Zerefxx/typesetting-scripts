zeref = require "lib-zeref.zeref-utils"

-- Functions used -->> https://github.com/KaraEffect0r/Kara_Effector
script_name = "Shape Deformed"
script_description = "Generates wobbles in the text coordinatess"
script_author = "Zeref"

GUI = {
    {class: "checkbox", name: "ftr", label: "Remove first line?", x: 1, y: 0},
    {class: "label", label: "Frequency in X:", x: 0, y: 1},
    {class: "label", label: "Amplitude in X:", x: 0, y: 2},
    {class: "label", label: "Frequency in Y:", x: 3, y: 1},
    {class: "label", label: "Amplitude in Y:", x: 3, y: 2},
    {class: "intedit", name: "frx", x: 1, y: 1, width: 2, height: 1, value: 0},
    {class: "intedit", name: "ampx", x: 1, y: 2, width: 2, height: 1, value: 0},
    {class: "intedit", name: "fry", x: 4, y: 1, width: 2, height: 1, value: 0},
    {class: "intedit", name: "ampy", x: 4, y: 2, width: 2, height: 1, value: 0},
}

wobble_text = (txt_shape, vals, rand) ->
    text_shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(txt_shape), 1), (x, y) ->
        wbfx, wbfy = vals[1] or 10, vals[3] or 10
        wbstx, wbsty = vals[2] or 10, vals[4] or 10
        x = x + math.cos(y * (wbfx * 0.001) * math.pi * 2) * wbstx
        y = y + math.sin(x * (wbfy * 0.001) * math.pi * 2) * wbsty
        return x, y)
    if rand
        text_shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(txt_shape), 1), (x, y) ->
            wbfx, wbfy = math.random(vals[1], -vals[1]) or 10, math.random(vals[3], -vals[3]) or 10
            wbstx, wbsty = math.random(vals[2], -vals[2]) or 10, math.random(vals[4], -vals[4]) or 10
            x = x + math.cos(y * (wbfx * 0.001) * math.pi * 2) * wbstx
            y = y + math.sin(x * (wbfy * 0.001) * math.pi * 2) * wbsty
            return x, y)
    return text_shape

wobble_ini = (subs, sel, vals, del, rand) ->
    tags, add = "", 0
    clear_tags = (tags) ->
        ot_tags = tags
        ot_tags = ot_tags\gsub("\\fn[%s+]*[^\\}]*", "")\gsub("\\fs[%s+]*%d+[%.%d+]*", "")\gsub("\\fsp[%s+]*%-?%d+[%.%d+]*", "")\gsub("\\u[%s+]*%d", "")\gsub("\\fscx[%s+]*%d+[%.%d+]*", "")\gsub("\\fscy[%s+]*%d+[%.%d+]*", "")\gsub("\\b[%s+]*%d", "")\gsub("\\i[%s+]*%d", "")\gsub("\\s[%s+]*%d", "")
        return ot_tags
    for _, i in ipairs sel
        l = subs[i + add]
        meta, styles = zeref.tags2style(subs, l.text)
        karaskel.preproc_line(subs, meta, styles, l)
        l.comment = true
        subs[i + add] = l
        l.comment = false
        if del
            subs.delete(i + add)
            add = add - 1
        line = table.copy(l)
        wobble = wobble_text zeref.text_to_shape(l), vals
        if rand
            wobble = wobble_text zeref.text_to_shape(l), vals, true
        if line.text\match "%b{}"
            tags = line.text\match "%b{}"
            tags = clear_tags(tags)
            if not tags\match "\\p[%s+]*%d"
                tags = tags\gsub "}", "\\p1}"
        find_shape = line.text\gsub("%b{}", "")\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
        if find_shape
            wobble = wobble_text find_shape, vals
            if rand
                wobble = wobble_text find_shape, vals, true
            tags = line.text\match "%b{}"
            if not tags\match "\\p[%s+]*%d"
                tags = tags\gsub "}", "\\p1}"
        if tags == ""
            tags = "{\\fscx100\\fscy100\\p1}"
        line.text = tags .. wobble
        subs.insert i + add + 1, line
        add = add + 1

wobble_config = (subs, sel) ->
    bx, ck = aegisub.dialog.display GUI, {"Run", "Random"}
    GUI[1].value, GUI[6].value, GUI[7].value, GUI[8].value, GUI[9].value = ck.ftr, ck.frx, ck.ampx, ck.fry, ck.ampy
    --
    vals = {GUI[6].value, GUI[7].value, GUI[8].value, GUI[9].value}
    if bx == "Run"
        if GUI[1].value
            return wobble_ini subs, sel, vals, true
        else
            return wobble_ini subs, sel, vals
    elseif bx == "Random"
        if GUI[1].value
            return wobble_ini subs, sel, vals, true, true
        else
            return wobble_ini subs, sel, vals, false, true

aegisub.register_macro "Zeref Macros/Shape Deformed", script_description, wobble_config