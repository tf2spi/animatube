package animatube
import "vendor:raylib"
import "core:encoding/json"
import "core:os"
import "core:c/libc"
import "core:log"
import "core:strings"
import "core:math"

EntityModel :: struct {
	model: raylib.Model,
	animations: []raylib.ModelAnimation,
	camera: raylib.Camera,
	position: raylib.Vector3,
	emote: int,
	frame: int,
}

EntitySprite :: struct {
	texture: raylib.Texture2D,
	animations: []struct {
		images: raylib.Image,
		count: int,
		stride: int,
	},
	position: raylib.Vector2,
	emote: int,
	idx: int,
	delay: uint,
	remaining: uint,
}

Entity :: union {
	EntityModel,
	EntitySprite,
}

Configuration :: struct {
	keycolor: raylib.Color,
	tint: raylib.Color,
	window: raylib.Vector2,
	camera: raylib.Camera,
	idle: Entity,
}

camera_default :: proc() -> raylib.Camera {
	camera: raylib.Camera
	camera.up = raylib.Vector3 { 0, 1, 0 }
	camera.projection = raylib.CameraProjection.ORTHOGRAPHIC
	camera.fovy = 90
	return camera
}

// This is a constant but Odin doesn't wanna admit it. Shrug.
config_default :: proc() -> Configuration {
	config: Configuration
	config.keycolor = raylib.GREEN
	config.tint = raylib.WHITE
	config.window = raylib.Vector2 { 800, 600, }
	config.camera = camera_default()
	return config
}

config_util_json_f64 :: proc(value: json.Value, default: f64) -> f64 {
	#partial switch f in value {
		case f64:
		return f

		case i64:
		return f64(f)
	}
	log.errorf("Failed to parse float from json!")
	return default
}

// Arrays tend to be small and this function's used a lot,
// so default to using the temp allocator. 
config_util_json_array_float :: proc(value: json.Value, size: int, allocator := context.temp_allocator) -> ([dynamic]f64, bool) {
	array: [dynamic]f64
	json_array, ok := value.(json.Array)
	if !ok {
		return array, ok
	}
	array = make([dynamic]f64, 0)
	for float_value in json_array {
		f := config_util_json_f64(float_value, math.nan_f64())
		if math.is_nan_f64(f) {
			log.errorf("Failed to parse float when parsing json float array", size, len(array))
			delete(array)
			return array, false
		}
		append(&array, f)
	}
	if size >= 0 {
		for size > len(array) { append(&array, 0) }
		for size < len(array) { pop(&array) }
	}
	return array, true
}

config_util_json_vector2 :: proc(value: json.Value, default: raylib.Vector2) -> raylib.Vector2 {
	array, ok := config_util_json_array_float(value, 2)
	if !ok { log.errorf("Failed to parse vector2 from json value!") }
	return raylib.Vector2 { f32(array[0]), f32(array[1]) } if ok else default
}

config_util_json_vector3 :: proc(value: json.Value, default: raylib.Vector3) -> raylib.Vector3 {
	array, ok := config_util_json_array_float(value, 3)
	if !ok { log.errorf("Failed to parse vector3 from json value!") }
	return raylib.Vector3 { f32(array[0]), f32(array[1]), f32(array[2]) } if ok else default
}

config_util_json_vector4 :: proc(value: json.Value, default: raylib.Vector4) -> raylib.Vector4 {
	array, ok := config_util_json_array_float(value, 4)
	if !ok { log.errorf("Failed to parse vector4 from json value!") }
	return raylib.Vector4 { f32(array[0]), f32(array[1]), f32(array[2]), f32(array[3]) } if ok else default
}

config_util_json_entity :: proc(value: json.Value) -> Entity {
	entity: Entity = {}
	object, ok := value.(json.Object)
	if !ok {
		log.warnf("Entity provided was not an object in json!")
		return entity
	}
	position: raylib.Vector3
	position_value: json.Value
	position_value, ok = object["position"]
	if ok {
		log.infof("Parsing entity.position ... ")
		position = config_util_json_vector3(position_value, position)
	}

	model_value: json.Value
	model_value, ok = object["model"]
	if ok {
		log.infof("Parsing model ...")
		model: EntityModel
		#partial switch s in model_value {
			case string:
			filename := strings.clone_to_cstring(s)
			anim_count: libc.int = 0
			animations := raylib.LoadModelAnimations(filename, &anim_count)
			if animations != nil && anim_count == 0 {
				raylib.UnloadModelAnimations(animations, 0)
				animations = nil
			}
			model = EntityModel {
				raylib.LoadModel(filename),
				animations[0:anim_count],
				camera_default(),
				position,
				0,
				0,
			}
			delete(filename)
			case:
			log.warnf("Model from entity json was not string!")
		}

		// Each entity gets their own camera if they're a model
		camera_value: json.Value
		camera_value, ok = object["camera"]
		if ok {
			log.infof("Parsing camera ...")
			#partial switch obj in camera_value {
				case json.Object:
				point: json.Value
	
				point, ok = obj["position"]
				if ok {
					log.infof("Parsing camera.position ...")
					model.camera.position = config_util_json_vector3(point, {})
				}
				point, ok = obj["target"]
				if ok {
					log.infof("Parsing camera.target ...")
					model.camera.target = config_util_json_vector3(point, {})
				}
				point, ok = obj["up"]
				if ok {
					log.infof("Parsing camera.up ...")
					model.camera.up = config_util_json_vector3(point, {0, 1, 0})
				}
				point, ok = obj["fovy"]
				if ok {
					log.info("Parsing camera.fovy ...")
					model.camera.fovy = f32(config_util_json_f64(point, 90))
				}
				case:
				log.warnf("Camera from json was not object!")
			}
		}
		entity = model
	}
	// TODO: If a model isn't used, parse a GIF or series of images
	return entity
}

config_parse_json :: proc(config_value: json.Value) -> (Configuration, bool) {
	config := config_default()
	config_object, ok := config_value.(json.Object)
	if !ok {
		log.errorf("Expected config to be an object!")
		return config, false
	}
	value: json.Value
	value, ok = config_object["idle"]
	if ok {
		log.infof("Parsing idle entity ...")
		config.idle = config_util_json_entity(value)
	}



	return config, ok
}


config_load_json :: proc(name: string) -> (Configuration, bool) {
	ok: bool
	config := config_default()
	bytes: []u8

	bytes, ok = os.read_entire_file(name)
	if !ok {
		log.errorf("Failed to read %s into memory!", name)
		return config, ok
	}

	config_json: json.Value
	json_err: json.Error
	config_json, json_err = json.parse(bytes)
	delete(bytes)
	if json_err != json.Error.None {
		log.errorf("Failed to parse %s as json! %v", name, json_err)
		return config, false
	}

	config, ok = config_parse_json(config_json)
	json.destroy_value(config_json)
	if !ok {
		log.errorf("%s parsed successfully as json but there was a parse error!", name)
	}
	return config, ok
}
