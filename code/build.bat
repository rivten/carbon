@echo off

rem pushd ..\build\
rem clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\code\cimgui\imgui\imgui.cpp -I ..\code\cimgui -o imgui.obj
rem clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\code\cimgui\imgui\imgui_demo.cpp -I ..\code\cimgui -o imgui_demo.obj
rem clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\code\cimgui\imgui\imgui_draw.cpp -I ..\code\cimgui -o imgui_draw.obj
rem clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\code\cimgui\imgui\imgui_widgets.cpp -I ..\code\cimgui -o imgui_widgets.obj
rem clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\code\cimgui\cimgui.cpp -I ..\code\cimgui -o cimgui.obj
rem popd
rem clang -g -gcodeview -std=c99 ..\code\carbon.c cimgui.obj imgui.obj imgui_demo.obj imgui_draw.obj imgui_widgets.obj -I ..\code\sokol -o carbon.exe -l user32.lib -l gdi32.lib
C:\zig\zig.exe build
