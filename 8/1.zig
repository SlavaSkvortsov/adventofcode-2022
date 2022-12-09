const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

fn check_is_visible(slice : []const u8, height: u8) bool {
    var i : usize = 0;
    while (i < slice.len) : (i += 1) {
        if (slice[i] >= height) {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var height_data = std.ArrayList([]u8).init(allocator);
    defer height_data.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var new_line = try allocator.alloc(u8, line.len);
        std.mem.copy(u8, new_line, line);
        try height_data.append(new_line);
    }

    var result: u16 = 0;
    var x_max = height_data.items[0].len - 1;
    var y_max = height_data.items.len - 1;

    for (height_data.items) |line, x| {
        for (line) |height, y| {
            if (x == 0 or y == 0 or x == x_max or y == y_max) {
                result += 1;
                continue;
            }

            // Check X up
            var x_check: u64 = 0;
            var visible = true;
            while (x_check < x) : (x_check += 1) {
                if (height_data.items[x_check][y] >= height) {
                    visible = false;
                    break;
                }
            }
            if (visible) {
                result += 1;
                continue;
            }

            // Check X down
            x_check = x_max;
            visible = true;
            while (x_check > x) : (x_check -= 1) {
                if (height_data.items[x_check][y] >= height) {
                    visible = false;
                    break;
                }
            }
            if (visible) {
                result += 1;
                continue;
            }

            if (
                check_is_visible(line[0..y], height)
                or check_is_visible(line[y+1..], height)
            ) {
                result += 1;
                continue;
            }
        }
    }
    print("{}\n", .{result});
}
