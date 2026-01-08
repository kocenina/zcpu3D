const std = @import("std");

const c = @cImport({
    @cInclude("RGFW/RGFW.h");
});

// RGFW_formatBGRA8
const Color = struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8,
};

const RED = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
const BLUE = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };

pub fn main() !void {
    //2560x1440
    const width: i32 = 800;
    const height: i32 = 600;

    const window = c.RGFW_createWindow("CPU rendering", 0, 0, width, height, c.RGFW_windowCenter | c.RGFW_windowNoResize);
    defer c.RGFW_window_close(window);

    // var monitor: c.RGFW_monitor = c.RGFW_window_getMonitor(window);
    // std.debug.print("{} {}\n", .{ monitor.mode.w, monitor.mode.h });
    // monitor.mode.w = width;
    // monitor.mode.h = height;

    var buffer: [width][height]Color = undefined;
    clear_buffer(@ptrCast(&buffer), width, height, BLUE);

    // need to go with native format RGFW_formatBGRA8, otherwise RGFW_copyImageData64 will be making copy of buffer one by one pixel.
    const surface = c.RGFW_createSurface(@ptrCast(&buffer), width, height, c.RGFW_formatBGRA8);
    defer c.RGFW_surface_free(surface);

    var xx: i32 = 0;
    var event: c.RGFW_event = undefined;
    while (c.RGFW_window_shouldClose(window) == c.RGFW_FALSE) {
        while (c.RGFW_window_checkEvent(window, &event) == c.RGFW_TRUE) {
            if (event.type == c.RGFW_quit or c.RGFW_window_isKeyPressed(window, c.RGFW_escape) == c.RGFW_TRUE) {
                c.RGFW_window_setShouldClose(window, c.RGFW_TRUE);
                break;
            }
        }

        clear_buffer(@ptrCast(&buffer), width, height, BLUE);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx, 10, 100, 10);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx, 30, 100, 10);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx, 50, 100, 10);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx, 70, 100, 10);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx - 100, 90, 100, 10);

        draw_rect(@ptrCast(&buffer), width, height, RED, xx, 110, 100, 10);

        xx += 1;
        c.RGFW_window_blitSurface(window, surface);
    }
}

fn clear_buffer(buffer: [*]Color, width: i32, height: i32, color: Color) void {
    if (width == 0 or height == 0)
        return;

    // memcpy maybe better???
    for (0..@intCast(width * height)) |index| {
        buffer[index] = color;
    }
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
