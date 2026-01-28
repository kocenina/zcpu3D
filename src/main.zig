const std = @import("std");

const core = @import("core.zig");
const Point2 = core.Point2;
const Point3 = core.Point3;
const math = @import("math.zig");

const model = @import("model.zig");
const Camera = @import("camera.zig").Camera;

const c = @import("cimport.zig").c;

//2560x1440
const HEIGHT = 1080 / 2;
const WIDTH = HEIGHT;

// RGFW_formatBGRA8
const Color = struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8 = 255,
};

const RED = Color{ .r = 255, .g = 0, .b = 0 };
const GREEN = Color{ .r = 0, .g = 255, .b = 0 };
const BLUE = Color{ .r = 0, .g = 0, .b = 255 };

const BACKGROUND = Color{ .r = 0, .g = 0, .b = 0 };

const cube = [_]Point3{
    Point3.init(-0.5, -0.5, -0.5),
    Point3.init(0.5, -0.5, -0.5),
    Point3.init(0.5, 0.5, -0.5),
    Point3.init(-0.5, 0.5, -0.5),

    Point3.init(-0.5, -0.5, 0.5),
    Point3.init(0.5, -0.5, 0.5),
    Point3.init(0.5, 0.5, 0.5),
    Point3.init(-0.5, 0.5, 0.5),
};

const cube_indeces = [_]u16{ 0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0, 1, 5, 6, 6, 2, 1 };
// const cube_indeces = [_]u16{ 0, 1, 2 };

const MVP = struct {
    projection: core.Mat4,
    view: core.Mat4 = undefined,
    model: core.Mat4 = undefined,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.err("GPA leaked", .{});
    }

    const allocator = gpa.allocator();

    const window = c.RGFW_createWindow("zcpu3D", 0, 0, WIDTH, HEIGHT, c.RGFW_windowCenter | c.RGFW_windowNoResize | c.RGFW_windowHideMouse | c.RGFW_windowCaptureMouse);
    defer c.RGFW_window_close(window);

    var buffer: [WIDTH][HEIGHT]Color = undefined;
    clear_buffer(@ptrCast(&buffer), WIDTH, HEIGHT, BACKGROUND);
    const olivec_canvas = c.olivec_canvas(@ptrCast(@alignCast(&buffer)), WIDTH, HEIGHT, WIDTH);
    var zbuffer: [WIDTH * HEIGHT]f32 = std.mem.zeroes([WIDTH * HEIGHT]f32);

    // need to go with native format RGFW_formatBGRA8, otherwise RGFW_copyImageData64 will be making copy of buffer one by one pixel.
    const surface = c.RGFW_createSurface(@ptrCast(&buffer), WIDTH, HEIGHT, c.RGFW_formatBGRA8);
    defer c.RGFW_surface_free(surface);

    const fps_refresh_frequency_micro = 100_000;
    var old_time = std.time.microTimestamp();
    var time_diff: i64 = 0;
    var number_of_frames: i32 = 1;
    var refresh_rate: f32 = 0;

    var angle: f32 = 0;

    var teapot = model.Model.load(allocator, "assets/teapot.obj");
    defer teapot.deinit();

    var camera = Camera.init();
    camera.position[0] = 0;
    camera.position[1] = 1;
    camera.position[2] = -2;
    camera.yaw = 0;

    const perspective = math.perspective_matrix(70, @as(f32, @floatFromInt(WIDTH)) / @as(f32, @floatFromInt(HEIGHT)), 0.1, 500);
    const transform = core.translation_matrix(0, 0, 5);

    var mvp = MVP{ .projection = perspective, .model = transform };

    camera.update(window.?, 0);
    mvp.view = math.look_at(camera.position, camera.front, camera.up);

    var event: c.RGFW_event = undefined;
    while (c.RGFW_window_shouldClose(window) == c.RGFW_FALSE) {
        while (c.RGFW_window_checkEvent(window, &event) == c.RGFW_TRUE) {
            if (event.type == c.RGFW_quit or c.RGFW_window_isKeyPressed(window, c.RGFW_escape) == c.RGFW_TRUE) {
                c.RGFW_window_setShouldClose(window, c.RGFW_TRUE);
                break;
            }
        }

        clear_buffer(@ptrCast(&buffer), WIDTH, HEIGHT, BACKGROUND);
        zbuffer = std.mem.zeroes([WIDTH * HEIGHT]f32);

        const cur_time = std.time.microTimestamp();
        const dt = cur_time - old_time;
        const usable_dt = @as(f32, @floatFromInt(dt)) / 1_000_000;
        old_time = cur_time;
        angle += usable_dt; //* std.math.pi;

        camera.update(window.?, usable_dt);
        mvp.view = math.look_at(camera.position, camera.front, camera.up);

        // draw_object(olivec_canvas, &mvp, &zbuffer, &cube, &cube_indeces, false);
        draw_object(olivec_canvas, &mvp, &zbuffer, teapot.vertices, teapot.faces, false);
        if (false)
            break;

        check_fps(olivec_canvas, refresh_rate);
        time_diff += dt;
        if (time_diff >= fps_refresh_frequency_micro) {
            refresh_rate = @as(f32, @floatFromInt(time_diff)) / @as(f32, @floatFromInt(1000 * number_of_frames));
            number_of_frames = 1;
            time_diff = 0;
        } else {
            number_of_frames += 1;
        }

        c.RGFW_window_blitSurface(window, surface);

        // slow down
        std.Thread.sleep(15_000_000);
    }
}

