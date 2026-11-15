extends CharacterBody2D

var movement_speed = 500.0
var is_landed = false
var landing_approved = false
var is_dead = false
var last_normal = Vector2.UP
var current_planet_name = ""

var initial_fuel = 0.0
var initial_oxygen = 0.0
var initial_materials = 0

var message_ui: Label = null
var hud_ui: Label = null

var fuel_consumption = 15.0 
var oxygen_consumption = 5.0   

var nasa_data = {
	"Tierra": {"name_en": "Earth", "gravity": "9.83 m/s²", "escape_vel": 11.19, "escape_fuel": 11.0, "needs_heat": false, "needs_gravity": false},
	"Earth": {"name_en": "Earth", "gravity": "9.83 m/s²", "escape_vel": 11.19, "escape_fuel": 11.0, "needs_heat": false, "needs_gravity": false},
	"Venus": {"name_en": "Venus", "gravity": "8.87 m/s²", "escape_vel": 10.36, "escape_fuel": 10.0, "needs_heat": true, "needs_gravity": true},
	"Marte": {"name_en": "Mars", "gravity": "3.73 m/s²", "escape_vel": 5.03, "escape_fuel": 5.0, "needs_heat": false, "needs_gravity": true},
	"Mars": {"name_en": "Mars", "gravity": "3.73 m/s²", "escape_vel": 5.03, "escape_fuel": 5.0, "needs_heat": false, "needs_gravity": true},
	"Mercurio": {"name_en": "Mercury", "gravity": "3.70 m/s²", "escape_vel": 4.30, "escape_fuel": 4.0, "needs_heat": true, "needs_gravity": true},
	"Mercury": {"name_en": "Mercury", "gravity": "3.70 m/s²", "escape_vel": 4.30, "escape_fuel": 4.0, "needs_heat": true, "needs_gravity": true}
}

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if get_node_or_null("/root/Global1") != null:
		initial_fuel = Global1.fuel
		initial_oxygen = Global1.oxygen
		initial_materials = Global1.materials
		var p1 = "res://cohete1.png"
		var p2 = "res://cohete2.png"
		if Global1.selected_ship == 1 and ResourceLoader.exists(p1):
			$Cohete.texture = load(p1)
		elif Global1.selected_ship == 2 and ResourceLoader.exists(p2):
			$Cohete.texture = load(p2)
			
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	
	hud_ui = Label.new()
	hud_ui.position = Vector2(20, 20)
	hud_ui.add_theme_font_size_override("font_size", 22)
	hud_ui.add_theme_color_override("font_color", Color.WHITE)
	hud_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_ui.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud_ui)
	
	message_ui = Label.new()
	message_ui.position = Vector2(40, 160)
	message_ui.add_theme_font_size_override("font_size", 26)
	message_ui.add_theme_color_override("font_color", Color.YELLOW)
	message_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	message_ui.add_theme_constant_override("outline_size", 8)
	message_ui.hide()
	layer.add_child(message_ui)

