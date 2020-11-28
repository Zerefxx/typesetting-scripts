require "karaskel"
require "Yutils" -- https://github.com/Youka/Yutils

zeref = {}
zeref.ipol_c = util.interpolate_color
zeref.ipol_a = util.interpolate_alpha
sf = string.format

tags_caps = {
    bord: "\\bord[%s+]*%d+[%.%d]*", xbord: "\\xbord[%s+]*%d+[%.%d]*", ybord: "\\ybord[%s+]*%d+[%.%d]*",
    be: "\\be[%s+]*%d+[%.%d]*", shade: "\\shad[%s+]*%d+[%.%d]*", xshade: "\\xshad[%s+]*%d+[%.%d]*",
    yshade: "\\yshad[%s+]*%d+[%.%d]*", blur: "\\blur[%s+]*%d+[%.%d]*", fs: "\\fs[%s+]*%d+[%.%d]*",
    fscx: "\\fscx[%s+]*%d+[%.%d]*", fscy: "\\fscy[%s+]*%d+[%.%d]*", fsp: "\\fsp[%s+]*%-?%d+[%.%d]*",
    frx: "\\frx[%s+]*%-?%d+[%.%d]*", fry: "\\fry[%s+]*%-?%d+[%.%d]*", frz: "\\fr[z]*[%s+]*%-?%d+[%.%d]*",
    fax: "\\fax[%s+]*%-?%d+[%.%d]*", fay: "\\fay[%s+]*%-?%d+[%.%d]*", color1: "\\1?c[%s+]*&H%x+&",
    color2: "\\2c[%s+]*&H%x+&", color3: "\\3c[%s+]*&H%x+&", color4: "\\4c[%s+]*&H%x+&",
    alpha1: "\\1a[%s+]*&H%x+&", alpha2: "\\2a[%s+]*&H%x+&", alpha3: "\\3a[%s+]*&H%x+&",
    alpha4: "\\4a[%s+]*&H%x+&", alpha: "\\alpha[%s+]*&H%x+&", pos: "\\pos%b()",
    move: "\\move%b()", org: "\\org%b()", clip: "\\i?clip%b()",
    fad: "\\fad%b()", fade: "\\fade%b()", bold: "\\b%d",
    italic: "\\i%d", strikout: "\\s%d", underline: "\\u%d", 
    fn: "\\fn[%s+]*[^\\}]*", an: "\\an[%s+]*%d", "%b{}"
}

zeref.rd = (x, dec) ->
    if dec and dec >= 1 then
        dec = 10 ^ math.floor dec
        math.floor(x * dec + 0.5) / dec 
    else 
        math.floor x + 0.5

zeref.math_angle = (x1, y1, x2, y2) ->
    angle = 0
    Ang = math.deg(math.atan((y2 - y1) / (x2 - x1)))
    if x2 > x1 and y2 > y1
        angle = 360 - Ang
    elseif x2 > x1 and y2 < y1
        angle = -Ang
    elseif x2 < x1 and y2 < y1
        angle = 180 - Ang
    elseif x2 < x1 and y2 > y1
        angle = 180 - Ang
    elseif x2 > x1 and y2 == y1
        angle = 0
    elseif x2 < x1 and y2 == y1
        angle = 180
    elseif x2 == x1 and y2 < y1
        angle = 90
    elseif x2 == x1 and y2 > y1
        angle = 270
    elseif x2 == x1 and y2 == y1
        angle = 0
    return zeref.rd angle, 3

zeref.math_polar = (angle, radius, Return) ->
    angle = angle or 0
    radius = radius or 0
    Px = zeref.rd radius * math.cos(math.rad(angle)), 3
    Py = zeref.rd -radius * math.sin(math.rad(angle)), 3
    if Return == "x" then
        return Px
    if Return == "y" then
        return Py
    return Px, Py

zeref.math_distance = (x1, y1, x2, y2) ->
    return zeref.rd( ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5, 3)

zeref.math_distance2 = (v1, v2) ->
    return zeref.rd((v2 - v1) ^ 2, 3)

