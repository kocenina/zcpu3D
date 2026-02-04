pub const Error = error{
    CannotCreateBoundingBox,
};

pub const Point2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn to_vec(self: *const Point2) Vec4 {
        return .{ self.x, self.y, 0, 0 };
    }

    pub fn to_ivec(self: *const Point2) iVec2 {
        return .{ @intFromFloat(self.x), @intFromFloat(self.y) };
    }
};

pub const Point3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Point3 {
        return .{ .x = x, .y = y, .z = z };
    }
};

pub fn triangle_bb(p1: iVec2, p2: iVec2, p3: iVec2, screen_width: u32, screen_height: u32) Error!struct { i32, i32, i32, i32 } {
    var lx: i32 = p1[0];
    var hx: i32 = p1[0];

    if (lx > p2[0]) lx = p2[0];
    if (lx > p3[0]) lx = p3[0];
    if (lx < 0) lx = 0;
    if (lx >= screen_width) return Error.CannotCreateBoundingBox;

    if (hx < p2[0]) hx = p2[0];
    if (hx < p3[0]) hx = p3[0];
    if (hx >= screen_width) hx = @intCast(screen_width - 1);
    if (hx < 0) return Error.CannotCreateBoundingBox;

    var ly: i32 = p1[1];
    var hy: i32 = p1[1];

    if (ly > p2[1]) ly = p2[1];
    if (ly > p3[1]) ly = p3[1];
    if (ly < 0) ly = 0;
    if (ly >= screen_height) return Error.CannotCreateBoundingBox;

    if (hy < p2[1]) hy = p2[1];
    if (hy < p3[1]) hy = p3[1];
    if (hy >= screen_height) hy = @intCast(screen_height - 1);
    if (hy < 0) return Error.CannotCreateBoundingBox;

    return .{ lx, ly, hx, hy };
}

pub fn point_in_triangle(point: iVec2, a: iVec2, b: iVec2, c: iVec2) struct { bool, Vec4 } {
    const area_abp = signed_triangle_area(a, b, point);
    const area_bcp = signed_triangle_area(b, c, point);
    const area_cap = signed_triangle_area(c, a, point);

    const is_in: bool = area_abp >= 0 and area_bcp >= 0 and area_cap >= 0;
    if (!is_in)
        return .{ false, Vec4{ 0, 0, 0, 0 } };

    const area_normalizer = 1 / (area_abp + area_bcp + area_cap);
    var weights = Vec4{ area_bcp, area_cap, area_abp, 0 }; // A B C
    weights = weights * @as(Vec4, @splat(area_normalizer));

    return .{ is_in, weights };
}

fn signed_triangle_area(a: iVec2, b: iVec2, c: iVec2) f32 {
    const ac = c - a;
    const ba = b - a;
    const perpedicular = iVec2{ -ba[1], ba[0] };
    return @as(f32, @floatFromInt(idot2(ac, perpedicular))) / 2;
}

pub const iVec2 = @Vector(2, i32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);
pub const ZeroVec4: Vec4 = @splat(0);

pub fn vec_to_point(vec: Vec4) Point3 {
    return Point3.init(vec[0], vec[1], vec[2]);
}

const Mat3 = [3]Vec3;
pub const Mat4 = [4]Vec4;
pub fn identity_mat() Mat4 {
    const static = struct {
        const identity = Mat4{
            Vec4{ 1.0, 0.0, 0.0, 0.0 },
            Vec4{ 0.0, 1.0, 0.0, 0.0 },
            Vec4{ 0.0, 0.0, 1.0, 0.0 },
            Vec4{ 0.0, 0.0, 0.0, 1.0 },
        };
    };
    return static.identity;
}

pub fn zero_mat() Mat4 {
    const static = struct {
        const zero = Mat4{
            @splat(0.0),
            @splat(0.0),
            @splat(0.0),
            @splat(0.0),
        };
    };
    return static.zero;
}

pub fn translation_matrix(x: f32, y: f32, z: f32) Mat4 {
    return .{
        Vec4{ 1, 0, 0, x },
        Vec4{ 0, 1, 0, y },
        Vec4{ 0, 0, 1, z },
        Vec4{ 0, 0, 0, 1 },
    };
}

pub fn rotation_y(angle: f32) Mat4 {
    const c = @cos(angle);
    const s = @sin(angle);

    return .{
        Vec4{ c, 0, s, 0 },
        Vec4{ 0, 1, 0, 0 },
        Vec4{ -s, 0, c, 0 },
        Vec4{ 0, 0, 0, 1 },
    };
}