fn printm(m: core.Mat4) void {
    std.debug.print("{any}\n", .{m});
}

fn draw_object(oc: c.Olivec_Canvas, mvp: *MVP, zbuffer: []f32, vertices: []const Point3, indices: []const u16, wireframe_on: bool) void {
    for (0..indices.len / 3) |ind| {
        const v1 = vertices[indices[ind * 3]];
        const v2 = vertices[indices[ind * 3 + 1]];
        const v3 = vertices[indices[ind * 3 + 2]];

        const vp = math.mul_mat_mul(mvp.view, mvp.projection);
        const mvp_calc = math.mul_mat_mul(mvp.model, vp);

        const vv1 = math.transform_position(v1, mvp_calc);
        const vv2 = math.transform_position(v2, mvp_calc);
        const vv3 = math.transform_position(v3, mvp_calc);

        const p1 = point_to_screen(point_3_2(vv1));
        const p2 = point_to_screen(point_3_2(vv2));
        const p3 = point_to_screen(point_3_2(vv3));

        const max_offset = 100.0;
        if (p1.x < -max_offset or p1.x > WIDTH + max_offset or p1.y < -max_offset or p1.y > HEIGHT + max_offset)
            continue;

        if (p2.x < -max_offset or p2.x > WIDTH + max_offset or p2.y < -max_offset or p2.y > HEIGHT + max_offset)
            continue;

        if (p3.x < -max_offset or p3.x > WIDTH + max_offset or p3.y < -max_offset or p3.y > HEIGHT + max_offset)
            continue;

        if (wireframe_on) {
            c.olivec_line(oc, @intFromFloat(p1.x), @intFromFloat(p1.y), @intFromFloat(p2.x), @intFromFloat(p2.y), 0xFF00FF00);
            c.olivec_line(oc, @intFromFloat(p2.x), @intFromFloat(p2.y), @intFromFloat(p3.x), @intFromFloat(p3.y), 0xFF00FF00);
            c.olivec_line(oc, @intFromFloat(p3.x), @intFromFloat(p3.y), @intFromFloat(p1.x), @intFromFloat(p1.y), 0xFF00FF00);
        } else {
            const x1: i32 = @intFromFloat(p1.x);
            const x2: i32 = @intFromFloat(p2.x);
            const x3: i32 = @intFromFloat(p3.x);
            const y1: i32 = @intFromFloat(p1.y);
            const y2: i32 = @intFromFloat(p2.y);
            const y3: i32 = @intFromFloat(p3.y);
            var lx: i32 = 0;
            var hx: i32 = 0;
            var ly: i32 = 0;
            var hy: i32 = 0;
            if (c.olivec_normalize_triangle(oc.width, oc.height, x1, y1, x2, y2, x3, y3, &lx, &hx, &ly, &hy)) {
                for (@intCast(ly)..@intCast(hy + 1)) |y| {
                    for (@intCast(lx)..@intCast(hx + 1)) |x| {
                        var bu1: i32 = 0;
                        var bu2: i32 = 0;
                        var bdet: i32 = 0;
                        if (c.olivec_barycentric(x1, y1, x2, y2, x3, y3, @intCast(x), @intCast(y), &bu1, &bu2, &bdet)) {
                            const bu3: i32 = bdet - bu1 - bu2;
                            const f1: f32 = @as(f32, @floatFromInt(bu1)) / @as(f32, @floatFromInt(bdet));
                            const f2: f32 = @as(f32, @floatFromInt(bu2)) / @as(f32, @floatFromInt(bdet));
                            const f3: f32 = @as(f32, @floatFromInt(bu3)) / @as(f32, @floatFromInt(bdet));

                            const z: f32 = 1 / vv1.z * f1 + 1 / vv2.z * f2 + 1 / vv3.z * f3;
                            if (z > zbuffer[x + y * WIDTH]) {
                                zbuffer[x + y * WIDTH] = z;
                                oc.pixels[x + y * WIDTH] = c.olivec_mix_colors3(0xFF1818FF, 0xFF18FF18, 0xFFFF1818, bu1, bu2, bdet);
                            }
                        }
                    }
                }
            }
        }
    }
}

