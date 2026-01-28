const core = @import("core.zig");
const Vec4 = core.Vec4;
const Mat4 = core.Mat4;
const Point3 = core.Point3;

pub inline fn transform_position(p: Point3, m: Mat4) Point3 {
    const v = vec_mat_mul(.{ p.x, p.y, p.z, 1 }, m);
    return .{ .x = v[0], .y = v[1], .z = v[2] };
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

    const m = Mat4{
        Vec4{ ax[0], ay[0], az[0], 0 },
        Vec4{ ax[1], ay[1], az[1], 0 },
        Vec4{ ax[2], ay[2], az[2], 0 },
        Vec4{ -dot3(ax, eye_pos), -dot3(ay, eye_pos), -dot3(az, eye_pos), 1.0 },
    };

    return transpose_matrix(m);
}

pub fn perspective_matrix(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var mat = core.zero_mat();

    const f: f32 = 1 / @tan(fov * 0.5);

    mat[0][0] = f / aspect;
    mat[1][1] = f;
    mat[2][2] = -(far + near) / (near - far);
    mat[2][3] = (far * near) / (near - far);
    mat[3][2] = 1;
    mat[3][3] = 0;
    return mat;
}
