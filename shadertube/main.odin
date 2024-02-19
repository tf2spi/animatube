package shadertube
import "core:fmt"
import "vendor:sdl2"
import "vendor:cgltf"

main :: proc() {
	sdl2.Init({sdl2.InitFlag.VIDEO, sdl2.InitFlag.EVENTS})
	x, y := i32(sdl2.WINDOWPOS_CENTERED), i32(sdl2.WINDOWPOS_CENTERED)
	w, h := i32(640), i32(480)
	window := sdl2.CreateWindow("Shadertube", x, y, w, h, {sdl2.WindowFlag.VULKAN})
	defer sdl2.DestroyWindow(window)

	// I rippped off this sample file from...
	// https://github.com/KhronosGroup/glTF-Tutorials/blob/main/gltfTutorial/gltfTutorial_003_MinimalGltfFile.md 
	scene, res := cgltf.parse_file({}, "sample.gltf")
	if res != .success {
		fmt.printf("GLTF Parse file failed! %v\n", res)
		return
	}
	defer cgltf.free(scene)
	eventloop: for {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
				case sdl2.EventType.QUIT:
				break eventloop
			}
		}
	}
}
