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
var missions_panel: Panel = null
var missions_label: Label = null

var fuel_consumption = 15.0 
var oxygen_consumption = 5.0   

var offset_rotacion_cohete2 = 0.0

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
		
		var p1 = "res://images-removebg-preview.png"
		var p2 = "res://rocket-removebg-preview (2).png"
		var tex_original_size = $Cohete.texture.get_size() if $Cohete.texture != null else Vector2(200, 200)
		var escala_original = $Cohete.scale
		
		if Global1.selected_ship == 1 and ResourceLoader.exists(p1):
			$Cohete.texture = load(p1)
		elif Global1.selected_ship == 2 and ResourceLoader.exists(p2):
			var nueva_tex = load(p2)
			$Cohete.texture = nueva_tex
			if nueva_tex != null and nueva_tex.get_width() > 0:
				var factor = tex_original_size.x / float(nueva_tex.get_width())
				$Cohete.scale = escala_original * factor
			$Cohete.rotation_degrees = offset_rotacion_cohete2
			
	var layer = CanvasLayer.new()
	layer.layer = 120 # Por encima de todo para que el botón siempre reciba clics
	add_child(layer)
	
	# 1. HUD de recursos
	hud_ui = Label.new()
	hud_ui.position = Vector2(210, 15)
	hud_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_ui.add_theme_font_size_override("font_size", 20)
	hud_ui.add_theme_color_override("font_color", Color.WHITE)
	hud_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_ui.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud_ui)
	
	# 2. Mensajes de aterrizaje
	message_ui = Label.new()
	message_ui.position = Vector2(210, 95)
	message_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_ui.add_theme_font_size_override("font_size", 24)
	message_ui.add_theme_color_override("font_color", Color.YELLOW)
	message_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	message_ui.add_theme_constant_override("outline_size", 8)
	message_ui.hide()
	layer.add_child(message_ui)
	
	# 3. Botón directo para abrir/cerrar la lista de Misiones
	var btn_missions = Button.new()
	btn_missions.text = "📋 MISSIONS [TAB]"
	btn_missions.position = Vector2(20, 80)
	btn_missions.custom_minimum_size = Vector2(170, 42)
	btn_missions.pressed.connect(_toggle_missions_list)
	layer.add_child(btn_missions)
	
	# 4. Ventana con la lista de las 4 misiones
	missions_panel = Panel.new()
	missions_panel.position = Vector2(20, 130)
	missions_panel.custom_minimum_size = Vector2(440, 220)
	missions_panel.visible = false
	layer.add_child(missions_panel)
	
	missions_label = Label.new()
	missions_label.position = Vector2(18, 14)
	missions_label.add_theme_font_size_override("font_size", 19)
	missions_label.add_theme_color_override("font_color", Color.WHITE)
	missions_panel.add_child(missions_label)
	
	var btn_close = Button.new()
	btn_close.text = "X"
	btn_close.position = Vector2(395, 8)
	btn_close.custom_minimum_size = Vector2(35, 30)
	btn_close.pressed.connect(func(): missions_panel.visible = false)
	missions_panel.add_child(btn_close)
	
	actualizar_texto_misiones()
	sincronizar_ui_amigo()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_toggle_missions_list()

func _toggle_missions_list():
	if missions_panel != null:
		actualizar_texto_misiones()
		missions_panel.visible = not missions_panel.visible

func actualizar_texto_misiones():
	if missions_label == null or get_node_or_null("/root/Global1") == null:
		return
	var c1 = "✅" if Global1.mission_1_done else "⬜"
	var c2 = "✅" if Global1.mission_2_done else "⬜"
	var c3 = "✅" if Global1.mission_3_done else "⬜"
	var c4 = "✅" if Global1.mission_4_done else "⬜"
	
	missions_label.text = "=== SPACE MISSIONS ===\n\n" + \
		c1 + " 1. Take 5 materials to Mars (" + str(Global1.mars_materials_delivered) + "/5) [+10 Coins]\n" + \
		c2 + " 2. Go to Mercury and land [+10 Coins]\n" + \
		c3 + " 3. Take materials to any planet [+5 Coins]\n" + \
		c4 + " 4. Go to Venus [+5 Coins]"

