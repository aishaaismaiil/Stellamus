extends Node3D

# ConduzPT: geometria REAL quando obtida do OpenStreetMap.
# Carro, largura de faixas, edifícios extrudidos e regras de condução são aproximações.
const LAT := 38.7470
const LON := -9.1110
const HALF_SIZE_M := 350.0
const OVERPASS := "https://overpass.kumi.systems/api/interpreter"
const ROAD_TYPES := ["residential", "tertiary", "secondary", "primary", "living_street", "service", "unclassified", "pedestrian", "footway", "cycleway"]
var road_segments: Array = []
var car: Node3D
var camera: Camera3D
var overview_camera: Camera3D
var overview_mode := false
var label: Label
var status_label: Label
var speed := 0.0
var heading := 0.0
var gear := 0
var clutch := false
var brakes := false
var handbrake := false
var map_loaded := false
var infractions := 0
var last_offroad := false
var request: HTTPRequest
var world_root: Node3D
var ground_mat: StandardMaterial3D
var road_mat: StandardMaterial3D
var building_mat: StandardMaterial3D
var white_mat: StandardMaterial3D
var node_locations := {}
var spawned_buildings := 0
var spawned_roads := 0
var markings_mat: StandardMaterial3D
var sidewalk_mat: StandardMaterial3D
var trees_mat: StandardMaterial3D
var decorative_count := 0

func _ready() -> void:
 _make_materials()
 world_root = Node3D.new()
 world_root.name = "Geometria_OSM"
 add_child(world_root)
 _create_world()
 _create_car()
 _create_ui()
 request = HTTPRequest.new()
 add_child(request)
 request.timeout = 30.0
 request.request_completed.connect(_on_osm_result)
 _load_local()

func _make_materials() -> void:
 ground_mat = _mat(Color("73876b"))
 road_mat = _mat(Color("33383f"))
 building_mat = _mat(Color("c8b9a2"))
 white_mat = _mat(Color("f2eee0"))
 markings_mat = _mat(Color("f4e9c8"))
 sidewalk_mat = _mat(Color("a8a8a1"))
 trees_mat = _mat(Color("3d7043"))

func _mat(c: Color) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = 0.95
 return m

func _create_world() -> void:
 var ground := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(1200, 1200)
 ground.mesh = plane
 ground.material_override = ground_mat
 ground.position.y = -0.10
 world_root.add_child(ground)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48, -35, 0)
 sun.light_energy = 1.4
 add_child(sun)
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("a8c7d7")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("ffffff")
 e.ambient_light_energy = 0.65
 env.environment = e
 add_child(env)

func _create_car() -> void:
 car = Node3D.new()
 car.name = "Automovel_simulado"
 add_child(car)
 var hood := MeshInstance3D.new()
 var hood_mesh := BoxMesh.new()
 hood_mesh.size = Vector3(1.65, 0.35, 2.5)
 hood.mesh = hood_mesh
 hood.position = Vector3(0, 0.55, -1.35)
 hood.material_override = _mat(Color("266a89"))
 car.add_child(hood)
 camera = Camera3D.new()
 camera.current = true
 camera.position = Vector3(0, 1.52, 0.15)
 camera.fov = 78
 car.add_child(camera)
 car.position = Vector3(0, 0.1, 0)
 overview_camera = Camera3D.new()
 overview_camera.position = Vector3(0, 430, 0)
 overview_camera.rotation_degrees = Vector3(-90, 0, 0)
 overview_camera.fov = 75
 add_child(overview_camera)

func _create_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 var panel := PanelContainer.new()
 panel.position = Vector2(14, 14)
 panel.custom_minimum_size = Vector2(480, 0)
 canvas.add_child(panel)
 var v := VBoxContainer.new()
 panel.add_child(v)
 var title := Label.new()
 title.text = "ConduzPT  •  CHELAS / LISBOA  •  PROTÓTIPO OSM 02"
 v.add_child(title)
 status_label = Label.new()
 status_label.text = "A carregar dados reais do OpenStreetMap…"
 v.add_child(status_label)
 label = Label.new()
 label.text = ""
 v.add_child(label)
 var instructions := Label.new()
 instructions.text = "↑ acelerar  ↓ travar  ← → direção\nShift embraiagem  |  0 ponto morto  |  1–5 mudanças\nEspaço travão de mão  |  R reposicionar  |  F3 vista aérea\nAtenção: geometria OSM ≠ sinalização verificada"
 v.add_child(instructions)

