const std = @import("std");
const Allocator = std.mem.Allocator;

// NOTE(hugo): The stretchy_buffer and hashmap types
// are directly taken from Per Vogsen's Bitwise project !

pub fn stretchy_buffer(comptime T: type) type {
    return struct {
        allocator: *Allocator,
        len: usize,
        elems: []T,

        const Self = @This();

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .allocator = allocator,
                .len = 0,
                .elems = [_]T{},
            };
        }

        pub fn push(buf: *Self, elem: T) !void {
            try fit(buf, 1 + buf.len);
            buf.elems[buf.len] = elem;
            buf.len += 1;
        }

        pub fn append(buf: *Self, elems: []const T) !void {
            for (elems) |e| try buf.push(e);
        }

        fn fit(buf: *Self, n: usize) !void {
            if (n > buf.elems.len) {
                try grow(buf, n);
            }
        }

        fn grow(buf: *Self, new_len: usize) !void {
            const new_cap = std.math.max(2 * buf.elems.len, std.math.min(new_len, 16));
            if (buf.elems.len == 0) {
                buf.elems = try buf.allocator.alloc(T, new_cap);
            } else {
                buf.elems = try buf.allocator.realloc(buf.elems, new_cap);
            }
        }

        pub fn clear(buf: *Self) void {
            buf.len = 0;
        }

        pub fn free(buf: *Self) void {
            buf.allocator.free(buf.elems);
        }

        pub fn elements(buf: *Self) []T {
            return buf.elems[0..buf.len];
        }
    };
}

test "init" {
    var buf = stretchy_buffer(i32).init(&std.heap.DirectAllocator.init().allocator);
    std.debug.assert(buf.len == 0);
    std.debug.assert(buf.elems.len == 0);
}

test "push i32" {
    var buf = stretchy_buffer(i32).init(&std.heap.DirectAllocator.init().allocator);
    try buf.push(1);
    try buf.push(2);
    try buf.push(5);
    for (buf.elements()) |e| {
        std.debug.warn("{}\n", e);
    }
    buf.clear();
    std.debug.assert(buf.len == 0);
}

test "push struct" {
    const myStruct = struct {
        a: i32,
        b: bool,
    };

    const A = myStruct{
        .a = 0,
        .b = true,
    };

    const B = myStruct{
        .a = 1,
        .b = false,
    };

    var buf = stretchy_buffer(myStruct).init(&std.heap.DirectAllocator.init().allocator);
    try buf.push(A);
    try buf.push(B);
    for (buf.elements()) |e| {
        std.debug.warn("{}\n", e);
    }
}

pub fn hashmap(comptime V: type) type {
    return struct {
        values: []V,
        keys: []?u64,
        len: usize,
        allocator: *Allocator,

        const Self = @This();

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .values = []align(@alignOf(V)) V{},
                .keys = []align(@alignOf(?u64)) ?u64{},
                .len = 0,
                .allocator = allocator,
            };
        }

        pub fn get(map: *Self, key: u64) ?V {
            if (map.len == 0) {
                return null;
            }
            var i = hash(key);
            while (true) {
                i &= map.values.len - 1;
                if (map.keys[i] == null) {
                    return null;
                } else if (map.keys[i].? == key) {
                    return map.values[i];
                }
                i += 1;
            }
        }

        pub fn put(map: *Self, key: u64, value: V) !void {
            if (2 * map.len >= map.values.len) {
                try map.grow(2 * map.values.len);
            }
            var i: u64 = hash(key);
            while (true) {
                i &= map.values.len - 1;
                if (map.keys[i] == null) {
                    map.len += 1;
                    map.keys[i] = key;
                    map.values[i] = value;
                    return;
                } else if (map.keys[i].? == key) {
                    map.values[i] = value;
                }
                i += 1;
            }
        }

        fn grow(map: *Self, new_cap: usize) !void {
            var cap = std.math.max(new_cap, 16);
            var new_map = Self{
                .allocator = map.allocator,
                .values = try map.allocator.alloc(V, cap),
                .keys = try map.allocator.alloc(?u64, cap),
                .len = map.len,
            };

            for (new_map.keys) |*k| {
                k.* = null;
            }

            for (map.values) |v, i| {
                if (map.keys[i]) |k| {
                    new_map.put(k, v) catch unreachable;
                }
            }

            map.allocator.free(map.values);
            map.allocator.free(map.keys);
            map.* = new_map;
        }

        fn hash(x: u64) u64 {
            var result: u64 = undefined;
            _ = @mulWithOverflow(u64, x, 0xff51afd7ed558ccd, &result);
            result ^= result >> 32;
            return result;
        }
    };
}

test "hash test" {
    var map = hashmap(u64).init(&std.heap.DirectAllocator.init().allocator);
    var i: u64 = 1;
    while (i < 1024) : (i += 1) {
        try map.put(i, i + 1);
    }

    i = 1;
    while (i < 1024) : (i += 1) {
        if (map.get(i)) |v| {
            std.debug.assert(v == i + 1);
        } else {
            unreachable;
        }
    }
}