fn translate_z(p: Point3, dz: f32) Point3 {
    return Point3.init(p.x, p.y - 2, p.z + dz);
}

fn rotate_y(point: Point3, angle: f32) Point3 {
    const cos = std.math.cos(angle);
    const sin = std.math.sin(angle);
    const x = cos * point.x - sin * point.z;
    const z = sin * point.x + cos * point.z;
    return .{ .x = x, .y = point.y, .z = z };
}

fn point_to_screen(point: Point2) Point2 {
    return .{ .x = (point.x + 1) / 2 * WIDTH, .y = (1 - (point.y + 1) / 2) * HEIGHT };
}

fn point_3_2(point: Point3) Point2 {
    const z: f32 = if (point.z != 0) point.z else 10000000.0;
    return .{ .x = point.x / z, .y = point.y / z };
}

fn check_fps(oc: c.Olivec_Canvas, refresh_rate: f32) void {
    var buffer = [_]u8{0} ** 64;
    const title = std.fmt.bufPrint(&buffer, "ms: {d:.2}, fps: {d:.2}", .{ refresh_rate, 1000 / @max(refresh_rate, 0.01) }) catch @panic("smol buffer");

    c.olivec_text(oc, title.ptr, 10, 10, c.olivec_default_font, 4, 0xFFFFFFFF);
}

fn clear_buffer(buffer: [*]Color, width: i32, height: i32, color: Color) void {
    if (width == 0 or height == 0)
        return;

    // memcpy maybe better???
    for (0..@intCast(width * height)) |index| {
        buffer[index] = color;
    }
}

fn draw_point(buffer: [*]Color, point: Point2) void {
    const point_size = 10;
    draw_rect(buffer, WIDTH, HEIGHT, GREEN, @as(i32, @intFromFloat(point.x)) - point_size / 2, @as(i32, @intFromFloat(point.y)) - point_size / 2, point_size, point_size);
}

fn draw_rect(buffer: [*]Color, b_width: i32, b_height: i32, color: Color, x: i32, y: i32, width: i32, height: i32) void {
    var start_x: i32 = @max(0, x);
    start_x = @min(b_width, start_x);

    var end_x: i32 = @max(0, x + width);
    end_x = @min(b_width, end_x);

    var start_y: i32 = @max(0, y);
    start_y = @min(b_height, start_y);

    var end_y: i32 = @max(0, y + height);
    end_y = @min(b_height, end_y);

    for (@intCast(start_x)..@intCast(end_x)) |xx| {
        for (@intCast(start_y)..@intCast(end_y)) |yy| {
            buffer[xx + (yy * @as(usize, @intCast(b_width)))] = color;
        }
    }
}
