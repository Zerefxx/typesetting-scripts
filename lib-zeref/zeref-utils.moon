require "karaskel"
require "utils"
require "Yutils" -- https://github.com/Youka/Yutils

zeref = {}
zeref.ipol_c = util.interpolate_color
zeref.ipol_a = util.interpolate_alpha
sf = string.format

zeref.rd = (x, dec) ->
    if dec and dec >= 1 then
        dec = 10 ^ math.floor dec
        math.floor(x * dec + 0.5) / dec 
    else 
        math.floor x + 0.5

zeref.shape_rd = (Shape, Round) ->
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
    return Shape

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

zeref.tags2style = (subs, vtext) ->
    tags = ""
    meta, styles = karaskel.collect_head subs
    for k = 1, styles.n
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

zeref.text_to_shape = (line, Text) ->
    Text = Text or line.text_stripped
    while Text\sub(-1, -1) == " "
        Text = Text\sub 1, -2
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
    text_confi = {font_name, bold, italic, underline, strikeout, font_size, scale_x, scale_y, spacing}
    extents = Yutils.decode.create_font(unpack(text_confi)).text_extents(Text)
    text_font = Yutils.decode.create_font(unpack(text_confi))
    text_shape = text_font.text_to_shape(Text)
    wd, hg = zeref.shape_area(text_shape)
    text_off_x_sh = 0.5 * (wd - text_scale * tonumber(extents.width))
    text_off_y_sh = 0.5 * (hg - text_scale * tonumber(extents.height))
    text_shapecf = zeref.shape_displace(text_shape, text_off_x_sh, text_off_y_sh)
    if text_shapecf\match(" c ") or text_shapecf\match(" c")
        return zeref.shape_rd(text_shapecf\gsub(" c", ""), 3)
    return zeref.shape_rd(text_shapecf, 3)

return zeref