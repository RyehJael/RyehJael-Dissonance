extends Node

const MOD_DIR = "RyehJael-Dissonance/"
const DISSONANCE_LOG = "RyehJael-Dissonance"

var dir = ""
var ext_dir = ""
var translations = {}
var dlc_content_loaded = false


func _init():
	ModLoaderLog.info("Init", DISSONANCE_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	ext_dir = dir + "extensions/"
	translations = {
		"CHARACTER_CONDUCTOR": "Conductor",
		"EFFECT_CONDUCTOR_LEVEL_SHIFT": "On level up: [color=#ff4d4d]-5[/color] to your highest non-Max HP primary stat, [color=#66cc66]+2[/color] to your lowest non-Max HP primary stat",
		"WEAPON_BATON": "Baton",
		"EFFECT_BATON_STAT_SHIFT": "Every {0} enemies killed by this weapon in a wave: [color=#ff4d4d]-1[/color] to your highest non-Max HP primary stat, [color=#66cc66]+1[/color] to your lowest non-Max HP primary stat"
	}

	ModLoaderMod.install_script_extension(ext_dir + "singletons/run_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/player_run_data.gd")
	_add_translations()


func _ready()->void:
	_load_dissonance_content()
	var _dlc_activated = ProgressData.connect("dlc_activated", self, "_on_dlc_activated")
	call_deferred("_load_dlc_content_if_available")
	ModLoaderLog.info("Ready", DISSONANCE_LOG)


func _load_dissonance_content()->void:
	var content_loader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	content_loader.load_data(dir + "content_data/dissonance_characters.tres", DISSONANCE_LOG)


func _load_dlc_content_if_available() -> void:
	if dlc_content_loaded:
		return
	if not ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		return

	var content_loader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	content_loader.load_data(dir + "content_data/dissonance_dlc_content.tres", DISSONANCE_LOG)
	dlc_content_loaded = true

	_install_dlc_content_if_needed()
	_normalize_baton_unlock_state()
	ItemService.init_unlocked_pool()
	_add_dlc_starting_weapons()


func _on_dlc_activated(dlc_id: String) -> void:
	if dlc_id != "abyssal_terrors":
		return
	_load_dlc_content_if_available()


func _add_translations() -> void:
	var english_translation = Translation.new()
	english_translation.set_locale("en")
	for key in translations.keys():
		english_translation.add_message(key, translations[key])
	TranslationServer.add_translation(english_translation)


func _install_dlc_content_if_needed() -> void:
	var baton_weapons = [
		load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/1/baton_data.tres"),
		load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/2/baton_2_data.tres"),
		load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/3/baton_3_data.tres"),
		load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/4/baton_4_data.tres")
	]

	var previous_weapon = null
	for weapon in baton_weapons:
		if weapon == null:
			continue
		weapon._generate_hashes()
		if previous_weapon != null:
			weapon.previous_upgrade = previous_weapon
		previous_weapon = weapon
		if not _has_resource_with_id(ItemService.weapons, "my_id", weapon.my_id):
			ItemService.weapons.push_back(weapon)

	var conductor_challenge = load("res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_conductor.tres")
	if conductor_challenge != null:
		conductor_challenge._generate_hashes()
		if conductor_challenge.reward != null:
			conductor_challenge.reward._generate_hashes()
		ChallengeService.hash_to_id[conductor_challenge.my_id_hash] = conductor_challenge.my_id
		if not _has_resource_with_id(ChallengeService.challenges, "my_id", conductor_challenge.my_id):
			ChallengeService.challenges.push_back(conductor_challenge)


func _has_resource_with_id(resources: Array, id_property: String, id_value: String) -> bool:
	for resource in resources:
		if resource != null and resource.get(id_property) == id_value:
			return true
	return false


func _add_dlc_starting_weapons() -> void:
	if not ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		return

	var conductor_data = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/conductor/conductor_data.tres")
	if conductor_data == null:
		return

	var lute_weapon = load("res://dlcs/dlc_1/weapons/melee/lute/1/lute_data.tres")
	if lute_weapon == null:
		return

	var has_lute = false
	for weapon in conductor_data.starting_weapons:
		if weapon != null and weapon.my_id == lute_weapon.my_id:
			has_lute = true
			break
	if not has_lute:
		conductor_data.starting_weapons.push_back(lute_weapon)

	var baton_weapon = load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/1/baton_data.tres")
	if baton_weapon == null:
		return

	for weapon in conductor_data.starting_weapons:
		if weapon != null and weapon.my_id == baton_weapon.my_id:
			return

	conductor_data.starting_weapons.push_back(baton_weapon)


func _normalize_baton_unlock_state() -> void:
	if not ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		return

	var baton_weapon_id = "weapon_baton"
	var baton_weapon_hash = Keys.generate_hash(baton_weapon_id)

	if ProgressData.weapons_unlocked.has(baton_weapon_id):
		ProgressData.weapons_unlocked.erase(baton_weapon_id)
		if not ProgressData.weapons_unlocked.has(baton_weapon_hash):
			ProgressData.weapons_unlocked.push_back(baton_weapon_hash)

	var conductor_challenge_hash = Keys.generate_hash("chal_conductor")
	var should_unlock_from_challenge = ChallengeService.is_challenge_completed(conductor_challenge_hash)
	var should_unlock_from_conductor_clear = false
	var conductor_hash = Keys.generate_hash("character_conductor")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(conductor_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_conductor_clear = true
			break

	if (should_unlock_from_challenge or should_unlock_from_conductor_clear) and not ProgressData.weapons_unlocked.has(baton_weapon_hash):
		ProgressData.weapons_unlocked.push_back(baton_weapon_hash)
