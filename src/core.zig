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
