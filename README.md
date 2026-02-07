# zcpu3D

3D software rendering application made in Zig.

![Screen](/images/screen02.gif)

Demo is using **RGFW** to render screen. 
It is capable of rendering several meshes, that can be imported from `.obj` files.

This is just experiment to brush up knowledge on math and sofware rendering.\
Can be builded only on Linux for now (tested on Arch btw). Just clone repository and build using `make` and run using `make run` - that will compile project with `Debug` optimizations.\
If you want to have blazingly fast app, run `make fast`.

## Credits:
- [RGFW](https://github.com/ColleagueRiley/RGFW)