package shadertube
import "core:fmt"
import "vendor:raylib"



main :: proc() {
	width, height :: 800, 600
	raylib.InitWindow(i32(width), i32(height), "Animatube")

	camera: raylib.Camera3D
	camera.position = raylib.Vector3 { 50.0, 50.0, 50.0 }
	camera.target = raylib.Vector3 { 0.0, 10.0, 0.0 }
	camera.up = raylib.Vector3 { 0.0, 1.0, 0.0 }
	camera.fovy = 45.0
	camera.projection = raylib.CameraProjection.ORTHOGRAPHIC

	model := raylib.LoadModel("suzanne.gltf")

	raylib.SetTargetFPS(60)
	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.A) {
			fmt.println("Poggers!")
		}
		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.GREEN)
		raylib.BeginMode3D(camera)

		raylib.DrawModel(model, raylib.Vector3{0.0, 0.0, 0.0}, 1.0, raylib.GRAY)
		raylib.EndMode3D()
		raylib.EndDrawing()
	}
	raylib.CloseWindow()
}
