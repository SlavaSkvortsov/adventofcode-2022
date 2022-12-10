const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;
const Point = struct { x: i32 = 0, y: i32 = 0 };

fn abs(x: i32) i32 {
    return if (x < 0) -x else x;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var visited_locations = std.AutoHashMap(Point, void).init(allocator);
    try visited_locations.put(Point{}, {});

    var rope = [_]Point{.{}} ** 10;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        print("STARTED {s}\n", .{line});
        var row = std.mem.split(u8, line, " ");
        var direction = row.next().?;
        var distance = try std.fmt.parseInt(i32, row.next().?, 10);

        var i: u8 = 0;
        while (i < distance) : (i += 1) {
            var x_offset: i8 = 0;
            var y_offset: i8 = 0;

            if (direction[0] == 'R') {
                x_offset = 1;
            } else if (direction[0] == 'L') {
                x_offset = -1;
            } else if (direction[0] == 'U') {
                y_offset = 1;
            } else if (direction[0] == 'D') {
                y_offset = -1;
            } else {
                unreachable;
            }
            rope[0].x += x_offset;
            rope[0].y += y_offset;

            for (rope[1..]) |*knot, j| {
                var previous_knot = rope[j];
                x_offset = 0;
                y_offset = 0;
                if (abs(knot.x - previous_knot.x) < 2 and abs(knot.y - previous_knot.y) < 2 ) break;

                if (knot.x == previous_knot.x) {
                    y_offset = if (knot.y > previous_knot.y) -1 else 1;
                } else if (knot.y == previous_knot.y) {
                    x_offset = if (knot.x > previous_knot.x) -1 else 1;
                } else {
                    x_offset = if (knot.x > previous_knot.x) -1 else 1;
                    y_offset = if (knot.y > previous_knot.y) -1 else 1;
                }

                print("Knot={} {u}-{}: from ({}, {}) ", .{j+1, direction[0], distance, knot.x, knot.y});
                knot.x += x_offset;
                knot.y += y_offset;

                print("to ({}, {}). Previous ({}, {}) \n", .{knot.x, knot.y, previous_knot.x, previous_knot.y});
                if (j == rope.len - 2) {
                    try visited_locations.put(Point{ .x = knot.x, .y = knot.y }, {});
                }
            }

            // var knots = std.AutoHashMap(Point, usize).init(allocator);
            // for (rope) |knot, hue| {
            //     try knots.put(knot, hue);
            // }
            // var y: i8 = 20;
            // print("DRAWING ROPE\n", .{});
            // while (y >= -20) : (y -= 1) {
            //     var x: i8 = -20;
            //     while (x < 20) : (x += 1) {
            //         if (knots.get(Point{ .x = x, .y = y })) |hue| {
            //             print("{d}", .{hue});
            //         } else {
            //             print(".", .{});
            //         }
            //     }
            //     print("\n", .{});
            // }
            // print("END OF CYCLE\n\n\n\n", .{});
        }
    }

    print("Visited {} locations", .{visited_locations.count()});
}
