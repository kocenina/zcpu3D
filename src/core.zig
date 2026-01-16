const std = @import("std");

pub const Point2 = struct {
    x: f32 = 0,
    y: f32 = 0,
};

pub const Point3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Point3 {
        return .{ .x = x, .y = y, .z = z };
    }
};

const Vec3 = @Vector(3, f32);

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

pub fn perspective_matrix(fov: f32, near: f32, far: f32) Mat4 {
    var mat = zero_mat();

    const scale: f32 = 1.0 / @tan(std.math.degreesToRadians(fov) / 2);
    mat[0][0] = scale;
    mat[1][1] = scale;
    mat[2][2] = (far + near) / (near - far);
    mat[2][3] = 2 * (far * near) / (near - far);
    mat[3][2] = -1;
    return mat;
}

// pub fn perspective_matrix(fov: f32, near: f32, far: f32) Mat4 {
//     var mat = zero_mat();

//     const scale: f32 = 1.0 / @tan(std.math.degreesToRadians(fov) / 2);
//     mat[0][0] = scale;
//     mat[1][1] = scale;
//     mat[2][2] = -far / (far - near);
//     mat[3][2] = - (far * near) / (far - near);
//     mat[2][3] = -1;
//     return mat;
// }

pub fn inverse_matrix(mat: Mat4) Mat4 {
    // var a00: Mat3 = .{
    //     Vec3{ mat[1][1], mat[1][2], mat[1][3] },
    //     Vec3{ mat[2][1], mat[2][2], mat[2][3] },
    //     Vec3{ mat[3][1], mat[3][2], mat[3][3] },
    // };

    // for (0..3) |idx| {
    //     a00[idx] = a00[idx] * mat[0][0];
    // }

    // const a10: Mat3 = .{
    //     Vec3{ mat[0][1], mat[0][2], mat[0][3] },
    //     Vec3{ mat[2][1], mat[2][2], mat[2][3] },
    //     Vec3{ mat[3][1], mat[3][2], mat[3][3] },
    // };
    // for (0..3) |idx| {
    //     a10[idx] = a10[idx] * mat[1][0];
    // }

    // const a20: Mat3 = .{
    //     Vec3{ mat[0][1], mat[0][2], mat[0][3] },
    //     Vec3{ mat[1][1], mat[1][2], mat[1][3] },
    //     Vec3{ mat[3][1], mat[3][2], mat[3][3] },
    // };
    // for (0..3) |idx| {
    //     a20[idx] = a20[idx] * mat[2][0];
    // }

    // const a30: Mat3 = .{
    //     Vec3{ mat[0][1], mat[0][2], mat[0][3] },
    //     Vec3{ mat[1][1], mat[1][2], mat[1][3] },
    //     Vec3{ mat[2][1], mat[2][2], mat[2][3] },
    // };
    // for (0..3) |idx| {
    //     a30[idx] = a30[idx] * mat[3][0];
    // }

    // const a11 = mat[0][0];
    // const a12 = mat[0][1];
    // const a13 = mat[0][2];
    // const a14 = mat[0][3];

    // const a21 = mat[1][0];
    // const a22 = mat[1][1];
    // const a23 = mat[1][2];
    // const a24 = mat[1][3];

    // const a31 = mat[2][0];
    // const a32 = mat[2][1];
    // const a33 = mat[2][2];
    // const a34 = mat[2][3];

    // const a41 = mat[3][0];
    // const a42 = mat[3][1];
    // const a43 = mat[3][2];
    // const a44 = mat[3][3];

    // const a1 = a11 * (a22 * a33 * a44 + a23 * a34 * a42 + a24 * a32 * a43 - a24 * a33 * a42 - a23 * a32 * a44 - a22 * a34 * a43);
    // const a2 = a21 * (a12 * a33 * a44 + a13 * a34 * a42 + a14 * a32 * a43 - a14 * a33 * a42 - a13 * a32 * a44 - a12 * a34 * a43);
    // const a3 = a31 * (a12 * a23 * a44 + a13 * a24 * a42 + a14 * a22 * a43 - a14 * a23 * a42 - a14 * a22 * a44 - a12 * a24 * a43);
    // const a4 = a41 * (a12 * a23 * a34 + a13 * a24 * a32 + a14 * a22 * a33 - a14 * a23 * a32 - a13 * a22 * a34 - a12 * a24 * a33);
    // const a: Vec4 = @splat(a1 - a2 + a3 - a4);

    // return .{
    //     mat[0] * a,
    //     mat[1] * a,
    //     mat[2] * a,
    //     mat[3] * a,
    // };

    // fine for now
    // inverse rotation matrix
    const rT0 = Vec4{ mat[0][0], mat[1][0], mat[2][0], 0 };
    const rT1 = Vec4{ mat[0][1], mat[1][1], mat[2][1], 0 };
    const rT2 = Vec4{ mat[0][2], mat[1][2], mat[2][2], 0 };
    const t = Vec4{ mat[0][3], mat[1][3], mat[2][3], 1 };
    const invT = Vec4{
        -dot4(rT0, t),
        -dot4(rT1, t),
        -dot4(rT2, t),
        1,
    };
    return .{
        Vec4{ rT0[0], rT0[1], rT0[2], invT[0] },
        Vec4{ rT1[0], rT1[1], rT1[2], invT[1] },
        Vec4{ rT2[0], rT2[1], rT2[2], invT[2] },
        Vec4{ 0, 0, 0, 1 },
    };
}

