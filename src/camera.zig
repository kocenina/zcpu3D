const core = @import("core.zig");
const Vec4 = core.Vec4;
const Mat4 = core.Mat4;

pub const Camera = struct {
    yaw: f32 = 0.0,
    pitch: f32 = 0.0,
    position: Vec4 = .{ 0, 0, 0, 0 },

    front: core.Vec4 = .{ 0, 0, 0, 0 },
    right: core.Vec4 = .{ 0, 0, 0, 0 },
    up: core.Vec4 = .{ 0, 0, 0, 0 },
    world_up: core.Vec4 = .{ 0, 1, 0, 0 },

    // mat4x4 lookAt(vec3  const & eye, vec3  const & center, vec3  const & up)
    // {
    //     vec3  f = normalize(center - eye);
    //     vec3  u = normalize(up);
    //     vec3  s = normalize(cross(f, u));
    //     u = cross(s, f);

    //     mat4x4 Result(1);
    //     Result[0][0] = s.x;
    //     Result[1][0] = s.y;
    //     Result[2][0] = s.z;
    //     Result[0][1] = u.x;
    //     Result[1][1] = u.y;
    //     Result[2][1] = u.z;
    //     Result[0][2] =-f.x;
    //     Result[1][2] =-f.y;
    //     Result[2][2] =-f.z;
    //     Result[3][0] =-dot(s, eye);
    //     Result[3][1] =-dot(u, eye);
    //     Result[3][2] = dot(f, eye);
    //     return Result;
    // }

    pub fn rotation(_: *Camera) void {
        // const input = self.scene.input;
        // // exit
        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_ESCAPE)) {
        //     self.scene.exit();
        // }

        // const per_camera = &self.camera.perspective_camera;

        // var x: f32 = 0.0;
        // var y: f32 = 0.0;
        // var z: f32 = 0.0;

        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_A)) {
        //     x -= 1.0;
        // }
        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_D)) {
        //     x += 1.0;
        // }

        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_LEFT_CONTROL)) {
        //     y -= 1.0;
        // }
        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_SPACE)) {
        //     y += 1.0;
        // }

        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_W)) {
        //     z += 1.0;
        // }
        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_S)) {
        //     z -= 1.0;
        // }

        // var cam_speed: f32 = CAMERA_MOVE_SPEED;
        // if (input.is_key_pressed(sersan.inputs.c.GLFW_KEY_LEFT_SHIFT)) {
        //     cam_speed = CAMERA_MOVE_SPEED_SPRINT;
        // }

        // var result = (per_camera.camera_context.right * sersan.zmath.f32x4s(x)) + (per_camera.camera_context.front * sersan.zmath.f32x4s(z));
        // if (x != 0 and z != 0)
        //     result = sersan.zmath.normalize4(result);

        // result = result * sersan.zmath.f32x4s(cam_speed) * sersan.zmath.f32x4s(delta_time);
        // per_camera.camera_context.position += result;
        // per_camera.camera_context.position[1] += y * cam_speed * delta_time;

        // const yaw: f32 = @floatCast(input.delta_mouse_x);
        // per_camera.camera_context.yaw -= yaw / 10;

        // const pitch: f32 = @floatCast(input.delta_mouse_y);
        // per_camera.camera_context.pitch -= pitch / 10;
    }

    pub fn refresh_vectors(self: *Camera) void {
        self.front = .{ 0, 0, 0, 0 };
        self.front[0] = @sin((self.yaw)) * @cos((self.pitch)); //  sin(glm::radians(GetYaw())) * cos(glm::radians(GetPitch()));
        self.front[1] = @sin((self.pitch)); //sin(glm::radians(GetPitch()));
        self.front[2] = @cos((self.yaw)) * @cos((self.pitch)); // cos(glm::radians(GetYaw())) * cos(glm::radians(GetPitch()));
        self.front = core.normalize3(self.front);

        self.right = core.normalize3(core.cross3(self.front, self.world_up));
        self.up = core.normalize3(core.cross3(self.right, self.front));
    }
};
