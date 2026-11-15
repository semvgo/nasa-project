extends CharacterBody2D

var movement_speed = 500.0
var is_landed = false
var landing_approved = false
var is_dead = false
var last_normal = Vector2.UP
var current_planet_name = ""

# Store initial player choices to restore on retry ('R')
var initial_fuel = 0.0
var initial_oxygen = 0.0
var initial_materials = 0

var message_ui: Label = null
var hud_ui: Label = null

# Consumption rates per second (Scale: 30 px = 1 Million km)
var fuel_consumption = 15.0 
var oxygen_consumption = 5.0   

# NASA Planetary Data + Required Items (Heat & Gravity)
var nasa_data = {
	"Tierra": {
		"name_en": "Earth", "gravity": "9.83 m/s²", "escape_vel": 11.19, "escape_fuel": 11.0,
		"needs_heat": false, "needs_gravity": false
	},
	"Earth": {
		"name_en": "Earth", "gravity": "9.83 m/s²", "escape_vel": 11.19, "escape_fuel": 11.0,
		"needs_heat": false, "needs_gravity": false
	},
	"Venus": {
		"name_en": "Venus", "gravity": "8.87 m/s²", "escape_vel": 10.36, "escape_fuel": 10.0,
		"needs_heat": true, "needs_gravity": true
	},
	"Marte": {
		"name_en": "Mars", "gravity": "3.73 m/s²", "escape_vel": 5.03, "escape_fuel": 5.0,
		"needs_heat": false, "needs_gravity": true
	},
	"Mars": {
		"name_en": "Mars", "gravity": "3.73 m/s²", "escape_vel": 5.03, "escape_fuel": 5.0,
		"needs_heat": false, "needs_gravity": true
	},
	"Mercurio": {
		"name_en": "Mercury", "gravity": "3.70 m/s²", "escape_vel": 4.30, "escape_fuel": 4.0,
		"needs_heat": true, "needs_gravity": true
	},
	"Mercury": {
		"name_en": "Mercury", "gravity": "3.70 m/s²", "escape_vel": 4.30, "escape_fuel": 4.0,
		"needs_heat": true, "needs_gravity": true
	}
}

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	if get_node_or_null("/root/Global1") != null:
		initial_fuel = Global1.fuel
		initial_oxygen = Global1.oxygen
		initial_materials = Global1.materials
		
		var path_1 = "res://cohete1.png"
		var path_2 = "res://cohete2.png"
		if Global1.selected_ship == 1 and ResourceLoader.exists(path_1):
			$Cohete.texture = load(path_1)
		elif Global1.selected_ship == 2 and ResourceLoader.exists(path_2):
			$Cohete.texture = load(path_2)
			
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	
	# English HUD (Top-Left)
	hud_ui = Label.new()
	hud_ui.position = Vector2(20, 20)
	hud_ui.add_theme_font_size_override("font_size", 22)
	hud_ui.add_theme_color_override("font_color", Color.WHITE)
	hud_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_ui.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud_ui)
	
	# English Alert / Landing Banner
	message_ui = Label.new()
	message_ui.position = Vector2(40, 190)
	message_ui.add_theme_font_size_override("font_size", 26)
	message_ui.add_theme_color_override("font_color", Color.YELLOW)
	message_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	message_ui.add_theme_constant_override("outline_size", 8)
	message_ui.hide()
	layer.add_child(message_ui)

func _physics_process(delta):
	if get_node_or_null("/root/Global1") == null:
		return

	# 1. GAME OVER: Press 'R' to Retry
	if is_dead:
		velocity = Vector2.ZERO
		if Input.is_key_pressed(KEY_R):
			Global1.fuel = initial_fuel
			Global1.oxygen = initial_oxygen
			Global1.materials = initial_materials
			get_tree().reload_current_scene()
		return

	update_hud()

	# 2. LANDED / ORBIT HOLD STATE
	if is_landed:
		velocity = Vector2.ZERO
		
		# Deploy materials with SPACE (Only works if landing_approved is true)
		if Input.is_action_just_pressed("ui_select"):
			deploy_materials()
			
		# Take off with ENTER
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			var escape_cost = 5.0
			if nasa_data.has(current_planet_name):
				escape_cost = nasa_data[current_planet_name]["escape_fuel"]
				
			if not landing_approved:
				escape_cost = 2.0 # Lower cost if rejected at orbit
				
			if Global1.fuel >= escape_cost:
				Global1.fuel -= escape_cost
				is_landed = false
				landing_approved = false
				global_position += last_normal * 25.0
				message_ui.hide()
				update_hud()
			else:
				die("NOT ENOUGH FUEL TO REACH ESCAPE VELOCITY!\nRequired: " + str(escape_cost) + " Fuel.")
		return

	# 3. OXYGEN CONSUMPTION IN SPACE
	Global1.oxygen -= oxygen_consumption * delta
	if Global1.oxygen <= 0:
		Global1.oxygen = 0
		update_hud()
		die("OUT OF OXYGEN IN DEEP SPACE!")
		return

	# 4. WASD MOVEMENT & FUEL CONSUMPTION
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
		$Cohete.flip_h = false
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
		$Cohete.flip_h = true
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
		
	if direction != Vector2.ZERO:
		if Global1.fuel > 0:
			Global1.fuel -= fuel_consumption * delta
			velocity = direction.normalized() * movement_speed
			if Global1.fuel <= 0:
				Global1.fuel = 0
				update_hud()
				die("OUT OF FUEL! Adrift in deep space.")
				return
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	# 5. COLLISION & ITEM CHECK (HEAT & GRAVITY)
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider_obj = collision.get_collider()
		last_normal = collision.get_normal()
		
		is_landed = true
		velocity = Vector2.ZERO
		
		current_planet_name = "Planet"
		if collider_obj != null and collider_obj.get_parent() != null:
			current_planet_name = str(collider_obj.get_parent().name)
			
		check_planet_items(current_planet_name)

	# 6. BLOCK DEPLOYING MATERIALS IN OPEN SPACE
	if Input.is_action_just_pressed("ui_select"):
		message_ui.add_theme_color_override("font_color", Color.ORANGE)
		message_ui.text = "⚠️ CANNOT DEPLOY MATERIALS IN OPEN SPACE!\nLand on a planet first."
		message_ui.show()

