# zcpu3D

3D software rendering application made in Zig.

![Screen](/images/screen02.gif)

Demo is using **RGFW** for rendering screen and **olive.c** for rasterizing triangles and lines. 
It is capable of rendering several meshes, that can be imported from `.obj` files.

This is just experiment to brush up knowledge on math and sofware rendering.
Can be builded only on Linux for now (tested on Arch btw). Just clone repository and build using `make` and run using `make run`.

## Credits:
- [RGFW](https://github.com/ColleagueRiley/RGFW)
- [olive.c](https://github.com/tsoding/olive.c)