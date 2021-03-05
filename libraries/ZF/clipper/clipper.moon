ffi = require("ffi")
requireffi = require("requireffi.requireffi")

C_6 = switch ffi.arch
    when "x86"
        requireffi("ZF.clipper.x86.clipper_6")
    when "x64"
        requireffi("ZF.clipper.x64.clipper_6")

ffi.cdef [[
    typedef struct __zf_int_point { int64_t x, y; } zf_int_point;
    typedef struct __zf_int_rect { int64_t left; int64_t top; int64_t right; int64_t bottom; } zf_int_rect;
    typedef signed long long cInt;
    typedef struct __zf_path zf_path;
    typedef struct __zf_paths zf_paths;
    typedef struct __zf_offset zf_offset;
    typedef struct __zf_clipper zf_clipper;

    const char* zf_err_msg();
    zf_path* zf_path_new();
    void zf_path_free(zf_path *self);
    zf_int_point* zf_path_get(zf_path *self, int i);
    bool zf_path_add(zf_path *self, cInt x, cInt y);
    int zf_path_size(zf_path *self);
    double zf_path_area(const zf_path *self);
    bool zf_path_orientation(const zf_path *self);
    void zf_path_reverse(zf_path *self);
    int zf_path_point_in_polygon(zf_path *self,cInt x, cInt y);
    zf_paths* zf_path_simplify(zf_path *self,int fillType);
    zf_path* zf_path_clean_polygon(const zf_path *in, double distance);

    zf_paths* zf_paths_new();
    void zf_paths_free(zf_paths *self);
    zf_path* zf_paths_get(zf_paths *self, int i);
    bool zf_paths_add(zf_paths *self, zf_path *path);
    zf_paths* zf_paths_simplify(zf_paths *self, int fillType);
    zf_paths* zf_paths_clean_polygon(zf_paths *self, double distance);
    int zf_paths_size(zf_paths *self);

    zf_offset* zf_offset_new(double miterLimit, double roundPrecision);
    void zf_offset_free(zf_offset *self);
    zf_paths* zf_offset_path(zf_offset *self, zf_path *subj, double delta, int jointType, int endType);
    zf_paths* zf_offset_paths(zf_offset *self, zf_paths *subj, double delta, int jointType, int endType);
    void zf_offset_clear(zf_offset *self);

    zf_clipper* zf_clipper_new();
    void zf_clipper_free(zf_clipper *CLP);
    void zf_clipper_clear(zf_clipper *CLP);
    bool zf_clipper_add_path(zf_clipper *CLP,zf_path *path, int pt, bool closed,const char *err);
    bool zf_clipper_add_paths(zf_clipper *CLP,zf_paths *paths, int pt, bool closed,const char *err);
    void zf_clipper_reverse_solution(zf_clipper *CLP, bool value);
    void zf_clipper_preserve_collinear(zf_clipper *CLP, bool value);
    void zf_clipper_strictly_simple(zf_clipper *CLP, bool value);
    zf_paths* zf_clipper_execute(zf_clipper *CLP,int clipType,int subjFillType,int clipFillType);
    zf_int_rect zf_clipper_get_bounds(zf_clipper *CLP);
]]

-- libs
Path, Paths, ClipperOffset, Clipper = {}, {}, {}, {}

ClipType = {
    intersection: 0,
    union: 1,
    difference: 2,
    xor: 3
}

JoinType = {
    square: 0,
    round: 1,
    miter: 2
}

EndType = {
    closed_polygon: 0,
    closed_line: 1,
    open_butt: 2,
    open_square: 3,
    open_round: 4
}

InitOptions = {
    reverse_solution: 1,
    strictly_simple: 2,
    preserve_collinear: 4
}

PolyType = {
    subject: 0,
    clip: 1
}

PolyFillType = {
    none: 0,
    even_odd: 1,
    non_zero: 2,
    positive: 3,
    negative: 4
}

-- Path
Path.new = -> ffi.gc(C_6.zf_path_new!, C_6.zf_path_free)
Path.add = (self, x, y) -> C_6.zf_path_add(self, x, y)
Path.get = (self, i) -> C_6.zf_path_get(self, i - 1)
Path.size = (self) -> C_6.zf_path_size(self)
Path.area = (self) -> C_6.zf_path_area(self)
Path.reverse = (self) -> C_6.zf_path_reverse(self)
Path.orientation = (self) -> C_6.zf_path_orientation(self)
Path.contains = (self, x, y) -> C_6.zf_path_point_in_polygon(self, x, y)