func check_planet_items(planet_key: String):
	var english_name = planet_key
	var player_has_heat = Global1.has_heat_shield or Global1.escudo_calor
	var player_has_grav = Global1.has_gravity_thrusters or Global1.propulsor_gravedad
	
	if nasa_data.has(planet_key):
		var d = nasa_data[planet_key]
		english_name = d["name_en"]
		var req_heat = d["needs_heat"]
		var req_grav = d["needs_gravity"]
		
		var can_pass_heat = (not req_heat) or player_has_heat
		var can_pass_grav = (not req_grav) or player_has_grav
		
		# Si tiene los objetos requeridos para pasar el calor y la gravedad
		if can_pass_heat and can_pass_grav:
			landing_approved = true
			var nasa_info = "\nSurface Gravity: " + d["gravity"] + " | Escape Velocity: " + str(d["escape_vel"]) + " km/s" + \
							"\nTake-off Fuel Cost: " + str(d["escape_fuel"])
			var msg_mats = "\n✅ Press SPACE to deploy Materials (" + str(Global1.materials) + " left)"
			
			message_ui.add_theme_color_override("font_color", Color.GREEN)
			message_ui.text = "SUCCESSFUL LANDING ON " + english_name.to_upper() + "!" + nasa_info + msg_mats + "\nPress ENTER to Take Off"
		else:
			# Si NO tiene los objetos para pasar la gravedad o el calor
			landing_approved = false
			var missing_items = ""
			if req_heat and not player_has_heat:
				missing_items += "\n❌ Missing Item: HEAT SHIELD (Required for extreme planetary temperatures)"
			if req_grav and not player_has_grav:
				missing_items += "\n❌ Missing Item: GRAVITY THRUSTERS (Required to overcome " + d["gravity"] + " gravity)"
				
			message_ui.add_theme_color_override("font_color", Color.ORANGE_RED)
			message_ui.text = "🚫 LANDING DENIED ON " + english_name.to_upper() + "!\n" + \
							  "Cannot pass planetary Heat/Gravity without required items:" + missing_items + \
							  "\n⚠️ Deploying materials & surface actions LOCKED.\nPress ENTER to leave orbit or 'R' to Retry."
	else:
		landing_approved = true
		message_ui.add_theme_color_override("font_color", Color.YELLOW)
		message_ui.text = "LANDED ON " + english_name.to_upper() + "\nPress SPACE to deploy Materials | Press ENTER to Take Off"
		
	message_ui.show()

func deploy_materials():
	if not landing_approved:
		message_ui.add_theme_color_override("font_color", Color.RED)
		message_ui.text = "🚫 ACTION BLOCKED: You lack the required Heat/Gravity items to land here!\nCannot deploy materials. Press ENTER to leave."
		message_ui.show()
		return
		
	if Global1.materials > 0:
		Global1.materials -= 1
		var new_object = ColorRect.new()
		new_object.color = Color.GREEN
		new_object.size = Vector2(30, 30)
		new_object.global_position = global_position + (last_normal * -20.0)
		get_parent().add_child(new_object)
		update_hud()
		
		message_ui.add_theme_color_override("font_color", Color.CYAN)
		message_ui.text = "📦 MATERIAL DEPLOYED ON SURFACE!\nMaterials remaining: " + str(Global1.materials) + "\nPress SPACE to deploy more or ENTER to Take Off."
		message_ui.show()
	else:
		message_ui.add_theme_color_override("font_color", Color.ORANGE)
		message_ui.text = "NO MATERIALS LEFT TO DEPLOY!\nPress ENTER to Take Off."
		message_ui.show()

func update_hud():
	var current_distance_mkm = global_position.length() / 30.0
	var heat_status = "YES" if (Global1.has_heat_shield or Global1.escudo_calor) else "NO"
	var grav_status = "YES" if (Global1.has_gravity_thrusters or Global1.propulsor_gravedad) else "NO"
	
	hud_ui.text = "⛽ Fuel: " + str(int(Global1.fuel)) + " | 🫧 Oxygen: " + str(int(Global1.oxygen)) + " | 📦 Materials: " + str(Global1.materials) + "\n" + \
				  "🛡️ Heat Shield: " + heat_status + " | 🚀 Gravity Thrusters: " + grav_status + "\n" + \
				  "📡 Distance from Earth: " + str(snapped(current_distance_mkm, 0.1)) + "M km"

func die(reason: String):
	is_dead = true
	velocity = Vector2.ZERO
	message_ui.add_theme_color_override("font_color", Color.RED)
	message_ui.text = "💀 MISSION FAILED 💀\n" + reason + "\nPress 'R' to Retry"
	message_ui.show()
