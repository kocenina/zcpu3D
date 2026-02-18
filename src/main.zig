const std = @import("std");

const math = @import("math.zig");
const Point2 = math.Point2;
const Point3 = math.Point3;

const iVec2 = math.iVec2;

const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

const model = @import("model.zig");
const Camera = @import("camera.zig").Camera;

const c = @import("cimport.zig").c;

const render = @import("render.zig");
const Color = render.Color;

const RENDER_HEIGHT = 1080 / 2;
const RENDER_WIDTH = RENDER_HEIGHT;

// Rendering at 0.5 resolution scale
const ENABLE_SCALING = true;
const TARGET_HEIGHT = if (ENABLE_SCALING) RENDER_HEIGHT * 2 else RENDER_HEIGHT;
const TARGET_WIDTH = if (ENABLE_SCALING) RENDER_WIDTH * 2 else RENDER_WIDTH;

const RED = Color{ .r = 255, .g = 0, .b = 0 };
const GREEN = Color{ .r = 0, .g = 255, .b = 0 };
const BLUE = Color{ .r = 0, .g = 0, .b = 255 };
const WHITE = Color{ .r = 255, .g = 255, .b = 255 };

const BACKGROUND = Color{ .r = 0, .g = 0, .b = 0 };

const FaceCulling = enum {
    NONE,
    BACK,
    FRONT,
};

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

    var target_buffer = render.ImageBuffer.init(allocator, TARGET_WIDTH, TARGET_HEIGHT);
    defer target_buffer.deinit();

    // need to go with native format RGFW_formatBGRA8, otherwise RGFW_copyImageData64 will be making copy of buffer one by one pixel.
    const surface = c.RGFW_createSurface(@ptrCast(target_buffer.data.ptr), @intCast(target_buffer.width), @intCast(target_buffer.height), c.RGFW_formatBGRA8);
    defer c.RGFW_surface_free(surface);

    var render_buffer = render.ImageBuffer.init(allocator, RENDER_WIDTH, RENDER_HEIGHT);
    defer render_buffer.deinit();
    render_buffer.set_all(BACKGROUND);

    var zbuffer = render.DepthBuffer.init(allocator, RENDER_WIDTH, RENDER_HEIGHT);
    defer zbuffer.deinit();

    const fps_refresh_frequency_micro = 100_000;
    var old_time = std.time.microTimestamp();
    var time_diff: i64 = 0;
    var number_of_frames: i32 = 1;
    var refresh_rate: f32 = 0;

    var angle: f32 = 0;

    var teapot_mesh = model.Model.load(allocator, "assets/teapot");
    defer teapot_mesh.deinit();

    // var monkey_mesh = model.Model.load(allocator, "assets/monkey");
    // defer monkey_mesh.deinit();

    var truck_mesh = model.Model.load(allocator, "assets/kenny/firetruck");
    defer truck_mesh.deinit();

    var camera = Camera.init();
    camera.position[0] = 8;
    camera.position[1] = 1;
    camera.position[2] = -15;
    camera.yaw = 0;

    const perspective = math.perspective_matrix(70, @as(f32, @floatFromInt(render_buffer.width)) / @as(f32, @floatFromInt(render_buffer.height)), 0.1, 500);

    var vp = VP{ .projection = perspective };

    var event: c.RGFW_event = undefined;
    c.RGFW_waitForEvent(c.RGFW_eventNoWait);
    c.RGFW_window_setExitKey(window, c.RGFW_escape);

    while (c.RGFW_window_shouldClose(window) == c.RGFW_FALSE) {
        while (c.RGFW_window_checkEvent(window, &event) == c.RGFW_TRUE) {}

        render_buffer.set_all(BACKGROUND);
        zbuffer.zero();

        const cur_time = std.time.microTimestamp();
        const dt = cur_time - old_time;
        const usable_dt = @as(f32, @floatFromInt(dt)) / 1_000_000;
        old_time = cur_time;
        angle += usable_dt * std.math.pi / 2.0;
        angle = 0;

        camera.update(window.?, usable_dt);
        vp.view = math.look_at(camera.position, camera.front, camera.up);

        const view_proj = math.mul_mat_mul(vp.view, vp.projection);
        const rotation = math.rotation_y(angle);

        var transform = math.translation_matrix(0, 0, 5);
        // draw_entity(render_buffer, &monkey_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, false, FaceCulling.BACK, allocator);

        // transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        // draw_entity(render_buffer, &monkey_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, true, FaceCulling.BACK, allocator);

        // transform = math.mul_mat_mul(math.translation_matrix(5, -1, 0), transform);
        // draw_entity(render_buffer, &teapot_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, false, FaceCulling.BACK, allocator);

        // transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        // draw_entity(render_buffer, &teapot_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, false, FaceCulling.FRONT, allocator);

        // transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        // draw_entity(render_buffer, &teapot_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, false, FaceCulling.BACK, allocator);

        transform = math.mul_mat_mul(math.translation_matrix(5, 0, 0), transform);
        draw_entity(render_buffer, &truck_mesh, math.mul_mat_mul(rotation, transform), view_proj, zbuffer, false, FaceCulling.BACK, allocator);

        check_fps(render_buffer, refresh_rate);
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
        //std.Thread.sleep(15_000_000);
    }
}

