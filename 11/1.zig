const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Operation = enum {
    multiply,
    add,
    square,
};


const Monkey = struct {
    const Self = @This();
    operation: Operation = Operation.multiply,
    value: u32 = 0,
    test_value: u32 = 0,
    test_success: usize = 0,
    test_fail: usize = 0,
    items: std.ArrayList(u32),
    inspected: u32 = 0,

    fn through_next(self: *Self) ?u32 {
        if (self.items.items.len == 0) return null;
        var item = self.items.orderedRemove(0);
        self.inspected += 1;
        if (self.operation == Operation.multiply) {
            item *= self.value;
        } else if (self.operation == Operation.add) {
            item += self.value;
        } else if (self.operation == Operation.square) {
            item *= item;
        }
        item = @divFloor(item, 3);
        return item;
    }

    fn get_target(self: Self, item: u32) usize {
        return if (@rem(item, self.test_value) == 0) self.test_success else self.test_fail;
    }
};

pub fn main() !void {
    var monkeys = std.ArrayList(Monkey).init(allocator);
    defer monkeys.deinit();

    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var new_monkey: ?*Monkey = null;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.startsWith(u8, line, "Monkey")) {
            try monkeys.append(Monkey{.items = std.ArrayList(u32).init(allocator) });
            new_monkey = &monkeys.items[monkeys.items.len - 1];
        } else if (std.mem.startsWith(u8, line, "  Starting items: ")) {
            var iterator = std.mem.split(u8, line[18..], ", ");
            while (iterator.next()) |item| {
                try new_monkey.?.items.append(std.fmt.parseInt(u32, item, 10) catch unreachable);
            }
        } else if (std.mem.startsWith(u8, line, "  Operation")) {
            if (std.mem.containsAtLeast(u8, line, 2, "old")) {
                new_monkey.?.operation = Operation.square;
            } else {
                new_monkey.?.value = try std.fmt.parseInt(u32, line[25..], 10);
                if (std.mem.containsAtLeast(u8, line, 1, "+")) {
                    new_monkey.?.operation = Operation.add;
                } else {
                    new_monkey.?.operation = Operation.multiply;
                }
            }
        } else if (std.mem.startsWith(u8, line, "  Test: divisible by ")) {
            new_monkey.?.test_value = try std.fmt.parseInt(u32, line[21..], 10);
        } else if (std.mem.startsWith(u8, line, "    If true: throw to monkey ")) {
            new_monkey.?.test_success = try std.fmt.parseInt(u8, line[29..], 10);
        } else if (std.mem.startsWith(u8, line, "    If false: throw to monkey ")) {
            new_monkey.?.test_fail = try std.fmt.parseInt(u8, line[30..], 10);
        }
    }

    var round: u8 = 0;
    while (round < 20) : (round += 1) {
        for (monkeys.items) |*monkey| {
            while (monkey.through_next()) |item| {
                var target = monkey.get_target(item);
                try monkeys.items[target].items.append(item);
            }
        }
    }

    for (monkeys.items) |monkey, i| {
        print("Monkey {} inspected {}\n", .{i, monkey.inspected});
    }
}