Path.simplify = (self, fillType) ->
    fillType = fillType or "non_zero"
    fillType = assert(PolyFillType[fillType], "unknown fill type")
    C_6.zf_path_simplify(self, fillType)

Path.clean_polygon = (self, distance) ->
    distance = distance or 1.415
    C_6.zf_path_clean_polygon(self, distance)

-- Paths
Paths.new = -> ffi.gc(C_6.zf_paths_new!, C_6.zf_paths_free)
Paths.add = (self, path) -> C_6.zf_paths_add(self, path)
Paths.get = (self, i) -> C_6.zf_paths_get(self, i - 1)

Paths.simplify = (self, fillType) ->
    fillType = fillType or "even_odd"
    fillType = assert(PolyFillType[fillType], "unknown fill type")
    C_6.zf_paths_simplify(self, fillType)

Paths.clean_polygon = (self, distance) ->
    distance = distance or 1.415
    C_6.zf_paths_clean_polygon(self, distance)

Paths.size = (self) -> C_6.zf_paths_size(self)

-- Clipper Offset
ClipperOffset.new = (miter_limite, arc_tolerance) ->
    co = C_6.zf_offset_new(miter_limite or 2, arc_tolerance or 0.25)
    ffi.gc(co, C_6.zf_offset_free)

ClipperOffset.offset_path = (self, path, delta, jt, et) ->
    jt, et = jt or "square", et or "open_butt"
    assert(JoinType[jt])
    assert(EndType[et])
    out = C_6.zf_offset_path(self, path, delta, JoinType[jt], EndType[et])
    error(ffi.string(C_6.zf_err_msg!)) if out == nil
    out

ClipperOffset.offset_paths = (self, paths, delta, jt, et) ->
    jt, et = jt or "square", et or "open_butt"
    assert(JoinType[jt])
    assert(EndType[et])
    out = C_6.zf_offset_paths(self, paths, delta, JoinType[jt], EndType[et])
    error(ffi.string(C_6.zf_err_msg!)) if out == nil
    out

ClipperOffset.clear = (self) ->
    C_6.zf_offset_clear(self)

-- Clipper
Clipper.new = (...) ->
    for _, opt in ipairs {...}
        assert(InitOptions[opt])
        switch opt
            when "strictly_simple"
                C_6.zf_clipper_strictly_simple(true)
            when "reverse_solution"
                C_6.zf_clipper_reverse_solution(true)
            else
                C_6.zf_clipper_preserve_collinear(true)
    ffi.gc(C_6.zf_clipper_new!, C_6.zf_clipper_free)

Clipper.clear = (self) ->
    C_6.zf_clipper_clear(self)

Clipper.add_path = (self, path, pt, closed) ->
    assert(path, "path is nil")
    assert(PolyType[pt], "unknown polygon type")
    closed = true if closed == nil
    C_6.zf_clipper_add_path(self, path, PolyType[pt], closed, err)

Clipper.add_paths = (self, paths, pt, closed) ->
    assert(paths, "paths is nil")
    assert(PolyType[pt], "unknown polygon type")
    closed = true if closed == nil
    error(ffi.string(C_6.zf_err_msg!)) unless C_6.zf_clipper_add_paths(self, paths, PolyType[pt], closed, err)

Clipper.execute = (self, clipType, subjFillType, clipFillType) ->
    subjFillType = subjFillType or "even_odd"
    clipFillType = clipFillType or "even_odd"
    clipType = assert(ClipType[clipType], "unknown clip type")
    subjFillType = assert(PolyFillType[subjFillType], "unknown fill type")
    clipFillType = assert(PolyFillType[clipFillType], "unknown fill type")
    out = C_6.zf_clipper_execute(self, clipType, subjFillType, clipFillType)
    error(ffi.string(C_6.zf_err_msg!)) if out == nil
    out

Clipper.get_bounds = (self) ->
    r = C_6.zf_clipper_get_bounds(self)
    tonumber(r.left), tonumber(r.top), tonumber(r.right), tonumber(r.bottom)

ffi.metatype("zf_path", {
    __index: Path
})
ffi.metatype("zf_paths", {
    __index: Paths
})
ffi.metatype("zf_offset", {
    __index: ClipperOffset
})
ffi.metatype("zf_clipper", {
    __index: Clipper
})

{
    Path:          Path.new,
    Paths:         Paths.new,
    ClipperOffset: ClipperOffset.new,
    Clipper:       Clipper.new
}
