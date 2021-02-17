pi, ln, sin, cos, tan, max, min  = math.pi, math.log, math.sin, math.cos, math.tan, math.max, math.min
abs, deg, rad, log, asin, sqrt   = math.abs, math.deg, math.rad, math.log10, math.asin, math.sqrt
acos, atan, sinh, cosh, tanh     = math.acos, math.atan, math.asin, math.cosh, math.tanh
rand, ceil, floor, atan2, format = math.random, math.ceil, math.floor, math.atan2, string.format

require "karaskel"
Yutils = require "Yutils"

ffi = require "ffi"
if ffi.os != "Windows"
    error("This is not compatible with your operating system.")
else
    export Poly = require "ZF.clipper.clipper"

-- Start Lib
export zf = {}

class MATH

    round: (x, dec) => -- round values
        dec = dec or 3
        if dec and dec >= 1
            dec = 10 ^ floor dec
            floor(x * dec + 0.5) / dec 
        else 
            floor x + 0.5

    angle: (px1, py1, px2, py2) => -- returns the angle between two points
        angle, x1, x2, y1, y2 = 0, px1 or 0, px2 or 0, py1 or 0, py2 or 0
        ang = deg(atan((y2 - y1) / (x2 - x1)))
        if x2 > x1 and y2 > y1
            angle = 360 - ang
        elseif x2 > x1 and y2 < y1
            angle = -ang
        elseif x2 < x1 and y2 < y1
            angle = 180 - ang
        elseif x2 < x1 and y2 > y1
            angle = 180 - ang
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
        @round(angle, 3)

    distance: (px1, py1, px2, py2) => -- returns the distance between two points
        x1, x2, y1, y2 = px1 or 0, px2 or 0, py1 or 0, py2 or 0
        @round(sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), 3)

    distancez: (x, y, z) =>
        error("one vector (2 or 3 numbers) expected", 2) if type(x) != "number" or type(y) != "number" or z != nil and type(z) != "number"
        z and math.sqrt(x * x + y * y + z * z) or math.sqrt(x * x + y * y)

    factk: (n) => -- returns the factorial of a number
        k_factk = 1
        if n > 1 then for i = 2, n do k_factk *= i
        k_factk

    bernstein: (i, n, t) => -- returns Bezier patches --> https://en.wikipedia.org/wiki/Bernstein%E2%80%93Vazirani_algorithm
        (@factk(n) / (@factk(i) * @factk(n - i))) * (t ^ i) * ((1 - t) ^ (n - i))

    confi_bezier: (n, x, y, t, rt) => -- returns the Bezier points configured
        px, py = x, y
        pos_x, pos_y = 0, 0
        if y == nil
            px, py = {}, {}
            switch type(x)
                when "string"
                    coor = [tonumber(c) for c in x\gmatch "%-?%d+[%.%d]*"]
                    for i = 1, #coor / 2
                        px[i] = coor[2 * i - 1]
                        py[i] = coor[2 * i - 0]
                when "table"
                    for i = 1, #x / 2
                        px[i] = x[2 * i - 1]
                        py[i] = x[2 * i - 0]

        n = n or #px
        for i = 1, n
            pos_x += px[i] * @bernstein(i - 1, n - 1, t)
            pos_y += py[i] * @bernstein(i - 1, n - 1, t)

        return pos_x if rt == "x"
        return pos_y if rt == "y"
        pos_x, pos_y

    length_bezier: (...) => -- returns the length of the bezier
        px, py, bx, by = {}, {}, {}, {}
        nN, shape_bezier = 1024, ""
        blength, coor = 0, {...}
    
        switch type(...)
            when "table"
                coor = ...
            when "string"
                shape_bezier = ...
                coor = [tonumber(c) for c in shape_bezier\gmatch "%-?%d+[%.%d]*"]
    
        if #coor == 4 then blength = @distance(coor[1], coor[2], coor[3], coor[4]) else
            for i = 1, #coor / 2
                px[i] = coor[2 * i - 1]
                py[i] = coor[2 * i - 0]
            for i = 1, nN do bx[i], by[i] = @confi_bezier(#px, px, py, (i - 1) / (nN - 1))
            for i = 2, nN do blength += @distance(bx[i], by[i], bx[i - 1], by[i - 1])
        blength

    polar: (angle, radius, rt) => -- returns to the polar angle of the points
        angle = angle or 0
        radius = radius or 0
        px = @round(radius * cos(rad(angle)), 3)
        py = @round(-radius * sin(rad(angle)), 3)
        return px if rt == "x"
        return py if rt == "y"
        px, py

    degree: (x1, y1, z1, x2, y2, z2) =>
        degree = deg(acos((x1 * x2 + y1 * y2 + z1 * z2) / (@distancez(x1, y1, z1) * @distancez(x2, y2, z2))))
        (x1 * y2 - y1 * x2) < 0 and -degree or degree

    interpolation: (pct, min, max) => -- interpolate two values
        if pct <= 0 then min elseif pct >= 1 then max else @round(pct * (max - min) + min, 3)

class TABLE

    op: (Table, mode, add) => -- returns several operations for tables
        Table = Table! if type(Table) == "function"
        table_sum, table_average, table_concat = 0, 0, ""
        table_add, table_inverse, table_function = {}, {}, {}
        if type(mode) == "function"
            for k, v in pairs(Table) do table_function[k] = mode(v)
            return table_function 
        elseif mode == "sum" or mode == "suma" or mode == nil
            -------------------
            add = add or #Table
            add = #Table if add > #Table
            -------------------
            for i = 1, add do table_sum = table_sum + Table[i]
            return table_sum
        elseif mode == "pro" or mode == "multi"
            table_pro = table.copy(Table)
            for i = 1, #Table do table_pro[i] = Table[i] * add
            return table_pro
        elseif mode == "concat"
            con_add = ""
            for i = 1, #Table
                con_add = ""
                con_add = add if add and i < #Table
                table_concat ..= Table[i] .. con_add
            return table_concat
        elseif mode == "average"
            for i = 1, #Table do table_average = table_average + Table[i]
            return table_average / #Table if #Table > 0
            return 0
        elseif mode == "min"
            table_min = table.copy(Table)
            table.sort(table_min, (a, b) ->
                return a < b)
            return table_min[1] if table_min[1]
            return 0
        elseif mode == "max"
            table_max = table.copy(Table)
            table.sort(table_max, (a, b) ->
                return a < b)
            return table_max[#table_max] if table_max[#table_max]
            return 0
        elseif mode == "rank"
            table_rank = table.copy(Table)
            table.sort(table_rank, (a, b) ->
                return a < b)
            return table_rank[#table_rank] - table_rank[1] if table_rank[1]
            return 0
        elseif mode == "org"
            table_org = table.copy(Table)
            table.sort(table_org, (a, b) ->
                return a < b)
            return table_org
        elseif mode == "org2"
            table_org2 = table.copy(Table)
            table.sort(table_org2, (a, b) ->
                return a > b)
            return table_org2
        elseif mode == "round"
            table_round = table.copy(Table)
            return zf.math\round(table_round, add)
        elseif mode == "add"
            if type(add) == "number"
                for i = 1, #Table do table_add[i] = Table[i] + add
            elseif type(add) == "table"
                for i = 1, #Table
                    if type(Table[i]) == "table"
                        table_add[i] = {}
                        for k = 1, #Table[i]
                            table_add[i][k] = Table[i][k] + add[1 + (k + 1) % 2]
                            table_add[i][k] = Table[i][k] + add[1 + (k - 1) % 2] if k % 2 == 1
                    elseif i % 2 == 1
                        table_add[i] = Table[i] + add[1 + (i - 1) % 2]
                    else
                        table_add[i] = Table[i] + add[1 + (i + 1) % 2]
            return table_add
        elseif mode == "inverse"
            for i = 1, #Table do table_inverse[i] = Table[#Table - i + 1]
            return table_inverse

    push: (t, ...) => -- pushes all the given values to the end of the table t and returns the pushed values. Nil values are ignored.
        n = select("#", ...)
        for i = 1, n do t[#t + 1] = select(i, ...)
        ...

    view: (Table, table_name, indent) => -- returns a table as string
        cart, autoref = "", ""
        isemptytable = (Table) ->
            next(Table) == nil
        basicSerialize = (o) ->
            so = tostring(o)
            if type(o) == "function"
                info = debug.getinfo o, "S"
                return format "%q", so .. ", C function" if info.what == "C"
                format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
            elseif type(o) == "number" or type(o) == "boolean"
                return so
            format "%q", so
        addtocart = (value, table_name, indent, saved, field) ->
            indent = indent or ""
            saved = saved or {}
            field = field or table_name
            cart ..= indent .. field
            if type(value) != "table"
                cart ..= " = " .. basicSerialize(value) .. ";\n"
            else
                if saved[value]
                    cart ..= " = {}; -- #{saved[value]}(self reference)\n"
                    autoref ..= "#{table_name} = #{saved[value]};\n"
                else
                    saved[value] = table_name
                    if isemptytable(value)
                        cart ..= " = {};\n"
                    else
                        cart ..= " = {\n"
                        for k, v in pairs(value) do
                            k = basicSerialize(k)
                            fname = "#{table_name}[ #{k} ]"
                            field = "[ #{k} ]"
                            addtocart v, fname, indent .. "	", saved, field
                        cart = "#{cart}#{indent}};\n"
        table_name = table_name or "table_unnamed"
        return "#{table_name} = #{basicSerialize(Table)}" if type(Table) != "table"
        addtocart Table, table_name, indent
        cart .. autoref

    interpolation: (t, loop, mode, accel, tags) =>
        accel = accel or 1
        vtable, ipols = table.copy(t), {}
        ipol_i, ipol_f, pct_ip
        max_loop = loop - 1
        pol, tags = interpolate, tags or ""

        switch mode
            when "number"
                pol = interpolate
            when "color"
                pol = interpolate_color
            when "alpha"
                pol = interpolate_alpha

        for i = 1, max_loop
            ipol_i = vtable[floor((i - 1) / (max_loop / (#vtable - 1))) + 1]
            ipol_f = vtable[floor((i - 1) / (max_loop / (#vtable - 1))) + 2]
            pct_ip = floor((i - 1) % (max_loop / (#vtable - 1))) / (max_loop / (#vtable - 1))
            ipols[i] = tags .. pol(pct_ip ^ accel, ipol_i, ipol_f)
        ipols[#ipols + 1] = tags .. vtable[#vtable]
        ipols
    
class POLY

    to_points: (shape, oth) => -- converts shapes to points in 3 different way
        shape = zf.poly\flatten(shape) if shape\match "b"
        points = {parts: {}, result: {}}
        points.parts = [p for p in shape\gmatch " ([^m]+)"]
        for k = 1, #points.parts do points.result[k] = [tonumber(p) * 1000 for p in points.parts[k]\gmatch "%-?%d+[%.%d+]*"]

        if oth
            if oth == "nt"
                points = {}
                for p in shape\gmatch " ([^m]+)"
                    points[#points + 1] = {}
                    for x, y in p\gmatch "(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)"
                        points[#points][#points[#points] + 1] = {x: tonumber(x), y: tonumber(y)}
                return points

            points_ot = {x: {}, y: {}}
            k = 1
            for x, y in shape\gmatch "(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)"
                points_ot.x[k] = tonumber(x)
                points_ot.y[k] = tonumber(y)
                k += 1
            return points_ot
        points.result

    to_shape: (points) => -- turns points into shapes, valid only for line points
        new_shape = {}

        for k = 1, #points
            new_shape[k] = "m "
            for p = 1, #points[k] do new_shape[k] ..= (p == 1 and "#{zf.math\round(points[k][p].x)} #{zf.math\round(points[k][p].y)} l " or "#{zf.math\round(points[k][p].x)} #{zf.math\round(points[k][p].y)} ")
        table.concat(new_shape)

    create_path: (path) => -- adds path to a C structure
        pts = Poly.Path!
        n_pts = #path
        for k = 1, n_pts, 2 do pts\add(path[k], path[k + 1])
        pts
        
    create_paths: (paths) => -- adds paths to a C structure
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))
        points

    simplify: (paths) => -- remove useless vertices from a polygon
        paths = @to_points(paths) if type(paths) == "string"
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))

        points = points\simplify!
        @to_shape( @get_solution(points) )

    clean: (paths) =>
        paths = @to_points(paths) if type(paths) == "string"
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))

        points = points\clean_polygon!
        @to_shape( @get_solution(points) )
    
    get_solution: (path) => -- returns the clipper library solution
        get_path_points = (path) ->
            result = {}
            for k = 1, path\size!
                point = path\get(k)
                result[k] = {x: tonumber(point.x) * 0.001, y: tonumber(point.y) * 0.001}
            result

        result = {}
        for k = 1, path\size! do result[k] = get_path_points(path\get(k))
        result
            
    clipper: (shape_or_points_subj, shape_or_points_clip, fill_types, clip_type) => -- returns a clipped shape, according to its set configurations
        points_subj = shape_or_points_subj
        points_clip = shape_or_points_clip

        points_subj = @to_points(points_subj) if type(points_subj) != "table"
        points_clip = @to_points(points_clip) if type(points_clip) != "table"

        -- even_odd, non_zero, positive, negative
        -- intersection, union, difference, xor
        fill_types = fill_types or "even_odd"
        clip_type = clip_type or "intersection"
        
        ft_subj, ft_clip = fill_types[1], fill_types[2]
        ft_subj, ft_clip = fill_types, fill_types if type(fill_types) != "table"

        subj = @create_paths(points_subj)
        clip = @create_paths(points_clip)

        pc = Poly.Clipper!
        pc\add_paths(subj, "subject")
        pc\add_paths(clip, "clip")
        final = pc\execute(clip_type, ft_subj, ft_clip)

        result = @get_solution(final)
        @to_shape(result)

    offset: (points, size, join_type, end_type, miter_limit, arc_toleranc) => -- returns a shape offseting, according to its set configurations
        join_type, end_type = join_type or "round", end_type or "closed_polygon"
        miter_limit, arc_toleranc = miter_limit or 3, arc_toleranc or 0.25
        points = @to_points(points) if type(points) == "string"

        po = Poly.ClipperOffset(miter_limit, arc_toleranc)
        pp = @create_paths(points)
        final = po\offset_paths(pp, size * 1000, join_type, end_type)

        result = @get_solution(final)
        @to_shape(result)

    to_outline: (points, size, outline_type, mode, miter_limit, arc_tolerance) => -- returns an outline and the opposite of it, according to your defined settings
        error("You need to add a size and it has to be bigger than 0.") unless size or size <= 0

        outline_type = outline_type\lower!
        miter_limit, arc_tolerance = miter_limit or 3, arc_tolerance or 0.25
        mode = mode or "Center"
        size = (mode == "Inside" and -size or size)
        points = @simplify(points) unless mode == "Center"
        create_offset = @offset(points, size, outline_type, nil, miter_limit, arc_tolerance)
        create_offset = @offset(points, size, outline_type, "closed_line", miter_limit, arc_tolerance) if mode == "Center"

        outline = switch mode
            when "Outside"
                @clipper(create_offset, points, nil, "difference")
            else
                @clipper(points, create_offset, nil, "difference")

        switch mode
            when "Outside"
                create_offset = points
            when "Center"
                return create_offset, outline

        outline, create_offset

class SUB_POLY extends POLY

    sep_points: (points) => -- a different way of separating points
        points = @to_shape(points) if type(points) == "table"
        @to_points(points, true)

    dimension: (points) => -- returns the winth and height values of a shape
        get_values = @sep_points(points)
        width, height = 0, 0
        if #get_values.x > 0
            width = zf.table\op(get_values.x, "rank")
            height = zf.table\op(get_values.y, "rank")
        width, height
    
    info: (points) => -- returns information contained in the shape
        get_values = @sep_points(points)
        minx       = zf.table\op(get_values.x, "min")
        maxx       = zf.table\op(get_values.x, "max")
        miny       = zf.table\op(get_values.y, "min")
        maxy       = zf.table\op(get_values.y, "max")
        w_shape    = maxx - minx 
        h_shape    = maxy - miny
        c_shape    = minx + w_shape / 2 
        m_shape    = miny + h_shape / 2
        n_shape    = #get_values.x
        n_points   = #get_values.x
        {
            :shape_x2, :shape_y2, :minx, :miny,
            :maxx, :maxy, :w_shape, :h_shape,
            :c_shape, :m_shape, :n_shape, :n_points
        }

    flatten: (shape, tol) => -- Yutils Flatten
        tol = tol or 1
        error("shape expected", 2) if type(shape) != "string"
 
        curve4_subdivide = (x0, y0, x1, y1, x2, y2, x3, y3, pct) ->
            x01, y01, x12, y12, x23, y23 = (x0 + x1) * pct, (y0 + y1) * pct, (x1 + x2) * pct, (y1 + y2) * pct, (x2 + x3) * pct, (y2 + y3) * pct
            x012, y012, x123, y123 = (x01 + x12) * pct, (y01 + y12) * pct, (x12 + x23) * pct, (y12 + y23) * pct
            x0123, y0123 = (x012 + x123) * pct, (y012 + y123) * pct
            x0, y0, x01, y01, x012, y012, x0123, y0123, x0123, y0123, x123, y123, x23, y23, x3, y3

        curve4_is_flat = (x0, y0, x1, y1, x2, y2, x3, y3, tolerance) ->
            vecs = {{x1 - x0, y1 - y0}, {x2 - x1, y2 - y1}, {x3 - x2, y3 - y2}}
            i, n = 1, #vecs
            while i <= n
                if vecs[i][1] == 0 and vecs[i][2] == 0
                    table.remove(vecs, i)
                    n -= 1
                else
                    i += 1

            for i = 2, n do return false if math.abs(zf.math\degree(vecs[i - 1][1], vecs[i - 1][2], 0, vecs[i][1], vecs[i][2], 0)) > tolerance
            true

        curve4_to_lines = (x0, y0, x1, y1, x2, y2, x3, y3) ->
            pts, pts_n = {x0, y0}, 2
            convert_recursive = (x0, y0, x1, y1, x2, y2, x3, y3) ->
                if curve4_is_flat(x0, y0, x1, y1, x2, y2, x3, y3, tol)
                    pts[pts_n + 1] = x3
                    pts[pts_n + 2] = y3
                    pts_n += 2
                else
                    x10, y10, x11, y11, x12, y12, x13, y13, x20, y20, x21, y21, x22, y22, x23, y23 = curve4_subdivide(x0, y0, x1, y1, x2, y2, x3, y3, 0.5)
                    convert_recursive(x10, y10, x11, y11, x12, y12, x13, y13)
                    convert_recursive(x20, y20, x21, y21, x22, y22, x23, y23)
                    return
            convert_recursive(x0, y0, x1, y1, x2, y2, x3, y3)
            return pts

        curves_start, curves_end, x0, y0 = 1
        curve_start, curve_end, x1, y1, x2, y2, x3, y3
        line_points, line_curve
        while true
            curves_start, curves_end, x0, y0 = shape\find("([^%s]+)%s+([^%s]+)%s+b%s+", curves_start)
            x0, y0 = tonumber(x0), tonumber(y0)
            if x0 and y0
                shape = shape\sub(1, curves_start - 1) .. shape\sub(curves_start)\gsub("b", "l", 1)
                curve_start = curves_end + 1
                while true
                    curve_start, curve_end, x1, y1, x2, y2, x3, y3 = shape\find("([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)", curve_start)
                    x1, y1, x2, y2, x3, y3 = tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2), tonumber(x3), tonumber(y3)
                    if x1 and y1 and x2 and y2 and x3 and y3
                        -- Convert curve to lines
                        line_points = curve4_to_lines(x0, y0, x1, y1, x2, y2, x3, y3)
                        for i = 1, #line_points do
                            line_points[i] = zf.math\round(line_points[i], 3)
                        line_curve = table.concat(line_points, " ")
                        shape = "#{shape\sub(1, curve_start - 1)}#{line_curve}#{shape\sub(curve_end + 1)}"
                        curve_end = curve_start + #line_curve - 1
                        x0, y0 = x3, y3
                        curve_start = curve_end + 1
                    break unless (x1 and y1 and x2 and y2 and x3 and y3)
                curves_start = curves_end + 1
            break unless (x0 and y0)
        shape

    filter: (points, filter) => -- filter to manipulate points
        points = @to_points(points, "nt") if type(points) != "table"
        filter = filter or (x, y) ->
            x, y
        for k, v in ipairs points
            for _, p in ipairs v do p.x, p.y = filter(p.x, p.y)
        points

    displace: (points, x2, y2) => -- displace points
        x2, y2 = x2 or 0, y2 or 0
        points = @filter points, (x, y) ->
            x + x2, y + y2
        @to_shape(points)

    round: (points, n) => -- round points
        n = n or 3
        points = @filter points, (x, y) ->
            zf.math\round(x, n), zf.math\round(y, n)
        @to_shape(points)
        
    rotate: (points, cx, cy, angle) =>
        angle = angle or 0
        cx = cx or 0
        cy = cy or 0
        points = @filter points, (x, y) ->
            new_ang = zf.math\angle(cx, cy, x, y)
            new_rad = zf.math\distance(cx, cy, x, y)
            cx + zf.math\polar(new_ang + angle, new_rad, "x"), cy + zf.math\polar(new_ang + angle, new_rad, "y")
        @to_shape(points)

    origin: (points, pos) => -- returns the original position of the points
        minx, miny = @info(points).minx, @info(points).miny
        return @displace(points, -minx, -miny), zf.math\round(minx, 3), zf.math\round(miny, 3) if pos
        @displace(points, -minx, -miny)

    expand: (points, line, meta) => -- expands the points of agreement with the values of tags some tags
        points = @org_points(points, line.styleref.align)
        points = @to_points(points, "nt")

        data = zf.util\find_coords(line, meta, true)
        frx = pi / 180 * data.rots.frx
        fry = pi / 180 * data.rots.fry
        frz = pi / 180 * data.rots.frz

        sx, cx = -sin(frx), cos(frx)
        sy, cy =  sin(fry), cos(fry)
        sz, cz = -sin(frz), cos(frz)

        xscale = data.scale.x / 100
        yscale = data.scale.y / 100

        fax = data.rots.fax * data.scale.x / data.scale.y
        fay = data.rots.fay * data.scale.y / data.scale.x
        x1 = {1, fax, data.pos.x - data.org.x}
        y1 = {fay, 1, data.pos.y - data.org.y}

        x2, y2 = {}, {}
        for i = 1, 3
            x2[i] = x1[i] * cz - y1[i] * sz
            y2[i] = x1[i] * sz + y1[i] * cz

        y3, z3 = {}, {}
        for i = 1, 3
            y3[i] = y2[i] * cx
            z3[i] = y2[i] * sx

        x4, z4 = {}, {}
        for i = 1, 3
            x4[i] = x2[i] * cy - z3[i] * sy
            z4[i] = x2[i] * sy + z3[i] * cy

        dist = 312.5
        z4[3] += dist

        offs_x = data.org.x - data.pos.x
        offs_y = data.org.y - data.pos.y

        m = {}
        for k = 1, 3 do m[k] = {}

        for i = 1, 3
            m[1][i] = z4[i] * offs_x + x4[i] * dist
            m[2][i] = z4[i] * offs_y + y3[i] * dist
            m[3][i] = z4[i]

        for i = 1, #points
            for k = 1, #points[i]
                v = {}
                for j = 1, 3 do v[j] = (m[j][1] * points[i][k].x * xscale) + (m[j][2] * points[i][k].y * yscale) + m[j][3] 
                w = 1 / max(v[3], 0.1)
                points[i][k].x = zf.math\round(v[1] * w, 3)
                points[i][k].y = zf.math\round(v[2] * w, 3)
        @to_shape(points)

    org_points: (points, an) => -- moves the points to positions relative to the alignment 7
        width, height = @dimension(points)
        switch an
            when 1 then @displace(points, nil, -height)
            when 2 then @displace(points, -width / 2, -height)
            when 3 then @displace(points, -width, -height)
            when 4 then @displace(points, nil, -height / 2)
            when 5 then @displace(points, -width / 2, -height / 2)
            when 6 then @displace(points, -width, -height / 2)
            when 7 then @displace(points)
            when 8 then @displace(points, -width / 2)
            when 9 then @displace(points, -width)

    to_clip: (points, an, px, py) => -- moves points to relative clip positions
        px, py = px or 0, py or 0
        width, height = @dimension(points)
        
        switch an
            when 1 then @displace(points, px, py - height)
            when 2 then @displace(points, px - width / 2, py - height)
            when 3 then @displace(points, px - width, py - height)
            when 4 then @displace(points, px, py - height / 2)
            when 5 then @displace(points, px - width / 2, py - height / 2)
            when 6 then @displace(points, px - width, py - height / 2)
            when 7 then @displace(points, px, py)
            when 8 then @displace(points, px - width / 2, py)
            when 9 then @displace(points, px - width, py)

    unclip: (points, an, px, py) => -- moves the points to relative shape positions
        points = zf.util\clip_to_draw(points)

        px, py = px or 0, py or 0
        width, height = @dimension(points)
        switch an
            when 1 then @displace(points, -px, -py + height)
            when 2 then @displace(points, -px + width / 2, -py + height)
            when 3 then @displace(points, -px + width, -py + height)
            when 4 then @displace(points, -px, -py + height / 2)
            when 5 then @displace(points, -px + width / 2, -py + height / 2)
            when 6 then @displace(points, -px + width, -py + height / 2)
            when 7 then @displace(points, -px, -py)
            when 8 then @displace(points, -px + width / 2, -py)
            when 9 then @displace(points, -px + width, -py)

    clip: (subj, clip, x, y, iclip) => -- the same thing as \clip and \iclip
        x, y = x or 0, y or 0
        rec_points = ""
        if type(clip) == "table"
            rec_points = {}
            for k = 1, #clip
                clip[k] = @displace(clip[k], -x, -y)
                if iclip
                    rec_points[k] = @clipper(subj, clip[k], "even_odd", "difference")
                else
                    rec_points[k] = @clipper(subj, clip[k], "even_odd", "intersection")
        else
            clip = @displace(clip, -x, -y)
            if iclip
                rec_points = @clipper(subj, clip, "even_odd", "difference")
            else
                rec_points = @clipper(subj, clip, "even_odd", "intersection")
        rec_points
    
    clipping: (rec, loop_x, loop_y, left, top, width, height, offset, mode) => -- an interpolation of clip cuts
        offset = offset or 3
        mode = mode or 79

        final, result = {}, {}
        loop = loop_x * loop_y
        for k = 1, loop
            clp = zf.util\clip_un(k, loop_x, loop_y, left, top, width, height, offset, mode)
            clp = zf.util\clip_to_draw(clp)
            final[k] = @clip(rec[1], clp, rec[2], rec[3])
            result[k] = final[k] if final[k] != ""
        result

class TEXT

    to_shape: (line, text, raw) => -- converts your text into shape
        text = text or zf.tags!\remove("full", line.text_stripped)
        while text\sub(-1, -1) == " " do text = text\sub(1, -2)
        style_cfg = {line.styleref.fontname, line.styleref.bold, line.styleref.italic,
        line.styleref.underline, line.styleref.strikeout, line.styleref.fontsize,
        line.styleref.scale_x, line.styleref.scale_y, line.styleref.spacing}

        font_name = style_cfg[1]
        bold      = style_cfg[2]
        italic    = style_cfg[3]
        underline = style_cfg[4]
        strikeout = style_cfg[5]
        font_size = style_cfg[6]
        scale_x   = style_cfg[7] / 100
        scale_y   = style_cfg[8] / 100
        spacing   = style_cfg[9]

        vals_font  = {font_name, bold, italic, underline, strikeout, font_size, scale_x, scale_y, spacing}
        extents    = Yutils.decode.create_font(unpack(vals_font)).text_extents(text)
        text_font  = Yutils.decode.create_font unpack(vals_font)
        text_shape = text_font.text_to_shape text
        text_shape = zf.poly\flatten(text_shape)
        wd, hg     = zf.poly\dimension(text_shape)
        nwd, nhg   = tonumber(extents.width), tonumber(extents.height)

        text_off_x_sh = 0.5 * (wd - nwd)
        text_off_y_sh = 0.5 * (hg - nhg)
        text_shapecf  = zf.poly\displace(text_shape, text_off_x_sh, text_off_y_sh)
        return text_shape if raw
        text_shapecf

    to_clip: (line, text, an, px, py) => -- converts your text into clip
        px, py = px or 0, py or 0
        an = an or line.styleref.align
        text = text or zf.tags!\remove("full", line.text_stripped)
        text_shape = @to_shape(line, text)

        line.width, line.height = aegisub.text_extents(line.styleref, text)
        width, height = zf.poly\dimension(text_shape)

        switch an
            when 1 then zf.poly\displace(text_shape, px - 0.5 * (width - line.width), py - (line.height / 2) - height / 2)
            when 2 then zf.poly\displace(text_shape, px - width / 2, py - (line.height / 2) - height / 2)
            when 3 then zf.poly\displace(text_shape, px - line.width - (width - line.width) / 2, py - (line.height / 2) - height / 2)
            when 4 then zf.poly\displace(text_shape, px - 0.5 * (width - line.width), py - height / 2)
            when 5 then zf.poly\displace(text_shape, px - width / 2, py - height / 2)
            when 6 then zf.poly\displace(text_shape, px - line.width - (width - line.width) / 2, py - height / 2)
            when 7 then zf.poly\displace(text_shape, px - 0.5 * (width - line.width), py - 0.5 * (height - line.height))
            when 8 then zf.poly\displace(text_shape, px - width / 2, py + (line.height / 2) - height / 2)
            when 9 then zf.poly\displace(text_shape, px - line.width - (width - line.width) / 2, py + (line.height / 2) - height / 2)

class SUPPORT

    tags2styles: (subs, line) => -- makes its style values equal those of tags on the line
        tags, vtext = "", line.text
        meta, styles = karaskel.collect_head subs
    
        for k = 1, styles.n
            styles[k].margin_l = line.margin_l if line.margin_l > 0
            styles[k].margin_r = line.margin_r if line.margin_r > 0
            styles[k].margin_v = line.margin_t if line.margin_t > 0
            styles[k].margin_v = line.margin_b if line.margin_b > 0
            if vtext\match "%b{}"
                tags = vtext\match "%b{}"
                styles[k].align     = tonumber tags\match "\\an[%s+]*(%d)" if tags\match "\\an[%s+]*%d"
                styles[k].fontname  = tags\match "\\fn[%s+]*([^\\}]*)" if tags\match "\\fn[%s+]*[^\\}]*"
                styles[k].fontsize  = tonumber tags\match "\\fs[%s+]*(%d+[%.%d+]*)" if tags\match "\\fs[%s+]*%d+[%.%d+]*"
                styles[k].scale_x   = tonumber tags\match "\\fscx[%s+]*(%d+[%.%d+]*)" if tags\match "\\fscx[%s+]*%d+[%.%d+]*"
                styles[k].scale_y   = tonumber tags\match "\\fscy[%s+]*(%d+[%.%d+]*)" if tags\match "\\fscy[%s+]*%d+[%.%d+]*"
                styles[k].spacing   = tonumber tags\match "\\fsp[%s+]*(%-?%d+[%.%d+]*)" if tags\match "\\fsp[%s+]*%-?%d+[%.%d+]*"
                styles[k].outline   = tonumber tags\match "\\bord[%s+]*(%d+[%.%d+]*)" if tags\match "\\bord[%s+]*%d+[%.%d+]*"
                styles[k].shadow    = tonumber tags\match "\\shad[%s+]*(%d+[%.%d+]*)" if tags\match "\\shad[%s+]*%d+[%.%d+]*"
                styles[k].angle     = tonumber tags\match "\\fr[z]*[%s+]*(%-?%d+[%.%d+]*)" if tags\match "\\fr[z]*[%s+]*%-?%d+[%.%d+]*"
                styles[k].color1    = tags\match "\\1?c[%s+]*(&[hH]%x+&)" if tags\match "\\1?c[%s+]*&[hH]%x+&"
                styles[k].color2    = tags\match "\\2c[%s+]*(&[hH]%x+&)" if tags\match "\\2c[%s+]*&[hH]%x+&"
                styles[k].color3    = tags\match "\\3c[%s+]*(&[hH]%x+&)" if tags\match "\\3c[%s+]*&[hH]%x+&"
                styles[k].color4    = tags\match "\\4c[%s+]*(&[hH]%x+&)" if tags\match "\\4c[%s+]*&[hH]%x+&"
                styles[k].bold      = true if tags\match "\\b[%s+]*1"
                styles[k].italic    = true if tags\match "\\i[%s+]*1"
                styles[k].underline = true if tags\match "\\u[%s+]*1"
                styles[k].strikeout = true if tags\match "\\s[%s+]*1"
        meta, styles
    
    find_coords: (line, meta, ogp) => -- finds coordinates of some tags
        coords = {
            pos:   {x: 0, y: 0}
            move:  {x1: 0, y1: 0, x2: 0, y2: 0}
            org:   {x: 0, y: 0}
            rots:  {frz: line.styleref.angle or 0, fax: 0, fay: 0, frx: 0, fry: 0}
            scale: {x: line.styleref.scale_x or 0, y: line.styleref.scale_y or 0}
        }
        if meta
            an = line.styleref.align or 7
            switch an
                when 1
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                when 2
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                when 3
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                when 4
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, meta.res_y / 2
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, meta.res_y / 2
                    coords.org.x, coords.org.y = line.styleref.margin_l, meta.res_y / 2
                when 5
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                when 6
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                when 7
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, line.styleref.margin_v
                    coords.org.x, coords.org.y = line.styleref.margin_l, line.styleref.margin_v
                when 8
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                when 9
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
    
        if line.text\match "%b{}"
            if line.text\match "\\frx[%s+]*%-?%d+[%.%d+]*"
                frx = line.text\match "\\frx[%s+]*(%-?%d+[%.%d+]*)"
                coords.rots.frx = tonumber frx
    
            if line.text\match "\\fry[%s+]*%-?%d+[%.%d+]*"
                fry = line.text\match "\\fry[%s+]*(%-?%d+[%.%d+]*)"
                coords.rots.fry = tonumber fry
                
            if line.text\match "\\fax[%s+]*%-?%d+[%.%d+]*"
                fax = line.text\match "\\fax[%s+]*(%-?%d+[%.%d+]*)"
                coords.rots.fax = tonumber fax
                
            if line.text\match "\\fay[%s+]*%-?%d+[%.%d+]*"
                fay = line.text\match "\\fay[%s+]*(%-?%d+[%.%d+]*)"
                coords.rots.fay = tonumber fay
    
            if line.text\match "\\pos%b()"
                px, py = line.text\match "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)"
                coords.pos.x = tonumber px
                coords.pos.y = tonumber py
    
            if line.text\match "\\move%(%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*,%-?%d+[%.%d+]*"
                x1, y1, x2, y2, t1, t2 = line.text\match "\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)"
                coords.move.x1 = tonumber x1
                coords.move.y1 = tonumber y1
                coords.move.x2 = tonumber x2
                coords.move.y2 = tonumber y2
                coords.pos.x   = tonumber x1
                coords.pos.y   = tonumber y1
    
            if line.text\match "\\org%b()"
                ox, oy = line.text\match "\\org%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)"
                coords.org.x = tonumber ox
                coords.org.y = tonumber oy
    
        if ogp
            unless line.text\match "\\org%b()"
                coords.org.x = coords.pos.x
                coords.org.y = coords.pos.y
        coords
    
    html_color: (color, mode) => -- transform an html color to hexadecimal and the other way around
        n_c, mode =  "", mode or "to_rgb"
        switch mode
            when "to_rgb"
                color = color\gsub "(%x%x)(%x%x)(%x%x)", (b, g, r) ->
                    n_c = "&H#{r}#{g}#{b}&"
                n_c
            when "to_html"
                rgb_color = util.color_from_style(rgb_color)
                rgb_color = rgb_color\gsub "&[hH](%x%x)(%x%x)(%x%x)&", (r, g, b) ->
                    n_c = "##{b}#{g}#{r}"
                n_c
    
    clip_to_draw: (clip) => -- converts data from clip to shape
        new_clip, final = {}, ""
        if clip\match("\\i?clip%b()")
            unless clip\match("\\i?clip%(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)")
                new_clip.l, new_clip.t, new_clip.r, new_clip.b = clip\match "\\i?clip%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)"
                final = "m #{new_clip.l} #{new_clip.t} l #{new_clip.r} #{new_clip.t} #{new_clip.r} #{new_clip.b} #{new_clip.l} #{new_clip.b}"
            else
                final = clip\match("\\i?clip%((m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)") if clip\match("\\i?clip%(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)")
        else
            final = clip
        final

    clip_un: (j, loop_x, loop_y, left, top, width, height, offset, mode) => -- an interpolation of clip cuts
        loop_W, loop_H = loop_x, loop_y
        left_x, top_y = left - offset, top - offset
        clip_W, clip_H = width + 2 * offset, height + 2 * offset
        offset = offset or 3
        mode = mode or 79
        size_W, size_H = clip_W / loop_W, clip_H / loop_H
        local cx1, cx2, cy1, cy2
    
        switch mode
            when 12, 71
                cx1 = zf.math\round(left_x + (ceil(j / loop_H) - 1) * size_W, 3)
                cx2 = zf.math\round(left_x + (ceil(j / loop_H) - 0) * size_W, 3)
            when 12, 79
                cx1 = zf.math\round(left_x + ((j - 1) % loop_W + 0) * size_W, 3)
                cx2 = zf.math\round(left_x + ((j - 1) % loop_W + 1) * size_W, 3)
            when 39, 93
                cx1 = zf.math\round(left_x + clip_W - (ceil(j / loop_H) - 0) * size_W, 3)
                cx2 = zf.math\round(left_x + clip_W - (ceil(j / loop_H) - 1) * size_W, 3)
            when 31, 97
                cx1 = zf.math\round(left_x + clip_W - ((j - 1) % loop_W + 1) * size_W, 3)
                cx2 = zf.math\round(left_x + clip_W - ((j - 1) % loop_W + 0) * size_W, 3)
    
        switch mode
            when 79, 97
                cy1 = zf.math\round(top_y + (ceil(j / loop_W) - 1) * size_H, 3)
                cy2 = zf.math\round(top_y + (ceil(j / loop_W) - 0) * size_H, 3)
            when 71, 93
                cy1 = zf.math\round(top_y + ((j - 1) % loop_H + 0) * size_H, 3)
                cy2 = zf.math\round(top_y + ((j - 1) % loop_H + 1) * size_H, 3)
            when 13, 31
                cy1 = zf.math\round(top_y + clip_H - (ceil(j / loop_W) - 0) * size_H, 3)
                cy2 = zf.math\round(top_y + clip_H - (ceil(j / loop_W) - 1) * size_H, 3)
            when 17, 39
                cy1 = zf.math\round(top_y + clip_H - ((j - 1) % loop_H + 1) * size_H, 3)
                cy2 = zf.math\round(top_y + clip_H - ((j - 1) % loop_H + 0) * size_H, 3)
    
        "\\clip(#{cx1},#{cy1},#{cx2},#{cy2})"

class TAGS

    new: (tags) =>
        @tags = tags

    find: => -- finds and returns the raw tags
        if @tags\match("%b{}") then @tags\match("%b{}")\sub(2, -2) else ""

    clean: (text) => -- Aegisub Macro - Clean Tags
        ktag = "\\[kK][fo]?%d+"
        combineadjacentnotks = (block1, block2) ->
            if string.find(block1, ktag) and string.find(block2, ktag)
                "{#{block1}}#{string.char(1)}{#{block2}}"
            else
                "{#{block1}#{block2}}"

        while true
            return if aegisub.progress.is_cancelled!
            text, replaced = string.gsub(text, "{(.-)}{(.-)}", combineadjacentnotks)
            break if replaced == 0

        text = text\gsub(string.char(1), "")\gsub("{([^{}]-)(" .. ktag .. ")(.-)}", "{%2%1%3}")
        while true
            return if aegisub.progress.is_cancelled!
            text, replaced = text\gsub("{([^{}]-)(" .. ktag .. ")(\\[^kK][^}]-)(" .. ktag .. ")(.-)}", "{%1%2%4%3%5}")
            break if replaced == 0

        linetags = ""
        first = (pattern) ->
            p_s, _, p_tag = text\find(pattern)
            if p_s
                text = text\gsub(pattern, "")
                linetags ..= p_tag

        firstoftwo = (pattern1, pattern2) ->
            p1_s, _, p1_tag = text\find(pattern1)
            p2_s, _, p2_tag = text\find(pattern2)
            text = text\gsub(pattern1, "")\gsub(pattern2, "")
            if p1_s and (not p2_s or p1_s < p2_s)
                linetags ..= p1_tag
            elseif p2_s
                linetags ..= p2_tag

        first("(\\an?%d+)")
        first("(\\org%([^,%)]*,[^,%)]*%))")
        firstoftwo("(\\move%([^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*%))", "(\\pos%([^,%)]*,[^,%)]*%))")
        firstoftwo("(\\fade%([^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*%))", "(\\fad%([^,%)]*,[^,%)]*%))")

        if linetags\len! > 0
            if text\sub(1, 1) == "{" then text = "{#{linetags}#{text\sub(2)}" else text = "{#{linetags}}#{text}"

        comb = (a, b, c, d, e) ->
            if (c != "\\clip" and c != "\\iclip") or d\sub(-1)\find("[,%({]") or e\sub(1, 1)\find("[,%)}]") then
                a .. b .. d .. e
            else
                a .. b .. d .. string.char(2) .. e

        while true
            text, replaced2 = text\gsub("({[^}\\]*)([^}%s]*(\\[^%(}\\%s]*))%s*(%([^%s%)}]*)%s+([^}]*)", comb)
            break if replaced2 == 0

        text, _ = text\gsub(string.char(2), " ")
        text\gsub("{%s*}", "")

    remove: (modes, tags) => -- only a tag removal repository
        @tags = tags or @find!
        modes = modes or "full"

        caps = {
            fn: "\\fn[%s+]*[^\\}]*", fs: "\\fs%d+[%.%d+]*", fsp: "\\fsp%-?%d+[%.%d+]*"
            fscx: "\\fscx%d+[%.%d+]*", fscy: "\\fscy%d+[%.%d+]*", b: "\\b%d"
            i: "\\i%d", s: "\\s%d", u: "\\u%d"
            p: "\\p%d", an: "\\an%d", fr: "\\fr[z]*%-?%d+[%.%d]*"
            frx: "\\frx%-?%d+[%.%d]*", fry: "\\fry%-?%d+[%.%d]*", fax: "\\fax%-?%d+[%.%d]*"
            fay: "\\fay%-?%d+[%.%d]*", pos: "\\pos%b()", org: "\\org%b()"
            _1c: "\\1?c[%s+]*&H%x+&", _2c: "\\2c[%s+]*&H%x+&", _3c: "\\3c[%s+]*&H%x+&"
            _4c: "\\4c[%s+]*&H%x+&", bord: "\\bord%d+[%.%d+]*", clip: "\\i?clip%b()"
            shad: "\\[xy]*shad%-?%d+[%.%d+]*", move:"\\move%b()"
        }

        switch modes
            when "shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_gradient"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.bord, "\\bord0")\gsub(caps._1c, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.shad, "\\shad0")
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\shad0" unless @tags\match(caps.shad)
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "text_shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.fscx, "\\fscx100")
                @tags = @tags\gsub(caps.fscy, "\\fscy100")\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_clip"
                @tags ..= "\\p1" unless @tags\match(caps.p)
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.clip, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
            when "text_clip"
                @tags = @tags\gsub(caps.clip, "")
            when "shape_expand"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.fscx, "\\fscx100")
                @tags = @tags\gsub(caps.fscy, "\\fscy100")\gsub(caps.fr, "")\gsub(caps.frx, "")\gsub(caps.fry, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.fay, "")\gsub(caps.org, "")
                @tags = @tags\gsub(caps.fax, "")\gsub(caps.an, "\\an7")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "full"
                @tags = @tags\gsub("%b{}", "")\gsub("\\N", " ")\gsub("\\n", " ")\gsub("\\h", " ")
            when "bezier_text"
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.pos, "")\gsub(caps.move, "")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.fsp, "")
            when "out"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps._1c, "")\gsub(caps.bord, "\\bord0")\gsub(caps.an, "\\an7")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\p1" unless @tags\match(caps.p)
        @tags

zf.math, zf.table, zf.poly, zf.text, zf.util, zf.tags = MATH!, TABLE!, SUB_POLY!, TEXT!, SUPPORT!, TAGS
return zf