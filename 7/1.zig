const std = @import("std");
const io = std.io;


const threshold = 100000;
var result: u64 = 0;


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
    if (size < threshold) result += size;
    return size;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("test_data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var total = try go_into_folder(in_stream);

    std.debug.print("\nResult is {d}, total is {d}", .{result, total});
}
