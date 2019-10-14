const std = @import("std");
const c = @import("c.zig");

fn to_c_string(s: []const u8) []const u8 {
    var result = std.heap.direct_allocator.alloc(u8, s.len + 1) catch unreachable;
    for (result) |*char, i| {
        if (i == s.len) {
            char.* = 0;
        } else {
            char.* = s[i];
        }
    }
    return result;
}

pub fn serialize_imgui(variable: var, name: []const u8) void {
    const T = @typeOf(variable);
    const type_name = @typeName(T);
    const c_type_name = to_c_string(type_name);
    defer std.heap.direct_allocator.free(c_type_name);
    const c_variable_name = to_c_string(name);
    defer std.heap.direct_allocator.free(c_variable_name);
    switch (@typeInfo(T)) {
        .ComptimeInt, .Int => {
            c.igText(c"%s:%s = %i", &c_variable_name[0], &c_type_name[0], @intCast(c_int, variable));
        },
        .Float => {
            c.igText(c"%s:%s = %f", &c_variable_name[0], &c_type_name[0], variable);
        },
        .Void => {},
        .Bool => {
            c.igText(c"%s:%s = %s", &c_variable_name[0], &c_type_name[0], if (variable) c"true" else c"false");
        },
        .Optional => {
            if (variable) |v| {
                // TODO(hugo): member_name ??
                c.igIndent(1.0);
                serialize_imgui(v, "");
                c.igUnindent(1.0);
            } else {
                c.igText(c"%s:%s = null", &c_variable_name[0], &c_type_name[0]);
            }
        },
        .ErrorUnion => {},
        .ErrorSet => {},
        .Enum => {},
        .Union => {},
        .Struct => {
            if (c.igCollapsingHeader(c"Struct", 0)) {
                comptime var field_i = 0;
                inline while (field_i < @memberCount(T)) : (field_i += 1) {
                    const member_name = @memberName(T, field_i);
                    c.igIndent(1.0);
                    serialize_imgui(@field(variable, member_name), member_name);
                    c.igUnindent(1.0);
                }
            }
        },
        .Pointer => {},
        .Array => {},
        .Fn => {},
        else => @compileError("Unable to serialize type'" ++ @typeName(T) ++ "'"),
    }
}
