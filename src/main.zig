const std = @import("std");

const math = @import("math.zig");
const Point2 = math.Point2;
const Point3 = math.Point3;
const Mat4 = math.Mat4;

const model = @import("model.zig");
const Camera = @import("camera.zig").Camera;

const c = @import("cimport.zig").c;

// Rendering at 0.5 resolution scale
const RENDER_HEIGHT = 1080 / 2;
const RENDER_WIDTH = RENDER_HEIGHT;

const TARGET_HEIGHT = RENDER_HEIGHT;
const TARGET_WIDTH = RENDER_WIDTH;

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

const VP = struct {
    projection: Mat4,
    view: Mat4 = undefined,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.err("GPA leaked", .{});
    }

    const allocator = gpa.allocator();

    const window = c.RGFW_createWindow("zcpu3D", 0, 0, TARGET_WIDTH, TARGET_HEIGHT, c.RGFW_windowCenter | c.RGFW_windowNoResize | c.RGFW_windowHideMouse | c.RGFW_windowCaptureMouse);
    defer c.RGFW_window_close(window);

    var target_buffer: [TARGET_WIDTH][TARGET_HEIGHT]Color = std.mem.zeroes([TARGET_WIDTH][TARGET_HEIGHT]Color);
    // need to go with native format RGFW_formatBGRA8, otherwise RGFW_copyImageData64 will be making copy of buffer one by one pixel.
    const surface = c.RGFW_createSurface(@ptrCast(&target_buffer), TARGET_WIDTH, TARGET_HEIGHT, c.RGFW_formatBGRA8);
    defer c.RGFW_surface_free(surface);

    var render_buffer: [RENDER_WIDTH][RENDER_HEIGHT]Color = undefined;
    clear_buffer(@ptrCast(&render_buffer), RENDER_WIDTH, RENDER_HEIGHT, BACKGROUND);
    const olivec_canvas = c.olivec_canvas(@ptrCast(@alignCast(&render_buffer)), RENDER_WIDTH, RENDER_HEIGHT, RENDER_WIDTH);
    var zbuffer: [RENDER_WIDTH * RENDER_HEIGHT]f32 = std.mem.zeroes([RENDER_WIDTH * RENDER_HEIGHT]f32);

    const fps_refresh_frequency_micro = 100_000;
    var old_time = std.time.microTimestamp();
    var time_diff: i64 = 0;
    var number_of_frames: i32 = 1;
    var refresh_rate: f32 = 0;

    var angle: f32 = 0;

    var teapot_mesh = model.Model.load(allocator, "assets/teapot.obj");
    defer teapot_mesh.deinit();

    var monkey_mesh = model.Model.load(allocator, "assets/monkey.obj");
    defer monkey_mesh.deinit();

    var camera = Camera.init();
    camera.position[0] = 8;
    camera.position[1] = 1;
    camera.position[2] = -15;
    camera.yaw = 0;

    const perspective = math.perspective_matrix(70, @as(f32, @floatFromInt(RENDER_WIDTH)) / @as(f32, @floatFromInt(RENDER_HEIGHT)), 0.1, 500);

    var vp = VP{ .projection = perspective };

    var event: c.RGFW_event = undefined;
    c.RGFW_waitForEvent(c.RGFW_eventNoWait);
    c.RGFW_window_setExitKey(window, c.RGFW_escape);

    while (c.RGFW_window_shouldClose(window) == c.RGFW_FALSE) {
        while (c.RGFW_window_checkEvent(window, &event) == c.RGFW_TRUE) {}

        clear_buffer(@ptrCast(&render_buffer), RENDER_WIDTH, RENDER_HEIGHT, BACKGROUND);
        zbuffer = std.mem.zeroes([RENDER_WIDTH * RENDER_HEIGHT]f32);

        const cur_time = std.time.microTimestamp();
        const dt = cur_time - old_time;
        const usable_dt = @as(f32, @floatFromInt(dt)) / 1_000_000;
        old_time = cur_time;
        angle += usable_dt * std.math.pi / 2.0;

        camera.update(window.?, usable_dt);
        vp.view = math.look_at(camera.position, camera.front, camera.up);

        const view_proj = math.mul_mat_mul(vp.view, vp.projection);
        const rotation = math.rotation_y(angle);

        var transform = math.translation_matrix(0, 0, 5);
        draw_entity(olivec_canvas, &monkey_mesh, math.mul_mat_mul(rotation, transform), view_proj, &zbuffer, false, allocator);

        transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        draw_entity(olivec_canvas, &monkey_mesh, math.mul_mat_mul(rotation, transform), view_proj, &zbuffer, true, allocator);

        transform = math.mul_mat_mul(math.translation_matrix(5, -1, 0), transform);
        draw_entity(olivec_canvas, &teapot_mesh, math.mul_mat_mul(rotation, transform), view_proj, &zbuffer, false, allocator);

        transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        draw_entity(olivec_canvas, &teapot_mesh, math.mul_mat_mul(rotation, transform), view_proj, &zbuffer, true, allocator);

        // for (0..100) |_| {
        //     transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        //     draw_entity(olivec_canvas, &monkey_mesh, math.mul_mat_mul(rotation, transform), view_proj, &zbuffer, false, allocator);
        // }

        check_fps(olivec_canvas, refresh_rate);
        time_diff += dt;
        if (time_diff >= fps_refresh_frequency_micro) {
            refresh_rate = @as(f32, @floatFromInt(time_diff)) / @as(f32, @floatFromInt(1000 * number_of_frames));
            number_of_frames = 1;
            time_diff = 0;
        } else {
            number_of_frames += 1;
        }

        make_target_screen(&render_buffer, &target_buffer);
        c.RGFW_window_blitSurface(window, surface);

        // slow down
        std.Thread.sleep(15_000_000);
    }
}

