const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct {
    x: i32,
    y: i32,
    z: i32,
};

const Cube = struct {
    neighbours: u8 = 0,
    exists: bool = false,
};

const Border = struct {
    const Self = @This();

    max_x: i32 = std.math.minInt(i32),
    max_y: i32 = std.math.minInt(i32),
    max_z: i32 = std.math.minInt(i32),
    min_x: i32 = std.math.maxInt(i32),
    min_y: i32 = std.math.maxInt(i32),
    min_z: i32 = std.math.maxInt(i32),

    fn out_of_bounds(self: Self, coords: Coords) bool {
        return (
            coords.x > self.max_x or coords.x < self.min_x or
            coords.y > self.max_y or coords.y < self.min_y or
            coords.z > self.max_z or coords.z < self.min_z
        );
    }
};


fn get_neighbours(coords: Coords) [6]Coords {
    return [_]Coords{
        Coords{ .x = coords.x - 1, .y = coords.y, .z = coords.z },
        Coords{ .x = coords.x + 1, .y = coords.y, .z = coords.z },
        Coords{ .x = coords.x, .y = coords.y - 1, .z = coords.z },
        Coords{ .x = coords.x, .y = coords.y + 1, .z = coords.z },
        Coords{ .x = coords.x, .y = coords.y, .z = coords.z - 1 },
        Coords{ .x = coords.x, .y = coords.y, .z = coords.z + 1 },
    };
}

fn add_cube(cubes: *std.AutoHashMap(Coords, *Cube), coords: Coords) !void {
    if (cubes.get(coords)) |c| {
        // print("cube already exists at {},{},{}\n", .{x, y, z});
        c.exists = true;
    } else {
        var new_cube = try allocator.create(Cube);
        new_cube.* = Cube{
            .neighbours = 0,
            .exists = true,
        };
        try cubes.put(coords, new_cube);
    }

    var neighbours = get_neighbours(coords);

    for (neighbours) |n| {
        if (cubes.get(n)) |c| {
            // print("found new neighbour {},{},{}\n", .{ n.x, n.y, n.z });
            c.*.neighbours += 1;
        } else {
            // print("putting new cube {},{},{}\n", .{ n.x, n.y, n.z });
            var new_cube = try allocator.create(Cube);
            new_cube.* = Cube{ .neighbours = 1 };
            try cubes.put(n, new_cube);
        }
    }
}

fn add_if_trapped(cubes: *std.AutoHashMap(Coords, *Cube), coords: Coords, border: Border) void {
    var queue = std.ArrayList(Coords).init(allocator);
    defer queue.deinit();
    var checked = std.AutoHashMap(Coords, void).init(allocator);
    defer checked.deinit();
    queue.append(coords) catch unreachable;

    while (queue.items.len > 0) {
        var check_coords = queue.pop();
        var neighbours = get_neighbours(check_coords);
        for (neighbours) |n| {
            if (checked.contains(n)) continue;
            if (cubes.get(n)) |c| {
                if (c.exists) continue
                else {
                    queue.append(n) catch unreachable;
                }
            } else if (border.out_of_bounds(n)) {
                return;
            } else {
                queue.append(n) catch unreachable;
            }
        }
        checked.put(check_coords, {}) catch unreachable;
    }

    var checked_iter = checked.keyIterator();
    while (checked_iter.next()) |n| {
        add_cube(cubes, n.*) catch unreachable;
    }
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var cubes = std.AutoHashMap(Coords, *Cube).init(allocator);
    defer cubes.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, ",");

        var coords = Coords{
            .x = try std.fmt.parseInt(i32, iter.next().?, 10),
            .y = try std.fmt.parseInt(i32, iter.next().?, 10),
            .z = try std.fmt.parseInt(i32, iter.next().?, 10),
        };
        try add_cube(&cubes, coords);
    }


    var border = Border{};
    var iterCoords = cubes.keyIterator();
    while (iterCoords.next()) |c| {
        if (c.x > border.max_x) border.max_x = c.x;
        if (c.y > border.max_y) border.max_y = c.y;
        if (c.z > border.max_z) border.max_z = c.z;
        if (c.x < border.min_x) border.min_x = c.x;
        if (c.y < border.min_y) border.min_y = c.y;
        if (c.z < border.min_z) border.min_z = c.z;
    }

    var iter = cubes.iterator();
    while (iter.next()) |data| {
        if (!data.value_ptr.*.exists) {
            add_if_trapped(&cubes, data.key_ptr.*, border);
        }
    }

    var result: u32 = 0;
    var cubesIter = cubes.valueIterator();
    while (cubesIter.next()) |c| {
        if (c.*.exists) {
            // print("cube has {} neighbours\n", .{c.*.neighbours});
            result += 6 - c.*.neighbours;
        }
    }

    print("{}\n", .{result});
    // 4164 is too high
}
