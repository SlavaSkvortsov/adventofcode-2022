const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i64, y: i64 };


fn manhattan_distance(point_1: Coords, point_2: Coords) !i32 {
    return @intCast(i32, try std.math.absInt(point_1.x - point_2.x) + try std.math.absInt(point_1.y - point_2.y));
}

const Y = 2000000;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var locked = std.AutoHashMap(i64, void).init(allocator);
    defer locked.deinit();
    var beacons = std.AutoHashMap(Coords, void).init(allocator);
    defer beacons.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var it = std.mem.split(u8, line, ",");
        const sensor_coords = Coords{
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
        };
        const beacon_coords = Coords{
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
        };
        try beacons.put(beacon_coords, undefined);
        var distance = try manhattan_distance(sensor_coords, beacon_coords);

        if (sensor_coords.y < Y and sensor_coords.y + distance >= Y) {
            // Sensor above the line
            var delta = sensor_coords.y + distance - Y;   // 3 + 8 - 10 = 1
            var x = sensor_coords.x - delta;   // 6 - 1 = 5
            // print("sensor_coords: ({}, {}), distance: {}, delta: {}, x: {}\n", .{sensor_coords.x, sensor_coords.y, distance, delta, x});
            while (x <= sensor_coords.x + delta) : (x += 1) {
                // print("putting {}\n" , .{x});
                try locked.put(x, undefined);
            }
        } else if (sensor_coords.y > Y and sensor_coords.y - distance <= Y) {
            // Sensor below the line
            var delta = Y - (sensor_coords.y - distance);   // 10 - (3 - 8) = 5
            var x = sensor_coords.x - delta;   // 6 - 5 = 1
            // print("sensor_coords: ({}, {}), distance: {}, delta: {}, x: {}\n", .{sensor_coords.x, sensor_coords.y, distance, delta, x});
            while (x <= sensor_coords.x + delta) : (x += 1) {
                // print("putting {}\n" , .{x});
                try locked.put(x, undefined);
            }
        }
    }

    var keys = beacons.keyIterator();
    var minus: u8 = 0;
    while (keys.next()) |key| {
        if (locked.contains(key.x) and key.y == Y) {
            print("locked, substract: ({}, {})\n", .{key.x, key.y});
            minus += 1;
        } else {
            print("beacon is not locked: ({}, {})\n", .{key.x, key.y});
        }
    }
    print("count: {}\n", .{ locked.count() - minus});
}
