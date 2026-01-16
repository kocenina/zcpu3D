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
