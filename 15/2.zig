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

fn scan_point(point: Coords, sensors: std.ArrayList(Sensor)) !bool{
    if (point.x < 0 or point.y < 0 or point.x > border or point.y > border) return false;
    for (sensors.items) |sensor| {
        if (try manhattan_distance(sensor.coords, point) <= sensor.manhattan_distance) {
            return false;
        }
    }
    return true;
}


fn check_sensor_borders(sensors: std.ArrayList(Sensor), check_sensor: Sensor) !?Coords {
    for (sensors.items) |sensor| {
        if (sensor.coords.x == check_sensor.coords.x and sensor.coords.y == check_sensor.coords.y) continue;

        var top_y = sensor.coords.y + sensor.manhattan_distance + 1;
        var bottom_y = sensor.coords.y - sensor.manhattan_distance - 1;
        var left_x = sensor.coords.x - sensor.manhattan_distance - 1;
        var right_x = sensor.coords.x + sensor.manhattan_distance + 1;

        var x = sensor.coords.x;
        var y = top_y;

        // From top to right
        while (x < right_x) {
            x += 1;
            y -= 1;
            var point = Coords {.x = x, .y = y};
            if (try scan_point(point, sensors)) return point;
        }

        // From right to bottom
        while (y > bottom_y) {
            x -= 1;
            y -= 1;
            var point = Coords {.x = x, .y = y};
            if (try scan_point(point, sensors)) return point;
        }

        // From bottom to left
        while (x > left_x) {
            x -= 1;
            y += 1;
            var point = Coords {.x = x, .y = y};
            if (try scan_point(point, sensors)) return point;
        }

        // From left to top
        while (y < top_y) {
            x += 1;
            y += 1;
            var point = Coords {.x = x, .y = y};
            if (try scan_point(point, sensors)) return point;
        }
    }
    return null;
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
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
        };
        const beacon_coords = Coords{
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
        };
        const distance = try manhattan_distance(sensor_coords, beacon_coords);
        sensors.append(Sensor{
            .coords = sensor_coords,
            .manhattan_distance = @intCast(u32, distance),
        }) catch unreachable;

    }


    for (sensors.items) |sensor| {
        if (try check_sensor_borders(sensors, sensor)) |point| {
            print("point: ({}, {})\n", .{point.x, point.y});
            print("result = {}\n", .{point.x * border + point.y});
            return;
        }
    }

}
// 10884459367718