const math = @import("math.zig");
const iVec2 = math.iVec2;
const Vec4 = math.Vec4;

const fonts = @import("fonts.zig");

const std = @import("std");

pub const Error = error{
    CannotCreateBoundingBox,
};

// RGFW_formatBGRA8
pub const Color = packed struct {
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
        width: usize,
        height: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) @This() {
            const data = allocator.alloc(T, width * height) catch @panic("OOM");
            @memset(data, std.mem.zeroes(T));

            return .{
                .data = data,
                .width = width,
                .height = height,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.data);
        }

        // https://ziglang.org/documentation/master/#Pass-by-value-Parameters
        // Structs, unions, and arrays can sometimes be more efficiently passed as a reference, since a copy could be arbitrarily expensive depending on the size.
        // When these types are passed as parameters, Zig may choose to copy and pass by value, or pass by reference, whichever way Zig decides will be faster.
        // This is made possible, in part, by the fact that parameters are immutable.

        pub inline fn get(self: @This(), x: usize, y: usize) T {
            return self.data[x + y * self.width];
        }

        pub inline fn set(self: @This(), x: usize, y: usize, stuff: T) void {
            self.data[x + y * self.width] = stuff;
        }

        pub inline fn iexists(self: @This(), x: i32, y: i32) bool {
            return x >= 0 and @as(usize, @intCast(x)) < self.width and y >= 0 and @as(usize, @intCast(y)) < self.height;
        }

        pub fn set_all(self: @This(), stuff: T) void {
            @memset(self.data[0 .. self.width * self.height], stuff);
        }

        pub fn zero(self: @This()) void {
            @memset(self.data, std.mem.zeroes(T));
        }
    };
}

pub fn draw_triangle(screen_buffer: ImageBuffer, projected_a: iVec2, projected_b: iVec2, projected_c: iVec2, original_z: Vec4, zbuffer: DepthBuffer, vt_a: Vec4, vt_b: Vec4, vt_c: Vec4, texture: *const @import("model.zig").Texture) bool {
    const bb = triangle_bb(projected_a, projected_b, projected_c, @intCast(screen_buffer.width), @intCast(screen_buffer.height)) catch return false;
    const lx: usize = @intCast(bb[0]);
    const ly: usize = @intCast(bb[1]);
    const hx: usize = @intCast(bb[2]);
    const hy: usize = @intCast(bb[3]);
    for (ly..(hy + 1)) |y| {
        for (lx..(hx + 1)) |x| {
            const res = point_in_triangle(iVec2{ @intCast(x), @intCast(y) }, projected_a, projected_b, projected_c);
            if (!res[0])
                continue;

            const weights = res[1];

            const z = 1 / math.dot3(weights, original_z);
            if (z > zbuffer.get(x, y)) {
                zbuffer.set(x, y, z);

                // const r: u32 = @intFromFloat(255.0 * (weights[0]));
                // const g: u32 = @as(u32, @intFromFloat(255.0 * (weights[1]))) << 8;
                // const b: u32 = @as(u32, @intFromFloat(255.0 * (weights[2]))) << 16;

                const vt = vt_a * @as(Vec4, @splat(weights[0])) + vt_b * @as(Vec4, @splat(weights[1])) + vt_c * @as(Vec4, @splat(weights[2]));
                const tx: usize = @intFromFloat(vt[0] * @as(f32, @floatFromInt(texture.width)));
                const ty: usize = @intFromFloat(vt[1] * @as(f32, @floatFromInt(texture.height)));

                const index = ty * texture.channels * texture.width + tx * texture.channels;
                const r: u32 = @intCast(texture.data[index + 1]);
                const g: u32 = @as(u32, @intCast(texture.data[index] + 2)) << 8;
                const b: u32 = @as(u32, @intCast(texture.data[index] + 3)) << 16;

                const color: u32 = 0xFF000000 | r | g | b;
                screen_buffer.set(x, y, @bitCast(color));
            }
        }
    }

    return true;
}

pub fn draw_line(screen_buffer: ImageBuffer, start: iVec2, end: iVec2, color: Color) void {
    bresenham(screen_buffer, start, end, color);
}

