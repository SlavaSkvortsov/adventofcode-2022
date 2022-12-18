const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;


const Valve = struct {
    name: [2]u8,
    leads: std.ArrayList(*Valve),
    leads_str: std.ArrayList([2]u8),
    paths: std.AutoHashMap([2]u8, u8),
    rate: u16,
};

fn shortest_paths(from: Valve, valves: std.AutoHashMap([2]u8, Valve)) std.AutoHashMap([2]u8, u8) {
    var paths = std.AutoHashMap([2]u8, u8).init(allocator);
    paths.put(from.name, 0) catch unreachable;
    var queue = std.ArrayList([2]u8).init(allocator);
    defer queue.deinit();

    queue.append(from.name) catch unreachable;
    while (queue.items.len > 0) {
        const current_valve_str = queue.pop();
        const current_valve = valves.get(current_valve_str) orelse unreachable;
        const current_length = paths.get(current_valve_str) orelse 0;
        for (current_valve.leads.items) |lead| {
            if (paths.get(lead.name)) |lenght| {
                if (lenght > current_length + 1) {
                    paths.put(lead.name, current_length + 1) catch unreachable;
                    queue.append(lead.name) catch unreachable;
                }
            } else {
                paths.put(lead.name, current_length + 1) catch unreachable;
                queue.append(lead.name) catch unreachable;
            }
        }
    }
    return paths;
}

// fn permutate(array: *std.ArrayList([2]u8), size: usize) void {
fn permutate(array: *std.ArrayList([2]u8), size: usize) void {
    if (size == 1) {
        // print("{}\n", .{array});
        return;
    }

    var i: usize = 0;
    while (i < size) : (i += 1) {
        permutate(array, size - 1);
        var elem = array.swapRemove(if (size % 2 == 1) 0 else i);
        array.append(elem) catch unreachable;
    }
}

fn brute_force(current_valve: Valve, closed_valves: std.AutoHashMap([2]u8, Valve), time_left: u8) u32 {
    var max_result: u32 = 0;

    var closed_valves_iter = closed_valves.iterator();
    while (closed_valves_iter.next()) |data| {
        if (current_valve.paths.get(data.key_ptr.*)) |path| {
            if (path < time_left) {
                var new_closed_valves = closed_valves.clone() catch unreachable;
                _ = new_closed_valves.remove(data.key_ptr.*);
                const result = brute_force(data.value_ptr.*, new_closed_valves, time_left - path - 1);
                if (result > max_result) {
                    max_result = result;
                }
            }
        }
    }
    return max_result + time_left * current_valve.rate;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
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
                .paths = std.AutoHashMap([2]u8, u8).init(allocator),
            },
        );
    }

    var valve_keys_iter = valves.valueIterator();
    while (valve_keys_iter.next()) |valve| {
        for (valve.leads_str.items) |next_name| {
            try valve.leads.append(valves.getPtr(next_name).?);
        }
    }

    var valves_value_iter = valves.valueIterator();
    while (valves_value_iter.next()) |valve| {
        valve.*.paths = shortest_paths(valve.*, valves);
        // print("{s}: {}\n", .{valve.name, valve.paths.count()});
        // var paths_iter = valve.paths.keyIterator();
        // while (paths_iter.next()) |path| {
        //     print("    {s}: {}\n", .{path, valve.paths.get(path.*).?});
        // }
    }

    var closed_valves = std.AutoHashMap([2]u8, Valve).init(allocator);
    var closed_values_list = std.ArrayList([2]u8).init(allocator);
    valve_keys_iter = valves.valueIterator();
    while (valve_keys_iter.next()) |valve| {
        if (valve.rate > 0) {
            try closed_valves.put(valve.name, valve.*);
            closed_values_list.append(valve.name) catch unreachable;
        }
    }

    permutate(&closed_values_list, closed_values_list.items.len);
    // const result = brute_force(
    //     valves.get([_]u8{ 'A', 'A' }).?,
    //     closed_valves,
    //     26,
    // );
    // print("Result = {}\n", .{result});
}
