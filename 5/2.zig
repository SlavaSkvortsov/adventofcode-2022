const std = @import("std");
const io = std.io;

const allocator = std.heap.page_allocator;


const total_stacks = 9;


pub fn main() !void {
    var stacks: [total_stacks]std.ArrayList(u8) = undefined;
    var i: u8 = 0;

    while (i < total_stacks) : (i += 1) {
        var new_stack = std.ArrayList(u8).init(allocator);
        defer new_stack.deinit();
        stacks[i] = new_stack;
    }


    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var init: bool = true;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            init = false;
            continue;
        }

        if (init) {
            i = 0;
            while (i < total_stacks) : (i += 1) {
                var pos: u8 = i * 4 + 1;
                if (pos >= line.len) {
                    break;
                }
                var char = line[pos];

                if (char != ' ') {
                    try stacks[i].insert(0, char);
                }
            }
            continue;
        }

        var split_line = std.mem.split(u8, line, " ");
        var quantity = try std.fmt.parseInt(u32, split_line.next().?, 10);
        var move_from_index = try std.fmt.parseInt(u32, split_line.next().?, 10) - 1;
        var move_to_index = try std.fmt.parseInt(u32, split_line.next().?, 10) - 1;

        var move_from = &stacks[move_from_index];
        var move_to = &stacks[move_to_index];

        try move_to.appendSlice(move_from.items[move_from.items.len - quantity..]);
        move_from.items.len -= quantity;
    }

    std.debug.print("\nResult is ", .{});
    for (stacks) |one_stack| {
        var value = one_stack.items[one_stack.items.len - 1];
        std.debug.print("{u}", .{value});
    }
}