pub fn draw_text(screen_buffer: ImageBuffer, text: []const u8, x: usize, y: usize, size: usize, color: Color) void {
    const font = fonts.DEFAULT_FONT;

    // inspired by olive.c
    for (text, 0..) |char, idx| {
        const gx = x + idx * font.width * (size + 1);
        const gy = y;
        const glyph = font.glyphs[char * font.width * font.height .. (char * font.width * font.height + font.width * font.height)];

        for (0..font.height) |sy| {
            for (0..font.width) |sx| {
                const px = gx + sx * size;
                const py = gy + sy * size;

                if (px >= screen_buffer.width or py >= screen_buffer.height)
                    continue;

                if (glyph[sx + sy * font.width] == 0)
                    continue;

                for (0..size) |spy| {
                    for (0..size) |spx| {
                        screen_buffer.set(px + spx, py + spy, color);
                    }
                }
            }
        }
    }
}

pub fn draw_point(screen_buffer: ImageBuffer, point: math.Point2, color: Color) void {
    const point_size = 10;
    draw_rect(screen_buffer, @as(i32, @intFromFloat(point.x)) - point_size / 2, @as(i32, @intFromFloat(point.y)) - point_size / 2, point_size, point_size, color);
}

pub fn draw_rect(screen_buffer: ImageBuffer, x: i32, y: i32, width: i32, height: i32, color: Color) void {
    var start_x: usize = @intCast(@max(0, x));
    start_x = @min(screen_buffer.width, start_x);

    var end_x: usize = @intCast(@max(0, x + width));
    end_x = @min(screen_buffer.width, end_x);

    var start_y: usize = @intCast(@max(0, y));
    start_y = @min(screen_buffer.height, start_y);

    var end_y: usize = @intCast(@max(0, y + height));
    end_y = @min(screen_buffer.height, end_y);

    for (@intCast(start_x)..@intCast(end_x)) |xx| {
        for (@intCast(start_y)..@intCast(end_y)) |yy| {
            screen_buffer.set(xx, yy, color);
        }
    }
}

pub fn point_to_screen(point: math.Point2, screen_buffer: ImageBuffer) math.Point2 {
    return .{ .x = (point.x + 1) / 2 * @as(f32, @floatFromInt(screen_buffer.width)), .y = (1 - (point.y + 1) / 2) * @as(f32, @floatFromInt(screen_buffer.height)) };
}

pub fn point_3d_to_2d(point: math.Point3) math.Point2 {
    const z: f32 = if (point.z != 0) point.z else std.math.floatMax(f32);
    return .{ .x = point.x / z, .y = point.y / z };
}

fn bresenham(screen_buffer: ImageBuffer, start: iVec2, end: iVec2, color: Color) void {
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
        if (screen_buffer.iexists(x0, y0)) {
            screen_buffer.set(@intCast(x0), @intCast(y0), color);
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

fn triangle_bb(p1: iVec2, p2: iVec2, p3: iVec2, screen_width: u32, screen_height: u32) Error!struct { i32, i32, i32, i32 } {
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

fn point_in_triangle(point: iVec2, a: iVec2, b: iVec2, c: iVec2) struct { bool, Vec4 } {
    const area_abp = signed_triangle_area(a, b, point);
    const area_bcp = signed_triangle_area(b, c, point);
    const area_cap = signed_triangle_area(c, a, point);

    var is_in = false;
    const total_area = area_abp + area_bcp + area_cap;
    if (total_area > 0) {
        is_in = area_abp >= 0 and area_bcp >= 0 and area_cap >= 0;
    } else if (total_area < 0) {
        is_in = area_abp <= 0 and area_bcp <= 0 and area_cap <= 0;
    }

    const area_normalizer = 1 / (area_abp + area_bcp + area_cap);
    var weights = Vec4{ area_bcp, area_cap, area_abp, 0 }; // A B C
    weights = weights * @as(Vec4, @splat(area_normalizer));

    return .{ is_in, weights };
}

fn signed_triangle_area(a: iVec2, b: iVec2, c: iVec2) f32 {
    const ac = c - a;
    const ba = b - a;

    // TODO use vector ops for perpedicular
    const perpedicular = iVec2{ -ba[1], ba[0] };
    return @as(f32, @floatFromInt(math.idot2(ac, perpedicular))) / 2;
}
