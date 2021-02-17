export script_name        = "Interpolate Master"
export script_description = "Does a linear interpolation between values of the first and last selected line"
export script_author      = "Zeref"
export script_version     = "1.0.2"
-- LIB
zf = require "ZF.utils"

__tags = {}
__tags[1] = {"bord", "xbord", "ybord", "be", "shad", "xshad", "yshad", "blur"}
__tags[2] = {"fs", "fscx", "fscy", "fsp"}
__tags[3] = {"frx", "fry", "fr", "fax", "fay"}
__tags[4] = {"_c", "_2c", "_3c", "_4c", "_1a", "_2a", "_3a", "_4a", "alpha"}
__tags[5] = {"pos", "org", "clip"}

interface = ->
    gui = {}
    for k = 1, #__tags[1] do gui[#gui + 1] = {class: "checkbox", name: __tags[1][k], label: __tags[1][k], x: 0, y: (k - 1), value: false}
    for k = 1, #__tags[2] do gui[#gui + 1] = {class: "checkbox", name: __tags[2][k], label: __tags[2][k], x: 2, y: (k - 1), value: false}
    for k = 1, #__tags[3] do gui[#gui + 1] = {class: "checkbox", name: __tags[3][k], label: __tags[3][k], x: 4, y: (k - 1), value: false}
    for k = 1, #__tags[4] do gui[#gui + 1] = {class: "checkbox", name: __tags[4][k], label: __tags[4][k]\gsub("_", ""), x: 6, y: (k - 1), value: false}
    for k = 1, #__tags[5] do gui[#gui + 1] = {class: "checkbox", name: __tags[5][k], label: __tags[5][k], x: 8, y: (k - 1), value: false}
    gui[#gui + 1] = {class: "checkbox", name: "ign", label: "𝐈𝐠𝐧𝐨𝐫𝐞 𝐓𝐞𝐱𝐭", x: 0, y: 8, value: false}
    gui[#gui + 1] = {class: "label", label: "\n\b\b\b\b\b::𝐀𝐜𝐜𝐞𝐥::\b\b\b\b\b", x: 0, y: 9}
    gui[#gui + 1] = {class: "floatedit", name: "accel", x: 0, y: 10, value: 1}
    return gui

SAVECONFIG = (ck) ->
    cap_GUI = table.copy(interface!)
    vals_write = "INTERPOLATE MASTER CONFIG - VERSION #{script_version}\n\n"
    j = 1
    for k = 1, #__tags[1]
        cap_GUI[j].value = ck[__tags[1][k]]
        j += 1
    for k = 1, #__tags[2]
        cap_GUI[j].value = ck[__tags[2][k]]
        j += 1
    for k = 1, #__tags[3]
        cap_GUI[j].value = ck[__tags[3][k]]
        j += 1
    for k = 1, #__tags[4]
        cap_GUI[j].value = ck[__tags[4][k]]
        j += 1
    for k = 1, #__tags[5]
        cap_GUI[j].value = ck[__tags[5][k]]
        j += 1
    cap_GUI[#cap_GUI - 2].value = ck.ign
    cap_GUI[#cap_GUI].value = ck.accel
    for k, v in ipairs cap_GUI do 
        vals_write ..= "{#{v.name} = #{v.value}}\n" if v.name
    cfg_save = aegisub.decode_path("?user") .. "\\interpolate_config.cfg"
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
    return _, false

LOADCONFIG = (gui) ->
    load_config = aegisub.decode_path("?user") .. "\\interpolate_config.cfg"
    read_config, rdn, n = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        j = 1
        for k = 1, #__tags[1]
            new_gui[j].value = false
            new_gui[j].value = true if read_config.v[__tags[1][k]] == "true"
            j += 1
        for k = 1, #__tags[2]
            new_gui[j].value = false
            new_gui[j].value = true if read_config.v[__tags[2][k]] == "true"
            j += 1
        for k = 1, #__tags[3]
            new_gui[j].value = false
            new_gui[j].value = true if read_config.v[__tags[3][k]] == "true"
            j += 1
        for k = 1, #__tags[4]
            new_gui[j].value = false
            new_gui[j].value = true if read_config.v[__tags[4][k]] == "true"
            j += 1
        for k = 1, #__tags[5]
            new_gui[j].value = false
            new_gui[j].value = true if read_config.v[__tags[5][k]] == "true"
            j += 1
        new_gui[#new_gui - 2].value = false
        new_gui[#new_gui - 2].value = true if read_config.v.act == "true"
        new_gui[#new_gui].value = tonumber read_config.v.accel
    return new_gui

__error = (ms) ->
    error = "\n#{script_name} -- Version: #{script_version}\n\nError: -- #{ms}"
    aegisub.debug.out(error)
    aegisub.cancel!

__concat = (t) ->
    index_size, re_index = {}, {}
    for i = 1, #t do index_size[i] = #t[i]
    max_sizes = zf.table\op(index_size, "max")
    for i = 1, max_sizes
        re_index[i] = ""
        for k = 1, #t do re_index[i] ..= (t[k][i] or "")
    return re_index

interpolation = (first, last, loop, accel = 1, tags = "") ->
    tags = tags\gsub("_", "")
    interpolate_shape = (pct, first, last) ->
        index_shape_first = [tonumber(s) for s in first\gmatch "%-?%d+[%.%d+]*"]
        index_shape_last  = [tonumber(s) for s in last\gmatch "%-?%d+[%.%d+]*"]
        if #index_shape_first != #index_shape_last
            __error("The shapes must have the same stitch length")
        else
            j = 1
            result = first\gsub "(%-?%d+[%.%d+]*)", (s) ->
                s = zf.math\interpolation(pct, index_shape_first[j], index_shape_last[j])
                j += 1
                return s
            return result
    t, index_pol = {tostring(first),  tostring(last)}, {}
    if t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")
        first_pos, last_pos = {}, {}
        first_pos.x, first_pos.y = t[1]\match("\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
        last_pos.x, last_pos.y = t[2]\match("\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
        first_pos.x, first_pos.y = tonumber(first_pos.x), tonumber(first_pos.y)
        last_pos.x, last_pos.y = tonumber(last_pos.x), tonumber(last_pos.y)
        for k = 1, loop
            pol_x = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_pos.x, last_pos.x)
            pol_y = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_pos.y, last_pos.y)
            index_pol[#index_pol + 1] = "\\pos(#{pol_x},#{pol_y})"
    elseif (not t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")) or (t[1]\match("\\pos%b()") and not t[2]\match("\\pos%b()"))
        __error("You must have the \\pos values in both positions")
    elseif t[1]\match("\\org%b()") and t[2]\match("\\org%b()")
        first_org, last_org = {}, {}
        first_org.x, first_org.y = t[1]\match("\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
        last_org.x, last_org.y = t[2]\match("\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
        first_org.x, first_org.y = tonumber(first_org.x), tonumber(first_org.y)
        last_org.x, last_org.y = tonumber(last_org.x), tonumber(last_org.y)
        for k = 1, loop
            pol_x = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_org.x, last_org.x)
            pol_y = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_org.y, last_org.y)
            index_pol[#index_pol + 1] = "\\org(#{pol_x},#{pol_y})"
    elseif (not t[1]\match("\\org%b()") and t[2]\match("\\org%b()")) or (t[1]\match("\\org%b()") and not t[2]\match("\\org%b()"))
        __error("You must have the \\org values in both positions")
    elseif t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")
        first_cp, last_cp = {}, {}
        clip = (t[1]\match("\\iclip") or t[2]\match("\\iclip")) and "iclip" or "clip"
        if not t[1]\match("\\i?clip%(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") and not t[2]\match("\\i?clip%(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)")
            first_cp.x1, first_cp.y1, first_cp.x2, first_cp.y2 = t[1]\match("\\i?clip%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
            last_cp.x1, last_cp.y1, last_cp.x2, last_cp.y2 = t[2]\match("\\i?clip%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
            first_cp.x1, first_cp.y1, first_cp.x2, first_cp.y2 = tonumber(first_cp.x1), tonumber(first_cp.y1), tonumber(first_cp.x2), tonumber(first_cp.y2)
            last_cp.x1, last_cp.y1, last_cp.x2, last_cp.y2 = tonumber(last_cp.x1), tonumber(last_cp.y1), tonumber(last_cp.x2), tonumber(last_cp.y2)
            for k = 1, loop
                pol_x1 = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_cp.x1, last_cp.x1)
                pol_y1 = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_cp.y1, last_cp.y1)
                pol_x2 = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_cp.x2, last_cp.x2)
                pol_y2 = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, first_cp.y2, last_cp.y2)
                index_pol[#index_pol + 1] = "\\#{clip}(#{pol_x1},#{pol_y1},#{pol_x2},#{pol_y2})"
        else
            first_cp.v = t[1]\match("\\i?clip%((m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
            last_cp.v = t[2]\match("\\i?clip%((m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
            for k = 1, loop
                pol_v = interpolate_shape((k - 1) ^ accel / (loop - 1) ^ accel, first_cp.v, last_cp.v)
                index_pol[#index_pol + 1] = "\\#{clip}(#{pol_v})"
    elseif (not t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")) or (t[1]\match("\\i?clip%b()") and not t[2]\match("\\i?clip%b()"))
        __error("You must have the \\clip - \\iclip values in both positions")
    else
        pol = (pct, first, last) -> zf.math\interpolation(pct, first, last)
        for k = 1, #t
            if t[k]\match "[&]*[Hh]%x%x%x%x%x%x[&]*"
                pol = interpolate_color
            elseif t[k]\match "[&]*[Hh]%x%x[&]*"
                pol = interpolate_alpha
        for k = 1, loop
            if t[1] == "" or t[2] == ""
                index_pol[#index_pol + 1] = ""
            else
                index_pol[#index_pol + 1] = tags .. pol((k - 1) ^ accel / (loop - 1) ^ accel, first, last)
    return index_pol

org_interpolation = (table_tags, tags) ->
    index_tags, index_ext = {}, {pos: {}, org: {}, clip: {}}
    for k = 1, #tags
        index_tags[tags[k]] = {}
    for k = 1, #tags
        for _, v in ipairs(table_tags)
            if v\match "\\#{tags[k]}(%-?%d+[%.%d+]*)"
                v\gsub "\\#{tags[k]}(%-?%d+[%.%d+]*)", (b) ->
                    index_tags[tags[k]][#index_tags[tags[k]] + 1] = tonumber(b)
            elseif v\match "\\#{tags[k]\gsub("_", "")}([&]*[Hh]%x%x%x%x%x%x[&]*)"
                v\gsub "\\#{tags[k]\gsub("_", "")}([&]*[Hh]%x%x%x%x%x%x[&]*)", (b) ->
                    index_tags[tags[k]][#index_tags[tags[k]] + 1] = tostring(b)
            elseif v\match "\\#{tags[k]\gsub("_", "")}([&]*[Hh]%x%x[&]*)"
                v\gsub "\\#{tags[k]\gsub("_", "")}([&]*[Hh]%x%x[&]*)", (b) ->
                    index_tags[tags[k]][#index_tags[tags[k]] + 1] = tostring(b)
            elseif tags[k] == "pos" and v\match "\\pos%b()"
                index_tags[tags[k]][#index_tags[tags[k]] + 1] = v\match("\\pos%b()")
            elseif tags[k] == "org" and v\match "\\org%b()"
                index_tags[tags[k]][#index_tags[tags[k]] + 1] = v\match("\\org%b()")
            elseif tags[k] == "clip" and v\match "\\i?clip%b()"
                index_tags[tags[k]][#index_tags[tags[k]] + 1] = v\match("\\i?clip%b()")
    return index_tags

index_interpolation = (t_tags, f_tags, n, old_tags, accel, style_values) ->
    index_pol, re_index = {}, {}
    for k = 1, #f_tags
        index_tags = org_interpolation(t_tags, f_tags)[f_tags[k]]
        if (not index_tags[1]) and (not index_tags[2])
            index_tags[1], index_tags[2] = "", ""
        elseif (not index_tags[1]) and index_tags[2]
            index_tags[1] = style_values.first[f_tags[k]]
        elseif index_tags[1] and (not index_tags[2])
            index_tags[2] = style_values.last[f_tags[k]]
        table.insert(index_pol, interpolation(index_tags[1], index_tags[2], n, accel, "\\#{f_tags[k]}"))
        for j = 1, #t_tags
            t_tags[j] = t_tags[j]\gsub("\\#{f_tags[k]\gsub("_", "")}%-?[%d&]^*[%.%dHh&%x]*", "")
            t_tags[j] = t_tags[j]\gsub("\\i?#{f_tags[k]}%b()", "")
        for j = 1, #old_tags
            old_tags[j] = old_tags[j]\gsub("\\#{f_tags[k]\gsub("_", "")}%-?[%d&]^*[%.%dHh&%x]*", "")
            old_tags[j] = old_tags[j]\gsub("\\i?#{f_tags[k]}%b()", "")
    re_index = __concat(index_pol)
    for k = 1, #re_index do re_index[k] ..= old_tags[k]
    return re_index

index_tags_text = (line_text) ->
    tags, text, nftags = {}, {}, false
    line_text = line_text\gsub("(.-)%{", (tx) ->
        text[#text + 1] = tx if tx != ""
        nftags = true if tx != "", 1)
    line_text = line_text\gsub "(%b{})([^%b{}]*)", (tg, tx) ->
        tags[#tags + 1] = tg
        text[#text + 1] = tx
    return text, tags, nftags

class interpol

    new: (subs, sel) =>
        @sb, @sl = subs, sel

    index_texts: =>
        @selected_lines = [@sb[i] for _, i in ipairs(@sl)]
        @txt_selected_lines = [@sb[i].text for _, i in ipairs(@sl)]

    org_text_and_tags: =>
        @index_texts!
        @index_tg_tx = {text: {}, tags: {}, nftags: {}}
        for i = 1, #@txt_selected_lines
            @index_tg_tx.text[i], @index_tg_tx.tags[i], @index_tg_tx.nftags[i] = index_tags_text(@txt_selected_lines[i])
        index_size = {tags: {}, text: {}}
        for i = 1, #@index_tg_tx.tags do index_size.tags[i] = #@index_tg_tx.tags[i]
        for i = 1, #@index_tg_tx.text do index_size.text[i] = #@index_tg_tx.text[i]
        max_size_tags = zf.table\op(index_size.tags, "max")
        max_size_text = zf.table\op(index_size.text, "max")
        local index_size_text
        for i = 1, #@index_tg_tx.text
            index_size_text = i if (#@index_tg_tx.text[i] == max_size_text)
        for i = 1, #@index_tg_tx.text
            @index_tg_tx.text[i] = @index_tg_tx.text[index_size_text]
        for i = 1, #@index_tg_tx.tags
            if #@index_tg_tx.tags[i] < max_size_tags
                for k = #@index_tg_tx.tags[i], (max_size_tags - 1)
                    if @index_tg_tx.nftags[i] == true
                        table.insert(@index_tg_tx.tags[i], 1, "")
                    else
                        table.insert(@index_tg_tx.tags[i], "")
        for i = 1, #@index_tg_tx.tags
            for k = 1, #@index_tg_tx.tags[i]
                @index_tg_tx.tags[i][k] = @index_tg_tx.tags[i][k]\sub(2, -2)
        return @index_tg_tx

    index_styles_values: =>
        @index_texts!
        first, last = @selected_lines[1], @selected_lines[#@selected_lines]
        meta, styles = karaskel.collect_head(@sb)
        karaskel.preproc_line(@sb, meta, styles, first)
        karaskel.preproc_line(@sb, meta, styles, last)
        @style_values = {
            first: {
                bord: first.styleref.outline, xbord: 0, ybord: 0
                be: 0, shad: first.styleref.shadow, xshad: 0
                yshad: 0, blur: 0, fs: first.styleref.fontsize
                fscx: first.styleref.scale_x, fscy: first.styleref.scale_x
                fsp: first.styleref.spacing, frx: 0, fry: 0
                fr: first.styleref.angle, fax: 0, fay: 0
                _c:  util.color_from_style(first.styleref.color1)
                _2c: util.color_from_style(first.styleref.color2)
                _3c: util.color_from_style(first.styleref.color3)
                _4c: util.color_from_style(first.styleref.color4)
                _1a: util.alpha_from_style(first.styleref.color1)
                _2a: util.alpha_from_style(first.styleref.color2)
                _3a: util.alpha_from_style(first.styleref.color3)
                _4a: util.alpha_from_style(first.styleref.color4)
            }
            last: {
                bord: last.styleref.outline, xbord: 0, ybord: 0
                be: 0, shad: last.styleref.shadow, xshad: 0
                yshad: 0, blur: 0, fs: last.styleref.fontsize
                fscx: last.styleref.scale_x, fscy: last.styleref.scale_x
                fsp: last.styleref.spacing, frx: 0, fry: 0
                fr: last.styleref.angle, fax: 0, fay: 0
                _c:  util.color_from_style(last.styleref.color1)
                _2c: util.color_from_style(last.styleref.color2)
                _3c: util.color_from_style(last.styleref.color3)
                _4c: util.color_from_style(last.styleref.color4)
                _1a: util.alpha_from_style(last.styleref.color1)
                _2a: util.alpha_from_style(last.styleref.color2)
                _3a: util.alpha_from_style(last.styleref.color3)
                _4a: util.alpha_from_style(last.styleref.color4)
            }
        }

    interpol_values: (selected_tags, accel) =>
        @org_text_and_tags!
        @index_styles_values!
        index_pol, old_tags, seg = {}, {}, @index_tg_tx.tags
        re_t = {seg[1], seg[#seg]}
        for k = 1, #seg[1] do old_tags[#old_tags + 1] = {}
        for k = 1, #seg do for j = 1, #seg[k] do table.insert(old_tags[j], seg[k][j]) 
        for k = 1, #re_t[1]
            index_pol[k] = index_interpolation({re_t[1][k], re_t[2][k]}, selected_tags, #@sl, old_tags[k], accel, @style_values)
            for j = 1, #index_pol[k] do index_pol[k][j] = "{#{index_pol[k][j]}}"\gsub("{}", "") .. @index_tg_tx.text[j][k]
        return __concat(index_pol)

    interpol_values_ign: (selected_tags, accel) =>
        @index_styles_values!
        @index_texts!
        __index_tg_tx, index_pol = {text: {}, tags: {}}, {}
        verify = (line) ->
            nftags, tags = false, ""
            line = line\gsub("(.-)%{", (v) ->
                nftags = true if v != "", 1)
            if nftags == false
                tags = line\match("%b{}") or ""
                line = line\gsub("%b{}", "", 1)
            return line, tags\sub(2, -2) or ""
        for i = 1, #@txt_selected_lines
            __index_tg_tx.text[i], __index_tg_tx.tags[i] = verify(@txt_selected_lines[i])
        index_pol = index_interpolation({__index_tg_tx.tags[1], __index_tg_tx.tags[#__index_tg_tx.tags]}, selected_tags, #@sl, __index_tg_tx.tags, accel, @style_values)
        for i = 1, #index_pol
            index_pol[i] = "{#{index_pol[i]}}"\gsub("{}", "") .. __index_tg_tx.text[i]
        return index_pol

    final: =>
        inter = LOADCONFIG(interface!)
        local bx, ck
        while true
            bx, ck = aegisub.dialog.display(inter, {"Run", " Run - Save Mods ", "Reset", "Cancel"}, close: "Cancel")
            inter = interface! if bx == "Reset"
            break if bx == "Run" or bx == " Run - Save Mods " or bx == "Cancel"
        __index_tags, __index_true = {}, {}
        for k = 1, #__tags
            for j = 1, #__tags[k]
                __index_tags[#__index_tags + 1] = __tags[k][j]
        for k = 1, #__index_tags
            __index_true[#__index_true + 1] = __index_tags[k] if (ck[__index_tags[k]] == true)
        switch bx
            when "Run", " Run - Save Mods "
                aegisub.progress.task("Interpolating...")
                SAVECONFIG(ck) if bx == " Run - Save Mods "
                if #__index_true > 0
                    for k, v in ipairs(@sl)
                        aegisub.progress.set((v - 1) / #@sl * 100)
                        l = @sb[v]
                        unless ck.ign
                            l.text = @interpol_values(__index_true, ck.accel)[k]
                        else
                            l.text = @interpol_values_ign(__index_true, ck.accel)[k]
                        @sb[v] = l
                    aegisub.progress.set(100)
                else
                    aegisub.cancel!
            when "Cancel"
                aegisub.cancel!

main = (subs, sel) ->
    return interpol(subs, sel)\final!

enable = (subs, sel) ->
    return (#sel > 1) and true or false

aegisub.register_macro script_name, script_description, main, enable