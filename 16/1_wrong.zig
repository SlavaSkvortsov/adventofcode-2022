const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Valve = struct {
    const Self = @This();

    const State = enum {
        Open,
        Closed,
    };

    name: [2]u8,
    leads: std.ArrayList(*Self),
    leads_str: std.ArrayList([2]u8),
    rate: u16,
};

fn brute_force(
    valves: std.AutoHashMap([2]u8, Valve),
    current_valve: Valve,
    time_left: u8,
    result: u32,
    opened_valves: std.AutoHashMap([2]u8, void),
) std.mem.Allocator.Error!u32 {
    if (time_left == 0) return result;

    var max_result = try move_to_next(valves, current_valve, time_left, result, opened_valves);
    var possible_result: u32 = 0;
    if (!opened_valves.contains(current_valve.name) and current_valve.rate > 0) {
        // can open
        var new_opened_valves = try opened_valves.cloneWithAllocator(allocator);
        try new_opened_valves.put(current_valve.name, undefined);
        var new_time_left = time_left - 1;
        possible_result = try move_to_next(
            valves,
            current_valve,
            new_time_left,
            new_time_left * current_valve.rate,
            new_opened_valves,
        );
    }
    return if (possible_result > max_result) possible_result else max_result;
}

fn move_to_next(
    valves: std.AutoHashMap([2]u8, Valve),
    current_valve: Valve,
    time_left: u8,
    result: u32,
    opened_valves: std.AutoHashMap([2]u8, void),
) std.mem.Allocator.Error!u32 {
    if (time_left == 0) return result;

    var max_result: u32 = 0;
    for (current_valve.leads.items) |lead| {
        const new_result = try brute_force(
            valves,
            lead.*,
            time_left - 1,
            result,
            opened_valves
        );
        if (new_result > max_result) max_result = new_result;
    }
    return max_result;
}


pub fn main() !void {
    var file = try std.fs.cwd().openFile("test_data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var valves = std.AutoHashMap([2]u8, Valve).init(allocator);
    defer valves.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var split = std.mem.split(u8, line, ";");
        var first_part = std.mem.split(u8, split.next().?, "=");
        var name = first_part.next().?[0..2].*;
        var value = try std.fmt.parseInt(u16, first_part.next().?, 10);

        var leads = std.ArrayList([2]u8).init(allocator);
        var leads_iter = std.mem.split(u8, split.next().?, ", ");
        while (leads_iter.next()) |lead| {
            try leads.append(lead[0..2].*);
        }
        try valves.put(
            name,
            Valve{
                .name = name,
                .leads_str = leads,
                .rate = value,
                .leads = std.ArrayList(*Valve).init(allocator),
            },
        );
    }

    var valve_keys_iter = valves.valueIterator();
    while (valve_keys_iter.next()) |valve| {
        for (valve.leads_str.items) |next_name| {
            try valve.leads.append(valves.getPtr(next_name).?);
        }
    }

    var result = try brute_force(
        valves,
        valves.get([_]u8{'A', 'A'}).?,
        30,
        0,
        std.AutoHashMap([2]u8, void).init(allocator),
    );
    print("{}\n", .{result});
}
