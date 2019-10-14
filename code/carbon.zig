const std = @import("std");

const c = @import("c.zig");
const serialize = @import("serialize.zig");

fn zero_struct(comptime T: type) T {
    var variable: T = undefined;
    @memset(@ptrCast([*]u8, &variable), 0, @sizeOf(T));

    return variable;
}

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var state: State = undefined;

export fn init() void {
    var desc = zero_struct(c.sg_desc);
    c.sg_setup(&desc);

    c.stm_setup();

    var imgui_desc = zero_struct(c.simgui_desc_t);
    c.simgui_setup(&imgui_desc);

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].val = [_]f32{ 0.2, 0.2, 0.2, 1.0 };

    const vertices = [_]f32{
        // positions     // colors
        0.0,  0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.5, 0.0, 1.0, 0.0, 1.0,
        -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
    };

    var buffer_desc = zero_struct(c.sg_buffer_desc);
    buffer_desc.size = vertices.len * @sizeOf(f32);
    buffer_desc.content = &vertices[0];
    buffer_desc.type = c.SG_BUFFERTYPE_VERTEXBUFFER;
    buffer_desc.label = c"triangle_vertices";
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&buffer_desc);

    var shader_desc = zero_struct(c.sg_shader_desc);
    shader_desc.vs.source =
        c\\#version 330
        c\\in vec3 vertex_position;
        c\\in vec4 in_color;
        c\\out vec4 color;
        c\\void main(void)
        c\\{
        c\\   gl_Position = vec4(vertex_position, 1.0);
        c\\   color = in_color;
        c\\}
    ;
    shader_desc.fs.source =
        c\\#version 330
        c\\out vec4 frag_color;
        c\\in vec4 color;
        c\\void main(void)
        c\\{
        c\\    frag_color = color;
        c\\}
    ;

    const shader = c.sg_make_shader(&shader_desc);

    var pipeline_desc = zero_struct(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[0].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[1].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.shader = shader;
    pipeline_desc.label = c"main_pipeline";
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

var last_time: u64 = 0;
var show_test_window: bool = false;
var show_another_window: bool = false;
var display_menu: bool = false;

var f: f32 = 0.0;

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    const dt = c.stm_sec(c.stm_laptime(&last_time));
    c.simgui_new_frame(width, height, dt);

    if (display_menu) {
        c.igSetNextWindowPos(zero_struct(c.ImVec2), 0, zero_struct(c.ImVec2));
        c.igSetNextWindowSize(c.ImVec2{ .x = @intToFloat(f32, width), .y = @intToFloat(f32, height) }, 0);

        _ = c.igBegin(c"Window", null, @enumToInt(c.ImGuiWindowFlags_NoTitleBar) | @enumToInt(c.ImGuiWindowFlags_NoBringToFrontOnFocus) | @enumToInt(c.ImGuiWindowFlags_NoResize) | @enumToInt(c.ImGuiWindowFlags_NoMove) | @enumToInt(c.ImGuiWindowFlags_AlwaysAutoResize));
        serialize.serialize_imgui(state, "state");

        c.igEnd();
    } else {
        c.igText(c"Hello, world!");
        _ = c.igSliderFloat(c"float", &f, 0.0, 1.0, c"%.3f", 1.0);
        _ = c.igColorEdit3(c"clear color", &state.pass_action.colors[0].val[0], 0);
        if (c.igButton(c"Test Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_test_window = !show_test_window;
        if (c.igButton(c"Another Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_another_window = !show_another_window;
        c.igText(c"Application average %.3f ms/frame (%.1f FPS)", 1000.0 / c.igGetIO().*.Framerate, c.igGetIO().*.Framerate);

        if (show_another_window) {
            c.igSetNextWindowSize(c.ImVec2{ .x = 200, .y = 100 }, @intCast(c_int, @enumToInt(c.ImGuiCond_FirstUseEver)));
            _ = c.igBegin(c"Another Window", &show_another_window, 0);
            c.igText(c"Hello");
            c.igEnd();
        }

        if (show_test_window) {
            c.igSetNextWindowPos(c.ImVec2{ .x = 460, .y = 20 }, @intCast(c_int, @enumToInt(c.ImGuiCond_FirstUseEver)), c.ImVec2{ .x = 0, .y = 0 });
            c.igShowDemoWindow(0);
        }
    }

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_draw(0, 3, 1);
    c.simgui_render();
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.simgui_shutdown();
    c.sg_shutdown();
}

export fn event(e: [*c]const c.sapp_event) void {
    _ = c.simgui_handle_event(e);

    if (e[0].type == c.sapp_event_type.SAPP_EVENTTYPE_KEY_DOWN and
        e[0].key_code == c.sapp_keycode.SAPP_KEYCODE_TAB)
    {
        display_menu = !display_menu;
    }
}

export fn sokol_main() c.sapp_desc {
    var app_desc = zero_struct(c.sapp_desc);
    app_desc.width = 640;
    app_desc.height = 480;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.event_cb = event;

    return app_desc;
}