zeref.shape_rd = (Shape, Round) ->
    Round = Round or 3
    Shape = Shape\gsub "%-?%d+[%.%d]*", (n) ->
        return zeref.rd tonumber(n), Round
    return Shape

zeref.ipol_n = (pct, min, max) ->
    if pct <= 0 then min elseif pct >= 1 then max else zeref.rd pct * (max - min) + min, 3

zeref.interpolate_shape = (val_1, val_2, pct) ->
    k = 1
    tbl_1 = [tonumber c for c in val_1\gmatch "%-?%d+[%.%d]*"]
    tbl_2 = [tonumber c for c in val_2\gmatch "%-?%d+[%.%d]*"]
    val_1 = val_1\gsub "%-?%d+[%.%d]*", (val) -> 
        val = tbl_1[k] + (tbl_2[k] - tbl_1[k]) * pct 
        k += 1
        return zeref.rd val, 3
    return val_1

zeref.shape_displace = (Shape, Dx, Dy) ->
    Dx, Dy = Dx or 0, Dy or 0
    Shape = Shape\gsub "(%-?%d+[%.%d]*)%s+(%-?%d+[%.%d]*)", (x, y) ->
        x, y = tonumber(x), tonumber(y)
        return sf "%s %s", x + Dx, y + Dy
    return zeref.shape_clean Shape

zeref.shape_scale = (Shape, Sx, Sy) ->
    Sx, Sy = Sx or 0, Sy or 0
    Shape = Shape\gsub "(%-?%d+[%.%d]*)%s+(%-?%d+[%.%d]*)", (x, y) ->
        x, y = tonumber(x), tonumber(y)
        return sf "%s %s", x * Sx / 100, y * Sy / 100
    return zeref.shape_clean Shape

