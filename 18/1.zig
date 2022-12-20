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
        var x: i32 = try std.fmt.parseInt(i32, iter.next().?, 10);
        var y: i32 = try std.fmt.parseInt(i32, iter.next().?, 10);
        var z: i32 = try std.fmt.parseInt(i32, iter.next().?, 10);

        var coords = Coords {
            .x = x,
            .y = y,
            .z = z,
        };
        if (cubes.get(coords)) |c| {
            // print("cube already exists at {},{},{}\n", .{x, y, z});
            c.exists = true;
        } else {
            var new_cube = try allocator.create(Cube);
            new_cube.* = Cube {
                .neighbours = 0,
                .exists = true,
            };
            try cubes.put(coords, new_cube);
        }

        var neighbours = [_]Coords{
            Coords{ .x = x-1, .y = y, .z = z },
            Coords{ .x = x+1, .y = y, .z = z },
            Coords{ .x = x, .y = y-1, .z = z },
            Coords{ .x = x, .y = y+1, .z = z },
            Coords{ .x = x, .y = y, .z = z-1 },
            Coords{ .x = x, .y = y, .z = z+1 },
        };

        for (neighbours) |n| {
            if (cubes.get(n)) |c| {
                // print("found new neighbour {},{},{}\n", .{ n.x, n.y, n.z });
                c.*.neighbours += 1;
            } else {
                // print("putting new cube {},{},{}\n", .{ n.x, n.y, n.z });
                var new_cube = try allocator.create(Cube);
                new_cube.* = Cube{ .neighbours=1 };
                try cubes.put(n, new_cube);
            }
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
}