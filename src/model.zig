const math = @import("math.zig");

const std = @import("std");

const MAX_READ_BYTES_SIZE = 5_000_000; // random

const Face = struct {
    vertex: math.Point3,
    normal: math.Point3,
    uv: math.Point2 = .{ .x = 0, .y = 0 },
};

// Loading wawefront obj files.
// Supporting just vertices and faces (v f).
pub const Model = struct {
    vertices: []math.Point3,
    normals: []math.Point3 = undefined,
    uvs: []math.Point2 = undefined,
    faces: []u16,
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
    const file = std.fs.cwd().openFile(path, .{}) catch @panic("File does not exist");
    defer file.close();

    var buffer = [_]u8{0} ** 1024;
    var reader = file.reader(&buffer);

    var vertices_array: std.ArrayList(math.Point3) = .{};
    defer vertices_array.deinit(allocator);

    var normals_array: std.ArrayList(math.Point3) = .{};
    defer normals_array.deinit(allocator);

    var uvs_array: std.ArrayList(math.Point2) = .{};
    defer uvs_array.deinit(allocator);

    var faces_array: std.ArrayList(u16) = .{};
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

    const faces = allocator.alloc(u16, faces_array.items.len) catch @panic("OOM");
    @memcpy(faces, faces_array.items);

    return .{ .vertices = vertices, .faces = faces, .allocator = allocator };
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

fn parse_faces(line: []u8) struct { u16, u16, u16 } {
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

fn parse_face_item(item: []const u8) u16 {
    // v1/vt1/vn1
    var splits = std.mem.splitAny(u8, item, "/");
    const index = std.fmt.parseInt(u16, splits.first(), 0) catch 1;
    // other stuff does not matter for me

    // index in obj files starts with 1
    return index - 1;
}
