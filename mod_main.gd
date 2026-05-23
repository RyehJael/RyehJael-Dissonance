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
		"EFFECT_CONDUCTOR_LEVEL_SHIFT": "On level up: {0} from your highest stat, {1} to your lowest stat",
		"CHARACTER_SIREN": "Siren",
		"EFFECT_SIREN_SPAWN_CURSED_ENEMY": "On enemy kill: {0}% chance to spawn a cursed enemy ({1})",
		"EFFECT_SIREN_CURSED_ENEMY_EXTRA_MATERIAL": "Cursed enemies drop {0} extra material",
		"ENEMIES_SPAWNED": "Enemies spawned: {0}",
		"CHARACTER_AEONIAN": "Aeonian",
		"EFFECT_AEONIAN_ROUND_DURATION": "Rounds last {0}s longer for every {1} permanent Max HP [{2}s]",
		"ITEM_STARDUST": "Stardust",
		"EFFECT_ROUND_DURATION_BONUS": "Rounds last +{0}s longer",
		"WEAPON_BATON": "Baton",
		"EFFECT_BATON_STAT_SHIFT": "Every {0} enemies killed by this weapon in a wave: {1} from your highest stat, {2} to your lowest stat"
	}

	ModLoaderMod.install_script_extension(ext_dir + "main.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/item_parent_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/weapon_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/shop/item_description.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/run_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/player_run_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/screenshaker.gd")
	ModLoaderMod.install_script_extension(ext_dir + "dlcs/dlc_1/dlc_1_data.gd")
	_add_translations()


func _ready()->void:
	_register_custom_effects()
	_load_dissonance_content()
	call_deferred("_normalize_stardust_unlock_state")
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


func _register_custom_effects() -> void:
	var baton_shift_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/baton_stat_shift_effect.gd")
	if baton_shift_effect != null and not _has_effect_with_id(baton_shift_effect.get_id()):
		ItemService.effects.push_back(baton_shift_effect)

	var siren_spawn_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/siren/siren_spawn_cursed_enemy_effect.gd")
	if siren_spawn_effect != null and not _has_effect_with_id(siren_spawn_effect.get_id()):
		ItemService.effects.push_back(siren_spawn_effect)

	var siren_safe_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/siren/siren_safe_effect.gd")
	if siren_safe_effect != null and not _has_effect_with_id(siren_safe_effect.get_id()):
		ItemService.effects.push_back(siren_safe_effect)

	var siren_safe_stat_gains_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/siren/siren_safe_stat_gains_modification_effect.gd")
	if siren_safe_stat_gains_effect != null and not _has_effect_with_id(siren_safe_stat_gains_effect.get_id()):
		ItemService.effects.push_back(siren_safe_stat_gains_effect)

	var aeonian_round_duration_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/aeonian/aeonian_round_duration_effect.gd")
	if aeonian_round_duration_effect != null and not _has_effect_with_id(aeonian_round_duration_effect.get_id()):
		ItemService.effects.push_back(aeonian_round_duration_effect)


func _has_effect_with_id(effect_id: String) -> bool:
	for effect in ItemService.effects:
		if effect != null and effect.get_id() == effect_id:
			return true
	return false


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


func _normalize_stardust_unlock_state() -> void:
	var stardust_item_id = "item_stardust"
	var stardust_item_hash = Keys.generate_hash(stardust_item_id)

	if ProgressData.items_unlocked.has(stardust_item_id):
		ProgressData.items_unlocked.erase(stardust_item_id)
		if not ProgressData.items_unlocked.has(stardust_item_hash):
			ProgressData.items_unlocked.push_back(stardust_item_hash)

	var aeonian_challenge_hash = Keys.generate_hash("chal_aeonian")
	var should_unlock_from_challenge = ChallengeService.is_challenge_completed(aeonian_challenge_hash)
	var should_unlock_from_aeonian_clear = false
	var aeonian_hash = Keys.generate_hash("character_aeonian")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(aeonian_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_aeonian_clear = true
			break

	if (should_unlock_from_challenge or should_unlock_from_aeonian_clear) and not ProgressData.items_unlocked.has(stardust_item_hash):
		ProgressData.items_unlocked.push_back(stardust_item_hash)
		ItemService.init_unlocked_pool()
