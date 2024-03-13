package animatube
import "core:fmt"
import "vendor:raylib"
import "core:log"
import "core:os"

main :: proc() {
	context.logger = log.create_file_logger(os.stderr)
	width, height :: 800, 600
	raylib.InitWindow(i32(width), i32(height), "Animatube")

	config, ok := config_load_json("suzanne.json")
	if !ok {
		config = config_default()
	}

	raylib.SetTargetFPS(60)
	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.A) {
			fmt.println("Poggers!")
		}
		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.GREEN)

		switch entity in config.entity {
			case EntityModel:
			raylib.BeginMode3D(config.camera)
			raylib.DrawModel(entity.model, raylib.Vector3{0.0, 0.0, 0.0}, 1.0, raylib.GRAY)
			raylib.EndMode3D()

			case EntitySprite:
		}

		raylib.EndDrawing()
	}
	raylib.CloseWindow()
}
