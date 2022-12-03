const std = @import("std");
const io = std.io;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var result: i32 = 0;
    const allocator = std.heap.page_allocator;
    var lines: u8 = 0;
    var counter = std.AutoArrayHashMap(u8, u8).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        lines += 1;

        var found_values = std.AutoArrayHashMap(u8, void).init(allocator);
        for (line) |c| {
            if (found_values.contains(c)) continue;
            try found_values.put(c, {});

            if (counter.get(c)) |current_value| {
                try counter.put(c, current_value + 1);
            } else try counter.put(c, 1);
        }
        if (lines == 3) {
            var iter = counter.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* < 3) continue;

                result += if (entry.key_ptr.* < 'a') entry.key_ptr.* - 'A' + 27 else entry.key_ptr.* - 'a' + 1;
                counter = std.AutoArrayHashMap(u8, u8).init(allocator);
                lines = 0;
                break;
            }
        }

    }
    std.debug.print("\nResult is {d}", .{result});
}