fn make_target_screen(render: *[RENDER_WIDTH][RENDER_HEIGHT]Color, target: *[TARGET_WIDTH][TARGET_HEIGHT]Color) void {
    if (RENDER_WIDTH == TARGET_WIDTH and RENDER_HEIGHT == TARGET_HEIGHT) {
        @memcpy(target, render);
        return;
    }
    if (RENDER_WIDTH * 2 != TARGET_WIDTH or RENDER_HEIGHT * 2 != TARGET_HEIGHT)
        return;

    clear_buffer(@ptrCast(target), TARGET_WIDTH, TARGET_HEIGHT, BACKGROUND);
    for (0..RENDER_WIDTH) |x| {
        for (0..RENDER_HEIGHT) |y| {
            target[x * 2][y * 2] = render[x][y];
            target[x * 2][y * 2 + 1] = render[x][y];
            target[x * 2 + 1][y * 2] = render[x][y];
            target[x * 2 + 1][y * 2 + 1] = render[x][y];
        }
    }
}

fn printm(m: Mat4) void {
    std.debug.print("{any}\n", .{m});
}

fn draw_entity(oc: c.Olivec_Canvas, mesh: *const model.Model, transform: Mat4, view_projection: Mat4, zbuffer: []f32, wireframe_on: bool, allocator: std.mem.Allocator) void {
    const mvp_calc = math.mul_mat_mul(transform, view_projection);

    const translated_verices = allocator.alloc(Point3, mesh.vertices.len) catch @panic("OOM");
    defer allocator.free(translated_verices);

    for (translated_verices, 0..) |*item, index| {
        item.* = math.transform_position(mesh.vertices[index], mvp_calc);
    }

    for (0..mesh.faces.len / 3) |ind| {
        const v1 = translated_verices[mesh.faces[ind * 3]];
        const v2 = translated_verices[mesh.faces[ind * 3 + 1]];
        const v3 = translated_verices[mesh.faces[ind * 3 + 2]];

        const p1 = point_to_screen(point_3_2(v1));
        const p2 = point_to_screen(point_3_2(v2));
        const p3 = point_to_screen(point_3_2(v3));

        const max_offset = 100.0;
        if (p1.x < -max_offset or p1.x > RENDER_WIDTH + max_offset or p1.y < -max_offset or p1.y > RENDER_HEIGHT + max_offset)
            continue;

        if (p2.x < -max_offset or p2.x > RENDER_WIDTH + max_offset or p2.y < -max_offset or p2.y > RENDER_HEIGHT + max_offset)
            continue;

        if (p3.x < -max_offset or p3.x > RENDER_WIDTH + max_offset or p3.y < -max_offset or p3.y > RENDER_HEIGHT + max_offset)
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

                            const z: f32 = 1 / v1.z * f1 + 1 / v2.z * f2 + 1 / v3.z * f3;
                            if (z > zbuffer[x + y * RENDER_WIDTH]) {
                                zbuffer[x + y * RENDER_WIDTH] = z;
                                oc.pixels[x + y * RENDER_WIDTH] = c.olivec_mix_colors3(0xFF1818FF, 0xFF18FF18, 0xFFFF1818, bu1, bu2, bdet);
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
    return .{ .x = (point.x + 1) / 2 * RENDER_WIDTH, .y = (1 - (point.y + 1) / 2) * RENDER_HEIGHT };
}

fn point_3_2(point: Point3) Point2 {
    const z: f32 = if (point.z != 0) point.z else 10000000.0;
    return .{ .x = point.x / z, .y = point.y / z };
}

fn check_fps(oc: c.Olivec_Canvas, refresh_rate: f32) void {
    var buffer = [_]u8{0} ** 64;
    const title = std.fmt.bufPrint(&buffer, "{}x{} ms: {d:.2}, fps: {d:.2}", .{ RENDER_WIDTH, RENDER_HEIGHT, refresh_rate, 1000 / @max(refresh_rate, 0.01) }) catch @panic("smol buffer");

    c.olivec_text(oc, title.ptr, 10, 10, c.olivec_default_font, 2, 0xFFFFFFFF);
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
    draw_rect(buffer, RENDER_WIDTH, RENDER_HEIGHT, GREEN, @as(i32, @intFromFloat(point.x)) - point_size / 2, @as(i32, @intFromFloat(point.y)) - point_size / 2, point_size, point_size);
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
