zeref = require 'lib-zeref.zeref-utils'

script_description = "A series of macros for modifying shapes and clips."
script_version = "1.0"

master_text_shape_to_clip = (subs, sel) ->
    for _, i in ipairs sel
        l = subs[i]
        meta, styles = zeref.tags2style subs, l
        karaskel.preproc_line subs, meta, styles, l
        cords = zeref.find_cords l, meta
        rota = {rot: cords.rots.frz, x: cords.pos.x, y: cords.pos.y}
        iclip_or_clip = "\\clip"
        tags = zeref.tags l.text
        if tags\match "\\move%b()"
            rota.x = cords.move.x1
            rota.y = cords.move.y1
        if tags\match "\\i?clip%b()"
            if tags\match "\\iclip%b()"
                iclip_or_clip = "\\iclip"
            tags = tags\gsub "\\i?clip%b()", ""
        shape = ""
        if l.text\match "%b{}"
            if l.text_stripped ~= "" and l.text_stripped ~= l.text_stripped\match("%s+") and not l.text\match("}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                clip = string.format "%s(%s)", iclip_or_clip, zeref.text_to_clip(l, l.styleref.align, rota.x, rota.y, rota)
                if rota.rot == 0
                    clip = string.format "%s(%s)", iclip_or_clip, zeref.text_to_clip(l, l.styleref.align, rota.x, rota.y)
                l.text = string.format "{%s}%s", tags .. clip, l.text_stripped
            elseif l.text\match("%b{}") and l.text\match("}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                if not tags\match "\\p%d"
                    tags ..= "\\p1"
                tags ..= "\\fscx100\\fscy100"
                shape = l.text\match "}[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"
                clip_shape = zeref.shape_to_clip shape, l.styleref.align, rota.x, rota.y, l.styleref.scale_x, l.styleref.scale_y, rota
                if rota.rot == 0
                    clip_shape = zeref.shape_to_clip shape, l.styleref.align, rota.x, rota.y, l.styleref.scale_x, l.styleref.scale_y
                clip = string.format "%s(%s)", iclip_or_clip, clip_shape
                l.text = string.format "{%s}%s", tags .. clip, shape
        else
            if l.text_stripped ~= "" and l.text_stripped ~= l.text_stripped\match("%s+") and not l.text\match("[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                clip = string.format "%s(%s)", iclip_or_clip, zeref.text_to_clip(l, l.styleref.align, rota.x, rota.y, rota)
                if rota.rot == 0
                    clip = string.format "%s(%s)", iclip_or_clip, zeref.text_to_clip(l, l.styleref.align, rota.x, rota.y)
                l.text = string.format "{%s}%s", tags .. clip, l.text_stripped
            elseif l.text\match "[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*"
                if not tags\match "\\p%d"
                    tags ..= "\\p1"
                tags ..= "\\fscx100\\fscy100"
                shape = l.text\match "[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"
                clip_shape = zeref.shape_to_clip shape, l.styleref.align, rota.x, rota.y, l.styleref.scale_x, l.styleref.scale_y, rota
                if rota.rot == 0
                    clip_shape = zeref.shape_to_clip shape, l.styleref.align, rota.x, rota.y, l.styleref.scale_x, l.styleref.scale_y
                clip = string.format "%s(%s)", iclip_or_clip, clip_shape
                l.text = string.format "{%s\\p1}%s", tags .. clip, shape
        subs[i] = l

master_clip_to_shape = (subs, sel) ->
    for _, i in ipairs sel
        l = subs[i]
        meta, styles = zeref.tags2style subs, l
        karaskel.preproc_line subs, meta, styles, l
        cords = zeref.find_cords l, meta
        tags = zeref.kill_tags zeref.tags(l.text), "shape"
        if tags\match "\\move%b()"
            cords.pos.x = cords.move.x1
            cords.pos.y = cords.move.y1
        tags ..= "\\fscx100\\fscy100"
        if not tags\match "\\p%d"
            tags ..= "\\p1"
        if tags\match "\\i?clip%b()"
            val_clip = tags\match "\\i?clip%b()"
            tags = tags\gsub "\\i?clip%b()", ""
            new_shape = zeref.clip_to_shape val_clip, l.styleref.align, cords.pos.x, cords.pos.y
            l.text = string.format "{%s}%s", tags, new_shape
        subs[i] = l

master_shape_to_center = (subs, sel) ->
    for _, i in ipairs sel
        l = subs[i]
        meta, styles = zeref.tags2style subs, l
        karaskel.preproc_line subs, meta, styles, l
        cords = zeref.find_cords l, meta
        tags = zeref.kill_tags zeref.tags(l.text), "shape2"
        if tags\match "\\move%b()"
            cords.pos.x = cords.move.x1
            cords.pos.y = cords.move.y1
        tags ..= "\\fscx100\\fscy100"
        if not tags\match "\\p%d"
            tags ..= "\\p1"
        if l.text\match "%b{}"
            if l.text\match "}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*"
                shape = l.text\match "}[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"
                new_shape, nx, ny = zeref.shape_origin_pos shape
                if tags\match "\\pos%b()"
                    tags = tags\gsub "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)", (x, y) ->
                        x += nx
                        y += ny
                        return string.format "\\pos(%s,%s)", x, y
                elseif tags\match "\\move%b()"
                    tags = tags\gsub "\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)", (x1, y1, x2, y2) ->
                        x1 += nx
                        y1 += ny
                        x2 += nx
                        y2 += ny
                        return string.format "\\move(%s,%s,%s,%s", x1, y1, x2, y2
                else
                    tags ..= string.format "\\pos(%s,%s)", cords.pos.x + nx, cords.pos.y + ny
                l.text = string.format "{%s}%s", tags, new_shape
        else
            if l.text\match "[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*"
                shape = l.text\match "[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"
                new_shape, nx, ny = zeref.shape_origin_pos shape
                tags ..= string.format "\\pos(%s,%s)", cords.pos.x + nx, cords.pos.y + ny
                l.text = string.format "{%s}%s", tags, new_shape
        subs[i] = l

master_text_to_shape = (subs, sel) ->
    for _, i in ipairs sel
        l = subs[i]
        meta, styles = zeref.tags2style subs, l
        karaskel.preproc_line subs, meta, styles, l
        tags = zeref.kill_tags zeref.tags(l.text), "shape2"
        tags ..= "\\fscx100\\fscy100"
        if not tags\match "\\p%d"
            tags ..= "\\p1"
        if l.text_stripped ~= "" and l.text_stripped ~= l.text_stripped\match("%s+") and not l.text\match("}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = zeref.text_to_shape_2 l
            l.text = string.format "{%s}%s", tags, shape
        subs[i] = l

aegisub.register_macro "Zeref Macros/Shapes - Clips/Text or Shape to Clip", "Basically, it transforms your text into a clip and moves according to the coordinates of the positions you specify.", master_text_shape_to_clip
aegisub.register_macro "Zeref Macros/Shapes - Clips/Clip to Shape", "Basically, it transforms your clip into shape and moves according to the coordinates of the positions you specify.", master_clip_to_shape
aegisub.register_macro "Zeref Macros/Shapes - Clips/Shape Origin", "Returns your shape to its original axis.", master_shape_to_center
aegisub.register_macro "Zeref Macros/Shapes - Clips/Text to Shape", "Returns your text in the form of a shape.", master_text_to_shape
