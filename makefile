all: build 

debug:
	zig build -Doptimize=Debug

build:
	zig build -Doptimize=Debug
	
run:
	zig build -Doptimize=Debug run

fast:
	zig build -Doptimize=ReleaseFast run