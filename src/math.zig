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
