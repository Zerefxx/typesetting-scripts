pi, ln, sin, cos, tan, max, min  = math.pi, math.log, math.sin, math.cos, math.tan, math.max, math.min
abs, deg, rad, log, asin, sqrt   = math.abs, math.deg, math.rad, math.log10, math.asin, math.sqrt
acos, atan, sinh, cosh, tanh     = math.acos, math.atan, math.asin, math.cosh, math.tanh
rand, ceil, floor, atan2, format = math.random, math.ceil, math.floor, math.atan2, string.format

require "karaskel"
export Yutils = require "Yutils"

ffi = require "ffi"
if ffi.os != "Windows"
    error("This is not compatible with your operating system.")
else
    export Poly = require "ZF.clipper.clipper"

-- Start Lib
export zf = {}
l2b, l2l, bezier_segments = {}, {}, {}

class MATH

    round: (x, dec = 3) => -- round values
        if dec and dec >= 1
            dec = 10 ^ floor dec
            return floor(x * dec + 0.5) / dec
        else
            return floor x + 0.5

    angle: (x1 = 0, y1 = 0, x2 = 0, y2 = 0) => -- returns the angle between two points
        angle = deg(atan((y2 - y1) / (x2 - x1)))
        if x2 > x1 and y2 == y1
            angle = 0
        elseif x2 > x1 and y2 > y1
            angle = 360 - angle
        elseif x2 == x1 and y2 > y1
            angle = 270
        elseif x2 < x1 and y2 > y1
            angle = 180 - angle
        elseif x2 < x1 and y2 == y1
            angle = 180
        elseif x2 < x1 and y2 < y1
            angle = 180 - angle
        elseif x2 == x1 and y2 < y1
            angle = 90
        elseif x2 > x1 and y2 < y1
            angle = -angle
        return angle

    distance: (x1 = 0, y1 = 0, x2 = 0, y2 = 0) => -- returns the distance between two points
        if type(x1) == "table"
            polylength = 0
            for i = 3, #x1, 2 do polylength += @distance(x1[i], x1[i + 1], x1[i - 2], x1[i - 1])
            return polylength
        return @round(((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5, 3)

    factk: (n) => -- returns the factorial of a number
        k_factk = 1
        if n > 1 then for i = 2, n do k_factk *= i
        return k_factk

    bernstein: (i, n, t) => -- returns Bezier patches --> https://en.wikipedia.org/wiki/Bernstein%E2%80%93Vazirani_algorithm
        return (@factk(n) / (@factk(i) * @factk(n - i))) * (t ^ i) * ((1 - t) ^ (n - i))

    confi_bezier: (x, y, t, rt) => -- returns the Bezier points configured
        px, py = x, y
        if y == nil
            px, py = {}, {}
            for i = 1, #x / 2
                px[i] = x[2 * i - 1]
                py[i] = x[2 * i - 0]
        pos_x, pos_y, n = 0, 0, #px
        for i = 1, n
            pos_x += px[i] * @bernstein(i - 1, n - 1, t)
            pos_y += py[i] * @bernstein(i - 1, n - 1, t)
        return (rt != "y" and pos_x or pos_y), not rt and pos_y or nil

    length_bezier: (bezier) => -- returns the length of the bezier
        px, py, bx, by = {}, {}, {}, {}
        blength, nN = 0
        for i = 1, #bezier / 2
            px[i], py[i] = bezier[2 * i - 1], bezier[2 * i]
        nN = ceil(1.33 * @distance(bezier))
        for i = 1, nN
            bx[i], by[i] = @confi_bezier(px, py, (i - 1) / (nN - 1))
        for i = 2, nN
            blength += @distance(bx[i], by[i], bx[i - 1], by[i - 1])
        return blength

    polar: (angle = 0, radius = 0, rt) => -- returns to the polar angle of the points
        px = @round(radius * cos(rad(angle)), 3)
        py = @round(-radius * sin(rad(angle)), 3)
        return (rt != "y" and px or py), not rt and py or nil

    interpolation: (pct, min, max) => -- interpolate two values
        if pct <= 0 then min elseif pct >= 1 then max else @round(pct * (max - min) + min, 3)

class TABLE

    op: (Table, mode, add) => -- returns several operations for tables
        Table = Table! if type(Table) == "function"
        table_sum, table_average, table_concat = 0, 0, ""
        table_add, table_inverse, table_function = {}, {}, {}
        switch mode
            when "sum", "suma"
                add or= #Table
                add = #Table if add > #Table
                for i = 1, add do table_sum = table_sum + Table[i]
                return table_sum
            when "pro", "multi"
                table_pro = table.copy(Table)
                for i = 1, #Table do table_pro[i] = Table[i] * add
                return table_pro
            when "concat"
                con_add = ""
                for i = 1, #Table
                    con_add = ""
                    con_add = add if add and i < #Table
                    table_concat ..= Table[i] .. con_add
                return table_concat
            when "average"
                for i = 1, #Table do table_average = table_average + Table[i]
                return table_average / #Table if #Table > 0
                return 0
            when "min"
                table_min = table.copy(Table)
                table.sort(table_min, (a, b) ->
                    return a < b)
                return table_min[1] if table_min[1]
                return 0
            when "max"
                table_max = table.copy(Table)
                table.sort(table_max, (a, b) ->
                    return a < b)
                return table_max[#table_max] if table_max[#table_max]
                return 0
            when "rank"
                table_rank = table.copy(Table)
                table.sort(table_rank, (a, b) ->
                    return a < b)
                return table_rank[#table_rank] - table_rank[1] if table_rank[1]
                return 0
            when "org"
                table_org = table.copy(Table)
                table.sort(table_org, (a, b) ->
                    return a < b)
                return table_org
            when "org2"
                table_org2 = table.copy(Table)
                table.sort(table_org2, (a, b) ->
                    return a > b)
                return table_org2
            when "round"
                table_round = table.copy(Table)
                return zf.math\round(table_round, add)
            when "add"
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
            when "inverse"
                for i = 1, #Table do table_inverse[i] = Table[#Table - i + 1]
                return table_inverse

    push: (t, ...) => -- pushes all the given values to the end of the table t and returns the pushed values. Nil values are ignored.
        n = select("#", ...)
        for i = 1, n do t[#t + 1] = select(i, ...)
        return ...

    view: (Table, table_name, indent) => -- returns a table as string
        cart, autoref = "", ""
        isemptytable = (Table) -> next(Table) == nil
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
            indent or= ""
            saved or= {}
            field or= table_name
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
        table_name or= "table_unnamed"
        return "#{table_name} = #{basicSerialize(Table)}" if type(Table) != "table"
        addtocart Table, table_name, indent
        return cart .. autoref

    interpolation: (t, loop, mode, accel = 1, tags = "") =>
        local ipol_i, ipol_f, pct_ip
        vtable, ipols = table.copy(t), {}
        max_loop = loop - 1
        pol = interpolate

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
        return ipols

class Point2Struct

    new: (x, y) =>
        @x = type(x) == "number" and x or 0
        @y = type(y) == "number" and y or 0

l2b.Point = (x, y) ->
    return Point2Struct(x, y)

l2b.v2SquaredLength = (a) ->
    return (a.x * a.x) + (a.y * a.y)

l2b.v2Length = (a) ->
    return math.sqrt(l2b.v2SquaredLength(a))

l2b.v2Negate = (v) ->
    result = l2b.Point!
    result.x = -v.x
    result.y = -v.y
    return result

l2b.v2Normalize = (v) ->
    result = l2b.Point!
    len = l2b.v2Length(v)
    if (len != 0)
        result.x = v.x / len
        result.y = v.y / len
    return result

l2b.v2Scale = (v, newlen) ->
    result = l2b.Point!
    len = l2b.v2Length(v)
    if (len != 0)
        result.x = v.x * newlen / len
        result.y = v.y * newlen / len
    return result

l2b.v2Add = (a, b) ->
    c = l2b.Point!
    c.x = a.x + b.x
    c.y = a.y + b.y
    return c

l2b.v2Dot = (a, b) ->
    return (a.x * b.x) + (a.y * b.y)

l2b.v2DistanceBetween2Points = (a, b) ->
    dx = a.x - b.x
    dy = a.y - b.y
    return math.sqrt((dx * dx) + (dy * dy))

l2b.v2AddII = (a, b) ->
    c = l2b.Point!
    c.x = a.x + b.x
    c.y = a.y + b.y
    return c

l2b.v2ScaleIII = (v, s) ->
    result = l2b.Point!
    result.x = v.x * s
    result.y = v.y * s
    return result

l2b.v2SubII = (a, b) ->
    c = l2b.Point!
    c.x = a.x - b.x
    c.y = a.y - b.y
    return c

l2b.computeMaxError = (d, first, last, bezCurve, u, splitPoint) ->
    P = l2b.Point!
    v = l2b.Point!
    splitPoint = (last - first + 1) / 2
    maxDist = 0
    for i = first + 1, last
        P = l2b.bezierII(3, bezCurve, u[i - first])
        v = l2b.v2SubII(P, d[i])
        dist = l2b.v2SquaredLength(v)
        if (dist >= maxDist)
            maxDist = dist
            splitPoint = i
    return {
        maxError: maxDist,
        splitPoint: splitPoint
    }

l2b.chordLengthParameterize = (d, first, last) ->
    u = {}
    u[0] = 0
    for i = first + 1, last
        u[i - first] = u[i - first - 1] + l2b.v2DistanceBetween2Points(d[i], d[i - 1])
    for i = first + 1, last
        u[i - first] = u[i - first] / u[last - first]
    return u

l2b.computeCenterTangent = (d, center) ->
    V1 = l2b.Point!
    V2 = l2b.Point!
    tHatCenter = l2b.Point!
    V1 = l2b.v2SubII(d[center - 1], d[center])
    V2 = l2b.v2SubII(d[center], d[center + 1])
    tHatCenter.x = (V1.x + V2.x) / 2
    tHatCenter.y = (V1.y + V2.y) / 2
    tHatCenter = l2b.v2Normalize(tHatCenter)
    return tHatCenter

l2b.computeLeftTangent = (d, __end) ->
    tHat1 = l2b.Point!
    tHat1 = l2b.v2SubII(d[__end + 1], d[__end])
    tHat1 = l2b.v2Normalize(tHat1)
    return tHat1

l2b.computeRightTangent = (d, __end) ->
    tHat2 = l2b.Point!
    tHat2 = l2b.v2SubII(d[__end - 1], d[__end])
    tHat2 = l2b.v2Normalize(tHat2)
    return tHat2

l2b.B0 = (u) ->
    tmp = 1 - u
    return (tmp * tmp * tmp)

l2b.B1 = (u) ->
    tmp = 1 - u
    return (3 * u * (tmp * tmp))

l2b.B2 = (u) ->
    tmp = 1 - u
    return (3 * u * u * tmp)

l2b.B3 = (u) ->
    return (u * u * u)

l2b.bezierII = (degree, V, t) ->
    Vtemp = {}
    for i = 0, degree
        Vtemp[i] = l2b.Point(V[i].x, V[i].y)
    for i = 1, degree
        for j = 0, (degree - i)
            Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
            Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y
    Q = l2b.Point(Vtemp[0].x, Vtemp[0].y)
    return Q

l2b.newtonRaphsonRootFind = (_Q, _P, u) ->
    Q1 = {
        [0]: l2b.Point!
        [1]: l2b.Point!
        [2]: l2b.Point!
    }
    Q2 = {
        [0]: l2b.Point!
        [1]: l2b.Point!
    }
    Q = {
        [0]: l2b.Point(_Q[0].x, _Q[0].y)
        [1]: l2b.Point(_Q[1].x, _Q[1].y)
        [2]: l2b.Point(_Q[2].x, _Q[2].y)
        [3]: l2b.Point(_Q[3].x, _Q[3].y)
    }
    P = l2b.Point(_P.x, _P.y)
    Q_u = l2b.bezierII(3, Q, u)

    for i = 0, 2
        Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
        Q1[i].y = (Q[i + 1].y - Q[i].y) * 3

    for i = 0, 1
        Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
        Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2

    Q1_u = l2b.bezierII(2, Q1, u)
    Q2_u = l2b.bezierII(1, Q2, u)

    numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
    denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)

    return u if denominator == 0
    uPrime = u - (numerator / denominator)
    return uPrime

l2b.reparameterize = (d, first, last, u, bezCurve) ->
    uPrime = {}
    _bezCurve = {
        [0]: l2b.Point(bezCurve[0].x, bezCurve[0].y),
        [1]: l2b.Point(bezCurve[1].x, bezCurve[1].y),
        [2]: l2b.Point(bezCurve[2].x, bezCurve[2].y),
        [3]: l2b.Point(bezCurve[3].x, bezCurve[3].y)
    }
    for i = first, last
        uPrime[i - first] = l2b.newtonRaphsonRootFind(_bezCurve, d[i], u[i - first])
    return uPrime

l2b.generateBezier = (d, first, last, uPrime, tHat1, tHat2) ->
    A, C, X = {}, {[0]: {}, [1]: {}}, {}
    tmp = l2b.Point!
    bezCurve = {}
    nPts = last - first + 1

    for i = 0, nPts - 1
        v1 = l2b.Point(tHat1.x, tHat1.y)
        v2 = l2b.Point(tHat2.x, tHat2.y)
        v1 = l2b.v2Scale(v1, l2b.B1(uPrime[i]))
        v2 = l2b.v2Scale(v2, l2b.B2(uPrime[i]))
        A[i] = {}
        A[i][0] = v1
        A[i][1] = v2

    C[0][0] = 0
    C[0][1] = 0
    C[1][0] = 0
    C[1][1] = 0
    X[0] = 0
    X[1] = 0

    for i = 0, nPts - 1
        C[0][0] += l2b.v2Dot(A[i][0], A[i][0])
        C[0][1] += l2b.v2Dot(A[i][0], A[i][1])
        C[1][0] = C[0][1]
        C[1][1] += l2b.v2Dot(A[i][1], A[i][1])
        tmp = l2b.v2SubII(d[first + i], l2b.v2AddII(l2b.v2ScaleIII(d[first], l2b.B0(uPrime[i])), l2b.v2AddII(l2b.v2ScaleIII(d[first], l2b.B1(uPrime[i])), l2b.v2AddII(l2b.v2ScaleIII(d[last], l2b.B2(uPrime[i])), l2b.v2ScaleIII(d[last], l2b.B3(uPrime[i]))))))
        X[0] += l2b.v2Dot(A[i][0], tmp)
        X[1] += l2b.v2Dot(A[i][1], tmp)

    det_C0_C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1]
    det_C0_X  = C[0][0] * X[1] - C[1][0] * X[0]
    det_X_C1  = X[0] * C[1][1] - X[1] * C[0][1]

    alpha_l = (det_C0_C1 == 0) and 0 or det_X_C1 / det_C0_C1
    alpha_r = (det_C0_C1 == 0) and 0 or det_C0_X / det_C0_C1

    segLength = l2b.v2DistanceBetween2Points(d[last], d[first])
    epsilon = 0.000001 * segLength

    if (alpha_l < epsilon) or (alpha_r < epsilon)
        dist = segLength / 3
        bezCurve[0] = d[first]
        bezCurve[3] = d[last]
        bezCurve[1] = l2b.v2Add(bezCurve[0], l2b.v2Scale(tHat1, dist))
        bezCurve[2] = l2b.v2Add(bezCurve[3], l2b.v2Scale(tHat2, dist))
        return bezCurve

    bezCurve[0] = d[first]
    bezCurve[3] = d[last]
    bezCurve[1] = l2b.v2Add(bezCurve[0], l2b.v2Scale(tHat1, alpha_l))
    bezCurve[2] = l2b.v2Add(bezCurve[3], l2b.v2Scale(tHat2, alpha_r))
    return bezCurve

l2b.fitCubic = (d, first, last, tHat1, tHat2, ____error) ->
    u, uPrime = {}, {}
    maxIterations = 4
    tHatCenter = l2b.Point!
    iterationError = ____error * ____error
    nPts = last - first + 1

    if (nPts == 2)
        dist = l2b.v2DistanceBetween2Points(d[last], d[first]) / 3
        bezCurve = {}
        bezCurve[0] = d[first]
        bezCurve[3] = d[last]
        tHat1 = l2b.v2Scale(tHat1, dist)
        tHat2 = l2b.v2Scale(tHat2, dist)
        bezCurve[1] = l2b.v2Add(bezCurve[0], tHat1)
        bezCurve[2] = l2b.v2Add(bezCurve[3], tHat2)
        l2b.drawBezierCurve(3, bezCurve)
        return

    u = l2b.chordLengthParameterize(d, first, last)
    bezCurve = l2b.generateBezier(d, first, last, u, tHat1, tHat2)

    resultMaxError = l2b.computeMaxError(d, first, last, bezCurve, u, splitPoint)
    maxError = resultMaxError.maxError
    splitPoint = resultMaxError.splitPoint

    if (maxError < ____error)
        l2b.drawBezierCurve(3, bezCurve)
        return

    if (maxError < iterationError)
        for i = 0, maxIterations
            uPrime = l2b.reparameterize(d, first, last, u, bezCurve)
            bezCurve = l2b.generateBezier(d, first, last, uPrime, tHat1, tHat2)
            resultMaxError = l2b.computeMaxError(d, first, last, bezCurve, uPrime, splitPoint)
            maxError = resultMaxError.maxError
            splitPoint = resultMaxError.splitPoint
            if (maxError < ____error)
                l2b.drawBezierCurve(3, bezCurve)
                return
            u = uPrime

    tHatCenter = l2b.computeCenterTangent(d, splitPoint)
    l2b.fitCubic(d, first, splitPoint, tHat1, tHatCenter, ____error)
    tHatCenter = l2b.v2Negate(tHatCenter)
    l2b.fitCubic(d, splitPoint, last, tHatCenter, tHat2, ____error)
    return

l2b.fitCurve = (d, nPts, ____error) ->
    tHat1 = l2b.Point!
    tHat2 = l2b.Point!
    tHat1 = l2b.computeLeftTangent(d, 0)
    tHat2 = l2b.computeRightTangent(d, nPts - 1)
    l2b.fitCubic(d, 0, nPts - 1, tHat1, tHat2, ____error)
    return

l2b.drawBezierCurve = (n, curve) ->
    table.insert(bezier_segments, curve)
    return

l2b.polyline2bezier = (polyline, ____error = 1) ->
    d, bezier_segments, j = {}, {}, 0
    for i = 1, #polyline
        d[j] = l2b.Point(polyline[i].x, polyline[i].y)
        j += 1
    l2b.fitCurve(d, #d + 1, ____error)
    return bezier_segments

l2b.solution = (shape, dist = math.pi, ____error = 1) -> -- by Itachi --> https://github.com/KaraEffect0r/Kara_Effector
    shape = type(shape) == "table" and zf.poly\to_shape(shape) or shape

    dis__one = (shape, dist) ->
        shapes = [s for s in shape\gmatch "m%s+%-?%d[%.%-%d l]*"]

        shape_simple = (shape) ->
            distance = (P1, P2) ->
                return ((P1.x - P2.x) ^ 2 + (P1.y - P2.y) ^ 2) ^ 0.5

            inpack = {}
            points = [{x: tonumber(x), y: tonumber(y)} for x, y in shape\gmatch "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"]
            points[0] = points[2]
            state = distance(points[1], points[2]) <= dist

            for i = 1, #points
                if distance(points[i], points[i - 1]) <= dist == state
                    inpack[#inpack + 1] = {bezier: state and "ok" or nil}
                    state = not state
                inpack[#inpack][#inpack[#inpack] + 1] = points[i]

            for i = 1, #inpack - 1
                unless inpack[i].bezier
                    table.insert(inpack[i + 1], 1, inpack[i][#inpack[i]])
                    inpack[i][#inpack[i]] = nil
            return inpack

        for i = 1, #shapes
            shapes[i] = shape_simple(shapes[i])
        return shapes

    make_shape = (shape, dist, ____error) ->
        sol_bezier = (points) ->
            shape = ""
            for k = 1, #points
                shape ..= "b #{zf.math\round(points[k][1].x)} #{zf.math\round(points[k][1].y)} #{zf.math\round(points[k][2].x)} #{zf.math\round(points[k][2].y)} #{zf.math\round(points[k][3].x)} #{zf.math\round(points[k][3].y)} "
            return "#{zf.math\round(points[1][0].x)} #{zf.math\round(points[1][0].y)} " .. shape

        sol_line = (points) ->
            shape = "l "
            for k = 1, #points
                shape ..= "#{points[k].x} #{points[k].y} l "
            return shape

        points = dis__one(shape, dist)
        for k = 1, #points
            for j = 1, #points[k]
                if points[k][j].bezier
                    points[k][j] = l2b.polyline2bezier(points[k][j], ____error)
                    points[k][j] = sol_bezier(points[k][j])
                else
                    points[k][j] = #points[k][j] > 0 and sol_line(points[k][j]) or "l "
            points[k] = "m " .. table.concat(points[k])
            points[k] = points[k]\gsub("m l", "m")
            points[k] = points[k]\sub(-2, -2) == "l" and points[k]\sub(1, -3) or points[k]
        return table.concat(points)

    return make_shape(shape, dist, ____error)

l2l.getSqDist = (p1, p2) ->
    dx = p1.x - p2.x
    dy = p1.y - p2.y
    return dx * dx + dy * dy

l2l.getSqSegDist = (p, p1, p2) ->
    x, y = p1.x, p1.y
    dx, dy = p2.x - x, p2.y - y

    if (dx != 0) or (dy != 0)
        t = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy)
        if (t > 1)
            x = p2.x
            y = p2.y
        elseif (t > 0)
            x += dx * t
            y += dy * t

    dx = p.x - x
    dy = p.y - y
    return dx * dx + dy * dy

l2l.simplifyRadialDist = (points, sqTolerance) ->
    local point
    prevPoint = points[1]
    newPoints = {prevPoint}

    for i = 2, #points
        point = points[i]
        if (l2l.getSqDist(point, prevPoint) > sqTolerance)
            table.insert(newPoints, point)
            prevPoint = point

    table.insert(newPoints, point) if (prevPoint != point)
    return newPoints

l2l.simplifyDPStep = (points, first, last, sqTolerance, simplified) ->
    local index
    maxSqDist = sqTolerance

    for i = first + 1, last
        sqDist = l2l.getSqSegDist(points[i], points[first], points[last])
        if (sqDist > maxSqDist)
            index = i
            maxSqDist = sqDist

    if (maxSqDist > sqTolerance)
        l2l.simplifyDPStep(points, first, index, sqTolerance, simplified) if (index - first > 1)
        table.insert(simplified, points[index])
        l2l.simplifyDPStep(points, index, last, sqTolerance, simplified) if (last - index > 1)

l2l.simplifyDouglasPeucker = (points, sqTolerance) ->
    last = #points

    simplified = {points[1]}
    l2l.simplifyDPStep(points, 1, last, sqTolerance, simplified)
    table.insert(simplified, points[last])
    return simplified

l2l.simplify = (points, tolerance, highestQuality = true, closed = true) ->
    return points if #points <= 2
    sqTolerance = (tolerance != nil) and tolerance * tolerance or 1
    points = highestQuality and points or l2l.simplifyRadialDist(points, sqTolerance)
    points = l2l.simplifyDouglasPeucker(points, sqTolerance)
    table.remove(points) unless closed
    return points

l2l.solution = (points, tolerance = 0.1, highestQuality, closed) ->
    points = (type(points) == "string") and zf.poly\to_points(points, true) or points
    sol = [l2l.simplify(v, tolerance, highestQuality, closed) for v in *points]
    return zf.poly\to_shape(sol)

class SHAPE  -- by Itachi --> https://github.com/KaraEffect0r/Kara_Effector

    new: (shape) =>
        @code = ""
        @part = {}
        @n = 0
        @minx = math.huge
        @maxx = -math.huge
        @miny = math.huge
        @maxy = -math.huge

        @part = type(shape) == "table" and table.copy(shape) or shape
        if type(shape) == "string"
            shape = shape\gsub "([bl]^*)(%s+%-?%d[%.%-%d ]*)", (bl, nums) ->
                i, k = (bl == "b" and 6 or 2), 0
                nums = nums\gsub "%-?%d[%.%d]*", (n) ->
                    k += 1
                    return (k % i == 0) and n .. " " .. bl or n
                return bl .. nums\sub(1, -3)
            shape_to_points = (shape) ->
                parts = {}
                for p in shape\gmatch("[mbl]^*%s+%-?%d[%.%-%d ]*")
                    parts[#parts + 1] = {type: p\match("[mbl]^*")}
                    for x, y in p\gmatch("(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)")
                        parts[#parts][#parts[#parts] + 1] = {x: tonumber(x), y: tonumber(y)}
                for i = 2, #parts
                    parts[i][0] = {x: parts[i - 1][#parts[i - 1]].x, y: parts[i - 1][#parts[i - 1]].y}
                return parts
            @part = shape_to_points(shape)
        for i = 1, #@part
            for j = 1, #@part[i]
                @minx, @miny = min(@minx, @part[i][j].x), min(@miny, @part[i][j].y)
                @maxx, @maxy = max(@maxx, @part[i][j].x), max(@maxy, @part[i][j].y)
                @n += 1
        for i = 1, #@part
            @code ..= @part[i].type .. " "
            for k = 1, #@part[i]
                @code ..= "#{zf.math\round(@part[i][k].x, 3)} #{zf.math\round(@part[i][k].y, 3)} "
        return s

    redraw: (tract = 2, section = "all") =>
        shapes = {}
        for i = 1, #@part
            if section != "bezier"
                if @part[i].type != "l"
                    shapes[i] = @part[i]
                else
                    shapes[i] = {type: "l"}
                    for k = 1, #@part[i]
                        x1, y1 = @part[i][k - 1].x, @part[i][k - 1].y
                        x2, y2 = @part[i][k].x, @part[i][k].y
                        ang, dist = zf.math\angle(x1, y1, x2, y2), zf.math\distance(x1, y1, x2, y2)
                        parts = dist / zf.math\round(dist / tract)
                        for j = 1, zf.math\round(dist / parts)
                            shapes[i][j] = {x: x1 + zf.math\polar(ang, parts * j, "x"), y: y1 + zf.math\polar(ang, parts * j, "y")}
            if section != "line"
                if @part[i].type != "b"
                    shapes[i] = shapes[i] or @part[i]
                else
                    shapes[i] = {type: "l"}
                    for k = 1, #@part[i]
                        bezier = {}
                        for j = 0, #@part[i]
                            bezier[#bezier + 1] = @part[i][j].x
                            bezier[#bezier + 1] = @part[i][j].y
                        length = zf.math\length_bezier(bezier)
                        n = zf.math\round(length / tract) + 1
                        for j = 1, n
                            shapes[i][j] = {x: zf.math\confi_bezier(bezier, nil, j / n, "x"), y: zf.math\confi_bezier(bezier, nil, j / n, "y")}
        return SHAPE(shapes)

    filter: (split, ...) =>
        @ = @redraw(split) if split and split > 0
        filters = (... and type(...) == "table") and ... or {...}
        filters[1] = #filters == 0 and ((x, y) -> return x, y) or filters[1]
        for j = 1, #filters
            for i = 1, #@part
                for k = 1, #@part[i]
                    x, y = @part[i][k].x, @part[i][k].y
                    @part[i][k].x, @part[i][k].y = filters[j](x, y)
            @ = SHAPE(@part)
        return @code

class POLY

    to_points: (shape, oth) => -- converts shapes to points in 3 different way
        shape = SHAPE(shape)\redraw(1, "bezier").code
        points = {parts: {}, result: {}}
        points.parts = [p for p in shape\gmatch " ([^m]+)"]
        points.result = [ [tonumber(p) * 1000 for p in v\gmatch "%-?%d+[%.%d+]*"] for v in *points.parts]
        if oth
            points = {parts: {}, result: {}}
            points.parts = [p for p in shape\gmatch " ([^m]+)"]
            points.result = [ [{x: tonumber(x), y: tonumber(y)} for x, y in v\gmatch "(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)"] for v in *points.parts]
            return points.result
        return points.result

    to_shape: (points) => -- turns points into shapes, valid only for line points
        new_shape = {}
        for k = 1, #points
            new_shape[k] = ""
            for p = 1, #points[k]
                new_shape[k] ..= "l #{zf.math\round(points[k][p].x)} #{zf.math\round(points[k][p].y)} "
            new_shape[k] = new_shape[k]\gsub("l", "m", 1)
        return table.concat(new_shape)

    create_path: (path) => -- adds path to a C structure
        pts = Poly.Path!
        n_pts = #path
        for k = 1, n_pts, 2 do pts\add(path[k], path[k + 1])
        return pts

    create_paths: (paths) => -- adds paths to a C structure
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))
        return points

    simplify: (paths, ass, tol = 1) => -- remove useless vertices from a polygon
        paths = @to_points(paths) if type(paths) == "string"
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))

        points = points\simplify!
        solution = @get_solution(points)
        return not ass and l2l.solution(solution, tol / 10) or l2b.solution(solution, tol)

    clean: (paths) =>
        paths = @to_points(paths) if type(paths) == "string"
        points = Poly.Paths!
        for k = 1, #paths do points\add(@create_path( paths[k] ))

        points = points\clean_polygon!
        return @to_shape( @get_solution(points) )

    get_solution: (path) => -- returns the clipper library solution
        get_path_points = (path) ->
            result = {}
            for k = 1, path\size!
                point = path\get(k)
                result[k] = {x: tonumber(point.x) * 0.001, y: tonumber(point.y) * 0.001}
            result
        result = {}
        for k = 1, path\size! do result[k] = get_path_points(path\get(k))
        return result

    clipper: (shape_or_points_subj, shape_or_points_clip, fill_types = "even_odd", clip_type = "intersection") => -- returns a clipped shape, according to its set configurations
        points_subj = shape_or_points_subj
        points_clip = shape_or_points_clip

        points_subj = @to_points(points_subj) if type(points_subj) != "table"
        points_clip = @to_points(points_clip) if type(points_clip) != "table"

        ft_subj, ft_clip = fill_types[1], fill_types[2]
        ft_subj, ft_clip = fill_types, fill_types if type(fill_types) != "table"

        subj = @create_paths(points_subj)
        clip = @create_paths(points_clip)

        pc = Poly.Clipper!
        pc\add_paths(subj, "subject")
        pc\add_paths(clip, "clip")
        final = pc\execute(clip_type, ft_subj, ft_clip)

        result = @get_solution(final)
        return @to_shape(result)

    offset: (points, size, join_type = "round", end_type = "closed_polygon", miter_limit = 2, arc_toleranc = 0.25) => -- returns a shape offseting, according to its set configurations
        points = @to_points(points) if type(points) == "string"
        po = Poly.ClipperOffset(miter_limit, arc_toleranc)
        pp = @create_paths(points)
        final = po\offset_paths(pp, size * 1000, join_type, end_type)

        result = @get_solution(final)
        return @to_shape(result)

    to_outline: (points, size, outline_type = "Round", mode = "Center", miter_limit = 2, arc_tolerance = 0.25) => -- returns an outline and the opposite of it, according to your defined settings
        error("You need to add a size and it has to be bigger than 0.") unless size or size <= 0

        outline_type = outline_type\lower!
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

        return @simplify(outline), @simplify(create_offset)

class SUB_POLY extends POLY

    sep_points: (points) => -- a different way of separating points
        points = @to_shape(points) if type(points) == "table"
        points_ot, k = {x: {}, y: {}}, 1
        for x, y in points\gmatch "(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)"
            points_ot.x[k] = tonumber(x)
            points_ot.y[k] = tonumber(y)
            k += 1
        return points_ot

    dimension: (points) => -- returns the winth and height values of a shape
        get_values = @sep_points(points)
        width, height = 0, 0
        if #get_values.x > 0
            width = zf.table\op(get_values.x, "rank")
            height = zf.table\op(get_values.y, "rank")
        return width, height

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
        return {
            :shape_x2, :shape_y2, :minx, :miny,
            :maxx, :maxy, :w_shape, :h_shape,
            :c_shape, :m_shape, :n_shape, :n_points
        }

    displace: (shape, x2 = 0, y2 = 0) => -- displace points
        shape = SHAPE(shape)\filter(nil, (x, y) ->
            x += x2
            y += y2
            return x, y)
        return shape

    round: (shape, n = 3) => -- round points
        shape = SHAPE(shape)\filter(nil, (x, y) ->
            x = zf.math\round(x, n)
            y = zf.math\round(y, n)
            return x, y)
        return shape

    origin: (points, pos) => -- returns the original position of the points
        minx, miny = @info(points).minx, @info(points).miny
        return @displace(points, -minx, -miny), zf.math\round(minx, 3), zf.math\round(miny, 3) if pos
        return @displace(points, -minx, -miny)

    expand: (shape, line, meta) => -- expands the points of agreement with the values of tags some tags
        shape = @org_points(shape, line.styleref.align)
        points = @to_points(shape, true)

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
        return @to_shape(points)

    smooth_edges: (shape, r) =>
        points, dist, c, l1, l2, shapes = {parts: {}, result: {}}, {}, {}, {}, {}, {}
        points.parts = ["m " .. p for p in shape\gmatch " ([^m]+)"] -- index the parts of a shape

        for k = 1, #points.parts
            points.result[k] = [{x: tonumber(x), y: tonumber(y)} for x, y in points.parts[k]\gmatch "(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)"] unless points.parts[k]\match("b") -- index the points of each part of a shape

        get_angle = (c, l) -> -- returns the value of the angle between points c and l
            delta_x = l.x - c.x
            delta_y = l.y - c.y
            return math.atan2(delta_y, delta_x)

        -- limits the radius according to the smallest distance found between points
        for k = 1, #points.parts
            unless points.parts[k]\match("b")
                for j = 2, #points.result[k]
                    x1 = points.result[k][j - 1].x
                    x2 = points.result[k][j].x
                    y1 = points.result[k][j - 1].y
                    y2 = points.result[k][j].y
                    table.insert(dist, math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) / 2)
        table.sort(dist, (a, b) -> return a < b)
        r = (dist[1] < r) and dist[1] or r

        -- does the smooth edges process
        for k = 1, #points.parts
            shapes[k] = ""
            if points.parts[k]\match("b")
                shapes[k] ..= points.parts[k]
            else
                for j = 1, #points.result[k]
                    prev = (j == 1) and #points.result[k] or j - 1
                    next = (j == #points.result[k]) and 1 or j + 1
                    c.x  = points.result[k][j].x
                    c.y  = points.result[k][j].y
                    l1.x = points.result[k][prev].x
                    l1.y = points.result[k][prev].y
                    l2.x = points.result[k][next].x
                    l2.y = points.result[k][next].y
                    angle_1 = get_angle(c, l1)
                    angle_2 = get_angle(c, l2)
                    x1 = zf.math\round(c.x + r * math.cos(angle_1))
                    y1 = zf.math\round(c.y + r * math.sin(angle_1))
                    x2 = zf.math\round(c.x + r * math.cos(angle_2))
                    y2 = zf.math\round(c.y + r * math.sin(angle_2))
                    pcx1, pcy1 = zf.math\round((x1 + 2 * c.x) / 3), zf.math\round((y1 + 2 * c.y) / 3)
                    pcx2, pcy2 = zf.math\round((x2 + 2 * c.x) / 3), zf.math\round((y2 + 2 * c.y) / 3)
                    shapes[k] ..= " l #{x1} #{y1} b #{pcx1} #{pcy1} #{pcx2} #{pcy2} #{x2} #{y2}"
                shapes[k] = shapes[k]\gsub(" l", "m", 1)

        return table.concat(shapes)\gsub("(%d)m", "%1 m")

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

    to_clip: (points, an, px = 0, py = 0) => -- moves points to relative clip positions
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

    unclip: (points, an, px = 0, py = 0) => -- moves the points to relative shape positions
        points = zf.util\clip_to_draw(points)
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

    clip: (subj, clip, x = 0, y = 0, iclip) => -- the same thing as \clip and \iclip
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
        return rec_points

    clipping: (rec, loop_x, loop_y, left, top, width, height, offset = 3, mode = 79) => -- an interpolation of clip cuts
        final, result = {}, {}
        loop = loop_x * loop_y
        for k = 1, loop
            clp = zf.util\clip_un(k, loop_x, loop_y, left, top, width, height, offset, mode)
            clp = zf.util\clip_to_draw(clp)
            final[k] = @clip(rec[1], clp, rec[2], rec[3])
            result[k] = final[k] if final[k] != ""
        return result

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
        text_shape = text_shape\gsub(" c", "")

        wd, hg     = zf.poly\dimension(text_shape)
        nwd, nhg   = tonumber(extents.width), tonumber(extents.height)

        text_off_x_sh = 0.5 * (wd - nwd)
        text_off_y_sh = 0.5 * (hg - nhg)
        text_shapecf  = zf.poly\displace(text_shape, text_off_x_sh, text_off_y_sh)

        return raw and text_shape or text_shapecf

    to_clip: (line, text, an = line.styleref.align, px = 0, py = 0) => -- converts your text into clip
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
        return meta, styles

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
        return coords

    html_color: (color, mode = "to_rgb") => -- transform an html color to hexadecimal and the other way around
        n_c =  ""
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
        return final

    clip_un: (j, loop_x, loop_y, left, top, width, height, offset = 3, mode = 79) => -- an interpolation of clip cuts
        loop_W, loop_H = loop_x, loop_y
        left_x, top_y = left - offset, top - offset
        clip_W, clip_H = width + 2 * offset, height + 2 * offset
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

        return "\\clip(#{cx1},#{cy1},#{cx2},#{cy2})"

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

    remove: (modes = "full", tags) => -- only a tag removal repository
        @tags = tags or @find!

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
            when "shape_poly"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
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

zf.math, zf.table, zf.poly, zf.shape = MATH!, TABLE!, SUB_POLY!, SHAPE
zf.text, zf.util, zf.tags = TEXT!, SUPPORT!, TAGS
return zf