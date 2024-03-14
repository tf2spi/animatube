package animatube
import "core:fmt"
import "vendor:raylib"
import "core:log"
import "core:os"

main :: proc() {
	context.logger = log.create_file_logger(os.stderr)
	width, height :: 800, 600
	raylib.InitWindow(i32(width), i32(height), "Animatube")

	config, ok := config_load_json("animation.json")
	if !ok {
		config = config_default()
	}

	raylib.SetTargetFPS(60)
	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.A) {
			log.infof("Poggers!")
		}
		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.GREEN)

		switch entity in config.idle {
			case EntityModel:
			raylib.BeginMode3D(entity.camera)
			if len(entity.animations) > 0 {
				animation := entity.animations[0]
				tmp := entity
				tmp.frame = (entity.frame + 1) % int(animation.frameCount)
				config.idle = tmp
				raylib.UpdateModelAnimation(entity.model, animation, i32(tmp.frame))
			}
			raylib.DrawModel(entity.model, entity.position, 1.0, raylib.GRAY)
			raylib.EndMode3D()

			case EntitySprite:
		}

		raylib.EndDrawing()
	}
	raylib.CloseWindow()
}
