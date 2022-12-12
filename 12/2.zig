const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Coords = struct {
    x: usize,
    y: usize,
};

const Node = struct {
    letter: u8,
    value: u32 = 90000,
};

fn get_coordinates(grid: std.ArrayList(std.ArrayList(Node)), value: u8) Coords {
    for (grid.items) |row, y| {
        for (row.items) |node, x| {
            if (node.letter == value) {
                return Coords{ .x = x, .y = y };
            }
        }
    }
    unreachable;
}

fn assign_weight(grid: std.ArrayList(std.ArrayList(Node)), coords: Coords, weight: u32) void {
    var current_node = &grid.items[coords.y].items[coords.x];
    if (current_node.value <= weight) {
        return;
    }
    current_node.value = weight;
    // Fuck you integer overflow
    const paths = [_][2]usize{
        [_]usize{coords.x + 2, coords.y + 1},
        [_]usize{coords.x, coords.y + 1},
        [_]usize{coords.x + 1, coords.y + 2 },
        [_]usize{coords.x + 1, coords.y },
    };
    for (paths) |fake_coords| {
        if (fake_coords[0] < 1 or fake_coords[0] >= grid.items[0].items.len + 1) continue;
        if (fake_coords[1] < 1 or fake_coords[1] >= grid.items.len + 1) continue;

        const next_coords = Coords{ .x = fake_coords[0] - 1, .y = fake_coords[1] - 1};
        const node = grid.items[next_coords.y].items[next_coords.x];
        if (node.letter == 'E') {
            if (current_node.value < 'y') continue;
        }
        else if (current_node.letter + 1 < node.letter) continue;

        assign_weight(grid, next_coords, weight + 1);
    }
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var grid = std.ArrayList(std.ArrayList(Node)).init(allocator);
    defer grid.deinit();

    var i: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var row = std.ArrayList(Node).init(allocator);
        for (line) |cell| {
            try row.append(Node{ .letter = cell });
        }
        try grid.append(row);
        i += 1;
    }

    var start = get_coordinates(grid, 'S');
    var start_node = &grid.items[start.y].items[start.x];
    start_node.letter = 'a';

    var end = get_coordinates(grid, 'E');
    var end_node = &grid.items[end.y].items[end.x];
    end_node.letter = 'z';

    for (grid.items) |row, y| {
        for (row.items) |node, x| {
            if (node.letter == 'a') {
                assign_weight(grid, Coords{ .x = x, .y = y }, 0);
            }
        }
    }


    print("Result: {d}\n", .{end_node.value});
}