fn make_target_screen(render_buffer: *render.ImageBuffer, target: *render.ImageBuffer) void {
    if (!ENABLE_SCALING) {
        @memcpy(target.data, render_buffer.data);
        return;
    }

    // maybe bottleneck
    for (0..render_buffer.height) |y| {
        const render_row = render_buffer.data[y * render_buffer.width .. (y * render_buffer.width + render_buffer.width)]; // row slice
        const target_row1 = target.data[y * 2 * target.width .. (y * 2 * target.width + target.width)];
        const target_row2 = target.data[(y * 2 + 1) * target.width .. ((y * 2 + 1) * target.width + target.width)];

        for (render_row, 0..) |_, x| {
            const color = render_row[x];

            target_row1[x * 2] = color;
            target_row1[x * 2 + 1] = color;
        }

        @memcpy(target_row2, target_row1);
    }
}

fn draw_entity(screen_buffer: render.ImageBuffer, mesh: *const model.Model, transform: Mat4, view_projection: Mat4, zbuffer: render.DepthBuffer, wireframe_on: bool, culling: FaceCulling, allocator: std.mem.Allocator) void {
    const mvp_calc = math.mul_mat_mul(transform, view_projection);

    const translated_verices = allocator.alloc(Point3, mesh.vertices.len) catch @panic("OOM");
    defer allocator.free(translated_verices);

    for (translated_verices, 0..) |*item, index| {
        item.* = math.transform_position(mesh.vertices[index], mvp_calc);
    }

    for (0..mesh.faces.len / 3) |ind| {
        const v1 = translated_verices[mesh.faces[ind * 3].vertex];
        const v2 = translated_verices[mesh.faces[ind * 3 + 1].vertex];
        const v3 = translated_verices[mesh.faces[ind * 3 + 2].vertex];

        const p1 = render.point_to_screen(render.point_3d_to_2d(v1), screen_buffer);
        const p2 = render.point_to_screen(render.point_3d_to_2d(v2), screen_buffer);
        const p3 = render.point_to_screen(render.point_3d_to_2d(v3), screen_buffer);

        // culling
        {
            if (culling != FaceCulling.NONE) {
                const vec1 = p1.to_vec();
                const vec2 = p2.to_vec();
                const vec3 = p3.to_vec();

                const first_vec = vec2 - vec1;
                const second_vec = vec3 - vec1;
                const cross = math.cross3(first_vec, second_vec);

                switch (culling) {
                    FaceCulling.BACK => {
                        if (cross[2] <= 0)
                            continue;
                    },
                    FaceCulling.FRONT => {
                        if (cross[2] >= 0)
                            continue;
                    },
                    else => unreachable,
                }
            }
        }

        // cut triangles off the screen
        const max_offset = 100.0;
        if (p1.x < -max_offset or p1.x > @as(f32, @floatFromInt(screen_buffer.width)) + max_offset or p1.y < -max_offset or p1.y > @as(f32, @floatFromInt(screen_buffer.height)) + max_offset)
            continue;

        if (p2.x < -max_offset or p2.x > @as(f32, @floatFromInt(screen_buffer.width)) + max_offset or p2.y < -max_offset or p2.y > @as(f32, @floatFromInt(screen_buffer.height)) + max_offset)
            continue;

        if (p3.x < -max_offset or p3.x > @as(f32, @floatFromInt(screen_buffer.width)) + max_offset or p3.y < -max_offset or p3.y > @as(f32, @floatFromInt(screen_buffer.height)) + max_offset)
            continue;

        if (wireframe_on) {
            render.draw_line(screen_buffer, p1.to_ivec(), p2.to_ivec(), GREEN);
            render.draw_line(screen_buffer, p2.to_ivec(), p3.to_ivec(), GREEN);
            render.draw_line(screen_buffer, p3.to_ivec(), p1.to_ivec(), GREEN);
        } else {
            const ip1 = p1.to_ivec();
            const ip2 = p2.to_ivec();
            const ip3 = p3.to_ivec();

            const vt1 = mesh.uvs[mesh.faces[ind * 3].uv].to_vec();
            const vt2 = mesh.uvs[mesh.faces[ind * 3 + 1].uv].to_vec();
            const vt3 = mesh.uvs[mesh.faces[ind * 3 + 2].uv].to_vec();

            const vn1 = mesh.normals[mesh.faces[ind * 3].normal].to_vec();
            const vn2 = mesh.normals[mesh.faces[ind * 3 + 1].normal].to_vec();
            const vn3 = mesh.normals[mesh.faces[ind * 3 + 2].normal].to_vec();

            _ = render.draw_triangle(screen_buffer, ip1, ip2, ip3, v1.to_vec(), v2.to_vec(), v3.to_vec(), zbuffer, vt1, vt2, vt3, &mesh.texture.?, vn1, vn2, vn3);
        }
    }
}

fn check_fps(screen_buffer: render.ImageBuffer, refresh_rate: f32) void {
    var buffer = [_]u8{0} ** 64;
    const title = std.fmt.bufPrint(&buffer, "{}x{} ms: {d:.2}, fps: {d:.2}", .{ screen_buffer.width, screen_buffer.height, refresh_rate, 1000 / @max(refresh_rate, 0.01) }) catch @panic("smol buffer");
    render.draw_text(screen_buffer, title, 10, 10, 2, WHITE);
}
