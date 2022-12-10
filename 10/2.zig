const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;
const Point = struct { x: i32, y: i32 };

fn abs(x: i32) i32 {
    return if (x < 0) -x else x;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var cycle: u32 = 0;
    var current_value: i64 = 1;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split_line: std.mem.SplitIterator(u8)  = std.mem.split(u8, line, " ");

        var addx: bool = std.mem.eql(u8, split_line.next().?, "addx"); // focking ZIG!!!!!
        var execute_until: u32 = cycle + if (addx) @as(u32, 2) else @as(u32, 1);

        while (cycle < execute_until) : (cycle += 1) {
            var CRT_position: u32 = @rem(cycle, 40);
            if (CRT_position == current_value or CRT_position == current_value - 1 or CRT_position == current_value + 1) {
                print("#", .{});
            } else {
                print(" ", .{});
            }
            if (CRT_position == 39){
                print("\n", .{});
            }
        }


        if (addx) {
            current_value += try std.fmt.parseInt(i32, split_line.next().?, 10);
        }
    }

}

