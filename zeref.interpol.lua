zeref = require 'lib-zeref.zeref-utils'

script_name = "Everything Interpolations"
script_description = "Interpolates from selected tags and by characters."
script_version = "1.6"

--
local sf, rd, ipol_n = string.format, zeref.rd, zeref.ipol_n
local ipol_c, ipol_a, KE_ipol_shp = zeref.ipol_c, zeref.ipol_a, zeref.interpolate_shape
local frame_dur, msa, msb = 41.708, aegisub.ms_from_frame(1), aegisub.ms_from_frame(101)
if msb then frame_dur = rd(( msb - msa ) / 100, 3) end
--

local tags_1 = {"\\bord", "\\xbord", "\\ybord", "\\be", "\\shad", "\\xshad", "\\yshad", "\\blur"}
local tags_2 = {"\\fs", "\\fscx", "\\fscy", "\\fsp"}
local tags_3 = {"\\frx", "\\fry", "\\frz", "\\fax", "\\fay"}
local tags_4 = {"\\c", "\\2c", "\\3c", "\\4c", "\\1a", "\\2a", "\\3a", "\\4a", "\\alpha"}
local tags_5 = {"\\pos", "\\move", "\\org", "\\i_clip"}
local tags_6 = {"\\fad"}

local GUI = function()
    local tbl1, tbl2, tbl3, tbl4, tbl5, tbl6
    local GUI = {
        {class = "label", label = ":Fill:", x = 0, y = 0},
        {class = "label", label = ":Scale:", x = 2, y = 0},
        {class = "label", label = ":Rotation:", x = 4, y = 0},
        {class = "label", label = ":Stylization:", x = 6, y = 0},
        {class = "label", label = ":Coordinates:", x = 8, y = 0},
        {class = "label", label = ":Transition:", x = 10, y = 0},
        {class = "label", label = ":Others:", x = 0, y = 9},
        {class = "checkbox", name = "shapes", label = "Shape", x = 0, y = 10, value = false},
        {class = "checkbox", name = "times", label = "Time", x = 2, y = 10, value = false}
    }
    for a = 1, #tags_1 do
        tbl1 = {class = "checkbox", name = tags_1[a]:gsub("\\", ""), label = tags_1[a], x = 0, y = a, value = false}
        table.insert(GUI, tbl1)
    end
    for b = 1, #tags_2 do
        tbl2 = {class = "checkbox", name = tags_2[b]:gsub("\\", ""), label = tags_2[b], x = 2, y = b, value = false}
        table.insert(GUI, tbl2)
    end
    for c = 1, #tags_3 do
        tbl3 = {class = "checkbox", name = tags_3[c]:gsub("\\", ""), label = tags_3[c], x = 4, y = c, value = false}
        table.insert(GUI, tbl3)
    end
    for d = 1, #tags_4 do
        tbl4 = {class = "checkbox", name = tags_4[d]:gsub("\\", "c"), label = tags_4[d], x = 6, y = d, value = false}
        table.insert(GUI, tbl4)
    end
    for e = 1, #tags_5 do
        tbl5 = {class = "checkbox", name = tags_5[e]:gsub("\\", ""), label = tags_5[e], x = 8, y = e, value = false}
        table.insert(GUI, tbl5)
    end
    for f = 1, #tags_6 do
        tbl6 = {class = "checkbox", name = tags_6[f]:gsub("\\", ""), label = tags_6[f], x = 10, y = f, value = false}
        table.insert(GUI, tbl6)
    end
    local tbl_ext1 = {class = "label", label = ":Accel:", x = 0, y = 11}
    local tbl_ext2 = {class = "floatedit", name = "vaccel", x = 0, y = 12, width = 4, height = 2, min = 0, value = 1}
    table.insert(GUI, tbl_ext1)
    table.insert(GUI, tbl_ext2)
    return GUI
end

local fGUI = {
    {class = "label", label = ":Step:", x = 0, y = 0},
    {class = "intedit", name = "step", x = 0, y = 1, height = 2, width = 2, min = 1, value = 1},
    {class = "checkbox", name = "remove", label = "Remove first line?", x = 0, y = 3, value = false}
}

