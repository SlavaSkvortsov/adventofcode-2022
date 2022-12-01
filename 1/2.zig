const std = @import("std");
const data = @embedFile("data.txt");

fn replace_smallest(arr: []i64, callories: i64) void {
    var i = arr.len;
    while (i > 0) : (i -= 1) {
        if (callories > arr[i - 1]) {
            if (i > 0) {
                var j: usize = 0;
                while (j < i - 1) : (j += 1) {
                    arr[j] = arr[j + 1];
                }
            }
            arr[i - 1] = callories;
            return;
        }
    }
}

test "two" {
    var lines = std.mem.split(u8, data, "\n");

    var top_elves = [3]i64{ 0, 0, 0 };
    var current_elf_calories: i64 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            replace_smallest(&top_elves, current_elf_calories);
            current_elf_calories = 0;
            continue;
        }
        current_elf_calories += try std.fmt.parseInt(i32, line, 10);
    }
    replace_smallest(&top_elves, current_elf_calories);
    std.debug.print("the best 3 elves have {d} calories\n", .{top_elves[0] + top_elves[1] + top_elves[2]});
}