func _physics_process(delta):
	if get_node_or_null("/root/Global1") == null:
		return

	sincronizar_ui_amigo()

	if Input.is_key_pressed(KEY_M):
		Global1.fuel = initial_fuel
		Global1.oxygen = initial_oxygen
		Global1.materials = initial_materials
		get_tree().change_scene_to_file("res://interfazelegir cohete.tscn")
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
	hud_ui.text = "⛽ Fuel: " + str(int(Global1.fuel)) + " | 🫧 Oxy: " + str(int(Global1.oxygen)) + " | 📦 Mats: " + str(Global1.materials) + " | 🪙 Coins: " + str(Global1.coins) + "\n🛡️ Heat: " + h_st + " | 🚀 Grav: " + g_st + " | 📡 Dist: " + str(dist_mkm) + "M km | [M]: Rocket Shop"

	if is_landed:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("ui_select"):
			if not landing_approved:
				mostrar_msg("🚫 BLOCKED: Missing Heat/Gravity items!\n[ENTER]: Leave Orbit", Color.RED)
			elif Global1.materials > 0:
				Global1.materials -= 1
				var bonus_txt = verificar_misiones_materiales(current_planet_name)
				actualizar_texto_misiones()
				mostrar_msg("📦 Material Delivered! (" + str(Global1.materials) + " left)" + bonus_txt + "\n[SPACE]: Deliver | [ENTER]: Take Off", Color.CYAN)
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

	var extra_rot = offset_rotacion_cohete2 if Global1.selected_ship == 2 else 0.0
	var dir = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_D):
		dir.x += 1
		$Cohete.flip_h = false
		$Cohete.flip_v = false
		$Cohete.rotation_degrees = 0.0 + extra_rot
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1
		if extra_rot == 0.0:
			$Cohete.flip_h = true
			$Cohete.flip_v = false
			$Cohete.rotation_degrees = 0.0
		else:
			$Cohete.flip_h = false
			$Cohete.rotation_degrees = 180.0 + extra_rot
	if Input.is_key_pressed(KEY_W):
		dir.y -= 1
		$Cohete.flip_h = false
		$Cohete.flip_v = false
		$Cohete.rotation_degrees = -90.0 + extra_rot
	if Input.is_key_pressed(KEY_S):
		dir.y += 1
		$Cohete.flip_h = false
		$Cohete.flip_v = false
		$Cohete.rotation_degrees = 90.0 + extra_rot
		
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
	var mission_alert = ""
	
	if key == "Venus" and not Global1.mission_4_done:
		Global1.mission_4_done = true
		dar_monedas(5)
		mission_alert += "\n🏆 MISSION 4 COMPLETE: Go to Venus! (+5 Coins)"

	if nasa_data.has(key):
		var d = nasa_data[key]
		var ok_h = (not d["needs_heat"]) or has_h
		var ok_g = (not d["needs_gravity"]) or has_g
		if ok_h and ok_g:
			landing_approved = true
			if (key == "Mercurio" or key == "Mercury") and not Global1.mission_2_done:
				Global1.mission_2_done = true
				dar_monedas(10)
				mission_alert += "\n🏆 MISSION 2 COMPLETE: Landed on Mercury! (+10 Coins)"
			mostrar_msg("✅ LANDED ON " + d["name_en"].to_upper() + " (" + d["gravity"] + ")" + mission_alert + "\n[SPACE]: Deliver | [ENTER]: Take Off (-" + str(d["escape_fuel"]) + " Fuel)", Color.GREEN)
		else:
			landing_approved = false
			var miss = []
			if d["needs_heat"] and not has_h: miss.append("Heat Shield")
			if d["needs_gravity"] and not has_g: miss.append("Gravity Thrusters")
			mostrar_msg("🚫 LANDING DENIED ON " + d["name_en"].to_upper() + "!" + mission_alert + "\nMissing: " + ", ".join(miss) + "\n[ENTER]: Leave | [R]: Retry", Color.ORANGE_RED)
	else:
		landing_approved = true
		mostrar_msg("✅ LANDED ON " + key.to_upper() + mission_alert + "\n[SPACE]: Deliver | [ENTER]: Take Off", Color.YELLOW)
	actualizar_texto_misiones()

func verificar_misiones_materiales(key: String) -> String:
	var txt = ""
	if key != "Tierra" and key != "Earth" and not Global1.mission_3_done:
		Global1.mission_3_done = true
		dar_monedas(5)
		txt += "\n🏆 MISSION 3 COMPLETE: Delivered to a planet! (+5 Coins)"
		
	if key == "Marte" or key == "Mars":
		Global1.mars_materials_delivered += 1
		if Global1.mars_materials_delivered >= 5 and not Global1.mission_1_done:
			Global1.mission_1_done = true
			dar_monedas(10)
			txt += "\n🏆 MISSION 1 COMPLETE: 5 Materials on Mars! (+10 Coins)"
		elif not Global1.mission_1_done:
			txt += " [Mars: " + str(Global1.mars_materials_delivered) + "/5]"
	return txt

func dar_monedas(cantidad: int):
	Global1.coins += cantidad
	Global1.monedas = Global1.coins
	sincronizar_ui_amigo()

func sincronizar_ui_amigo():
	var nodo_monedas = get_parent().get_node_or_null("CanvasLayer/monedas")
	if nodo_monedas != null:
		for hijo in nodo_monedas.find_children("*", "Label", true, false):
			hijo.text = str(Global1.coins)

func mostrar_msg(txt: String, col: Color):
	message_ui.add_theme_color_override("font_color", col)
	message_ui.text = txt
	message_ui.show()

func morir(reason: String):
	is_dead = true
	velocity = Vector2.ZERO
	mostrar_msg("💀 MISSION FAILED: " + reason + "\nPress [R] to Retry | [M]: Shop", Color.RED)
