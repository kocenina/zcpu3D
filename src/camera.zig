const core = @import("core.zig");
const Vec4 = core.Vec4;
const Mat4 = core.Mat4;

const math = @import("math.zig");

const c = @import("cimport.zig").c;

pub const Camera = struct {
    yaw: f32 = 0.0,
    pitch: f32 = 0.0,
    position: Vec4 = .{ 0, 0, 0, 0 },

    front: core.Vec4 = .{ 0, 0, 0, 0 },
    right: core.Vec4 = .{ 0, 0, 0, 0 },
    up: core.Vec4 = .{ 0, 0, 0, 0 },
    world_up: core.Vec4 = .{ 0, 1, 0, 0 },

    const CAMERA_MOVE_SPEED: comptime_float = 10;
    const CAMERA_MOVE_SPEED_SPRINT: comptime_float = CAMERA_MOVE_SPEED * 10;
    const MOUSE_SENSITIVITY: comptime_float = 0.5;

    pub fn init() Camera {
        return .{};
    }

    pub fn update(self: *Camera, window: *c.RGFW_window, dt: f32) void {
        self.movement(window, dt);
        self.refresh_vectors();
    }
    pub fn movement(self: *Camera, window: *c.RGFW_window, dt: f32) void {
        var x: f32 = 0.0;
        var y: f32 = 0.0;
        var z: f32 = 0.0;

        if (c.RGFW_window_isKeyDown(window, c.RGFW_a) == c.RGFW_TRUE) {
            x -= 1.0;
        }
        if (c.RGFW_window_isKeyDown(window, c.RGFW_d) == c.RGFW_TRUE) {
            x += 1.0;
        }

        if (c.RGFW_window_isKeyDown(window, c.RGFW_controlL) == c.RGFW_TRUE) {
            y -= 1.0;
        }
        if (c.RGFW_window_isKeyDown(window, c.RGFW_space) == c.RGFW_TRUE) {
            y += 1.0;
        }

        // Should be opposite, something not right with lookat matrix I think.
        if (c.RGFW_window_isKeyDown(window, c.RGFW_w) == c.RGFW_TRUE) {
            z -= 1.0;
        }
        if (c.RGFW_window_isKeyDown(window, c.RGFW_s) == c.RGFW_TRUE) {
            z += 1.0;
        }

        var cam_speed: f32 = CAMERA_MOVE_SPEED;
        if (c.RGFW_window_isKeyDown(window, c.RGFW_shiftL) == c.RGFW_TRUE) {
            cam_speed = CAMERA_MOVE_SPEED_SPRINT;
        }

        const xvec: Vec4 = @splat(x);
        const zvec: Vec4 = @splat(z);
        const csvec: Vec4 = @splat(cam_speed);
        const dtvec: Vec4 = @splat(dt);
        var result = (self.right * xvec) + (self.front * zvec);
        if (x != 0 and z != 0)
            result = math.normalize3(result);

        result = result * csvec * dtvec;
        self.position += result;
        self.position[1] += y * cam_speed * dt;

        var mouse_x: f32 = 0;
        var mouse_y: f32 = 0;
        c.RGFW_getMouseVector(&mouse_x, &mouse_y);

        self.yaw += mouse_x * dt * MOUSE_SENSITIVITY;
        self.pitch -= mouse_y * dt * MOUSE_SENSITIVITY;
    }

    pub fn refresh_vectors(self: *Camera) void {
        self.front = .{ 0, 0, 0, 0 };
        self.front[0] = @sin((self.yaw)) * @cos((self.pitch)); //  sin(glm::radians(GetYaw())) * cos(glm::radians(GetPitch()));
        self.front[1] = @sin((self.pitch)); //sin(glm::radians(GetPitch()));
        self.front[2] = @cos((self.yaw)) * @cos((self.pitch)); // cos(glm::radians(GetYaw())) * cos(glm::radians(GetPitch()));
        self.front = math.normalize3(self.front);

        self.right = math.normalize3(math.cross3(self.front, self.world_up));
        self.up = math.normalize3(math.cross3(self.right, self.front));
    }
};