local tags_replace = {
    "\\bord[%s+]*%d+[%.%d]*", "\\xbord[%s+]*%d+[%.%d]*", "\\ybord[%s+]*%d+[%.%d]*",
    "\\be[%s+]*%d+[%.%d]*", "\\shad[%s+]*%d+[%.%d]*", "\\xshad[%s+]*%d+[%.%d]*",
    "\\yshad[%s+]*%d+[%.%d]*", "\\blur[%s+]*%d+[%.%d]*", "\\fs[%s+]*%d+[%.%d]*",
    "\\fscx[%s+]*%d+[%.%d]*", "\\fscy[%s+]*%d+[%.%d]*", "\\fsp[%s+]*%-?%d+[%.%d]*",
    "\\frx[%s+]*%-?%d+[%.%d]*", "\\fry[%s+]*%-?%d+[%.%d]*", "\\fr[z]*[%s+]*%-?%d+[%.%d]*",
    "\\fax[%s+]*%-?%d+[%.%d]*", "\\fay[%s+]*%-?%d+[%.%d]*", "\\1?c[%s+]*&H%x+&",
    "\\2c[%s+]*&H%x+&", "\\3c[%s+]*&H%x+&", "\\4c[%s+]*&H%x+&",
    "\\1a[%s+]*&H%x+&", "\\2a[%s+]*&H%x+&", "\\3a[%s+]*&H%x+&",
    "\\4a[%s+]*&H%x+&", "\\alpha[%s+]*&H%x+&", "\\pos%b()",
    "\\move%b()", "\\org%b()", "\\i?clip%b()",
    "\\fad%b()"
}

local tagscap = {
    "(\\bord)[%s+]*(%d+[%.%d]*)", "(\\xbord)[%s+]*(%d+[%.%d]*)", "(\\ybord)[%s+]*(%d+[%.%d]*)", 
    "(\\be)[%s+]*(%d+[%.%d]*)", "(\\shad)[%s+]*(%d+[%.%d]*)", "(\\xshad)[%s+]*(%d+[%.%d]*)", 
    "(\\yshad)[%s+]*(%d+[%.%d]*)", "(\\blur)[%s+]*(%d+[%.%d]*)", "(\\fs)[%s+]*(%d+[%.%d]*)", 
    "(\\fscx)[%s+]*(%d+[%.%d]*)", "(\\fscy)[%s+]*(%d+[%.%d]*)", "(\\fsp)[%s+]*(%-?%d+[%.%d]*)", 
    "(\\frx)[%s+]*(%-?%d+[%.%d]*)", "(\\fry)[%s+]*(%-?%d+[%.%d]*)", "(\\fr[z]*)[%s+]*(%-?%d+[%.%d]*)",
    "(\\fax)[%s+]*(%-?%d+[%.%d]*)", "(\\fay)[%s+]*(%-?%d+[%.%d]*)", "(\\1?c)[%s+]*(&H*%x+&)", 
    "(\\2c)[%s+]*(&H*%x+&)", "(\\3c)[%s+]*(&H*%x+&)", "(\\4c)[%s+]*(&H*%x+&)", 
    "(\\1a)[%s+]*(&H*%x+&)", "(\\2a)[%s+]*(&H*%x+&)", "(\\3a)[%s+]*(&H*%x+&)", 
    "(\\4a)[%s+]*(&H*%x+&)", "(\\alpha)[%s+]*(&H*%x+&)"
}

local tags = {
    "\\bord", "\\xbord", "\\ybord", 
    "\\be", "\\shad", "\\xshad", 
    "\\yshad", "\\blur", "\\fs", 
    "\\fscx", "\\fscy", "\\fsp", 
    "\\frx", "\\fry", "\\fr",
    "\\fax", "\\fay", "\\c", 
    "\\2c", "\\3c", "\\4c", 
    "\\1a", "\\2a", "\\3a", 
    "\\4a", "\\alpha", "\\pos",
    "\\move", "\\org", "\\clip",
    "\\fad"
}