pub fn transpose_matrix(mat: Mat4) Mat4 {
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
    // var matT: Mat4 = undefined;
    // for (0..4) |y| {
    //     for (0..4) |x| {
    //         matT[x][y] = mat[y][x];
    //     }
    // }
    // return matT;
}

pub fn mul_mat_mat(mat1: Mat4, mat2: Mat4) Mat4 {
    // const matT = transpose_matrix(mat1);
    const matT = (mat1);
    return .{
        Vec4{
            dot4(matT[0], mat2[0]),
            dot4(matT[1], mat2[0]),
            dot4(matT[2], mat2[0]),
            dot4(matT[3], mat2[0]),
        },
        Vec4{
            dot4(matT[0], mat2[1]),
            dot4(matT[1], mat2[1]),
            dot4(matT[2], mat2[1]),
            dot4(matT[3], mat2[1]),
        },
        Vec4{
            dot4(matT[0], mat2[2]),
            dot4(matT[1], mat2[2]),
            dot4(matT[2], mat2[2]),
            dot4(matT[3], mat2[2]),
        },
        Vec4{
            dot4(matT[0], mat2[3]),
            dot4(matT[1], mat2[3]),
            dot4(matT[2], mat2[3]),
            dot4(matT[3], mat2[3]),
        },
    };
}

pub fn mul_mat_vec(mat: Mat4, vec: Vec4) Vec4 {
    return .{
        dot4(mat[0], vec),
        dot4(mat[1], vec),
        dot4(mat[2], vec),
        dot4(mat[3], vec),
    };
    // return .{
    //     mat[0][0] * vec[0] + mat[0][1] * vec[1] + mat[0][2] * vec[2] + mat[0][3] * vec[3],
    //     mat[1][0] * vec[0] + mat[1][1] * vec[1] + mat[1][2] * vec[2] + mat[1][3] * vec[3],
    //     mat[2][0] * vec[0] + mat[2][1] * vec[1] + mat[2][2] * vec[2] + mat[2][3] * vec[3],
    //     mat[3][0] * vec[0] + mat[3][1] * vec[1] + mat[3][2] * vec[2] + mat[3][3] * vec[3],
    // };
}

inline fn dot4(vec1: Vec4, vec2: Vec4) f32 {
    const vec = vec1 * vec2;
    return @reduce(.Add, vec);
}

pub inline fn normalize3(vec: Vec4) Vec4 {
    return vec / @as(Vec4, @splat(@sqrt(dot3(vec, vec))));
}

pub inline fn cross3(a: Vec4, b: Vec4) Vec4 {
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

pub fn transform_position(mat: Mat4, pos: Point3) Point3 {
    const vec = Vec4{ pos.x, pos.y, pos.z, 1.0 };
    const t_vec = mul_mat_vec(mat, vec);
    return .{
        .x = t_vec[0],
        .y = t_vec[1],
        .z = t_vec[2],
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
