const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i64, y: i64 };


fn manhattan_distance(point_1: Coords, point_2: Coords) !i32 {
    return @intCast(i32, try std.math.absInt(point_1.x - point_2.x) + try std.math.absInt(point_1.y - point_2.y));
}

// const border = 4000000;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var points = std.AutoHashMap(Coords, u16).init(allocator);
    defer points.deinit();

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
        const distance = try manhattan_distance(sensor_coords, beacon_coords);

        try points.put(Coords{ .x = sensor_coords.x, .y = sensor_coords.y + distance}, 0);
        try points.put(Coords{ .x = sensor_coords.x, .y = sensor_coords.y - distance}, 0);
        try points.put(Coords{ .x = sensor_coords.x + distance, .y = sensor_coords.y}, 0);
        try points.put(Coords{ .x = sensor_coords.x - distance, .y = sensor_coords.y}, 0);
    }

    const diff = 50;
    var iterator = points.keyIterator();
    while (iterator.next()) |point| {
        var x = point.x - diff;
        while (x <= point.x + diff) : (x += 1) {
            var y = point.y - diff;
            while (y <= point.y + diff) : (y += 1) {
                if (x == point.x and y == point.y) continue;
                var potential_point = Coords{ .x = x, .y = y };
                if (points.contains(potential_point)) {
                    var current_value: u16 = points.get(point.*).?;
                    try points.put(point.*, current_value + 1);
                    print("Found point at {},{} near point {},{}\n", .{x, y, point.x, point.y});
                }
            }
        }
    }
}