pub inline fn transform_position(p: Point3, m: Mat4) Point3 {
    const v = vec_mat_mul(.{ p.x, p.y, p.z, 1 }, m);
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}

inline fn idot2(vec1: iVec2, vec2: iVec2) i32 {
    const vec = vec1 * vec2;
    return @reduce(.Add, vec);
}

inline fn dot4(vec1: Vec4, vec2: Vec4) f32 {
    const vec = vec1 * vec2;
    return @reduce(.Add, vec);
}

pub inline fn transpose_matrix(mat: Mat4) Mat4 {
    const r0 = mat[0];
    const r1 = mat[1];
    const r2 = mat[2];
    const r3 = mat[3];

    const t0 = @shuffle(f32, r0, r1, Vec4{ 0, 1, -1, -2 });
    const t1 = @shuffle(f32, r0, r1, Vec4{ 2, 3, -3, -4 });
    const t2 = @shuffle(f32, r2, r3, Vec4{ 0, 1, -1, -2 });
    const t3 = @shuffle(f32, r2, r3, Vec4{ 2, 3, -3, -4 });

    return .{
        @shuffle(f32, t0, t2, Vec4{ 0, 2, -1, -3 }),
        @shuffle(f32, t0, t2, Vec4{ 1, 3, -2, -4 }),
        @shuffle(f32, t1, t3, Vec4{ 0, 2, -1, -3 }),
        @shuffle(f32, t1, t3, Vec4{ 1, 3, -2, -4 }),
    };
}

pub inline fn vec_mat_mul(v: Vec4, m: Mat4) Vec4 {
    const tm = m;
    return .{
        dot4(v, tm[0]),
        dot4(v, tm[1]),
        dot4(v, tm[2]),
        dot4(v, tm[3]),
    };
}

pub inline fn mul_mat_mul(a: Mat4, b: Mat4) Mat4 {
    const tma = transpose_matrix(a);
    return .{
        Vec4{
            dot4(tma[0], b[0]),
            dot4(tma[1], b[0]),
            dot4(tma[2], b[0]),
            dot4(tma[3], b[0]),
        },
        Vec4{
            dot4(tma[0], b[1]),
            dot4(tma[1], b[1]),
            dot4(tma[2], b[1]),
            dot4(tma[3], b[1]),
        },
        Vec4{
            dot4(tma[0], b[2]),
            dot4(tma[1], b[2]),
            dot4(tma[2], b[2]),
            dot4(tma[3], b[2]),
        },
        Vec4{
            dot4(tma[0], b[3]),
            dot4(tma[1], b[3]),
            dot4(tma[2], b[3]),
            dot4(tma[3], b[3]),
        },
    };
}

pub inline fn cross3(a: Vec4, b: Vec4) Vec4 {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
        0,
    };
}

pub inline fn dot3(vec1: Vec4, vec2: Vec4) f32 {
    const vec = vec1 * vec2;
    return vec[0] + vec[1] + vec[2];
}

pub inline fn normalize3(vec: Vec4) Vec4 {
    return vec / @as(Vec4, @splat(@sqrt(dot3(vec, vec))));
}

pub inline fn normalize4(vec: Vec4) Vec4 {
    return vec / @as(Vec4, @splat(@sqrt(dot4(vec, vec))));
}

pub fn look_at(eye_pos: Vec4, front: Vec4, up: Vec4) Mat4 {
    const az = normalize3(front);
    const ax = normalize3(cross3(up, az));
    const ay = normalize3(cross3(az, ax));

    return .{
        Vec4{ ax[0], ax[1], ax[2], -dot3(ax, eye_pos) },
        Vec4{ ay[0], ay[1], ay[2], -dot3(ay, eye_pos) },
        Vec4{ az[0], az[1], az[2], -dot3(az, eye_pos) },
        Vec4{ 0, 0, 0, 1 },
    };
}

pub fn perspective_matrix(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var mat = zero_mat();

    const f: f32 = 1 / @tan(fov * 0.5);

    mat[0][0] = f / aspect;
    mat[1][1] = f;
    mat[2][2] = -(far + near) / (near - far);
    mat[2][3] = (far * near) / (near - far);
    mat[3][2] = 1;
    mat[3][3] = 0;
    return mat;
}
