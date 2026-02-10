const math = @import("math.zig");

const c = @import("cimport.zig").c;

const std = @import("std");

const MAX_READ_BYTES_SIZE = 5_000_000; // random

const Face = struct {
    vertex: u16,
    normal: u16,
    uv: u16,
};

const Texture = struct {
    data: []u8,
    width: usize,
    height: usize,
    channels: usize,
};

// Loading wawefront obj files.
// Supporting just vertices and faces (v f).
pub const Model = struct {
    vertices: []math.Point3,
    normals: []math.Point3 = undefined,
    uvs: []math.Point2 = undefined,
    faces: []Face,
    texture: ?Texture,
    allocator: std.mem.Allocator,

    pub fn load(allocator: std.mem.Allocator, path: []const u8) Model {
        return load_model(allocator, path);
    }

    pub fn deinit(self: *Model) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.normals);
        self.allocator.free(self.uvs);
        self.allocator.free(self.faces);
    }
};

fn load_model(allocator: std.mem.Allocator, path: []const u8) Model {
    const file_path = allocator.alloc(u8, path.len + 4) catch @panic("OOM");
    defer allocator.free(file_path);

    // obj file path
    @memcpy(file_path[0..path.len], path);
    @memcpy(file_path[path.len..], ".obj");

    const objfile = std.fs.cwd().openFile(file_path, .{}) catch @panic("File does not exist");
    defer objfile.close();

    const obj_content = read_obj(objfile, allocator);

    // mtl file path
    @memcpy(file_path[path.len..], ".mtl");
    const mtlfile: ?std.fs.File = std.fs.cwd().openFile(file_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("no mtl\n", .{});
            null,
        },
        else => @panic(@errorName(err)),
    };

    var texture: ?Texture = null;
    if (mtlfile) |file| {
        defer file.close();
        texture = read_mtl(file);
    }

    return .{ .vertices = obj_content[0], .normals = obj_content[1], .uvs = obj_content[2], .faces = obj_content[3], .texture = texture, .allocator = allocator };
}

fn read_obj(objfile: std.fs.File, allocator: std.mem.Allocator) struct { []math.Point3, []math.Point3, []math.Point2, []Face } {
    var buffer = [_]u8{0} ** 1024;
    var reader = objfile.reader(&buffer);

    var vertices_array: std.ArrayList(math.Point3) = .{};
    defer vertices_array.deinit(allocator);

    var normals_array: std.ArrayList(math.Point3) = .{};
    defer normals_array.deinit(allocator);

    var uvs_array: std.ArrayList(math.Point2) = .{};
    defer uvs_array.deinit(allocator);

    var faces_array: std.ArrayList(Face) = .{};
    defer faces_array.deinit(allocator);

    while (true) {
        const line = reader.interface.takeDelimiter('\n') catch @panic("Read failed");
        if (line == null) break;

        if (line.?.len <= 5) continue;

        switch (line.?[0]) {
            'v' => {
                switch (line.?[1]) {
                    ' ' => vertices_array.append(allocator, parse_vertex(line.?)) catch @panic("OOM"),
                    'n' => normals_array.append(allocator, parse_vertex(line.?)) catch @panic("OOM"),
                    't' => uvs_array.append(allocator, parse_uv(line.?)) catch @panic("OOM"),
                    else => {},
                }
            },
            'f' => {
                const fcs = parse_faces(line.?);
                faces_array.append(allocator, fcs[0]) catch @panic("OOM");
                faces_array.append(allocator, fcs[1]) catch @panic("OOM");
                faces_array.append(allocator, fcs[2]) catch @panic("OOM");
            },
            else => {},
        }
    }

    // TODO Instead of copying, I could just free allocated capacity, that is not used in arraylist. Maybe later.
    const vertices = allocator.alloc(math.Point3, vertices_array.items.len) catch @panic("OOM");
    @memcpy(vertices, vertices_array.items);

    const normals = allocator.alloc(math.Point3, normals_array.items.len) catch @panic("OOM");
    @memcpy(normals, normals_array.items);

    const uvs = allocator.alloc(math.Point2, uvs_array.items.len) catch @panic("OOM");
    @memcpy(uvs, uvs_array.items);

    const faces = allocator.alloc(Face, faces_array.items.len) catch @panic("OOM");
    @memcpy(faces, faces_array.items);

    return .{ vertices, normals, uvs, faces };
}

fn read_mtl(mtlfile: std.fs.File, allocator: std.mem.Allocator) ?Texture {
    var buffer = [_]u8{0} ** 1024;
    var reader = mtlfile.reader(&buffer);

    const texture_attr = "map_Kd";

    while (true) {
        const line = reader.interface.takeDelimiter('\n') catch @panic("Read failed");
        if (line == null) break;

        if (line.?.len <= texture_attr.len + 1) continue;

        if (!std.mem.startsWith(u8, line, texture_attr))
            continue;

        const texture_path = line[texture_attr.len + 1 ..];
        return load_texture(texture_path, allocator);
    }

    return null;
}

fn load_texture(path: []const u8, allocator: std.mem.Allocator) ?Texture {
    var x: c_int = 0;
    var y: c_int = 0;
    var channels: c_int = 0;
    const stbi_image = c.stbi_load(path, &x, &y, &channels, c.STBI_rgb_alpha);
    if (stbi_image == null)
        return null;

    defer c.stbi_image_free(stbi_image);

    const texture_data = allocator.alloc(u8, x * y * channels) catch @panic("OOM");
    @memcpy(texture_data, stbi_image);
    return .{ .data = texture_data, .width = @intCast(x), .height = @intCast(y), .channels = @intCast(channels) };
}

fn parse_vertex(line: []u8) math.Point3 {
    var splits = std.mem.splitAny(u8, line, " ");
    _ = splits.first(); // v or vn
    const x = std.fmt.parseFloat(f32, splits.next() orelse "0.0") catch 0.0;
    const y = std.fmt.parseFloat(f32, splits.next() orelse "0.0") catch 0.0;
    const z = std.fmt.parseFloat(f32, splits.next() orelse "0.0") catch 0.0;

    return math.Point3.init(x, y, z);
}

fn parse_uv(line: []u8) math.Point2 {
    var splits = std.mem.splitAny(u8, line, " ");
    _ = splits.first(); // vt
    const x = std.fmt.parseFloat(f32, splits.next() orelse "0.0") catch 0.0;
    const y = std.fmt.parseFloat(f32, splits.next() orelse "0.0") catch 0.0;

    return math.Point2.init(x, y);
}

fn parse_faces(line: []const u8) struct { Face, Face, Face } {
    var splits = std.mem.splitAny(u8, line, " ");
    _ = splits.first(); // f

    const first_item = splits.next() orelse "1";
    const second_item = splits.next() orelse "1";
    const third_item = splits.next() orelse "1";

    const x = parse_face_item(first_item);
    const y = parse_face_item(second_item);
    const z = parse_face_item(third_item);

    return .{ x, y, z };
}

pub fn parse_face_item(item: []const u8) Face {
    // v1/vt1/vn1
    var splits = std.mem.splitAny(u8, item, "/");
    const f = std.fmt.parseInt(u16, splits.first(), 0) catch 1;
    const t = std.fmt.parseInt(u16, splits.next() orelse "7", 0) catch 1;
    const n = std.fmt.parseInt(u16, splits.next() orelse "8", 0) catch 1;
    // other stuff does not matter for me

    // index in obj files starts with 1
    return .{ .vertex = f - 1, .normal = n - 1, .uv = t - 1 };
}