func _physics_process(delta):
	if get_node_or_null("/root/Global1") == null:
		return

	if is_dead:
		velocity = Vector2.ZERO
		if Input.is_key_pressed(KEY_R):
			Global1.fuel = initial_fuel
			Global1.oxygen = initial_oxygen
			Global1.materials = initial_materials
			get_tree().reload_current_scene()
		return

	var dist_mkm = snapped(global_position.length() / 30.0, 0.1)
	var h_st = "ON" if (Global1.has_heat_shield or Global1.escudo_calor) else "OFF"
	var g_st = "ON" if (Global1.has_gravity_thrusters or Global1.propulsor_gravedad) else "OFF"
	hud_ui.text = "⛽ Fuel: " + str(int(Global1.fuel)) + " | 🫧 Oxy: " + str(int(Global1.oxygen)) + " | 📦 Mats: " + str(Global1.materials) + "\n🛡️ Heat: " + h_st + " | 🚀 Grav: " + g_st + " | 📡 Dist: " + str(dist_mkm) + "M km"

	if is_landed:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("ui_select"):
			if not landing_approved:
				mostrar_msg("🚫 BLOCKED: Missing Heat/Gravity items!\n[ENTER]: Leave Orbit", Color.RED)
			elif Global1.materials > 0:
				Global1.materials -= 1
				mostrar_msg("📦 Material Delivered! (" + str(Global1.materials) + " left)\n[SPACE]: Deliver | [ENTER]: Take Off", Color.CYAN)
			else:
				mostrar_msg("⚠️ No materials left! [ENTER]: Take Off", Color.ORANGE)
				
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			var cost = nasa_data[current_planet_name]["escape_fuel"] if (nasa_data.has(current_planet_name) and landing_approved) else 2.0
			if Global1.fuel >= cost:
				Global1.fuel -= cost
				is_landed = false
				landing_approved = false
				global_position += last_normal * 25.0
				message_ui.hide()
			else:
				morir("Not enough fuel for take-off! (Need " + str(cost) + ")")
		return

	Global1.oxygen -= oxygen_consumption * delta
	if Global1.oxygen <= 0:
		Global1.oxygen = 0
		morir("Out of Oxygen!")
		return

	var dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		dir.x += 1
		$Cohete.flip_h = false
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1
		$Cohete.flip_h = true
	if Input.is_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		dir.y += 1
		
	if dir != Vector2.ZERO:
		Global1.fuel -= fuel_consumption * delta
		velocity = dir.normalized() * movement_speed
		if Global1.fuel <= 0:
			Global1.fuel = 0
			morir("Out of Fuel!")
			return
	else:
		velocity = Vector2.ZERO

	var col = move_and_collide(velocity * delta)
	if col:
		var obj = col.get_collider()
		last_normal = col.get_normal()
		is_landed = true
		velocity = Vector2.ZERO
		current_planet_name = str(obj.get_parent().name) if (obj != null and obj.get_parent() != null) else "Planet"
		revisar_planeta(current_planet_name)

	if Input.is_action_just_pressed("ui_select"):
		mostrar_msg("⚠️ Land on a planet first!", Color.ORANGE)

func revisar_planeta(key: String):
	var has_h = Global1.has_heat_shield or Global1.escudo_calor
	var has_g = Global1.has_gravity_thrusters or Global1.propulsor_gravedad
	if nasa_data.has(key):
		var d = nasa_data[key]
		var ok_h = (not d["needs_heat"]) or has_h
		var ok_g = (not d["needs_gravity"]) or has_g
		if ok_h and ok_g:
			landing_approved = true
			mostrar_msg("✅ LANDED ON " + d["name_en"].to_upper() + " (" + d["gravity"] + ")\n[SPACE]: Deliver | [ENTER]: Take Off (-" + str(d["escape_fuel"]) + " Fuel)", Color.GREEN)
		else:
			landing_approved = false
			var miss = []
			if d["needs_heat"] and not has_h: miss.append("Heat Shield")
			if d["needs_gravity"] and not has_g: miss.append("Gravity Thrusters")
			mostrar_msg("🚫 LANDING DENIED ON " + d["name_en"].to_upper() + "!\nMissing: " + ", ".join(miss) + "\n[ENTER]: Leave | [R]: Retry", Color.ORANGE_RED)
	else:
		landing_approved = true
		mostrar_msg("✅ LANDED ON " + key.to_upper() + "\n[SPACE]: Deliver | [ENTER]: Take Off", Color.YELLOW)

func mostrar_msg(txt: String, col: Color):
	message_ui.add_theme_color_override("font_color", col)
	message_ui.text = txt
	message_ui.show()

func morir(reason: String):
	is_dead = true
	velocity = Vector2.ZERO
	mostrar_msg("💀 MISSION FAILED: " + reason + "\nPress [R] to Retry", Color.RED)
