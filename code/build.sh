#../../zig/build/bin/zig build

clang carbon.c -o ../build/carbon -lX11 -ldl -lGL -lGLEW ../code/cimgui/cimgui.so -Wl,-rpath,../code/cimgui/
