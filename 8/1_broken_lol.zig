const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;
const Tree = struct {
    height: u8,
    visible: ?bool,
};

pub fn main() !void {
    var file = try std.fs.cwd().openFile("test_data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var height_data = std.ArrayList([]u8).init(allocator);
    defer height_data.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var new_line = try allocator.alloc(u8, line.len);
        std.mem.copy(u8, new_line, line);
        try height_data.append(new_line);
    }

    var result: u16 = 0;
    var x_max = height_data.items[0].len - 1;
    var y_max = height_data.items.len - 1;

    var visible_map = std.ArrayList(std.ArrayList(?bool)).init(allocator);
    defer visible_map.deinit();
    for (height_data.items) |line, i| {
        var visible_map_line = std.ArrayList(?bool).init(allocator);
        // defer visible_map_line.deinit();

        var j: usize = 0;
        while (j < line.len) : (j += 1) {
            if (i == 0 or j == 0 or i == y_max or j == x_max) {
                try visible_map_line.append(true);
                result += 1;
                continue;
            }
            try visible_map_line.append(null);
        }
        try visible_map.append(visible_map_line);
    }

    var success = false;
    while (!success) {
        success = true;
        for (height_data.items) |tree_list, x| {
            for (tree_list) |height, y| {
                if (visible_map.items[x].items[y] != null) continue;

                if (x == 0 or x == x_max or y == 0 or y == y_max) {
                    // edge of the map
                    // Tree.set_visible(&tree, true);
                    visible_map.items[x].items[y] = true;
                } else {
                    // check if tree is visible
                    var visible = false;
                    var full_data = true;

                    var trees_to_check = [_]Tree{
                        Tree { .height = height_data.items[x][y - 1], .visible = visible_map.items[x].items[y - 1] },
                        Tree { .height = height_data.items[x][y + 1], .visible = visible_map.items[x].items[y + 1] },
                        Tree { .height = height_data.items[x - 1][y], .visible = visible_map.items[x - 1].items[y] },
                        Tree { .height = height_data.items[x + 1][y], .visible = visible_map.items[x + 1].items[y] },
                    };
                    for (trees_to_check) |tree_to_check| {
                        if (tree_to_check.visible == null and tree_to_check.height < height) {
                            full_data = false;
                            continue;
                        }
                        if (tree_to_check.visible == true and tree_to_check.height < height) {
                            print("tree at {},{} is visible", .{ x, y });
                            print(". I compared it to height {u}\n", .{ tree_to_check.height });
                            visible = true;
                            result += 1;
                            break;
                        }
                    }
                    if (!full_data) success = false;

                    if (visible or full_data) {
                        print("x: {}, y: {}, height: {u}, visible: {}, full_data: {}\n", .{ x, y, height, visible, full_data });
                        visible_map.items[x].items[y] = visible;
                    }
                }
            }
        }
        print("\n\nresult: {}\n", .{result});
        for (visible_map.items) |line| {
            for (line.items) |visible| {
                if (visible == true) {
                    print("1", .{});
                } else if (visible == false) {
                    print("0", .{});
                } else {
                    print("?", .{});
                }
            }
            print("\n", .{});
        }
    }


    for (height_data.items) |line| {
        print("{u}\n", .{line});
    }
    print("\nResult is {d}", .{result});
}