func _load_local() -> void:
 # 700 m x 700 m; aproximadamente 0.00315° latitude, 0.00404° longitude
 var south := LAT - 0.00315
 var north := LAT + 0.00315
 var west := LON - 0.00404
 var east := LON + 0.00404
 var bbox := "%.6f,%.6f,%.6f,%.6f" % [south, west, north, east]
 var query := "[out:json][timeout:25];(way[\"highway\"](%s);way[\"building\"](%s););out body;>;out skel qt;" % [bbox, bbox]
 var url := OVERPASS + "?data=" + query.uri_encode()
 var err := request.request(url)
 if err != OK:
  status_label.text = "Não foi possível iniciar o download. Usa um ficheiro OSM local."
  _load_local()

func _on_osm_result(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 if result == HTTPRequest.RESULT_SUCCESS and code == 200:
  var parsed = JSON.parse_string(body.get_string_from_utf8())
  if parsed is Dictionary and parsed.has("elements"):
   _build_osm(parsed)
   return
 status_label.text = "Servidor OSM indisponível (HTTP %s). A tentar ficheiro local…" % code
 _load_local()

func _load_local() -> void:
 var path := "res://dados/chelas.osm.json"
 if FileAccess.file_exists(path):
  var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
  if parsed is Dictionary and parsed.has("elements"):
   _build_osm(parsed)
   return
 status_label.text = "Sem dados reais: consulta README para importar Chelas. Não foi criado mapa fictício."

func _to_local(lat: float, lon: float) -> Vector3:
 var x := (lon - LON) * 111320.0 * cos(deg_to_rad(LAT))
 var z := -(lat - LAT) * 111320.0
 return Vector3(x, 0, z)

func _build_osm(data: Dictionary) -> void:
 node_locations.clear()
 for el in data.elements:
  if el.get("type") == "node":
   node_locations[int(el.id)] = _to_local(float(el.lat), float(el.lon))
 for el in data.elements:
  if el.get("type") != "way":
   continue
  var tags: Dictionary = el.get("tags", {})
  var points: Array = []
  for id in el.get("nodes", []):
   if node_locations.has(int(id)):
    points.append(node_locations[int(id)])
  if tags.has("highway") and str(tags.highway) in ROAD_TYPES:
   var width := _road_width(tags)
   var vehicle_road := str(tags.highway) not in ["footway", "cycleway", "pedestrian"]
   for i in range(points.size() - 1):
    _road_piece(points[i], points[i+1], width, vehicle_road)
   spawned_roads += 1
  elif tags.has("building") and points.size() >= 4:
   _building(points, tags)
 map_loaded = spawned_roads > 0
 status_label.text = "OSM REAL: %d vias / %d edifícios | F3 vista aérea | mapa centrado 38.7470,-9.1110" % [spawned_roads, spawned_buildings]
 if map_loaded:
  _place_on_road()

func _road_width(tags: Dictionary) -> float:
 var kind := str(tags.get("highway", ""))
 if kind in ["footway", "cycleway", "pedestrian"]:
  return 2.0
 var lanes := int(tags.get("lanes", "2")) if str(tags.get("lanes", "2")).is_valid_int() else 2
 return clampf(float(lanes) * 3.2, 3.2, 13.0)

func _road_piece(a: Vector3, b: Vector3, width: float, vehicle_road: bool = true) -> void:
 var delta := b - a
 var length := delta.length()
 if length < 0.5:
  return
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(width, 0.08, length)
 mesh.mesh = box
 mesh.material_override = road_mat if vehicle_road else sidewalk_mat
 mesh.position = (a+b)/2.0 + Vector3(0, 0.02, 0)
 mesh.rotation.y = atan2(-delta.x, -delta.z)
 world_root.add_child(mesh)
 if vehicle_road:
  road_segments.append({"a": a, "b": b, "width": width})
  _add_road_details(a, b, width, mesh.rotation.y)

func _add_road_details(a: Vector3, b: Vector3, width: float, angle: float) -> void:
 var length := a.distance_to(b)
 if length < 5.0:
  return
 var midpoint := (a+b)/2.0
 # Marcas centrais são indicativas; o OSM não garante marcações reais.
 if width >= 5.5:
  var forward := (b-a).normalized()
  var dash_count := int(length / 8.0)
  for i in range(dash_count):
   var center := a + forward * (float(i) + 0.5) * 8.0
   var dash := MeshInstance3D.new()
   var dash_mesh := BoxMesh.new()
   dash_mesh.size = Vector3(0.12, 0.015, 2.7)
   dash.mesh = dash_mesh
   dash.material_override = markings_mat
   dash.position = center + Vector3(0, 0.075, 0)
   dash.rotation.y = angle
   world_root.add_child(dash)
 # Passeios geométricos aproximados, não uma medição do passeio real.
 var side := Vector3(cos(angle), 0, -sin(angle))
 for sign_side in [-1.0, 1.0]:
  var walk := MeshInstance3D.new()
  var walk_mesh := BoxMesh.new()
  walk_mesh.size = Vector3(1.35, 0.13, length)
  walk.mesh = walk_mesh
  walk.material_override = sidewalk_mat
  walk.position = midpoint + side * (sign_side * (width/2.0 + 0.75)) + Vector3(0, 0.025, 0)
  walk.rotation.y = angle
  world_root.add_child(walk)

func _building(points: Array, tags: Dictionary) -> void:
 var minx := 1e9
 var maxx := -1e9
 var minz := 1e9
 var maxz := -1e9
 for p in points:
  minx = minf(minx, p.x)
  maxx = maxf(maxx, p.x)
  minz = minf(minz, p.z)
  maxz = maxf(maxz, p.z)
 var w := maxx-minx
 var d := maxz-minz
 if w < 2.0 or d < 2.0:
  return
 # Bounding-box proxy: edifícios NÃO são volumetria fiel.
 var height := 11.0
 if str(tags.get("building:levels", "")).is_valid_float():
  height = clampf(float(tags["building:levels"]) * 3.0, 3.0, 55.0)
 var m := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(w, height, d)
 m.mesh = box
 m.material_override = building_mat
 m.position = Vector3((minx+maxx)/2.0, height/2.0, (minz+maxz)/2.0)
 world_root.add_child(m)
 spawned_buildings += 1

func _place_on_road() -> void:
 if road_segments.is_empty():
  return
 var best: Dictionary = road_segments[0]
 var dist := INF
 for s in road_segments:
  if s.width < 3.0:
   continue
  var mid: Vector3 = (s.a + s.b)/2.0
  if mid.length() < dist:
   dist = mid.length()
   best = s
 car.position = (best.a + best.b)/2.0 + Vector3(0, 0.1, 0)
 var vec: Vector3 = best.b - best.a
 heading = atan2(-vec.x, -vec.z)
 car.rotation.y = heading
 speed = 0.0

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
  overview_mode = not overview_mode
  overview_camera.current = overview_mode
  camera.current = not overview_mode

func _process(delta: float) -> void:
 var accel := Input.is_key_pressed(KEY_UP)
 brakes = Input.is_key_pressed(KEY_DOWN)
 clutch = Input.is_key_pressed(KEY_SHIFT)
 handbrake = Input.is_key_pressed(KEY_SPACE)
 for g in range(0, 6):
  if Input.is_key_pressed(KEY_0 + g) and clutch:
   gear = g
 if Input.is_key_pressed(KEY_R) and not Input.is_key_pressed(KEY_SHIFT):
  _place_on_road()
 var steering := float(Input.is_key_pressed(KEY_LEFT)) - float(Input.is_key_pressed(KEY_RIGHT))
 if gear > 0 and accel and not clutch and not handbrake:
  speed += (3.8 / float(gear)) * delta
 if brakes or handbrake:
  speed -= 9.0 * delta
 else:
  speed -= 0.7 * delta
 speed = clampf(speed, 0.0, 27.0)
 if speed > 0.1:
  heading += steering * delta * clampf(speed / 7.0, 0.15, 1.0) * 0.75
 car.rotation.y = heading
 car.position += -car.global_transform.basis.z * speed * delta
 if map_loaded:
  var on_road := _distance_to_road(car.position) < 1.0
  if not on_road and not last_offroad:
   infractions += 1
  last_offroad = not on_road
 label.text = "Velocidade: %d km/h   |   Mudança: %s   |   Infrações simuladas: %d\n%s" % [roundi(speed*3.6), "N" if gear == 0 else str(gear), infractions, "Fora da via aproximada!" if last_offroad else "Treino livre sobre geometria OSM"]

func _distance_to_road(p: Vector3) -> float:
 var best := INF
 for s in road_segments:
  var a: Vector3 = s.a
  var b: Vector3 = s.b
  var ab: Vector3 = b-a
  var t := clampf((p-a).dot(ab)/maxf(ab.length_squared(), 0.01), 0, 1)
  best = minf(best, (p-(a+ab*t)).length()-s.width/2.0)
 return best
