const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const List = struct {
    value: ?std.ArrayList(List) = null,
    integer: ?u32 = null,
    letters: usize = 0,
    divider: bool = false,
};


fn print_list(list: List) void {
    if (list.value) |value| {
        print("[", .{});
        for (value.items) |inner_list| {
            print_list(inner_list);
        }
        print("]", .{});
    } else {
        print(",{d}", .{list.integer.?});
    }
}


fn parse_string(line: []u8) !List {
    // print("Parsing: {s}\n", .{line});
    var list = List{ .value = std.ArrayList(List).init(allocator) };
    var i: usize = 0;
    var int = std.ArrayList(u8).init(allocator);
    defer int.deinit();
    while (i < line.len) : (i += 1) {

        if (line[i] == '0' or line[i] == '1' or line[i] == '2' or line[i] == '3' or line[i] == '4' or line[i] == '5' or line[i] == '6' or line[i] == '7' or line[i] == '8' or line[i] == '9') {
            // print("Adding {c} to int\n", .{line[i]});
            var char: u8 = line[i];
            int.append(char) catch unreachable;
            continue;
        }

        if (int.items.len > 0) {
            var integer = try std.fmt.parseInt(u8, int.items, 10);
            // print("Adding int {d} to list\n", .{integer});
            int = std.ArrayList(u8).init(allocator);
            try list.value.?.append(List{ .integer = integer });
        }

        if (line[i] == '[') {
            // print("Adding sublist to list\n", .{});
            try list.value.?.append(try parse_string(line[i + 1..]));
            i += list.value.?.items[list.value.?.items.len - 1].letters;
        } else if (line[i] == ']') {
            // print("End of sublist\n", .{});
            i += 1;
            break;
        } else continue;
    }
    if (int.items.len > 0) {
        var integer = try std.fmt.parseInt(u8, int.items, 10);
        // print("Adding int {d} to list\n", .{integer});
        int = std.ArrayList(u8).init(allocator);
        try list.value.?.append(List{ .integer = integer });
    }
    list.letters = i;
    // print("Returning list with {d} letters\n", .{list.letters});
    return list;
}

fn compare(first: List, second: List) !?bool {
    // print("Comparing ", .{});
    // print_list(first);
    // print(" to ", .{});
    // print_list(second);
    // print("\n", .{});
    // print("\n", .{});

    if (first.integer != null and second.integer != null) {
        // print("Comparing {d} and {d}\n", .{first.integer.?, second.integer.?});
        if (first.integer.? < second.integer.?) return true
        else if (first.integer.? > second.integer.?) return false
        else return null;
    } else if (first.integer != null and second.integer == null) {
        var value = std.ArrayList(List).init(allocator);
        defer value.deinit();

        try value.append(first);
        return try compare(List{ .value = value }, second);
    } else if (first.integer == null and second.integer != null) {
        var value = std.ArrayList(List).init(allocator);
        defer value.deinit();

        try value.append(second);
        return try compare(first, List{ .value = value });
    }

    var i: usize = 0;
    while (i < first.value.?.items.len and i < second.value.?.items.len) : (i += 1) {
        var compare_result = try compare(first.value.?.items[i], second.value.?.items[i]);
        if (compare_result == null) continue;
        return compare_result;
    }
    // print("Comparing lengths {d} and {d}\n", .{first.value.?.items.len, second.value.?.items.len});
    if (first.value.?.items.len < second.value.?.items.len) return true
    else if (first.value.?.items.len > second.value.?.items.len) return false
    else return null;
}

fn compare_fn(_: void, first: List, second: List) bool {
    var result = compare(first, second) catch false;
    if (result == null) return false;
    return result.?;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var lists = std.ArrayList(List).init(allocator);
    defer lists.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        try lists.append(try parse_string(line[1..line.len - 1]));
        if (std.mem.eql(u8, line, "[[2]]") or std.mem.eql(u8, line, "[[6]]")) {
            lists.items[lists.items.len - 1].divider = true;
        }
    }
    var x = try lists.toOwnedSlice();
    std.sort.sort(List, x, {}, compare_fn);
    for (x) |list, i| {
        if (list.divider) print("Divider = {}\n", .{i + 1});
    }

}
