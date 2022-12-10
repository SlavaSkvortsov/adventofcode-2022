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

    var cycle: u32 = 1;
    var current_value: i64 = 1;
    var result: i64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split_line: std.mem.SplitIterator(u8)  = std.mem.split(u8, line, " ");

        var addx: bool = std.mem.eql(u8, split_line.next().?, "addx"); // focking ZIG!!!!!
        var execute_until: u32 = cycle + if (addx) @as(u32, 2) else @as(u32, 1);

        while (cycle < execute_until) : (cycle += 1) {
            if (@rem(cycle, 40) == 20){
                print("ADDING TO RESULT - cycle: {}, current_value: {}, result: {}\n", .{cycle, current_value, result});
                result += current_value * cycle;
            }
        }

        if (addx) {
            current_value += try std.fmt.parseInt(i32, split_line.next().?, 10);
        }
    }
    print("Current value: {}\n", .{current_value});
    print("Result: {}\n", .{result});

}
