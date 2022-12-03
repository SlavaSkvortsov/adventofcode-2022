const std = @import("std");
const io = std.io;

pub fn main() !void {
    std.debug.print("\n A is {d}", .{'A'});
    std.debug.print("\n B is {d}", .{'B'});
    std.debug.print("\n Z is {d}", .{'Z'});
    std.debug.print("\n a is {d}", .{'a'});
    std.debug.print("\n b is {d}", .{'b'});
    std.debug.print("\n z is {d}\n", .{'z'});
}
