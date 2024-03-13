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
}

EntitySprite :: struct {
	images: []raylib.Image,
	time: f32,
	remaining: f32,
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
	entity: Entity,
}

config_default :: proc() -> Configuration {
	config: Configuration
	config.keycolor = raylib.GREEN
	config.tint = raylib.WHITE
	config.window = raylib.Vector2 { 800, 600, }
	config.camera.up = raylib.Vector3 { 0, 1, 0 }
	config.camera.projection = raylib.CameraProjection.ORTHOGRAPHIC
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
	if size >= 0 && size != len(array) {
		log.errorf("Expected json float array of size %d but got size %d", size, len(array))
		delete(array)
		return array, false
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

config_parse_json :: proc(config_value: json.Value) -> (Configuration, bool) {
	config := config_default()
	config_object, ok := config_value.(json.Object)
	if !ok {
		log.errorf("Expected config to be an object!")
		return config, false
	}

	value: json.Value
	value, ok = config_object["model"]
	if ok {
		log.infof("Parsing model ...")
		#partial switch s in value {
			case string:
			filename := strings.clone_to_cstring(s)
			anim_count: libc.int = 0
			animations := raylib.LoadModelAnimations(filename, &anim_count)
			config.entity = EntityModel {
				raylib.LoadModel(filename),
				animations[0:anim_count],
			}
			delete(filename)
			case:
			log.warnf("Model from json was not string!")
		}

		value, ok = config_object["camera"]
		if ok {
			log.infof("Parsing camera ...")
			#partial switch obj in value {
				case json.Object:
				point: json.Value

				point, ok = obj["position"]
				if ok {
					log.infof("Parsing camera.position ...")
					config.camera.position = config_util_json_vector3(point, {})
				}
				point, ok = obj["target"]
				if ok {
					log.infof("Parsing camera.target ...")
					config.camera.target = config_util_json_vector3(point, {})
				}
				point, ok = obj["up"]
				if ok {
					log.infof("Parsing camera.up ...")
					config.camera.up = config_util_json_vector3(point, {0, 1, 0})
				}
				point, ok = obj["fovy"]
				if ok {
					log.info("Parsing camera.fovy ...")
					config.camera.fovy = f32(config_util_json_f64(point, 90))
				}
				case:
				log.warnf("Camera from json was not object!")
			}
		}
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
