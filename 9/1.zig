const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;
const Point = struct { x: i32, y: i32 };

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
    var head_x: i32 = 0;
    var head_y: i32 = 0;
    var tail_x: i32 = 0;
    var tail_y: i32 = 0;

    var point = Point{ .x = tail_x, .y = tail_y };
    try visited_locations.put(point, {});

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var row = std.mem.split(u8, line, " ");
        var direction = row.next().?;
        var distance = try std.fmt.parseInt(i32, row.next().?, 10);

        var i: u8 = 0;
        while (i < distance) : (i += 1) {
            var x_offset: i8 = 0;
            var y_offset: i8 = 0;

            if (direction[0] == 'R') {
                x_offset += 1;
            } else if (direction[0] == 'L') {
                x_offset -= 1;
            } else if (direction[0] == 'U') {
                y_offset += 1;
            } else if (direction[0] == 'D') {
                y_offset -= 1;
            } else {
                unreachable;
            }
            head_x += x_offset;
            head_y += y_offset;

            if (abs(head_x - tail_x) < 2 and abs(head_y - tail_y) < 2) {
                continue;
            }

            if (x_offset != 0) {
                tail_x += x_offset;
                if (tail_y != head_y) {
                    tail_y = head_y;
                }
            } else if (y_offset != 0) {
                tail_y += y_offset;
                if (tail_x != head_x) {
                    tail_x = head_x;
                }
            }
            point = Point{ .x = tail_x, .y = tail_y };
            try visited_locations.put(point, {});
        }
    }

    print("Visited {} locations", .{visited_locations.count()});
}
