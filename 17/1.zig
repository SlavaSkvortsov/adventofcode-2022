const std = @import("std");
const io = std.io;
const print = std.debug.print;

const allocator = std.heap.page_allocator;

const Point = struct {
    x: u64,
    y: u64,
};

const Figure = struct {
    const Self = @This();

    width: u64,
    height: u64,
    points: [] const Point,  // relative to the bottom left corner

    pub fn move_corner_on_wind(self: Self, point: *Point, wind: *Wind) void {
        if (wind.next() < 0) {
            if (point.x == 0) {
                return;
            } else {
                point.x -= 1;
            }
        } else if (point.x == MAX_X - self.width + 1) {
            return;
        } else {
            point.x += 1;
        }
    }
};

const Chamber = struct {
    const Self = @This();

    max_y: u64 = 0,
    points: std.AutoHashMap(Point, void),

    pub fn is_colliding(self: *Self, figure: Figure, offset: Point) bool {
        for (figure.points) |point| {
            if (self.points.contains(Point{ .x = point.x + offset.x, .y = point.y + offset.y })) return true;
        }
        return false;
    }

    pub fn print_me(self: Self) void {
        print("Chamber with max_y={}:\n", .{self.max_y});

        var y = self.max_y;
        while (y >= 1) {
            var x: u64 = 0;
            print("|", .{});
            while (x <= MAX_X) : (x += 1) {
                if (self.points.contains(Point{ .x = x, .y = y })) {
                    print("#", .{});
                } else {
                    print(".", .{});
                }
            }
            print("|\n", .{});
            if (y == 1) {
                print("+-------+\n", .{});
                break;
            }
            y -= 1;
        }
    }
};

const Wind = struct {
    const Self = @This();

    directions: []u8,
    cursor: usize = 0,

    pub fn next(self: *Self) i8 {
        const result = self.directions[self.cursor];
        // print("Wind: {u}\n", .{result});
        if (self.cursor == self.directions.len - 1) {
            self.cursor = 0;
        } else {
            self.cursor += 1;
        }
        return if (result == '>') 1 else if (result == '<') -1 else 0;
    }
};

const DashFigure = Figure{
    .width = 4,
    .height = 1,
    .points = &([_]Point{
        Point{ .x = 0, .y = 0 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 2, .y = 0 },
        Point{ .x = 3, .y = 0 },
    }),
};


const PlusFigure = Figure{
    .width = 3,
    .height = 3,
    .points = &([_]Point{
        Point{ .x = 0, .y = 1 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 1, .y = 1 },
        Point{ .x = 1, .y = 2 },
        Point{ .x = 2, .y = 1 },
    }),
};


const JFigure = Figure{
    .width = 3,
    .height = 3,
    .points = &([_]Point{
        Point{ .x = 0, .y = 0 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 2, .y = 0 },
        Point{ .x = 2, .y = 1 },
        Point{ .x = 2, .y = 2 },
    }),
};


const IFigure = Figure{
    .width = 1,
    .height = 4,
    .points = &([_]Point{
        Point{ .x = 0, .y = 0 },
        Point{ .x = 0, .y = 1 },
        Point{ .x = 0, .y = 2 },
        Point{ .x = 0, .y = 3 },
    }),
};

const MAX_X = 6;


fn drop_figure(figure: Figure, wind: *Wind, chamber: *Chamber) void {
    var bottom_left = Point{ .x = 2, .y = chamber.max_y + 1 };

    // Before reaching the highest point
    var i: u8 = 0;
    while (i < 4) : (i += 1) {
        figure.move_corner_on_wind(&bottom_left, wind);
    }
    // print("bottom_left=({},{}), \n", .{bottom_left.x, bottom_left.y});

    // Now we need to check if the figure can be placed
    while (true) {
        if (bottom_left.y == 1) {
            // We reached the bottom
            break;
        }

        var potential_bottom_left = Point{ .x = bottom_left.x, .y = bottom_left.y - 1 };
        if (chamber.is_colliding(figure, potential_bottom_left)) break;
        bottom_left = Point { .x = potential_bottom_left.x, .y = potential_bottom_left.y };

        figure.move_corner_on_wind(&potential_bottom_left, wind);
        if (chamber.is_colliding(figure, potential_bottom_left)) continue;
        bottom_left = Point { .x = potential_bottom_left.x, .y = potential_bottom_left.y };
    }
    var potential_max_y = bottom_left.y + figure.height - 1;
    if (potential_max_y > chamber.max_y) {
        chamber.max_y = potential_max_y;
    }
    for (figure.points) |point| {
        chamber.points.put(Point{ .x = point.x + bottom_left.x, .y = point.y + bottom_left.y }, undefined) catch unreachable;
    }
}


const SquareFigure = Figure{
    .width = 2,
    .height = 2,
    .points = &([_]Point{
        Point{ .x = 0, .y = 0 },
        Point{ .x = 0, .y = 1 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 1, .y = 1 },
    }),
};


pub fn main() !void {
    var file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buff: [11000]u8 = undefined;

    var bytes = try in_stream.readAll(&buff);
    var wind = Wind{ .directions = buff[0..bytes] };
    print("Wind: {}\n", .{wind.directions.len});
    var figures = [_]Figure{
        DashFigure,
        PlusFigure,
        JFigure,
        IFigure,
        SquareFigure,
    };
    var chamber = Chamber{ .points = std.AutoHashMap(Point, void).init(allocator) };
    var i: usize = 0;

    while (i < 2022) : (i += 1) {
        drop_figure(figures[i % figures.len], &wind, &chamber);
        // chamber.print_me();
    }

    std.debug.print("max_y: {}\n", .{chamber.max_y});

    // 3044 is too low
}