zeref.shape_area = (Shape) ->
    table_rnk = (Table) ->
        table_rank = util.deep_copy Table
        table.sort table_rank, (a, b) ->
            return a < b
        if table_rank[1]
            return table_rank[#table_rank] - table_rank[1]
        return 0
    shape_px, shape_py = {}, {}
    shape_parts = [tonumber(c) for c in Shape\gmatch "%-?%d+[%.%d]*"]
    for i = 1, #shape_parts / 2
        shape_px[i] = shape_parts[2 * i - 1]
        shape_py[i] = shape_parts[2 * i - 0]
    shape_width, shape_height = 0, 0
    if #shape_parts > 0
        shape_width = table_rnk shape_px
        shape_height = table_rnk shape_py
    return shape_width, shape_height

zeref.shape_info = (Shape) ->
    shape_coor_x = [tonumber(x) for x in Shape\gmatch "(%-?%d+[%.%d]*)%s+%-?%d+[%.%d]*"]
    shape_coor_y = [tonumber(y) for y in Shape\gmatch "%-?%d+[%.%d]*%s+(%-?%d+[%.%d]*)"]
    table_min = (Table) ->
        table_mi = table.copy Table
        table.sort table_mi, (a, b) ->
            return a < b
        if table_mi[1]
            return table_mi[1]
        return 0
    table_max = (Table) ->
        table_ma = table.copy Table
        table.sort table_ma, (a, b) ->
            return a < b
        if table_ma[#table_ma]
            return table_ma[#table_ma]
        return 0
    shape_x2 = table.copy shape_coor_x
    shape_y2 = table.copy shape_coor_y
    minx = table_min shape_coor_x, "min"
    maxx = table_max shape_coor_x, "max"
    miny = table_min shape_coor_y, "min"
    maxy = table_max shape_coor_y, "max"
    w_shape = maxx - minx 
    h_shape = maxy - miny
    c_shape = minx + w_shape / 2 
    m_shape = miny + h_shape / 2
    n_shape = #shape_coor_x
    n_points = #shape_coor_x
    return {
        :shape_x2, :shape_y2, :minx, :miny,
        :maxx, :maxy, :w_shape, :h_shape,
        :c_shape, :m_shape, :n_shape, :n_points
    }

zeref.shape_origin = (Shape) ->
    nminx, nminy = zeref.shape_info(Shape).minx, zeref.shape_info(Shape).miny
    Shape = zeref.shape_displace(Shape, -nminx, -nminy)
    return zeref.shape_clean Shape

zeref.shape_incenter = (Shape) ->
    s_width, s_height = zeref.shape_area Shape
    Shape = zeref.shape_origin Shape
    Shape = zeref.shape_displace Shape, -s_width / 2, -s_height / 2
    return zeref.shape_rd Shape, 3

zeref.shape_clean = (Shape) ->
    Shape = Shape\gsub(" c", "")\gsub("%s+", " ")
    return zeref.shape_rd Shape

zeref.shape_rotate = (Shape, Angle, org_x, org_y) ->
    Ang = Angle or 0
    cx = org_x or 0
    cy = org_y or 0
    Shape = Shape\gsub "(%-?%d+[%.%d]*)%s+(%-?%d+[%.%d]*)", (x, y) ->
        x, y = tonumber(x), tonumber(y)
        new_ang = zeref.math_angle(cx, cy, x, y)
        new_rad = zeref.math_distance(cx, cy, x, y)
        x = cx + zeref.math_polar(new_ang + Ang, new_rad, "x")
        y = cy + zeref.math_polar(new_ang + Ang, new_rad, "y")
        return string.format("%s %s", x, y)
    return zeref.shape_clean Shape

zeref.shape_origin_pos = (Shape) ->
    val_x, val_y = zeref.shape_info(Shape).minx, zeref.shape_info(Shape).miny
    Shape = zeref.shape_origin(Shape)
    return zeref.shape_clean(Shape), val_x, val_y

zeref.table_view = (Table, Table_name, indent) ->
    cart, autoref = "", ""
    isemptytable = (Table) ->
        return next(Table) == nil
    basicSerialize = (o) ->
        so = tostring(o)
        if type(o) == "function"
            info = debug.getinfo o, "S"
            if info.what == "C"
                return string.format "%q", so .. ", C function"
            return string.format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
        elseif type(o) == "number" or type(o) == "boolean"
            return so
        return string.format "%q", so
    addtocart = (value, Table_name, indent, saved, field) ->
        indent = indent or ""
        saved = saved or {}
        field = field or Table_name
        cart ..= indent .. field
        if type(value) ~= "table"
            cart ..= " = " .. basicSerialize(value) .. ";\n"
        else
            if saved[value]
                cart ..= " = {}; -- " .. saved[value] .. " (self reference)\n"
                autoref ..= Table_name .. " = " .. saved[value] .. ";\n"
            else
                saved[value] = Table_name
                if isemptytable(value)
                    cart ..= " = {};\n"
                else
                    cart ..= " = {\n"
                    for k, v in pairs(value) do
                        k = basicSerialize(k)
                        fname = string.format "%s[ %s ]", Table_name, k
                        field = string.format "[ %s ]", k
                        addtocart v, fname, indent .. "	", saved, field
                    cart = string.format "%s%s};\n", cart, indent
    Table_name = Table_name or "table_unnamed"
    if type(Table) ~= "table"
        return string.format "%s = %s", Table_name, basicSerialize(Table)
    addtocart Table, Table_name, indent
    return cart .. autoref

zeref.tags = (text) ->
    if text\match "%b{}"
        return text\match("%b{}")\sub(2, -2)
    return ""

zeref.cl_tags = (text) ->
    text = text\gsub("%b{}", "")\gsub("\\N", " ")\gsub("\\n", " ")\gsub("\\h", " ")
    return text

zeref.kill_tags = (tags, modes) ->
    if modes == "shape"
        tags = tags\gsub(tags_caps.fs, "")\gsub(tags_caps.fscx, "")\gsub(tags_caps.fscy, "")
        tags = tags\gsub(tags_caps.fsp, "")\gsub(tags_caps.frz, "")\gsub(tags_caps.fn, "")
    if modes == "shape2"
        tags = tags\gsub(tags_caps.fs, "")\gsub(tags_caps.fscx, "")\gsub(tags_caps.fscy, "")
        tags = tags\gsub(tags_caps.fsp, "")\gsub(tags_caps.fn, "")
    if modes == "full"
        tags = tags\gsub(tags_caps[#tags_caps], "")
    return tags

zeref.tags2style = (subs, line) ->
    tags, vtext = "", line.text
    meta, styles = karaskel.collect_head subs
    for k = 1, styles.n
        if line.margin_l > 0
            styles[k].margin_l = line.margin_l
        if line.margin_r > 0
            styles[k].margin_r = line.margin_r
        if line.margin_t > 0
            styles[k].margin_v = line.margin_t
        if line.margin_b > 0
            styles[k].margin_v = line.margin_b
        if vtext\match "%b{}"
            tags = vtext\match "%b{}"
            if tags\match "\\an[%s+]*%d"
                styles[k].align = tonumber tags\match "\\an[%s+]*(%d)"
            if tags\match "\\fn[%s+]*[^\\}]*"
                styles[k].fontname = tags\match "\\fn[%s+]*([^\\}]*)"
            if tags\match "\\fs[%s+]*%d+[%.%d+]*"
                styles[k].fontsize = tonumber tags\match "\\fs[%s+]*(%d+[%.%d+]*)"
            if tags\match "\\fscx[%s+]*%d+[%.%d+]*"
                styles[k].scale_x = tonumber tags\match "\\fscx[%s+]*(%d+[%.%d+]*)"
            if tags\match "\\fscy[%s+]*%d+[%.%d+]*"
                styles[k].scale_y = tonumber tags\match "\\fscy[%s+]*(%d+[%.%d+]*)"
            if tags\match "\\fsp[%s+]*%-?%d+[%.%d+]*"
                styles[k].spacing = tonumber tags\match "\\fsp[%s+]*(%-?%d+[%.%d+]*)"
            if tags\match "\\bord[%s+]*%d+[%.%d+]*"
                styles[k].outline = tonumber tags\match "\\bord[%s+]*(%d+[%.%d+]*)"
            if tags\match "\\shad[%s+]*%d+[%.%d+]*"
                styles[k].shadow = tonumber tags\match "\\shad[%s+]*(%d+[%.%d+]*)"
            if tags\match "\\fr[z]*[%s+]*%-?%d+[%.%d+]*"
                styles[k].angle = tonumber tags\match "\\fr[z]*[%s+]*(%-?%d+[%.%d+]*)"
            if tags\match "\\b1"
                styles[k].bold = true
            if tags\match "\\i1"
                styles[k].italic = true
            if tags\match "\\u1"
                styles[k].underline = true
            if tags\match "\\s1"
                styles[k].strikeout = true
    return meta, styles

zeref.text_to_char = (text) ->
    char = [c for c in unicode.chars text]
    return char

zeref.char_metrics = (line) -> -- gera cordenadas de caracteres, width, left e center
    tchar = zeref.text_to_char line.text_stripped
    char, char_nob, left = {}, {}, line.left
    char.n, char.text = #tchar, ""
    for k = 1, char.n
        char[k] = {}
        char[k].text_stripped = tchar[k]
        if char[k].text_stripped != " " char_nob[#char_nob + 1] = char[k]
        char[k].width = aegisub.text_extents line.styleref, tchar[k]
        char[k].left = left
        char[k].center = left + char[k].width / 2
        char[k].right = left + char[k].width
        char[k].start_time = line.start_time
        char[k].end_time = line.end_time
        char[k].duration = char[k].end_time - char[k].start_time
        left = left + char[k].width
    char_nob.text = char.text
    return char_nob

zeref.find_cords = (line, meta) ->
    cords = {
        pos: {x: 0, y: 0}
        move: {x1: 0, y1: 0, x2: 0, y2: 0}
        org: {x: 0, y: 0}
        rots: {frz: line.styleref.angle, fax: 0, fay: 0, frx: 0, fry: 0}
    }
    al = line.styleref.align
    if al == 1
        cords.pos.x, cords.pos.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
        cords.move.x1, cords.move.y1 = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
        cords.org.x, cords.org.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
    elseif al == 2
        cords.pos.x, cords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
        cords.move.x1, cords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
        cords.org.x, cords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
    elseif al == 3
        cords.pos.x, cords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
        cords.move.x1, cords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
        cords.org.x, cords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
    elseif al == 4
        cords.pos.x, cords.pos.y = line.styleref.margin_l, meta.res_y / 2
        cords.move.x1, cords.move.y1 = line.styleref.margin_l, meta.res_y / 2
        cords.org.x, cords.org.y = line.styleref.margin_l, meta.res_y / 2
    elseif al == 5
        cords.pos.x, cords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
        cords.move.x1, cords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
        cords.org.x, cords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
    elseif al == 6
        cords.pos.x, cords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
        cords.move.x1, cords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y / 2
        cords.org.x, cords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
    elseif al == 7
        cords.pos.x, cords.pos.y = line.styleref.margin_l, line.styleref.margin_v
        cords.move.x1, cords.move.y1 = line.styleref.margin_l, line.styleref.margin_v
        cords.org.x, cords.org.y = line.styleref.margin_l, line.styleref.margin_v
    elseif al == 8
        cords.pos.x, cords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
        cords.move.x1, cords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
        cords.org.x, cords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
    elseif al == 9
        cords.pos.x, cords.pos.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
        cords.move.x1, cords.move.y1 = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
        cords.org.x, cords.org.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
    if line.text\match "%b{}"
        if line.text\match "\\frx%-?%d+[%.%d+]*"
            frx = line.text\match "\\frx(%-?%d+[%.%d+]*)"
            cords.rots.frx = tonumber frx
        if line.text\match "\\fry%-?%d+[%.%d+]*"
            fry = line.text\match "\\fry(%-?%d+[%.%d+]*)"
            cords.rots.fry = tonumber fry
        if line.text\match "\\fax%-?%d+[%.%d+]*"
            fax = line.text\match "\\fax(%-?%d+[%.%d+]*)"
            cords.rots.fax = tonumber fax
        if line.text\match "\\fay%-?%d+[%.%d+]*"
            fay = line.text\match "\\fay(%-?%d+[%.%d+]*)"
            cords.rots.fay = tonumber fay
        if line.text\match "\\pos%(%-?%d+[%.%d+]*,%-?%d+[%.%d+]*%)"
            px, py = line.text\match "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)"
            cords.pos.x = tonumber px
            cords.pos.y = tonumber py
        if line.text\match "\\move%(%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*"
            x1, y1, x2, y2, t1, t2 = line.text\match "\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)"
            cords.move.x1 = tonumber x1
            cords.move.y1 = tonumber y1
            cords.move.x2 = tonumber x2
            cords.move.y2 = tonumber y2
        if line.text\match "\\org%(%-?%d+[%.%d+]*,%-?%d+[%.%d+]*%)"
            ox, oy = line.text\match "\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)"
            cords.org.x = tonumber ox
            cords.org.y = tonumber oy
    return cords

zeref.text_to_shape = (line, text, raw) ->
    text = text or zeref.cl_tags(line.text_stripped)
    while text\sub(-1, -1) == " "
        text = text\sub 1, -2
    text_scale = 1
    style_cfg = {line.styleref.fontname, line.styleref.bold, line.styleref.italic,
    line.styleref.underline, line.styleref.strikeout, line.styleref.fontsize,
    line.styleref.scale_x, line.styleref.scale_y, line.styleref.spacing}
    ----------------------------
    font_name = style_cfg[1]
    bold      = style_cfg[2]
    italic    = style_cfg[3]
    underline = style_cfg[4]
    strikeout = style_cfg[5]
    font_size = style_cfg[6]
    scale_x   = text_scale * (style_cfg[7]) / 100
    scale_y   = text_scale * (style_cfg[8]) / 100
    spacing   = style_cfg[9]
    ----------------------------
    vals_font = {font_name, bold, italic, underline, strikeout, font_size, scale_x, scale_y, spacing}
    extents = Yutils.decode.create_font(unpack(vals_font)).text_extents(text)
    text_font = Yutils.decode.create_font unpack(vals_font)
    text_shape = text_font.text_to_shape text
    wd, hg = zeref.shape_area text_shape
    nwd, nhg = tonumber(extents.width), tonumber(extents.height)
    text_off_x_sh = 0.5 * (wd - text_scale * nwd)
    text_off_y_sh = 0.5 * (hg - text_scale * nhg)
    text_shapecf = zeref.shape_displace text_shape, text_off_x_sh, text_off_y_sh
    if raw
        return zeref.shape_clean text_shape
    return zeref.shape_clean text_shapecf

zeref.text_to_shape_2 = (line) ->
    shape = zeref.clip_to_shape(zeref.text_to_clip(line, line.styleref.align, 0, 0), line.styleref.align, 0, 0)
    return shape

zeref.text_to_clip = (line, an, px, py, rot) ->
    text_shape = zeref.text_to_shape line
    text_shape_f = zeref.text_to_shape line, nil, true
    width, height = zeref.shape_area text_shape
    if an == 1
        shape = zeref.shape_displace text_shape_f, px, py - line.height
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 2
        shape = zeref.shape_displace text_shape, px - width / 2, py - (line.height / 2) - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 3
        shape = zeref.shape_displace text_shape, px - line.width - (width - line.width) / 2, py - (line.height / 2) - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 4
        shape = zeref.shape_displace text_shape_f, px, py - line.height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 5
        shape = zeref.shape_displace text_shape, px - width / 2, py - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 6
        shape = zeref.shape_displace text_shape, px - line.width - (width - line.width) / 2, py - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 7
        shape = zeref.shape_displace text_shape_f, px, py
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 8
        shape = zeref.shape_displace text_shape, px - width / 2, py + (line.height / 2) - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 9
        shape = zeref.shape_displace text_shape, px - line.width - (width - line.width) / 2, py + (line.height / 2) - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape

zeref.shape_to_clip = (shape, an, px, py, sx, sy, rot) ->
    sx, sy = sx or 100, sy or 100
    shape = zeref.shape_scale shape, sx, sy
    width, height = zeref.shape_area shape
    if an == 1
        shape = zeref.shape_displace shape, px, py - height
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 2
        shape = zeref.shape_displace shape, px - width / 2, py - height
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 3
        shape = zeref.shape_displace shape, px - width, py - height
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 4
        shape = zeref.shape_displace shape, px, py - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 5
        shape = zeref.shape_displace shape, px - width / 2, py - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 6
        shape = zeref.shape_displace shape, px - width, py - height / 2
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 7
        shape = zeref.shape_displace shape, px, py
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 8
        shape = zeref.shape_displace shape, px - width / 2, py
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape
    elseif an == 9
        shape = zeref.shape_displace shape, px - width, py
        if rot
            return zeref.shape_rotate shape, rot.rot, px, py
        return shape

zeref.clip_to_shape = (clip, an, px, py) ->
    n_to_v = (l, t, r, b) -> -- clip numerico para clip vetorial
        return string.format "m %s %s l %s %s %s %s %s %s", l, t, r, t, r, b, l, b
    clip = clip\gsub "\\i?clip%b()", (n) ->
        if n\match "m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*"
            return n\match "m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*"
        elseif n\match "%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*"
            sl, st, sr, sb = n\match "(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)"
            return n_to_v sl, st, sr, sb
    shape = clip
    width, height = zeref.shape_area shape
    if an == 1
        shape = zeref.shape_displace shape, -px, -py + height
        return shape
    elseif an == 2
        shape = zeref.shape_displace shape, -px + width / 2, -py + height
        return shape
    elseif an == 3
        shape = zeref.shape_displace shape, -px + width, -py + height
        return shape
    elseif an == 4
        shape = zeref.shape_displace shape, -px, -py + height / 2
        return shape
    elseif an == 5
        shape = zeref.shape_displace shape, -px + width / 2, -py + height / 2
        return shape
    elseif an == 6
        shape = zeref.shape_displace shape, -px + width, -py + height / 2
        return shape
    elseif an == 7
        shape = zeref.shape_displace shape, -px, -py
        return shape
    elseif an == 8
        shape = zeref.shape_displace shape, -px + width / 2, -py
        return shape
    elseif an == 9
        shape = zeref.shape_displace shape, -px + width, -py
        return shape

return zeref
