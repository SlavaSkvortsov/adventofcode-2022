const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i32, y: i32 };

const State = enum {
    beacon,
    sensor,
    empty,
    unknown,
};


const Border = struct {
    min_x: i32,
    min_y: i32,
    max_x: i32,
    max_y: i32,
};



fn get_border(map: std.AutoHashMap(Coords, State)) Border {
    var result = Border {
        .min_x = 500,
        .min_y = 0,
        .max_x = std.math.minInt(i32),
        .max_y = std.math.minInt(i32),
    };

    var keys = map.keyIterator();
    while (keys.next()) |key| {
        if (key.x < result.min_x) result.min_x = key.x;
        if (key.x > result.max_x) result.max_x = key.x;
        if (key.y < result.min_y) result.min_y = key.y;
        if (key.y > result.max_y) result.max_y = key.y;
    }

    return result;
}


fn print_map(map: std.AutoHashMap(Coords, State)) void {
    var border = get_border(map);
    var y: i32 = border.min_y;
    while (y <= border.max_y) : (y += 1) {
        print("{d:4} ", .{y});
        var x: i32 = border.min_x;
        while (x <= border.max_x) : (x += 1) {
            const c = map.get(Coords { .x = x, .y = y }) orelse State.unknown;
            switch (c) {
                State.beacon => print("B", .{}),
                State.sensor => print("S", .{}),
                State.empty => print("#", .{}),
                State.unknown => print(".", .{}),
            }
        }
        print("\n", .{});
    }
}

fn fill_empty(map: *std.AutoHashMap(Coords, State), sensor: Coords, beacon: Coords) !void {
    const manhattan_distance = @intCast(
        i32, try std.math.absInt(sensor.x - beacon.x) + try std.math.absInt(sensor.y - beacon.y),
    );

    var y: i32 = sensor.y + manhattan_distance;
    while (y >= sensor.y - manhattan_distance) : (y -= 1) {
        var delta = manhattan_distance - try std.math.absInt(y - sensor.y);
        var x = sensor.x - delta;
        while (x <= sensor.x + delta) : (x += 1) {
            _ = try map.getOrPutValue(Coords { .x = x, .y = y }, State.empty);
        }
    }
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var map = std.AutoHashMap(Coords, State).init(allocator);
    defer map.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var it = std.mem.split(u8, line, ",");
        const sensor = Coords{
            .x = try std.fmt.parseInt(i32, it.next().?, 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };
        const beacon = Coords{
            .x = try std.fmt.parseInt(i32, it.next().?, 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };
        try map.put(sensor, State.sensor);
        try map.put(beacon, State.beacon);
        try fill_empty(&map, sensor, beacon);
    }
    print_map(map);

    var count: u16 = 0;
    var x = get_border(map).min_x;
    while (x <= get_border(map).max_x) : (x += 1) {
        if (map.get(Coords { .x = x, .y = 10 }) == State.empty) count += 1;
    }
    print("count: {}\n", .{count});
}
