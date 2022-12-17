const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i64, y: i64 };

const Line = struct {
    start: Coords,
    end: Coords,
    a: i64,
    b: i64,
};

const Sensor = struct {
    coords: Coords,
    manhattan_distance: u32,
};

fn manhattan_distance(point_1: Coords, point_2: Coords) !i32 {
    return @intCast(i32, try std.math.absInt(point_1.x - point_2.x) + try std.math.absInt(point_1.y - point_2.y));
}

const border = 4000000;

fn make_line_by_two_points(start: Coords, end: Coords) !Line {
    // y = ax + b
    // a = (y2 - y1) / (x2 - x1)
    // b = y1 - a * x1
    const a = try std.math.divExact(i64, end.y - start.y, end.x - start.x);
    const b = start.y - a * start.x;
    return Line {
        .start = start,
        .end = end,
        .a = a,
        .b = b,
    };
}


fn get_intersection(line_1: Line, line_2: Line) !?Coords {
    // y = ax + b
    // y = cx + d
    // a * x + b = c * x + d
    // (a - c) * x = d - b
    // x = (d - b) / (a - c)
    if (line_1.a == line_2.a) {
        return null;
    }
    // print("line 1: y = {}x + {}\n", .{line_1.a, line_1.b});
    // print("line 2: y = {}x + {}\n", .{line_2.a, line_2.b});
    const x = try std.math.divTrunc(i64, line_2.b - line_1.b, line_1.a - line_2.a);
    const y = line_1.a * x + line_1.b;
    var intersection = Coords {
        .x = x,
        .y = y,
    };
    if (intersection.x < 0 or intersection.y < 0 or intersection.x > border or intersection.y > border) return null;
    if (intersection.x < line_1.start.x and intersection.x > line_1.end.x) return null;
    if (intersection.x < line_2.start.x and intersection.x > line_2.end.x) return null;
    if (intersection.y < line_1.start.y and intersection.y > line_1.end.y) return null;
    if (intersection.y < line_2.start.y and intersection.y > line_2.end.y) return null;
    return intersection;
}

fn scan_near_point(point: Coords, sensors: std.ArrayList(Sensor)) !bool{
    const diff = 50;
    var x = point.x - diff;
    while (x <= point.x + diff) : (x += 1) {
        var y = point.y - diff;
        while (y <= point.y + diff) : (y += 1) {
            var test_point = Coords{ .x = x, .y = y };
            var success = true;
            for (sensors.items) |sensor| {
                if (try manhattan_distance(sensor.coords, test_point) <= sensor.manhattan_distance) {
                    // print("{}, {} failed\n", .{x, y});
                    success = false;
                    break;
                }
            }
            if (success) {
                if (x < 0 or y < 0 or x > border or y > border) {
                    // print("Point is outside of the border\n", .{});
                    return false;
                }

                print("Found point at {},{}\n", .{x, y});
                return true;
            }
        }
    }
    return false;

}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var points = std.ArrayList(Coords).init(allocator);
    defer points.deinit();

    var sensors = std.ArrayList(Sensor).init(allocator);
    defer sensors.deinit();

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
        try sensors.append(Sensor{
            .coords = sensor_coords,
            .manhattan_distance = @intCast(u32, distance),
        });


        try points.append(Coords{ .x = sensor_coords.x, .y = sensor_coords.y + distance});
        try points.append(Coords{ .x = sensor_coords.x, .y = sensor_coords.y - distance});
        try points.append(Coords{ .x = sensor_coords.x + distance, .y = sensor_coords.y});
        try points.append(Coords{ .x = sensor_coords.x - distance, .y = sensor_coords.y});
    }

    for (points.items) |point| {
        if (try scan_near_point(point, sensors)) {
            print("FUCK YEA", .{});
            break;
        }
    }

    // const diff = 2;
    // var iterator = points.keyIterator();
    // while (iterator.next()) |point| {
    //     var x = point.x - diff;
    //     while (x <= point.x + diff) : (x += 1) {
    //         var y = point.y - diff;
    //         while (y <= point.y + diff) : (y += 1) {
    //             if (x == point.x and y == point.y) continue;
    //             var potential_point = Coords{ .x = x, .y = y };
    //             if (points.contains(potential_point)) {
    //                 var current_value: u16 = points.get(point.*).?;
    //                 try points.put(point.*, current_value + 1);
    //                 print("Found point at {},{} near point {},{}\n", .{x, y, point.x, point.y});
    //             }
    //         }
    //     }
    // }

    // The main suspect is 2189211,3899620

}
