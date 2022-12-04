const std = @import("std");
const io = std.io;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var count: u32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var elves = std.mem.split(u8, line, ",");

        var first_elf = std.mem.split(u8, elves.next().?, "-");
        var second_elf = std.mem.split(u8, elves.next().?, "-");

        var first_begin = try std.fmt.parseInt(u32, first_elf.next().?, 10);
        var first_end = try std.fmt.parseInt(u32, first_elf.next().?, 10);
        var second_begin = try std.fmt.parseInt(u32, second_elf.next().?, 10);
        var second_end = try std.fmt.parseInt(u32, second_elf.next().?, 10);

        if (
            (first_begin >= second_begin and first_end <= second_end)
            or (first_begin <= second_begin and first_end >= second_end)
        ) {
            count += 1;
        }
    }
    std.debug.print("\nResult is {d}", .{count});
}
