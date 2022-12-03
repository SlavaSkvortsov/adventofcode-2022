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
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        const delimiter = @divExact(line.len, 2);
        var first_compartment = std.AutoHashMap(u8, void).init(allocator);
        var already_found = std.AutoHashMap(u8, void).init(allocator);

        for (line[0..delimiter]) |c| {
            try first_compartment.put(c, {});
        }

        for (line[delimiter..]) |c| {
            if (first_compartment.contains(c)) {
                if (!already_found.contains(c)) {
                    result += if (c < 'a') c - 'A' + 27 else c - 'a' + 1;
                    try already_found.put(c, {});
                }
            }
        }
    }
    std.debug.print("\nResult is {d}", .{result});
}
