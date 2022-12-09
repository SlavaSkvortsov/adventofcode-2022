const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

fn check_is_visible(slice: []const u8, height: u8) bool {
    var i: usize = 0;
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

    var x_max = height_data.items[0].len - 1;
    var y_max = height_data.items.len - 1;

    var best_result: u64 = 0;

    for (height_data.items) |line, x| {
        for (line) |height, y| {
            print("x: {}, y: {}, height: {u}\n", .{ x, y, height });

            var x_visible_up: u64 = 0;
            var x_visible_down: u64 = 0;
            var y_visible_left: u64 = 0;
            var y_visible_right: u64 = 0;

            // Check X up
            if (x > 0) {
                var x_check: u64 = x;
                while (x_check > 0) : (x_check -= 1) {
                    x_visible_up += 1;
                    if (height_data.items[x_check - 1][y] >= height) break;
                }
            }

            // Check X down
            if (x < x_max) {
                var x_check: u64 = x;
                while (x_check < x_max) : (x_check += 1) {
                    x_visible_down += 1;
                    if (height_data.items[x_check + 1][y] >= height) break;
                }
            }

            // Check Y left
            if (y > 0) {
                var y_check: u64 = y;
                while (y_check > 0) : (y_check -= 1) {
                    y_visible_left += 1;
                    if (height_data.items[x][y_check - 1] >= height) break;
                }
            }

            // Check Y right
            if (y < y_max) {
                var y_check: u64 = y;
                while (y_check < y_max) : (y_check += 1) {
                    y_visible_right += 1;
                    if (height_data.items[x][y_check + 1] >= height) break;
                }
            }
            print("x_visible_up: {}, x_visible_down: {}, y_visible_left: {}, y_visible_right: {}\n", .{ x_visible_up, x_visible_down, y_visible_left, y_visible_right });
            if (x_visible_up * x_visible_down * y_visible_left * y_visible_right > best_result) {
                best_result = x_visible_up * x_visible_down * y_visible_left * y_visible_right;
            }
        }
    }
    print("best_result: {}\n", .{ best_result });
}
