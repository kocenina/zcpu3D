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

pub const Vec4 = @Vector(4, f32);
pub const ZeroVec4: Vec4 = @splat(0);

pub fn vec_to_point(vec: Vec4) Point3 {
    return Point3.init(vec[0], vec[1], vec[2]);
}

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

pub fn translation_matrix(x: f32, y: f32, z: f32) Mat4 {
    return .{
        Vec4{ 1, 0, 0, x },
        Vec4{ 0, 1, 0, y },
        Vec4{ 0, 0, 1, z },
        Vec4{ 0, 0, 0, 1 },
    };
}

pub fn mul_mat_vec(mat: Mat4, vec: Vec4) Vec4 {
    return .{
        dot(mat[0], vec),
        dot(mat[1], vec),
        dot(mat[2], vec),
        dot(mat[3], vec),
    };
    // return .{
    //     mat[0][0] * vec[0] + mat[0][1] * vec[1] + mat[0][2] * vec[2] + mat[0][3] * vec[3],
    //     mat[1][0] * vec[0] + mat[1][1] * vec[1] + mat[1][2] * vec[2] + mat[1][3] * vec[3],
    //     mat[2][0] * vec[0] + mat[2][1] * vec[1] + mat[2][2] * vec[2] + mat[2][3] * vec[3],
    //     mat[3][0] * vec[0] + mat[3][1] * vec[1] + mat[3][2] * vec[2] + mat[3][3] * vec[3],
    // };
}

inline fn dot(vec1: Vec4, vec2: Vec4) f32 {
    const vec = vec1 * vec2;
    return @reduce(.Add, vec);
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
