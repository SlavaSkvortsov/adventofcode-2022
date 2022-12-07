const std = @import("std");
const io = std.io;


const total_space = 70000000;
const required_space = 30000000;

const allocator = std.heap.page_allocator;
var spaces = std.ArrayList(u64).init(allocator);

fn go_into_folder(in_stream: anytype) !u64 {
    var size: u64 = 0;
    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.eql(u8, line, "$ ls") or std.mem.startsWith(u8, line, "dir")) continue
        else if (std.mem.eql(u8, line, "$ cd ..")) break
        else if (std.mem.startsWith(u8, line, "$ cd")) {
            size += try go_into_folder(in_stream);
            continue;
        } else {
            var row = std.mem.split(u8, line, " ");
            size += try std.fmt.parseInt(u64, row.next().?, 10);
        }
    }
    try spaces.append(size);

    return size;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var total_occupied = try go_into_folder(in_stream);

    var new_array = try spaces.toOwnedSlice();
    std.sort.sort(u64, new_array, {}, std.sort.asc(u64));

    var minimum = required_space - (total_space - total_occupied);

    for (new_array) |space| {
        if (space > minimum) {
            std.debug.print("Result is: {}\n", .{space});
            return;
        }
    }
}
