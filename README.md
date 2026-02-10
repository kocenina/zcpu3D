# zcpu3D

3D software rendering application made in Zig.

![Screen](/images/screen02.gif)

Demo is using **RGFW** to render screen. 
It is capable of rendering several meshes, that can be imported from `.obj` files. Also, it can print basic pixel font on screen.

This is just experiment to brush up knowledge on maths and sofware rendering.\
Can be builded only on Linux for now (tested on Arch btw). Just clone repository and build using `make` and run using `make run` - that will compile project with `Debug` optimizations.\
If you want to have blazingly fast app (up to 6 times fps) run `make fast`.

What can you expect:
```
fn draw_triangle(screen_buffer: ImageBuffer, projected_a: iVec2, projected_b: iVec2, projected_c: iVec2, original_z: Vec4, zbuffer: DepthBuffer) bool
fn draw_line(screen_buffer: ImageBuffer, start: iVec2, end: iVec2, color: Color) void
fn draw_point(screen_buffer: ImageBuffer, point: math.Point2, color: Color)
fn draw_rect(screen_buffer: ImageBuffer, x: usize, y: usize, width: usize, height: usize, color: Color)
```

## Used assets:
- [Utah Teapot](https://graphics.stanford.edu/courses/cs148-10-summer/as3/code/as3/teapot.obj)
- [Blender Suzanne](https://www.blender.org/)

## Credits:
- [RGFW](https://github.com/ColleagueRiley/RGFW)
- [stb_image](https://github.com/nothings/stb)