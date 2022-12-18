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

const Elephant = struct {
    valve: *Valve,
    time: u8,
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

fn print_depth(depth: u8) void {
    var i: u8 = 0;
    while (i < depth) : (i += 1) {
        print("  ", .{});
    }
}

fn brute_force(elephants: [2]Elephant, closed_valves: std.AutoHashMap([2]u8, Valve), time_left: u8, depth: u8) u32 {
    var max_result: u32 = 0;
    var count: u32 = 0;

    for (elephants) |elephant, i| {
        if (elephant.time > 0) continue;

        var closed_valves_iter = closed_valves.iterator();
        while (closed_valves_iter.next()) |data| {
            if (depth == 0 ) {
                print("count: {}\n", .{count});
                count += 1;
            }
            if (elephant.valve.paths.get(data.key_ptr.*)) |path| {
                if (path < time_left) {
                    var new_closed_valves = closed_valves.clone() catch unreachable;
                    defer new_closed_valves.deinit();
                    _ = new_closed_valves.remove(data.key_ptr.*);


                    var new_elephants = [2]Elephant{
                        Elephant{
                            .valve = if (i == 0) data.value_ptr else elephants[0].valve,
                            .time = if (i == 0) path + 1 else elephants[0].time,
                        },
                        Elephant{
                            .valve = if (i == 1) data.value_ptr else elephants[1].valve,
                            .time = if (i == 1) path + 1 else elephants[1].time,
                        },
                    };

                    var min_time = if (new_elephants[0].time < new_elephants[1].time) new_elephants[0].time else new_elephants[1].time;

                    for (new_elephants) |*new_elephant| {
                        new_elephant.*.time -= min_time;
                    }
                    // print_depth(depth);
                    // print("Elephant {d} is opening valve {s} wasting {}\n", .{i, data.key_ptr.*, path + 1});
                    //
                    // print_depth(depth);
                    // print("Time left: {}\n", .{time_left - min_time});
                    //
                    // print_depth(depth);
                    // print("New time: {}, {}\n", .{new_elephants[0].time, new_elephants[1].time});
                    //
                    // print_depth(depth);
                    // print("New valve: {s}, {s}\n", .{new_elephants[0].valve.name, new_elephants[1].valve.name});
                    //
                    // print_depth(depth);
                    // print("Closed valves: {}\n", .{new_closed_valves.count()});

                    // print_depth(depth);
                    // print("Max result: {}\n", .{max_result});

                    // print_depth(depth);
                    // print("\n", .{});
                    // var threads: std.ArrayList(*std.Thread) = std.ArrayList(*std.Thread).init(allocator);
                    // var t: usize = 0;
                    //
                    // while (t < num_threads) : (t += 1) {
                    //     // Start a new thread and pass the context to the worker thread.
                    //     try threads.append(try std.Thread.spawn(worker_ctx, workerFunction));
                    // }
                    //
                    // // Wait for all threads to finish.
                    // for (threads.items) |thread| {
                    //     thread.wait();
                    // }

                    const result = brute_force(
                        new_elephants,
                        new_closed_valves,
                        time_left - min_time,
                        depth + 1,
                    ) + (data.value_ptr.*.rate * (time_left - path - 1));
                    if (result > max_result) {
                        max_result = result;
                    }
                }
            }
        }
    }
    // print_depth(if (depth > 0) depth - 1 else 0);
    // print("Max result: {}\n", .{max_result});
    return max_result;
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



    var start_valve = valves.get([_]u8{ 'A', 'A' }).?;
    const result = brute_force(
        [2]Elephant{
            Elephant{
                .valve = &start_valve,
                .time = 0,
            },
            Elephant{
                .valve = &start_valve,
                .time = 0,
            },
        },
        closed_valves,
        26,
        0,
    );
    print("Result = {}\n", .{result});
}
