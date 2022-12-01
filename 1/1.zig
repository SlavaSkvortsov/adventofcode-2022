const std = @import("std");
const data = @embedFile("data.txt");

test "one" {
    var lines = std.mem.split(u8, data, "\n");

    var the_best_elf_calories: i64 = 0;
    var current_elf_calories: i64 = 0;

    while (lines.next()) |line| {
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
