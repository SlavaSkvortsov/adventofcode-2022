const std = @import("std");
const io = std.io;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var the_best_elf_calories: i64 = 0;
    var current_elf_calories: i64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            if (current_elf_calories > the_best_elf_calories) {
                the_best_elf_calories = current_elf_calories;
            }
            current_elf_calories = 0;
            continue;
        }
        current_elf_calories += try std.fmt.parseInt(i32, line, 10);
    }
    std.debug.print("the_best_elf calories: {d}\n", .{the_best_elf_calories});
}
