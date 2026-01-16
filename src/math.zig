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
        a[0] * b[2] - a[2] * b[0],
        a[0] * b[1] - a[1] * b[0],
        0,
    };
}

pub inline fn cross4(a: Vec4, b: Vec4) Vec4 {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[0] * b[2] - a[2] * b[0],
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
    const f: Vec4 = normalize3(front);
    var u: Vec4 = normalize3(up);
    const s = normalize3(cross3(f, u));

    u = cross3(s, f);

    return .{
        Vec4{ s[0], u[0], -f[0], -dot3(s, eye_pos) },
        Vec4{ s[1], u[1], -f[1], -dot3(u, eye_pos) },
        Vec4{ s[2], u[2], -f[2], -dot3(f, eye_pos) },
        Vec4{ 0, 0, 0, 1 },
    };
}

// pub fn look_at(eye_pos: Vec4, front: Vec4, up: Vec4) Mat4 {
//     // const forward = normalize3(front); // camera Z axis
//     // const right = normalize3(cross3(up, forward));
//     // const up2 = cross3(forward, right);

//     // float3 forward = from - to;
//     // normalize(forward);
//     // float3 right = cross(arbitraryUp, forward);
//     // normalize(right);
//     // float3 up = cross(forward, right);

//     const forward = normalize3(front); // camera Z axis
//     const right = normalize3(cross3(up, forward));
//     const up2 = cross3(forward, right);

//     return .{
//         Vec4{ right[0], up2[0], forward[0], eye_pos[0] },
//         Vec4{ right[1], up2[1], forward[1], eye_pos[1] },
//         Vec4{ right[2], up2[2], forward[2], eye_pos[2] },
//         Vec4{ 0, 0, 0, 1 },
//     };
// }

// pub fn perspective_matrix(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
//     var mat = core.zero_mat();
//     _ = aspect;

//     const scale: f32 = 1.0 / @tan(@import("std").math.degreesToRadians(fov) / 2);
//     mat[0][0] = scale;
//     mat[1][1] = scale;
//     mat[2][2] = (far + near) / (near - far);
//     mat[2][3] = 2 * (far * near) / (near - far);
//     mat[3][2] = -1;
//     return mat;
// }

pub fn perspective_matrix(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var mat = core.zero_mat();

    const f: f32 = 1 / @tan(fov * 0.5);

    mat[0][0] = f / aspect;
    mat[1][1] = f;
    mat[2][2] = (far + near) / (near - far);
    mat[2][3] = 2 * (far * near) / (near - far);
    mat[3][2] = -1;
    mat[3][3] = 0;
    return mat;
}
