const math = @import("math.zig");
const iVec2 = math.iVec2;

const c = @import("cimport.zig").c;

const std = @import("std");

// RGFW_formatBGRA8
pub const Color = struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8 = 255,
};

pub const ImageBuffer = define_screen_buffer(Color);
pub const DepthBuffer = define_screen_buffer(f32);

fn define_screen_buffer(T: type) type {
    return struct {
        data: []T,
        width: u32,
        height: u32,

        pub fn set_all(self: @This(), stuff: T) void {
            @memset(self.data[0..@intCast(self.width * self.height)], stuff);
        }

        pub fn zero(self: @This()) void {
            std.mem.zeroes([@intCast(self.width * self.height)]f32);
        }
    };
}

pub fn draw_line(screen: c.Olivec_Canvas, start: iVec2, end: iVec2, color: u32) void {
    bresenham(screen, start, end, color);
}

fn bresenham(screen: c.Olivec_Canvas, start: iVec2, end: iVec2, color: u32) void {
    var x0: i32 = start[0];
    var y0: i32 = start[1];
    const x1: i32 = end[0];
    const y1: i32 = end[1];
    const dx: i32 = @intCast(@abs(x1 - x0));
    const sx: i32 = if (x0 < x1) 1 else -1;
    const dy: i32 = -@as(i32, @intCast(@abs(y1 - y0)));
    const sy: i32 = if (y0 < y1) 1 else -1;
    var e = dx + dy;

    while (true) {
        if (point_on_screen(screen, x0, y0)) {
            color_px(screen, x0, y0, color);
        }

        const e2 = 2 * e;
        if (e2 >= dy) {
            if (x0 == x1) break;
            e = e + dy;
            x0 = x0 + sx;
        }
        if (e2 <= dx) {
            if (y0 == y1) break;
            e = e + dx;
            y0 = y0 + sy;
        }
    }
}

inline fn point_on_screen(screen: c.Olivec_Canvas, x: i32, y: i32) bool {
    return x >= 0 and x < screen.width and y >= 0 and y < screen.height;
}

inline fn color_px(screen: c.Olivec_Canvas, x: i32, y: i32, color: u32) void {
    screen.pixels[@as(usize, @intCast(x)) + @as(usize, @intCast(y)) * screen.width] = color;
}
