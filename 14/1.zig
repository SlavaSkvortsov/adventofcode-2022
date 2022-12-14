const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct { x: i32, y: i32 };
const sand_spawner = Coords { .x = 500, .y = 0 };

const State = enum {
    wall,
    sand,
    empty,
};


const Border = struct {
    min_x: i32,
    min_y: i32,
    max_x: i32,
    max_y: i32,
};


fn add_line(map: *std.AutoHashMap(Coords, State), begin: Coords, end: Coords) void {
    var x = begin.x;
    var y = begin.y;

    var dx = end.x - begin.x;
    if (dx != 0) {
        dx = if (dx > 0) 1 else -1;
    }
    var dy = end.y - begin.y;
    if (dy != 0) {
        dy = if (dy > 0) 1 else -1;
    }
    while (true) {
        map.put(Coords { .x = x, .y = y }, State.wall) catch unreachable;
        if (x == end.x and y == end.y) break;
        x += dx;
        y += dy;
    }
}

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
        var x: i32 = border.min_x;
        while (x <= border.max_x) : (x += 1) {
            const c = map.get(Coords { .x = x, .y = y }) orelse State.empty;
            switch (c) {
                State.wall => print("█", .{}),
                State.sand => print("o", .{}),
                State.empty => print(".", .{}),
            }
        }
        print("\n", .{});
    }
}

fn add_sand(map: *std.AutoHashMap(Coords, State), border: Border) bool {
    var previous_coords: Coords = sand_spawner;
    while (true) {
        var coords = drop_sand(previous_coords, map.*);
        if (coords == null) break;
        if (coords.?.x < border.min_x or coords.?.x > border.max_x) return false;
        if (coords.?.y < border.min_y or coords.?.y > border.max_y) return false;
        previous_coords = coords.?;
    }
    map.put(previous_coords, State.sand) catch unreachable;
    return true;
}

fn drop_sand(coords: Coords, map: std.AutoHashMap(Coords, State)) ?Coords {
    const y = coords.y + 1;
    // Check below
    var result_coords = Coords { .x = coords.x, .y = y };
    if (!map.contains(result_coords)) return result_coords;

    // Check left
    result_coords = Coords { .x = coords.x - 1, .y = y };
    if (!map.contains(result_coords)) return result_coords;

    // Check right
    result_coords = Coords { .x = coords.x + 1, .y = y };
    if (!map.contains(result_coords)) return result_coords;

    return null;
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

        var it = std.mem.split(u8, line, " -> ");
        var coords_begin: ?Coords = null;
        while (it.next()) |coords_str| {
            var coords_it = std.mem.split(u8, coords_str, ",");
            if (coords_begin == null) {
                coords_begin = Coords {
                    .x = try std.fmt.parseInt(i32, coords_it.next().?, 10),
                    .y = try std.fmt.parseInt(i32, coords_it.next().?, 10),
                };
                continue;
            }
            var coords_end = Coords {
                .x = try std.fmt.parseInt(i32, coords_it.next().?, 10),
                .y = try std.fmt.parseInt(i32, coords_it.next().?, 10),
            };

            add_line(&map, coords_begin.?, coords_end);
            coords_begin = coords_end;
        }
    }
    print_map(map);
    print("\nADDING SOME SAND\n", .{});
    var result: u16 = 0;
    const border = get_border(map);
    while (add_sand(&map, border)) {
        result += 1;
    }
    print_map(map);
    print("result: {}\n", .{result});
}
