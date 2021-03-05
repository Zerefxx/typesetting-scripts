export script_name        = "Shape Relocate"
export script_description = "Relocate the shape and returns information intended for karaoke"
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.utils"

main = (subs, sel) ->
    index_r, index_pos = {}, {} -- recebem as recolocações e as posições relativas a origem
    shape_relocate = (shape) -> -- realoca a shape em sua posição original e indexa as recolocações
        shape, nx, ny = zf.poly\origin(shape, true)
        width, height = zf.poly\dimension(shape)
        index_pos[#index_pos + 1] = {x: nx, y: ny, w: width, h: height, s: (nx + ny)}
        return shape, nx, ny

    table.sort(index_pos, (a, b) -> return a.s < b.s) if index_pos[1] != nil -- organiza os valores da reolocações

    infos = { -- recebem as informações já apuradas
        shapes:           {}
        primary_colors:   {}
        secondary_colors: {}
        outline_colors:   {}
        shadow_colors:    {}
    }

    make_infos = (v, t) -> -- faz as tabelas em modo de string destinada a linhas de karaokê
        v = ""
        for k = 1, #t do v ..= "\"#{t[k]}\", "
        return v\sub(1, -3)

    GUI = { -- a famosa gui
        {class: "label", label: ":Alignment:", x: 0, y: 0}
        {class: "dropdown", name: "an", items: {1, 2, 3, 4, 5, 6, 7, 8, 9}, x: 0, y: 1, width: 5, value: 7}
        {class: "checkbox", label: "Return infos in table?", name: "rt", x: 0, y: 2, value: false}
    }

    bx, ck = aegisub.dialog.display(GUI, {"Run", "Cancel"}, {close: "Cancel"})
    if bx == "Run"
        for k, v in ipairs(sel)
            l = subs[v]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            detect = zf.tags!\remove("full", l.text)

            shape = nil
            if detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = detect
            else
                error("shape expected")

            shape, nx, ny = shape_relocate(shape)
            index_r[#index_r + 1] = {shape: shape, nx: nx, ny: ny}

        aegisub.progress.task("Generating Shape...")
        for k, i in ipairs(sel)
            aegisub.progress.set((i - 1) / #sel * 100)
            l = subs[i]

            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape_poly")

            px, py = (index_r[k].nx - index_pos[1].x), (index_r[k].ny - index_pos[1].y)
            switch tonumber(ck.an) -- realoca cada ponto de acordo com o alinhamento definido
                when 1
                    py -= index_pos[1].h
                when 2
                    px -= index_pos[1].w / 2
                    py -= index_pos[1].h
                when 3
                    px -= index_pos[1].w
                    py -= index_pos[1].h
                when 4
                    py -= index_pos[1].h / 2
                when 5
                    px -= index_pos[1].w / 2
                    py -= index_pos[1].h / 2
                when 6
                    px -= index_pos[1].w
                    py -= index_pos[1].h / 2
                when 8
                    px -= index_pos[1].w / 2
                when 9
                    px -= index_pos[1].w

            shape = zf.poly\displace(index_r[k].shape, px, py)
            -- remove valores de posicionamento
            if tags\match "\\move%b()"
                tags = tags\gsub "\\move%b()", "\\pos(0,0)"
            elseif tags\match "\\pos%b()"
                tags = tags\gsub "\\pos%b()", "\\pos(0,0)"
            else
                tags ..= "\\pos(0,0)"

            __tags = zf.tags\clean("{#{tags}}")
            l.text = "#{__tags}#{shape}"

            subs[i] = l

            table.insert(infos.shapes, shape)
            table.insert(infos.primary_colors,   color_from_style(l.styleref.color1))
            table.insert(infos.secondary_colors, color_from_style(l.styleref.color2))
            table.insert(infos.outline_colors,   color_from_style(l.styleref.color3))
            table.insert(infos.shadow_colors,    color_from_style(l.styleref.color4))
            
        if ck.rt == true
            shapes           = make_infos("shapes", infos.shapes)
            primary_colors   = make_infos("primary_colors", infos.primary_colors)
            secondary_colors = make_infos("secondary_colors", infos.secondary_colors)
            outline_colors   = make_infos("outline_colors", infos.outline_colors)
            shadow_colors    = make_infos("shadow_colors", infos.shadow_colors)
            
            preset_ex = "fxgroup.first = (syl.i == 1)\n"
            preset_ex ..= "!maxloop(#shapes)!{\\an7\\pos($center,$middle)\\c!primary_colors[j]!\\p1}!shapes[j]!"
            final = "shapes = {#{shapes}}\nprimary_colors = {#{primary_colors}}\nsecondary_colors = {#{secondary_colors}}\noutline_colors = {#{outline_colors}}\nshadow_colors = {#{shadow_colors}}\n#{preset_ex}"
            aegisub.log(final)

        aegisub.progress.set(100)
    else
        aegisub.cancel!

aegisub.register_macro "Everything Shape/#{script_name}", script_description, main