local KE_table_concat4 = function(...) -- concatena valores de tabelas mutualmente
    local Table = {...}
    if #Table == 1 then Table = ... end
    local tbl_sizes = {}
    for i = 1, #Table do tbl_sizes[i] = #Table[i] end
    local max = function(Table)
        local table_max = table.copy(Table)
        table.sort(table_max, function(a, b) return a < b end)
        if table_max[#table_max] then return table_max[#table_max] end
        return 0
    end
    local max_sizes = max(tbl_sizes)
    local tbl_concat4 = {}
    for i = 1, max_sizes do
        tbl_concat4[i] = ""
        for k = 1, #Table do tbl_concat4[i] = tbl_concat4[i] .. (Table[k][i] or "") end
    end
    return tbl_concat4
end

local KE_ipol = function(tab, loop, tags) -- interpola valores de uma tabela
    local vtable, ipols = table.copy(tab), {}
    local ipol_i, ipol_f, pct_ip
    local max_loop = loop - 1
    local pol, tags = ipol_n, tags or ""
    local function string_in_tbl(str_in_tbl)
        for i = 1, #str_in_tbl do if type(str_in_tbl[ i ]) == "string" then return true, str_in_tbl[ i ] end end return false
    end
    if string_in_tbl(vtable) then
        local _, Val_str = string_in_tbl(vtable)
        if Val_str:match("[&Hh]^*%x%x%x%x%x%x[&]*") then pol = ipol_c elseif Val_str:match("[&Hh]^*%x%x[&]*") then pol = ipol_a end
    end
    for i = 1, max_loop do
        ipol_i = vtable[math.floor((i - 1) / (max_loop / (#vtable - 1))) + 1]
        ipol_f = vtable[math.floor((i - 1) / (max_loop / (#vtable - 1))) + 2]
        pct_ip = math.floor((i - 1) % (max_loop / (#vtable - 1))) / (max_loop / (#vtable - 1))
        ipols[i] = tags .. pol(pct_ip, ipol_i, ipol_f)
    end
    ipols[#ipols + 1] = tags .. vtable[#vtable]
    return ipols
end

local tags_detect = function(line, vtext) -- Detecta as tags capturando o nome e o seu respectivo valor e se caso tiver valor, substitua na tabela tagsraw
    local vtags = {names = {}, values = {}}
    local tagss = {}
    for k = 1, #tags - 5 do
        tagss[k] = tags[k]
    end
    if vtext:match("%b{}") then
        if vtext:match("\\fr[z]*") then tagss[15] = vtext:match("\\fr[z]*") end -- caso encontre derivados dessa tag
        if vtext:match("\\1?c") then tagss[18] = vtext:match("\\1?c") end -- caso encontre derivados dessa tag
        for k = 1, #tagscap do
            vtext = vtext:gsub(tagscap[k],
                function(n, v)
                    table.insert(vtags.names, n)
                    table.insert(vtags.values, v)
                end
            )
            for j = 1, #vtags.names do
                for c = 1, #tagss do
                    if vtags.names[j]:match(tagss[c]) then
                        tagss[c] = tagss[c]:gsub(vtags.names[j], vtags.names[j] .. vtags.values[j])
                    end
                end
            end
        end
    end
    if tagss[1]:match("%d+[%.%d+]*") == nil then tagss[1] = tagss[1] .. line.styleref.outline end
    if tagss[2]:match("%d+[%.%d+]*") == nil then tagss[2] = tagss[2] .. 0 end
    if tagss[3]:match("%d+[%.%d+]*") == nil then tagss[3] = tagss[3] .. 0 end
    if tagss[4]:match("%d+[%.%d+]*") == nil then tagss[4] = tagss[4] .. 0 end
    if tagss[5]:match("%d+[%.%d+]*") == nil then tagss[5] = tagss[5] .. line.styleref.shadow end
    if tagss[6]:match("%-?%d+[%.%d+]*") == nil then tagss[6] = tagss[6] .. 0 end
    if tagss[7]:match("%-?%d+[%.%d+]*") == nil then tagss[7] = tagss[7] .. 0 end
    if tagss[8]:match("%d+[%.%d+]*") == nil then tagss[8] = tagss[8] .. 0 end
    if tagss[9]:match("%d+[%.%d+]*") == nil then tagss[9] = tagss[9] .. line.styleref.fontsize end
    if tagss[10]:match("%d+[%.%d+]*") == nil then tagss[10] = tagss[10] .. line.styleref.scale_x end
    if tagss[11]:match("%d+[%.%d+]*") == nil then tagss[11] = tagss[11] .. line.styleref.scale_y end
    if tagss[12]:match("%-?%d+[%.%d+]*") == nil then tagss[12] = tagss[12] .. line.styleref.spacing end
    if tagss[13]:match("%-?%d+[%.%d+]*") == nil then tagss[13] = tagss[13] .. 0 end
    if tagss[14]:match("%-?%d+[%.%d+]*") == nil then tagss[14] = tagss[14] .. 0 end
    if tagss[15]:match("%-?%d+[%.%d+]*") == nil then tagss[15] = tagss[15] .. line.styleref.angle end
    if tagss[16]:match("%-?%d+[%.%d+]*") == nil then tagss[16] = tagss[16] .. 0 end
    if tagss[17]:match("%-?%d+[%.%d+]*") == nil then tagss[17] = tagss[17] .. 0 end
    if tagss[18]:match("[&Hh]^*%x%x%x%x%x%x[&]*") == nil then tagss[18] = tagss[18] .. util.color_from_style(line.styleref.color1) end
    if tagss[19]:match("[&Hh]^*%x%x%x%x%x%x[&]*") == nil then tagss[19] = tagss[19] .. util.color_from_style(line.styleref.color2) end
    if tagss[20]:match("[&Hh]^*%x%x%x%x%x%x[&]*") == nil then tagss[20] = tagss[20] .. util.color_from_style(line.styleref.color3) end
    if tagss[21]:match("[&Hh]^*%x%x%x%x%x%x[&]*") == nil then tagss[21] = tagss[21] .. util.color_from_style(line.styleref.color4) end
    if tagss[22]:match("[&Hh]^*%x%x[&]*") == nil then tagss[22] = tagss[22] .. util.alpha_from_style(line.styleref.color1) end
    if tagss[23]:match("[&Hh]^*%x%x[&]*") == nil then tagss[23] = tagss[23] .. util.alpha_from_style(line.styleref.color2) end
    if tagss[24]:match("[&Hh]^*%x%x[&]*") == nil then tagss[24] = tagss[24] .. util.alpha_from_style(line.styleref.color3) end
    if tagss[25]:match("[&Hh]^*%x%x[&]*") == nil then tagss[25] = tagss[25] .. util.alpha_from_style(line.styleref.color4) end
    if tagss[26]:match("[&Hh]^*%x%x[&]*") == nil then tagss[26] = tagss[26] .. util.alpha_from_style(line.styleref.color1) end
    return tagss
end

local pols = function(loop, line, val_i, val_f, val_buttom)
    local n_vals, accel = {}, bts[42].value
    local tvalsI, tvalsF = tags_detect(line, val_i), tags_detect(line, val_f)
    for k = 1, #tags do n_vals[k] = {} end
    local function n_to_v(l, t, r, b) -- clip numerico para clip vetorial
        return sf("m %s %s l %s %s %s %s %s %s", l, t, r, t, r, b, l, b)
    end
    for k = 1, loop do
        local mod = (k - 1) ^ accel / (loop - 1) ^ accel
        if val_buttom <= 17 then
            local valsi = tvalsI[val_buttom]:match("\\%a+(%-?%d+[%.%d+]*)")
            local valsf = tvalsF[val_buttom]:match("\\%a+(%-?%d+[%.%d+]*)")
            n_vals[val_buttom][k] = sf("%s", tags[val_buttom] .. ipol_n(mod, valsi, valsf))
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. 0 .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. 0) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom > 17 and val_buttom <= 21 then
            local valsi = tvalsI[val_buttom]:match("\\[%d]*%a+(&H%x+&)")
            local valsf = tvalsF[val_buttom]:match("\\[%d]*%a+(&H%x+&)")
            n_vals[val_buttom][k] = sf("%s", tags[val_buttom] .. ipol_c(mod, valsi, valsf))
        end
        if val_buttom > 21 and val_buttom <= 26 then
            local valsi = tvalsI[val_buttom]:match("\\[%d]*%a+(&H%x+&)")
            local valsf = tvalsF[val_buttom]:match("\\[%d]*%a+(&H%x+&)")
            n_vals[val_buttom][k] = sf("%s", tags[val_buttom] .. ipol_a(mod, valsi, valsf))
        end
        if val_buttom == 1 then
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.outline  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.outline) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 5 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.shadow  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.shadow) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 9 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.fontsize  .. "%.%d+") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.fontsize) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 10 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.scale_x  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.scale_x) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 11 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.scale_y  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.scale_y) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 12 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.spacing  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.spacing) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 15 then 
            if n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.angle  .. "[%-?%.%d+]") then n_vals[val_buttom][k] = n_vals[val_buttom][k]
            elseif n_vals[val_buttom][k]:match(tags[val_buttom] .. line.styleref.angle) then n_vals[val_buttom][k] = "" end
        end
        if val_buttom == 18 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.color_from_style(line.styleref.color1)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 19 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.color_from_style(line.styleref.color2)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 20 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.color_from_style(line.styleref.color3)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 21 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.color_from_style(line.styleref.color4)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 22 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.alpha_from_style(line.styleref.color1)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 23 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.alpha_from_style(line.styleref.color2)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 24 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.alpha_from_style(line.styleref.color4)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 25 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.alpha_from_style(line.styleref.color4)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 26 then if n_vals[val_buttom][k]:match(tags[val_buttom] .. util.alpha_from_style(line.styleref.color1)) then n_vals[val_buttom][k] = "" end end
        if val_buttom == 27 then
            -- interpolação do \pos
            n_vals[27][k] = ""
            if val_i:match("\\pos%b()") and val_f:match("\\pos%b()") then
                local px_i, py_i = val_i:match("\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                local px_f, py_f = val_f:match("\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                px_i, py_i, px_f, py_f = tonumber(px_i), tonumber(py_i), tonumber(px_f), tonumber(py_f)
                n_vals[27][k] = sf("\\pos(%s,%s)", ipol_n(mod, px_i, px_f), ipol_n(mod, py_i, py_f))
            end
        elseif val_buttom == 28 then
            -- interpolação do \move
            n_vals[28][k] = ""
            if val_i:match("\\move%b()") and val_f:match("\\move%b()") then
                local mx1_i, my1_i, mx2_i, my2_i, mt1_i, mt2_i = val_i:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%d+[%.%d+]*),(%d+[%.%d+]*)%)")
                local mx1_f, my1_f, mx2_f, my2_f, mt1_f, mt2_f = val_f:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%d+[%.%d+]*),(%d+[%.%d+]*)%)")
                if mt1_i == nil and mt2_i == nil and mt1_f == nil and mt2_f == nil then
                    mx1_i, my1_i, mx2_i, my2_i = val_i:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_f, my1_f, mx2_f, my2_f = val_f:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_i, my1_i, mx2_i, my2_i = tonumber(mx1_i), tonumber(my1_i), tonumber(mx2_i), tonumber(my2_i)
                    n_vals[28][k] = sf("\\move(%s,%s,%s,%s)", ipol_n(mod, mx1_i, mx1_f), ipol_n(mod, my1_i, my1_f), ipol_n(mod, mx2_i, mx2_f), ipol_n(mod, my2_i, my2_f))
                elseif mt1_i ~= nil and mt2_i ~= nil and mt1_f ~= nil and mt2_f ~= nil then
                    mx1_i, my1_i, mx2_i, my2_i, mt1_i, mt2_i = tonumber(mx1_i), tonumber(my1_i), tonumber(mx2_i), tonumber(my2_i), tonumber(mt1_i), tonumber(mt2_i)
                    mx1_f, my1_f, mx2_f, my2_f, mt1_f, mt2_f = tonumber(mx1_f), tonumber(my1_f), tonumber(mx2_f), tonumber(my2_f), tonumber(mt1_f), tonumber(mt2_f)
                    n_vals[28][k] = sf("\\move(%s,%s,%s,%s,%s,%s)", ipol_n(mod, mx1_i, mx1_f), ipol_n(mod, my1_i, my1_f), ipol_n(mod, mx2_i, mx2_f),ipol_n(mod, my2_i, my2_f), ipol_n(mod, mt1_i, mt1_f), ipol_n(mod, mt2_i, mt2_f))
                elseif mt1_i == nil and mt2_i == nil and mt1_f ~= nil and mt2_f ~= nil then
                    mx1_i, my1_i, mx2_i, my2_i = val_i:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_f, my1_f, mx2_f, my2_f = val_f:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_i, my1_i, mx2_i, my2_i = tonumber(mx1_i), tonumber(my1_i), tonumber(mx2_i), tonumber(my2_i)
                    n_vals[28][k] = sf("\\move(%s,%s,%s,%s,%s,%s)", ipol_n(mod, mx1_i, mx1_f), ipol_n(mod, my1_i, my1_f), ipol_n(mod, mx2_i, mx2_f),ipol_n(mod, my2_i, my2_f), rd(0 + mt1_f * mod, 3), rd(0 + mt2_f * mod, 3))
                elseif mt1_i ~= nil and mt2_i ~= nil and mt1_f == nil and mt2_f == nil then
                    mx1_i, my1_i, mx2_i, my2_i = val_i:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_f, my1_f, mx2_f, my2_f = val_f:match("\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)")
                    mx1_i, my1_i, mx2_i, my2_i = tonumber(mx1_i), tonumber(my1_i), tonumber(mx2_i), tonumber(my2_i)
                    n_vals[28][k] = sf("\\move(%s,%s,%s,%s,%s,%s)", ipol_n(mod, mx1_i, mx1_f), ipol_n(mod, my1_i, my1_f), ipol_n(mod, mx2_i, mx2_f),ipol_n(mod, my2_i, my2_f), rd(mt1_i - mt1_i * mod, 3), rd(mt2_i - mt2_i * mod, 3))
                end
            end
        elseif val_buttom == 29 then
            -- interpolação do \org
            n_vals[29][k] = ""
            if val_i:match("\\org%b()") and val_f:match("\\org%b()") then
                local ox_i, oy_i = val_i:match("\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                local ox_f, oy_f = val_f:match("\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                ox_i, oy_i, ox_f, oy_f = tonumber(ox_i), tonumber(oy_i), tonumber(ox_f), tonumber(oy_f)
                n_vals[29][k] = sf("\\org(%s,%s)", ipol_n(mod, ox_i, ox_f), ipol_n(mod, oy_i, oy_f))
            end
        elseif val_buttom == 30 then
            -- interpolação do \clip - iclip
            n_vals[30][k] = ""
            if val_i:match("\\i?clip%b()") and val_f:match("\\i?clip%b()") then
                if val_i:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") and val_f:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") then
                    local nclip, csh_i = val_i:match("(\\i?clip)%([%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
                    local csh_f = val_f:match("\\i?clip%([%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
                    n_vals[30][k] = sf("%s(%s)", nclip, KE_ipol_shp(csh_i, csh_f, mod))
                elseif val_i:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") and val_f:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") == nil then
                    local nclip, csh_i = val_i:match("(\\i?clip)%([%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
                    local cpf_x1, cpf_y1, cpf_x2, cpf_y2 = val_f:match("\\i?clip%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                    local csh_f = n_to_v(cpf_x1, cpf_y1, cpf_x2, cpf_y2)
                    n_vals[30][k] = sf("%s(%s)", nclip, KE_ipol_shp(csh_i, csh_f, mod))
                elseif val_i:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") == nil and val_f:match("\\i?clip%([%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)") then
                    local nclip, cpi_x1, cpi_y1, cpi_x2, cpi_y2 = val_i:match("(\\i?clip)%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                    local csh_i = n_to_v(cpi_x1, cpi_y1, cpi_x2, cpi_y2)
                    local csh_f = val_f:match("\\i?clip%([%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
                    n_vals[30][k] = sf("%s(%s)", nclip, KE_ipol_shp(csh_i, csh_f, mod))
                else
                    local nclip, cpi_x1, cpi_y1, cpi_x2, cpi_y2 = val_i:match("(\\i?clip)%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                    local cpf_x1, cpf_y1, cpf_x2, cpf_y2 = val_f:match("\\i?clip%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                    cpi_x1, cpi_y1, cpi_x2, cpi_y2 = tonumber(cpi_x1), tonumber(cpi_y1), tonumber(cpi_x2), tonumber(cpi_y2)
                    cpf_x1, cpf_y1, cpf_x2, cpf_y2 = tonumber(cpf_x1), tonumber(cpf_y1), tonumber(cpf_x2), tonumber(cpf_y2)
                    n_vals[30][k] = sf("%s(%s,%s,%s,%s)", nclip, ipol_n(mod, cpi_x1, cpf_x1), ipol_n(mod, cpi_y1, cpf_y1), ipol_n(mod, cpi_x2, cpf_x2), ipol_n(mod, cpi_y2, cpf_y2))
                end
            end
        elseif val_buttom == 31 then
            -- interpolação do \fad
            n_vals[31][k] = ""
            if val_i:match("\\fad%b()") and val_f:match("\\fad%b()") then
                local fd1_i, fd2_i = val_i:match("\\fad%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                local fd1_f, fd2_f = val_f:match("\\fad%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)")
                fd1_i, fd2_i, fd1_f, fd2_f = tonumber(fd1_i), tonumber(fd2_i), tonumber(fd1_f), tonumber(fd2_f)
                n_vals[31][k] = sf("\\fad(%s,%s)", ipol_n(mod, fd1_i, fd1_f), ipol_n(mod, fd2_i, fd2_f))
            end
        end
    end
    return n_vals
end

local in_tags = function(line, vtext1, vtext2, loop) -- detecta o que foi selecionada e retorna uma tabela com todos valores de tags interpolados concatenados
    local ct, vals = 1, {}
    local vtags
    for k = 10, 40 do
        if bts[k].value == true then
            table.insert(vals, pols(loop, line, vtext1, vtext2, ct)[ct])
            vtags = KE_table_concat4(vals)
        end
        ct = ct + 1
    end
    return vtags
end

local cl_tags = function(ntags, tags) -- remove as tags anteriores
    for k = 1, #tags_replace do
        if ntags:match(tags_replace[k] or "") then
            tags = tags:gsub(tags_replace[k], "")
        end
    end
    return tags
end

local in_fn = function(subs, sel) -- retorna os valores referentes a primeira e última seleção
    local vals, refs = {}, {vals = {}, tags = {"", ""}}
    for _, i in ipairs(sel) do
        local l = subs[i]
        table.insert(vals, l)
    end
    refs.vals[1], refs.vals[2] = vals[1], vals[#vals]
    if refs.vals[1].text:match("%b{}") then refs.tags[1] = refs.vals[1].text:match("%b{}") end
    if refs.vals[2].text:match("%b{}") then refs.tags[2] = refs.vals[2].text:match("%b{}") end
    return refs
end

local in_line = function(subs, sel)
    local meta, styles = karaskel.collect_head(subs)
    local vals_in = in_fn(subs, sel)
    local text, tags, rtags = "", "", ""
    aegisub.progress.task("Processing...")
    for _, i in ipairs(sel) do
        local k = _
        aegisub.progress.set((i - 1) / #sel * 100)
        local l = subs[i]
        karaskel.preproc_line(subs, meta, styles, l)
        local rtext = l.text
        local ntags = in_tags(l, vals_in.tags[1], vals_in.tags[2], #sel)
        text = rtext:gsub("%b{}", "")
        if rtext:match("%b{}") then tags = rtext:match("%b{}"):sub(2, -2) end
        if bts[9].value == true then
            -- interpolação do time :)
            local IN1, FN1 = vals_in.vals[1].start_time, vals_in.vals[1].end_time
            local IN2, FN2 = vals_in.vals[2].start_time, vals_in.vals[2].end_time
            local polIN = IN1 + (IN2 - IN1) * (k - 1) / #sel
            local polFN = FN1 + (FN2 - FN1) * k / #sel
            l.start_time = polIN
            l.end_time = polFN
        end
        if bts[8].value == true then
            -- interpolação de shapes :)
            local v1, v2 = vals_in.vals[1].text, vals_in.vals[2].text
            if v1:match("%b{}") and v2:match("%b{}") then
                if v1:match("}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") and v2:match("}[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") then
                    local sh1, sh2 = v1:match("}[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"), v2:match("}[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)")
                    text = KE_ipol_shp(sh1, sh2, (k - 1) ^ bts[42].value / (#sel - 1) ^ bts[42].value)
                end
            else
                if v1:match("[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") and v2:match("[%s+]*m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") then
                    local sh1, sh2 = v1:match("[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)"), v2:match("[%s+]*(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)")
                    text = "{\\p1}" .. KE_ipol_shp(sh1, sh2, (k - 1) ^ bts[42].value / (#sel - 1) ^ bts[42].value)
                end
            end
        end
        l.text = sf("{%s}%s", tags, text)
        if tags == "" then l.text = sf("%s", text) end
        if ntags ~= nil then
            rtags = cl_tags(ntags[k], tags)
            l.text = sf("{%s}%s", rtags .. ntags[k], text )
            if rtext == "" or rtext:match("%b{}") == nil then
                l.text = sf("{%s}%s", ntags[k], text)
            end
        end
        subs[i] = l
    end
    aegisub.progress.set(100)
end

local valschar = function(tags, cp) -- carrega as tags que estarão entre exclamações e adiciona elas em tabelas separando valores e o nomes das tags
    local jtags, ntags, vtags, vltags = {}, {}, {}, ""
    if tags ~= "" then
        tags = tags:gsub("(\\[%d]*%a+%b!!)", function(x) table.insert(jtags, x) end)
        for i = 1, #jtags do
            vltags = loadstring(sf("return function() return {%s} end", jtags[i]:match("[%d]*%a+(%b!!)"):sub(2, -2)))()
            ntags[i] = "\\" .. jtags[i]:match("([%d]*%a+)%b!!")
            vtags[i] = vltags()
        end
        if cp then return jtags end
        return ntags, vtags, jtags
    end
end

local bychar = function(text) -- configura tudo para interpolação por character :)
    local textS = text:gsub("%b{}", "")
    local v1tag = {}
    local textT, vtags, tags_textT, tags_text, txttag, blank = {}, {}, {}, "", ""
    if text:match("%b{}") then
        txttag = text:match("%b{}")
        local nt, vt, jt = valschar(txttag)
        for c in text:gmatch("({[^%}]+)") do table.insert(v1tag, c) end -- indexa todas as tags que comporem a linha
        for k = 1, #jt do v1tag[1] = v1tag[1]:gsub(jt[k], "") end -- remove a expressão anterior
        if textS ~= "" then
            for c in unicode.chars(textS) do table.insert(textT, c) end -- gera os caracteres a partir do texto, indexando eles a uma tabela
            for i = 1, #vt do vtags[i] = KE_ipol(vt[i], #textT, nt[i]) end -- interpola os valores e concatena as tags
            for i = 1, #textT do
                tags_textT[i] = ""
                for k = 1, #vtags do
                    tags_textT[i] = tags_textT[i] .. vtags[k][i]
                end
                tags_textT[i] = "{" .. tags_textT[i] .. "}"
                if textT[i]:match("%s+") then
                    blank = textT[i]:match("%s+") -- pula os espaços
                    tags_text = tags_text .. blank
                elseif textT[i]:match("[\\Nnh]+") then
                    blank = textT[i]:match("[\\Nnh]+")
                    tags_text = tags_text .. blank
                else
                    if v1tag[1] ~= nil then
                        tags_textT[1] = v1tag[1] .. tags_textT[1]:gsub("{", "")
                    end
                    tags_text = tags_text .. tags_textT[i] .. textT[i]
                end
            end
            return tags_text
        end
    end
    return text
end

local frame_generator = function(subs, sel, step, del) -- gera frames a partir do valor de duração de linha
    local step, add = step or 1, 0
    aegisub.progress.task("Processing...")
    for _, i in ipairs(sel) do
        aegisub.progress.set((i - 1) / #sel * 100)
        local l = subs[i + add]
        l.comment = true
        subs[i + add] = l
        if del then subs.delete(i + add) add = add - 1 end
        local ls, lf = l.start_time, l.end_time - l.start_time
        local frames = rd(lf / (frame_dur * step), 3)
        for k = 1, frames do
            l.comment = false
            local line = table.copy(l)
            line.start_time = ls + lf * (k - 1) / frames
            line.end_time = ls + lf * k / frames
            subs.insert(i + add + 1, line)
            add = add + 1
        end
    end
    aegisub.progress.set(100)
end

local master_ipol = function(subs, sel)
    local bx, ck = aegisub.dialog.display(GUI(), {"Run", "Cancel"})
    bts = GUI()
    bts[8].value  = ck.shapes; bts[9].value = ck.times;   bts[10].value = ck.bord;
    bts[11].value = ck.xbord;  bts[12].value = ck.ybord;  bts[13].value = ck.be;
    bts[14].value = ck.shad;   bts[15].value = ck.xshad;  bts[16].value = ck.yshad;
    bts[17].value = ck.blur;   bts[18].value = ck.fs;     bts[19].value = ck.fscx;
    bts[20].value = ck.fscy;   bts[21].value = ck.fsp;    bts[22].value = ck.frx;
    bts[23].value = ck.fry;    bts[24].value = ck.frz;    bts[25].value = ck.fax;
    bts[26].value = ck.fay;    bts[27].value = ck.cc;     bts[28].value = ck.c2c;
    bts[29].value = ck.c3c;    bts[30].value = ck.c4c;    bts[31].value = ck.c1a;
    bts[32].value = ck.c2a;    bts[33].value = ck.c3a;    bts[35].value = ck.calpha;
    bts[36].value = ck.pos;    bts[37].value = ck.move;   bts[38].value = ck.org;
    bts[39].value = ck.i_clip; bts[40].value = ck.fad;    bts[42].value = ck.vaccel;
    if bx == "Run" then in_line(subs, sel) end
end

local master_character = function(subs, sel)
    for _, i in ipairs(sel) do
        local l = subs[i]
        local texto = bychar(l.text)
        l.text = texto
        subs[i] = l
    end
end

local activate = function(sel)
    for _, i in ipairs(sel) do
        if _ > 1 then return true end
    end
    return false
end

local master_frames = function(subs, sel)
    local bx, clk = aegisub.dialog.display(fGUI, {"Generate", "Exit"})
    fGUI[2].value = clk.step
    fGUI[3].value = clk.remove
    if bx == "Generate" then 
        if fGUI[3].value == true then return frame_generator(subs, sel, fGUI[2].value, true) else return frame_generator(subs, sel, fGUI[2].value) end
    end
end

local char_active = function(subs, sel)
    local tags, vls = ""
    for _, i in ipairs(sel) do
        local l = subs[i]
        if l.text:match("%b{}") then
            tags = l.text:match("%b{}")
            vls = valschar(tags, true)
            if #vls >= 1 then return true end
        end
    end
    return false
end

aegisub.register_macro("Zeref Macros/Interpolations Master/Everything Ipol", script_description, master_ipol, activate)
aegisub.register_macro("Zeref Macros/Interpolations Master/Everything Ipol - By Char", script_description, master_character, char_active)
aegisub.register_macro("Zeref Macros/Interpolations Master/Generate Frames", script_description, master_frames)