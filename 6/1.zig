const std = @import("std");
const io = std.io;

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1]u8 = undefined;


    var marker = std.ArrayList(u8).init(allocator);
    defer marker.deinit();
    var count: u32 = 0;

    while ((try in_stream.read(&buf) != 0)) {
        count += 1;

        var i: usize = 0;
        for (marker.items) |symbol| {
            if (symbol == buf[0]) {
                i += 1;
                while (i > 0) : (i -= 1) {
                    _ = marker.orderedRemove(i - 1);
                }
                break;
            }
            i += 1;
        }
        try marker.append(buf[0]);
        if (marker.items.len == 4) {
            std.debug.print("\nFOUND IT! {}\n", .{count});
            break;
        }
    }
}
