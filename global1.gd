extends Node
signal cambiar_Textura

# Recursos principales (English)
var selected_ship = 1
var fuel = 1000.0
var oxygen = 1000.0
var materials = 5
var coins = 0 # Inicia con 0 monedas
var ship2_unlocked = false # Guarda si ya compró el cohete 2

# Objetos para pasar gravedad y calor
var has_heat_shield = false
var has_gravity_thrusters = false

# Alias en español
var nave_elegida = 1
var gasolina = 1000.0
var oxigeno = 1000.0
var materiales = 15
var monedas = 0
var escudo_calor = true
var propulsor_gravedad = true

# --- PROGRESO DE LAS 4 MISIONES ---
var mars_materials_delivered = 0
var mission_1_done = false # 1. Take 5 materials to Mars
var mission_2_done = false # 2. Go to Mercury and land
var mission_3_done = false # 3. Take materials to any planet
var mission_4_done = false # 4. Go to Venus
