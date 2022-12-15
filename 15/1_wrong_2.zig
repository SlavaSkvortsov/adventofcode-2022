const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i32, y: i32 };

const Sensor = struct {
    coords: Coords,
    manhattan_distance: u32,
};


fn manhattan_distance(point_1: Coords, point_2: Coords) !u32 {
    return @intCast(u32, try std.math.absInt(point_1.x - point_2.x) + try std.math.absInt(point_1.y - point_2.y));
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var sensors = std.ArrayList(Sensor).init(allocator);
    defer sensors.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var it = std.mem.split(u8, line, ",");
        const sensor_coords = Coords{
            .x = try std.fmt.parseInt(i32, it.next().?, 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };
        const beacon_coords = Coords{
            .x = try std.fmt.parseInt(i32, it.next().?, 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };

        try sensors.append(Sensor{
            .coords = sensor_coords,
            .manhattan_distance = try manhattan_distance(sensor_coords, beacon_coords),
        });
    }

    var min_x: i32 = std.math.maxInt(i32);
    var max_x: i32 = std.math.minInt(i32);
    for (sensors.items) |sensor| {
        if (sensor.coords.x < min_x) min_x = sensor.coords.x;
        if (sensor.coords.x > max_x) max_x = sensor.coords.x;
    }
    min_x -= max_x - min_x;
    max_x += max_x - min_x;

    var result: u32 = 0;
    var x = min_x;
    var first_empty: ?i32 = null;
    while (x <= max_x) : (x += 1) {
        const point = Coords { .x = x, .y = 2000000 };
        for (sensors.items) |sensor| {
            if (try manhattan_distance(sensor.coords, point) <= sensor.manhattan_distance) {
                result += 1;
                if (first_empty == null) first_empty = x;
                break;
            }
        }
    }
// ###S########################
    print("count: {}\n", .{result });
}
