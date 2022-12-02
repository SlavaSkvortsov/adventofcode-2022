const std = @import("std");
const io = std.io;

const rock_paper_scissors = [3]u8{ 'A', 'B', 'C' };

fn get_move(left: u8, outcome: u8) u8 {
    const left_position: usize = switch (left) {
        'A' => 0,
        'B' => 1,
        'C' => 2,
        else => unreachable,
    };
    if (outcome == 'Y') {
        return left;
    } else if (outcome == 'X') {
        return rock_paper_scissors[@mod((left_position + 2), 3)];
    } else {
        return rock_paper_scissors[@mod((left_position + 1), 3)];
    }
}


fn get_points(left: u8, right: u8) i32 {
    if (left == right) {
        return 3;
    } else if ((left == 'A' and right == 'B') or (left == 'B' and right == 'C') or (left == 'C' and right == 'A')) {
        return 6;
    }
    return 0;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var result: i32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 3) continue;
        var left: u8 = line[0];
        var outcome: u8 = line[2];

        var right = get_move(left, outcome);

        result += get_points(left, right);
        result += switch (right) {
            'A' => 1,
            'B' => 2,
            'C' => 3,
            else => unreachable,
        };

    }
    std.debug.print("Result is {d}", .{result});
}
