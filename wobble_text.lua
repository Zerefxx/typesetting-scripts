Yutils = include( "Yutils.lua" ) -- https://github.com/Youka/Yutils
include( "karaskel.lua" )

 -- Functions used -->> {{ https://github.com/KaraEffect0r/Kara_Effector }}

local frame_dur = 41.708
local xres, yres = aegisub.video_size( )
if not xres then
    xres, yres = 1280, 720
end
local ratio = xres / 1280
local msa = aegisub.ms_from_frame( 1 )
local msb = aegisub.ms_from_frame( 101 )
if msb then
    frame_dur = Yutils.math.round( ( msb - msa ) / 100, 3 )
end

local GUI = {
	{
		class = "checkbox", name = "ftr", label = "Remove first line?", x = 1, y = 0
	},
	{
		class = "label", label = "Accel:", x = 0, y = 3
	},
	{
		class = "label", label = "Continuity:", x = 0, y = 4
	},
	{
		class = "label", label = "Frequency in X:", x = 0, y = 1
	},
	{
		class = "label", label = "Amplitude in X:", x = 0, y = 2
	},
	{
		class = "label", label = "Frequency in Y:", x = 3, y = 1
	},
	{
		class = "label", label = "Amplitude in Y:", x = 3, y = 2
	},
	{
		class = "intedit", name = "accel", x = 1, y = 3, width = 2, height = 1, min = 1, value = 1
	},
	{
		class = "intedit", name = "cont", x = 1, y = 4, width = 2, height = 1, min = 1, value = 1
	},
	{
		class = "intedit", name = "frx", x = 1, y = 1, width = 2, height = 1, value = 0
	},
	{
		class = "intedit", name = "ampx", x = 1, y = 2, width = 2, height = 1, value = 0
	},
	{
		class = "intedit", name = "fry", x = 4, y = 1, width = 2, height = 1, value = 0
	},
	{
		class = "intedit", name = "ampy", x = 4, y = 2, width = 2, height = 1, value = 0
	},
	{
		class = "checkbox", name = "gen", label = "Generate Animation?", x = 4, y = 0
	},
}

__table_replay = function( Len, ... )
	local Len = Yutils.math.round( math.abs( Len ) )
	local Table = { }
	local e_val = { ... }
	if type( ... ) == "table" then
		e_val = ...
	end
	for i = 1, Len do
		for k = 1, #e_val do
			if type( e_val[ k ] ) == "function" then
				Table[ #Table + 1 ] = e_val[ k ]( )
			else
				Table[ #Table + 1 ] = e_val[ k ]
			end
		end
	end
	return Table
end

__table_duplicate = function( Table )
	local lookup_table = { }
	local function table_copy( Table )
		if type( Table ) ~= "table" then
			return Table
		elseif lookup_table[ Table ] then
			return lookup_table[ Table ]
		end
		local new_table = { }
		lookup_table[ Table ] = new_table
		for k, v in pairs( Table ) do
			new_table[ table_copy( k ) ] = table_copy( v )
		end
		return setmetatable( new_table, getmetatable( Table ) )
	end
	return table_copy( Table )
end

__table_op = function( Table )
	local table_rank = __table_duplicate( Table )
	table.sort( table_rank, function( a, b ) return a < b end )
	if table_rank[ 1 ] then
		return table_rank[ #table_rank ] - table_rank[ 1 ]
	end
	return 0
end

__string_count = function( String, Capture )
	local String = String or "__string_count"
	local Capture = Capture or "count"
	local str_count = 0
	if type( Capture ) == "string" then
		if Capture == "number" then
			Capture = "%-?%d+[%.%d]*"
		elseif Capture == "color" then
			Capture = "[%&%#Hh]^*%x%x%x%x%x%x[%&]*"
		elseif Capture == "alpha" then
			Capture = "%&[Hh]^*%x%x%&"
		elseif Capture == "shape" then
			Capture = "m %-?%d+[%.%d]* %-?%d+[%.%-%dblm ]*"
		end
		for cap in String:gmatch( Capture ) do
			str_count = str_count + 1
		end
	elseif type( Capture ) == "table" then
		for i = 1, #Capture do
			if Capture[ i ] == "number" then
				Capture[ i ] = "%-?%d+[%.%d]*"
			elseif Capture[ i ] == "color" then
				Capture[ i ] = "[%&%#Hh]^*%x%x%x%x%x%x[%&]*"
			elseif Capture[ i ] == "alpha" then
				Capture[ i ] = "%&[Hh]^*%x%x%&"
			elseif Capture[ i ] == "shape" then
				Capture[ i ] = "m %-?%d+[%.%d]* %-?%d+[%.%-%dblm ]*"
			end
			if type( Capture[ i ] ) == "string" then
				for cap in String:gmatch( Capture[ i ] ) do
					str_count = str_count + 1
				end
			end
		end
	end
	return str_count
end

__math_format = function( String, ... )
	local Values = { ... }
	if ...
		and type( ... ) == "table" then
		Values = ...
	end
	if #Values == 0 then
		Values = { 1 }
	end
	local max_index = __string_count( String, "%%[aAcdeEfgGioqsuxX]^*" )
	local str_mathf = string.format( String, unpack( __table_replay( math.ceil( max_index / #Values ), Values ) ) )
	-----------------------------------------------------------------------------------------------------
	local str_mathformat
	str_mathf = str_mathf:gsub( "meta%.res_x", "xres" ):gsub( "meta%.res_y", "yres" )
	:gsub( "(&H%x+&)", "\"" .. "%1" .. "\"" )
	if pcall( loadstring( string.format( [[
			return function( )
				local xres, yres = aegisub.video_size( )
				if not xres then
					xres, yres = 1280, 720
				end
				local ratio = xres / 1280
				local msa = aegisub.ms_from_frame( 1 )
				local msb = aegisub.ms_from_frame( 101 )
				local frame_dur = 41.708
				if msb then
					frame_dur = Yutils.math.round( ( msb - msa ) / 100, 3 )
				end
				local pi, ln, log = math.pi, math.log, math.log10
				local sin, cos, tan = math.sin, math.cos, math.tan
				local abs, deg, rad = math.abs, math.deg, math.rad
				local asin, acos, atan = math.asin, math.acos, math.atan
				local sinh, cosh, tanh = math.sinh, math.cosh, math.tanh
				local rand, ceil, floor = math.random, math.ceil, math.floor
				local atan2, format = math.atan2, string.format
				local unpack = table.unpack or unpack
				return %s
			end
			]], str_mathf )
		) ) then
		local math_format_funct = loadstring( string.format( [[
			return function( )
				local xres, yres = aegisub.video_size( )
				if not xres then
					xres, yres = 1280, 720
				end
				local ratio = xres / 1280
				local msa = aegisub.ms_from_frame( 1 )
				local msb = aegisub.ms_from_frame( 101 )
				local frame_dur = 41.708
				if msb then
					frame_dur = Yutils.math.round( ( msb - msa ) / 100, 3 )
				end
				local pi, ln, log = math.pi, math.log, math.log10
				local sin, cos, tan = math.sin, math.cos, math.tan
				local abs, deg, rad = math.abs, math.deg, math.rad
				local asin, acos, atan = math.asin, math.acos, math.atan
				local sinh, cosh, tanh = math.sinh, math.cosh, math.tanh
				local rand, ceil, floor = math.random, math.ceil, math.floor
				local atan2, format = math.atan2, string.format
				local unpack = table.unpack or unpack
				return %s
			end
			]], str_mathf )
		)( )
		if pcall( math_format_funct ) then
			str_mathformat = math_format_funct( )
			if str_mathformat then
				return str_mathformat
			end
			str_mathf = str_mathf:gsub( "xres", "meta.res_x" ):gsub( "yres", "meta.res_y" )
			:gsub( "\"(&H%x+&)\"", "%1" )
			return str_mathf
		end
	end
	str_mathf = str_mathf:gsub( "xres", "meta.res_x" ):gsub( "yres", "meta.res_y" )
	:gsub( "\"(&H%x+&)\"", "%1" )
	-----------------------------------------------------------------------------------------------------
	return str_mathf
end

__shape_round = function( Shape, Round )
	--redondea los valores de la Shape a las cifras decimales indicadas o al entero más cercano
	local Round = Round or 0
	if type( Shape ) == "table" then
		for i = 1, #Shape do
			Shape[ i ] = __shape_round( Shape[ i ], Round )
		end
	else
		Shape = Shape:gsub( "%-?%d+[%.%d]*",
			function( num )
				return Yutils.math.round( tonumber( num ), Round )
			end
		)
	end
	return Shape
end

__shape_displace = function( Shape, Dx, Dy )
	local Dx = Dx or 0
	local Dy = Dy or 0
	Shape = Shape:gsub( "(%-?%d+[%.%d]*)%s+(%-?%d+[%.%d]*)", 
		function( x, y )
			local x, y = tonumber( x ), tonumber( y )
			return string.format( "%s %s", x + Dx, y + Dy )
		end
	)
	return Shape
end

__shape_insert = function( Shape1, Shape2 )
	--inserta mutuamente el código de una shape en la otra
	local Shape1 = Shape1 or ""
	local Shape2 = Shape2 or ""
	-------------------------------------
	local function parts( Shape )
		--segmentos de una shape
		local Parts = { }
		for p in Shape:gmatch( "[mlb]^*%s+%-?%d+[%.%d]*%s+[%-%.%d ]*" ) do
			table.insert( Parts, p )
		end
		return Parts
	end
	-------------------------------------
	local function valxy( Part_1, Part_2, Part_3 )
		local new_part1, new_part2 = ""
		local Part_3 = Part_3 or Part_2
		local type_part_1 = Part_1:match( "[mlb]^*" )	--tipo de segmento de shape 1
		local type_part_2 = Part_2:match( "[mlb]^*" )	--tipo de segmento de shape 2
		local type_part_3 = Part_3:match( "[mlb]^*" )	--tipo de segmento de shape 2
		if type_part_1 == type_part_2 then
			--si son del mismo tipo, retorna ambos segmentos
			return { Part_1, Part_2 }
		end
		local xpoint1, xpoint2 --punto de referencia del segmento 1
		if type_part_1 == "m"
			or type_part_1 == "l" then
			--toma en cuenta las dos coordenadas del segmento
			xpoint1 = Part_1:match( "%-?%d+[%.%d]*%s+%-?%d+[%.%d]*" )
		else --toma en cuenta las dos últimas coordenadas del segmento
			xpoint1 = Part_1:match( "%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+(%-?%d+[%.%d]*%s+%-?%d+[%.%d]*)" )
		end
		if type_part_3 == "m"
			or type_part_3 == "l" then
			--toma en cuenta las dos coordenadas del segmento
			xpoint2 = Part_3:match( "%-?%d+[%.%d]*%s+%-?%d+[%.%d]*" )
		else --toma en cuenta las dos últimas coordenadas del segmento
			xpoint2 = Part_3:match( "%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+%-?%d+[%.%d]*%s+(%-?%d+[%.%d]*%s+%-?%d+[%.%d]*)" )
		end
		--segmento 2 insertado en el 1
		if type_part_2 == "m"
			or type_part_2 == "l" then
			new_part1 = Part_1 .. type_part_2 .. " " .. xpoint1 .. " "
		else
			new_part1 = Part_1 .. type_part_2 .. " " .. xpoint1 .. " " .. xpoint1 .. " " .. xpoint1 .. " "
		end
		--segmento 1 insertado en el 2
		if type_part_1 == "m"
			or type_part_1 == "l" then
			new_part2 = type_part_1 .. " " .. xpoint2 .. " " .. Part_2
		else
			new_part2 = type_part_1 .. " " .. xpoint2 .. " " .. xpoint2 .. " " .. xpoint2 .. " " .. Part_2
		end
		return { new_part1, new_part2 }
	end
	-------------------------------------
	local Parts_1 = parts( Shape1 )				--segmentos de la shape 1
	local Parts_2 = parts( Shape2 )				--segmentos de la shape 2
	local Shape_fx1, Shape_fx2 = { }, { }		--modificaciones de las shapes 1 y 2
	local last_point_1 = Parts_1[ #Parts_1 ]	--último segmento de la shape 1
	local last_point_2 = Parts_2[ #Parts_2 ]	--último segmento de la shape 2
	local max_n = math.max( #Parts_1, #Parts_2 )
	for i = 2, max_n do
		if Parts_1[ i ]
			and Parts_2[ i ] then
			Shape_fx1[ i ] = valxy( Parts_1[ i ], Parts_2[ i ] )[ 1 ]
			Shape_fx2[ i ] = valxy( Parts_1[ i ], Parts_2[ i ], Parts_2[ i - 1 ] )[ 2 ]
		elseif Parts_1[ i ] then
			Shape_fx1[ i ] = valxy( Parts_1[ i ], last_point_2 )[ 1 ]
			Shape_fx2[ i ] = valxy( Parts_1[ i ], last_point_2 )[ 2 ]
		else
			Shape_fx1[ i ] = valxy( last_point_1, Parts_2[ i ] )[ 1 ]
			Shape_fx2[ i ] = valxy( last_point_1, Parts_2[ i ], Parts_2[ i - 1 ] )[ 2 ]
		end
	end
	Shape_fx1[ 1 ], Shape_fx2[ 1 ] = Parts_1[ 1 ], Parts_2[ 1 ]
	return table.concat( Shape_fx1 ), table.concat( Shape_fx2 )
end

__WD_shape = function( Shape, Height )
	if type( Shape ) == "table" then
		local recursion_tbl = { }
		for k, v in pairs( Shape ) do
			recursion_tbl[ k ] = __WD_shape( v, Height )
		end
		return recursion_tbl
	end
	local shape_parts, shape_px, shape_py = { }, { }, { }
	for c in Shape:gmatch( "%-?%d+[%.%d]*" ) do
		table.insert( shape_parts, tonumber( c ) )
	end
	for i = 1, #shape_parts / 2 do
		shape_px[ i ] = shape_parts[ 2 * i - 1 ]
		shape_py[ i ] = shape_parts[ 2 * i - 0 ]
	end
	local shape_width, shape_height = 0, 0
	if #shape_parts > 0 then
		shape_width  = __table_op( shape_px, "rank" )
		shape_height = __table_op( shape_py, "rank" )
	end
	if Height == "height" then
		return shape_height
	end
	Shape = shape_width
	return Shape
end

__HG_shape = function( Shape )
	if type( Shape ) == "function" then
		Shape = Shape( )
	end
	return __WD_shape( Shape, "height" )
end

__text_to_shape = function( line )
	local Text_cfg, Text = line.text, line.text_stripped
	while Text:sub( -1, -1 ) == " " do
		Text = Text:sub( 1, -2 )
	end
	local text_scale = 1
	local tags_configs = { }
	-- DETECTA OS VALORES DO ESTILO
    local style_cfg = {
        line.styleref.fontname,
		line.styleref.bold,
		line.styleref.italic,
		line.styleref.underline,
		line.styleref.strikeout,
		tonumber( line.styleref.fontsize ),
		tonumber( line.styleref.scale_x ),
		tonumber( line.styleref.scale_y ),
		tonumber( line.styleref.spacing )
	}
	-- DETECTA OS VALORES DAS TAGS DA LINHA QUE SELECIONOU
	local tags_configs = {
		Text_cfg:match("\\fn[%s+]*([^\\]*)"),
		Text_cfg:match("\\b[%s+]*%d") and (Text_cfg:match("\\b[%s+]*(%d)") == "1" and true or false) or nil,
		Text_cfg:match("\\i[%s+]*%d") and (Text_cfg:match("\\i[%s+]*(%d)") == "1" and true or false) or nil,
		Text_cfg:match("\\u[%s+]*%d") and (Text_cfg:match("\\u[%s+]*(%d)") == "1" and true or false) or nil,
		Text_cfg:match("\\s[%s+]*%d") and (Text_cfg:match("\\s[%s+]*(%d)") == "1" and true or false) or nil,
		Text_cfg:match("\\fs[%s+]*(%d+[%.%d+]*)"),
		Text_cfg:match("\\fscx[%s+]*(%d+[%.%d+]*)"),
		Text_cfg:match("\\fscy[%s+]*(%d+[%.%d+]*)"),
		Text_cfg:match("\\fsp([%s+%-]*%d+[%.%d+]*)")
	}
	-- DEFINE QUAL IRÁ USAR, O PADRÃO SEMPRE SERÁ PRIMEIRAMENTE 
	-- DAS TAGS DIGITADAS, CASO NÃO TENHA O VALOR, O ESTILO ASSUMIRÁ
	local font_name = tags_configs[ 1 ] or style_cfg[ 1 ]
	local bold      = tags_configs[ 2 ] or style_cfg[ 2 ]
	local italic    = tags_configs[ 3 ] or style_cfg[ 3 ]
	local underline = tags_configs[ 4 ] or style_cfg[ 4 ]
	local strikeout = tags_configs[ 5 ] or style_cfg[ 5 ]
	local font_size = tonumber( tags_configs[ 6 ] or style_cfg[ 6 ] )
	local scale_x   = tonumber( text_scale * (tags_configs[ 7 ] or style_cfg[ 7 ]) / 100 )
	local scale_y   = tonumber( text_scale * (tags_configs[ 8 ] or style_cfg[ 8 ]) / 100 )
	local spacing   = tonumber( tags_configs[ 9 ] or style_cfg[ 9 ] )
	----------------------------
	local text_confi = {
		font_name,
		bold,   
		italic,
		underline,
		strikeout,
		font_size,
		scale_x,
		scale_y,
		spacing
	}
	-- GERA OS VALORES INTERNOS DA FONTE, A PARTIR DAS INFOS CAPTURADAS
	local extents = Yutils.decode.create_font( unpack( text_confi ) ).text_extents( Text )
	local text_font = Yutils.decode.create_font( unpack( text_confi ) )
	local text_shape = text_font.text_to_shape( Text )
	local text_off_x_sh = 0.5 * ( __WD_shape( text_shape ) - text_scale * tonumber( extents.width ) )
	local text_off_y_sh = 0.5 * ( __HG_shape( text_shape ) - text_scale * tonumber( extents.height ) )
	local text_shape__cf = __shape_displace( text_shape, text_off_x_sh, text_off_y_sh ) -- desloca a shape de acordo com as posições indicadas
	if text_shape__cf:match( " c " ) or text_shape__cf:match( " c" ) then
		return __shape_round( text_shape__cf:gsub( " c", "" ), 3 )
	end
    return __shape_round( text_shape__cf, 3 )
end

__ipol_n = function( vals, loop, algorithm )
	local algorithm = algorithm or "%s"
	local function ipol_shpclip( val_1, val_2, pct_ipol )
		local val_1, val_2 = __shape_insert( val_1, val_2 )
		local tbl_1, tbl_2, k = { }, { }, 1
		for c in val_1:gmatch( "%-?%d+[%.%d]*" ) do
			table.insert( tbl_1, tonumber( c ) )
		end
		for c in val_2:gmatch( "%-?%d+[%.%d]*" ) do
			table.insert( tbl_2, tonumber( c ) )
		end
		local val_ipol = val_1:gsub( "%-?%d+[%.%d]*",
			function( val )
				local val = tbl_1[ k ] + (tbl_2[ k ] - tbl_1[ k ]) * pct_ipol
				k = k + 1
				return Yutils.math.round( val, 3 )
			end
		)
		return val_ipol
	end
	local ipols = {}
	local ipol_i, ipol_f, pct_ip
	for i = 1, loop do
		ipol_i = vals[ math.floor( (i - 1) / (loop / (#vals - 1)) ) + 1 ]
		ipol_f = vals[ math.floor( (i - 1) / (loop / (#vals - 1)) ) + 2 ]
		pct_ip = math.floor( (i - 1) % (loop / (#vals - 1)) ) / (loop / (#vals - 1))
		ipols[ i ] = ipol_shpclip( ipol_i, ipol_f, __math_format( algorithm, pct_ip ) )
	end
	return ipols
end

__wobble_text = function( txt_shape, vals, rand )
	local text_shape = Yutils.shape.filter( Yutils.shape.split( Yutils.shape.flatten( txt_shape ), 1),
		function(x, y)
			local wbfx, wbfy = vals[ 1 ] or 10, vals[ 3 ] or 10
			local wbstx, wbsty = vals[ 2 ] or 10, vals[ 4 ] or 10
			local sx = x + math.cos(y * (wbfx * 0.001) * math.pi * 2) * wbstx
			local sy = y + math.sin(x * (wbfy * 0.001) * math.pi * 2) * wbsty
			x, y = sx, sy
			return x, y
		end
		)
	if rand then
		text_shape = Yutils.shape.filter( Yutils.shape.split( Yutils.shape.flatten( txt_shape ), 1),
		function(x, y)
			local wbfx, wbfy = math.random( vals[ 1 ], -vals[ 1 ] ) or 10, math.random( vals[ 3 ], -vals[ 3 ] ) or 10
			local wbstx, wbsty = math.random( vals[ 2 ], -vals[ 2 ] ) or 10, math.random( vals[ 4 ], -vals[ 4 ] ) or 10
			local sx = x + math.cos(y * (wbfx * 0.001) * math.pi * 2) * wbstx
			local sy = y + math.sin(x * (wbfy * 0.001) * math.pi * 2) * wbsty
			x, y = sx, sy
			return x, y
		end
		)
	end
	return text_shape
end

__generate_wobble = function( txt_shape, vals1, vals2, cont, loop, rand )
	-- vals1 = { 1, 2, 3, 4 }
	-- vals2 = { 1, 2, 3, 4 }
	local table_wob = {}
	local v1 = { vals1[ 1 ], vals1[ 2 ], vals1[ 3 ], vals1[ 4 ] }
	local v2 = { vals2[ 1 ], vals2[ 2 ], vals2[ 3 ], vals2[ 4 ] }
	if rand then
		for k = 1, loop do
			local val = { __wobble_text( txt_shape, v1, rand ), __wobble_text( txt_shape, v2, rand ) }
			if cont > 1 then
				for v = 1, cont do
					table.insert( val, val[ v ] )
				end
			end
			table_wob[ k ] = __ipol_n( val, loop )[ k ]
		end
	else
		for k = 1, loop do
			local val = { __wobble_text( txt_shape, v1 ), __wobble_text( txt_shape, v2 ) }
			if cont > 1 then
				for v = 1, cont do
					table.insert( val, val[ v ] )
				end
			end
			table_wob[ k ] = __ipol_n( val, loop )[ k ]
		end
	end
	return table_wob
end

__wobble = function( subs, sel, vals, del, rand )
	local meta, styles = karaskel.collect_head( subs )
	local add = 0
	aegisub.progress.task( "Generating Wobble..." )
	for _, i in ipairs( sel ) do
		aegisub.progress.set( (i - 1)/#sel * 100 )
		local l = subs[ i + add ]
		karaskel.preproc_line( subs, meta, styles, l )
		l.comment = true
		local texto, tags = l.text
		if texto:match( "%b{}" ) then
			tags = texto:match( "%b{}" )
			:gsub( "\\fn[%s+]*([^\\]*)", "" )
			:gsub( "\\fs[%s+]*%d+[%.%d+]*", "" )
			:gsub( "\\fsp[%s+%-]*%d+[%.%d+]*", "" )
			:gsub( "\\fsc[xy]*[%s+]*%d+[%.%d+]*", "" )
			:gsub( "\\b[%s+]*%d+", "" )
			:gsub( "\\i[%s+]*%d+", "" )
			:gsub( "\\s[%s+]*%d+", "" )
			:gsub( "\\u[%s+]*%d+", "" )
			if tags:match( "\\p[%s+]*%d" ) then
				local pn = tags:match( "\\p[%s+]*(%d)" )
				tags = tags:gsub( "\\p[%s+]*%d", "\\fscx100\\fscy100\\p" .. pn )
			else
				tags = tags:gsub( "}", "\\fscx100\\fscy100\\p1}" )
			end
		else 
			tags = "{\\fscx100\\fscy100\\p1}"
		end
		subs[ i + add ] = l
		l.comment = false
		if del then
			subs.delete( i + add )
			add = add - 1
		end
		--
		local v = { vals[ 1 ], vals[ 2 ], vals[ 3 ], vals[ 4 ] }
		local line = table.copy( l )
		line.text = tags .. __wobble_text( __text_to_shape( l ), vals )
		if rand then
			line.text = tags .. __wobble_text( __text_to_shape( l ), vals, true )
		end
		subs.insert( i + add + 1, line )
		add = add + 1
	end
	aegisub.progress.set( 100 )
end

__wobble_animation = function( subs, sel, accel, vals, cont, del, rand )
	local meta, styles = karaskel.collect_head( subs )
	local accel, add = accel or 1, 0
	aegisub.progress.task( "Generating Wobble..." )
	for _, i in ipairs( sel ) do
		aegisub.progress.set( (i - 1)/#sel * 100 )
		local l = subs[ i + add ]
		karaskel.preproc_line( subs, meta, styles, l )
		l.comment = true
		local texto, tags = l.text
		if texto:match( "%b{}" ) then
			tags = texto:match( "%b{}" )
			:gsub( "\\fn[%s+]*([^\\]*)", "" )
			:gsub( "\\fs[%s+]*%d+[%.%d+]*", "" )
			:gsub( "\\fsp[%s+%-]*%d+[%.%d+]*", "" )
			:gsub( "\\fsc[xy]*[%s+]*%d+[%.%d+]*", "" )
			:gsub( "\\b[%s+]*%d+", "" )
			:gsub( "\\i[%s+]*%d+", "" )
			:gsub( "\\s[%s+]*%d+", "" )
			:gsub( "\\u[%s+]*%d+", "" )
			if tags:match( "\\p[%s+]*%d" ) then
				local pn = tags:match( "\\p[%s+]*(%d)" )
				tags = tags:gsub( "\\p[%s+]*%d", "\\fscx100\\fscy100\\p" .. pn )
			else
				tags = tags:gsub( "}", "\\fscx100\\fscy100\\p1}" )
			end
		else
			tags = "{\\fscx100\\fscy100\\p1}"
		end
		subs[ i + add ] = l
		if del then
			subs.delete( i + add )
			add = add - 1
		end
		--
		local v1 = { vals[ 1 ], vals[ 2 ], vals[ 3 ], vals[ 4 ] }
		local v2 = {}
		for v = 1, #v1 do -- inverte para negativo ou positivo
			if v1[ v ] > 0 then
				v2[ v ] = -v1[ v ]
			else
				v2[ v ] = v1[ v ] * (-1)
			end
		end
		if v2[ 3 ] > 0 and v2[ 4 ] > 0 then
			v2[ 4 ] = -v2[ 4 ]
		else
			v2[ 4 ] = v2[ 4 ] * (-1)
		end
		--
		local ls, le, lf = l.start_time, l.end_time, l.end_time - l.start_time
		local frames = lf / (frame_dur * accel)
		for k = 1, frames do
			l.comment = false
			local line = table.copy( l )
			line.start_time = ls + lf * (k - 1)/frames
			line.end_time = ls + lf * k/frames
			line.text = tags .. __generate_wobble( __text_to_shape( l ), v1, v2, cont, frames )[ k ]
			if rand then
				line.text = tags .. __generate_wobble( __text_to_shape( l ), v1, v2, cont, frames, true )[ k ]
			end
			subs.insert( i + add + 1, line )
			add = add + 1
		end
	end
	aegisub.progress.set( 100 )
end

__wave = function( subs, sel )
	local bx, ck = aegisub.dialog.display( GUI, { "Run", "Random", "Exit" } )
	GUI[ 1 ].value  = ck.ftr
	GUI[ 8 ].value  = ck.accel
	GUI[ 9 ].value  = ck.cont
	GUI[ 10 ].value = ck.frx
	GUI[ 11 ].value = ck.ampx
	GUI[ 12 ].value = ck.fry
	GUI[ 13 ].value = ck.ampy
	GUI[ 14 ].value = ck.gen
	local vals = { GUI[ 10 ].value, GUI[ 11 ].value, GUI[ 12 ].value, GUI[ 13 ].value }
	if bx == "Run" then
		if GUI[ 14 ].value == true then
			if GUI[ 1 ].value == true then
				return __wobble_animation( subs, sel, GUI[ 8 ].value, vals, GUI[ 9 ].value, true )
			else
				return __wobble_animation( subs, sel, GUI[ 8 ].value, vals, GUI[ 9 ].value )
			end
		else
			if GUI[ 1 ].value == true then
				return __wobble( subs, sel, vals, true )
			else
				return __wobble( subs, sel, vals )
			end
		end
	elseif bx == "Random" then
		if GUI[ 14 ].value == true then
			if GUI[ 1 ].value == true then
				return __wobble_animation( subs, sel, GUI[ 8 ].value, vals, GUI[ 9 ].value, true, true )
			else
				return __wobble_animation( subs, sel, GUI[ 8 ].value, vals, GUI[ 9 ].value, false, true )
			end
		else
			if GUI[ 1 ].value == true then
				return __wobble( subs, sel, vals, true, true )
			else
				return __wobble( subs, sel, vals, false, true )
			end
		end
	end
end
--
script_name        = "Wobble Text"
script_description = "Generates wobbles in the text coordinatess"
script_author      = "Zeref-FX"
--
aegisub.register_macro( script_name, script_description, __wave )
aegisub.register_filter( script_name, script_description, 2000, __wave )
