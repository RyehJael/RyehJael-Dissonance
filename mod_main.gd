extends Node

const MOD_DIR = "RyehJael-Dissonance/"
const DISSONANCE_LOG = "RyehJael-Dissonance"
const ABYSSAL_TERRORS_DLC_ID = "abyssal_terrors"
const DLC_1_DATA_PATH = "res://dlcs/dlc_1/dlc_1_data.gd"
const DLC_LUTE_WEAPON_PATH = "res://dlcs/dlc_1/weapons/melee/lute/1/lute_data.tres"
const DLC_FLUTE_WEAPON_PATH = "res://dlcs/dlc_1/weapons/ranged/flute/1/flute_data.tres"
const DLC_HIKING_STICK_WEAPON_PATH = "res://dlcs/dlc_1/weapons/melee/hiking_stick/1/hiking_stick_data.tres"
const DLC_MUSICAL_SET_PATH = "res://dlcs/dlc_1/sets/musical/musical_set_data.tres"
const DLC_NAVAL_SET_PATH = "res://dlcs/dlc_1/sets/naval/naval_set_data.tres"
const DISSONANCE_BATON_WEAPON_PATH = "res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/1/baton_data.tres"
const DISSONANCE_CONCH_WEAPON_PATH = "res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/1/conch_data.tres"
const DISSONANCE_CONCH_WEAPON_PATHS = [
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/1/conch_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/2/conch_2_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/3/conch_3_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/4/conch_4_data.tres",
]
const DISSONANCE_BATON_WEAPON_PATHS = [
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/1/baton_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/2/baton_2_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/3/baton_3_data.tres",
	"res://mods-unpacked/RyehJael-Dissonance/content/weapons/melee/baton/4/baton_4_data.tres",
]
const DissonanceDifficultyRecords = preload("res://mods-unpacked/RyehJael-Dissonance/extensions/dissonance_difficulty_records.gd")
const DISSONANCE_CHARACTER_IDS = [
	"character_aeonian",
	"character_conductor",
	"character_influencer",
	"character_poet",
	"character_producer",
	"character_siren",
]

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
		"EFFECT_SIREN_SPAWN_CURSED_ENEMY": "On enemy kill: {0}% ({1}) chance to spawn an extra cursed enemy",
		"EFFECT_SIREN_CURSED_ENEMY_EXTRA_MATERIAL": "Cursed enemies drop {0} extra material",
		"ENEMIES_SPAWNED": "Enemies spawned: {0}",
		"CHARACTER_AEONIAN": "Aeonian",
		"EFFECT_AEONIAN_ROUND_DURATION": "Rounds last {0}s longer for every {1} permanent Max HP [{2}s]",
		"CHARACTER_POET": "Poet",
		"EFFECT_POET_CURSE_SHOP_REROLL": "Shop refreshes cost {0} Curse instead of materials",
		"EFFECT_POET_ENEMY_SCALING": "Enemies have {0}% Max HP and {0}% damage for every {1} {2} [{3}%]",
		"CHARACTER_INFLUENCER": "Influencer",
		"EFFECT_INFLUENCER_BAN_HARVESTING": "On item ban: gain {0} {1}",
		"EFFECT_INFLUENCER_BONUS_BAN": "Every {0} items/weapons bought: gain {1} bonus Ban",
		"CHARACTER_PRODUCER": "Producer",
		"EFFECT_PRODUCER_PET_AFFINITY": "While within {0}({3}) range of a pet for {1}s: gain {2} of that pet's related stat ",
		"CHAL_UNLOCK_AEONIAN": "Aeonian",
		"CHAL_UNLOCK_CONDUCTOR": "Conductor",
		"CHAL_UNLOCK_INFLUENCER": "Influencer",
		"CHAL_UNLOCK_POET": "Poet",
		"CHAL_UNLOCK_PRODUCER": "Producer",
		"CHAL_UNLOCK_SIREN": "Siren",
		"CHAL_DISSONANCE_REACH_WAVE": "Reach wave {0}",
		"CHAL_DISSONANCE_PRIMARY_STATS": "Have at least {0} of every primary stat",
		"CHAL_DISSONANCE_BAN_ITEMS": "Ban {0} items in a single run",
		"CHAL_DISSONANCE_REACH_STAT": "Reach {0} {1}",
		"CHAL_DISSONANCE_CURSED_KILLS_WAVE": "Kill {0} cursed enemies in a single wave",
		"CHAL_DISSONANCE_OWN_PETS_AT_ONCE": "Own {0} pets at one time",
		"ITEM_STARDUST": "Stardust",
		"EFFECT_ROUND_DURATION_BONUS": "Rounds last +{0}s longer",
		"WEAPON_CONCH": "Conch",
		"EFFECT_CONCH_SPAWN_CURSED_ENEMY": "{0}% chance to spawn an extra cursed enemy when killing an enemy with this weapon",
		"WEAPON_BATON": "Baton",
		"EFFECT_BATON_STAT_SHIFT": "Every {0} enemies killed by this weapon in a wave: {1} from your highest stat, {2} to your lowest stat",
		"ITEM_CASH_COW": "Cash Cow",
		"EFFECT_CASH_COW": "Spawns a Cash Cow that eats and stores materials. At the end of each wave, held materials increase by {0}%. While you are nearby, it cannot move and heals at {1}% of your HP Regeneration rate. Drops all stored materials when killed.",
		"MATERIALS_HELD": "Materials held: {0}",
		"ITEM_BLACK_NOTEBOOK": "Black Notebook",
		"EFFECT_BLACK_NOTEBOOK_XP_FROM_CURSED_ENEMY": "Cursed enemy kills have a {0}% chance to give {1} XP ({2})",
		"XP_GAINED": "XP gained: {0}",
		"ITEM_DISTURBING_PHOTO": "Disturbing Photo",
		"EFFECT_DISTURBING_PHOTO_BAN": "The next non-unique item bought is banned",
		"ITEM_TORN_PHOTO": "Torn Photo",
		"EFFECT_TORN_PHOTO": "The photo has been torn",
		"CASH_COW_NAME": "Cash Cow",
		"CASH_COW_BEHAVIOUR_DESCRIPTION": "Moves toward materials and eats them. While you are nearby, it cannot move and heals from half your HP Regeneration rate. Enemies can target and kill it. When killed, it drops all held materials and stays dead until the next wave."
	}

	ModLoaderMod.install_script_extension(ext_dir + "main.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/item_parent_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/weapon_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/shop/base_shop.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/shop/item_description.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/progress_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/run_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/player_run_data.gd")
	ModLoaderMod.install_script_extension(ext_dir + "global/screenshaker.gd")
	if _resource_exists(DLC_1_DATA_PATH):
		ModLoaderMod.install_script_extension(ext_dir + "dlcs/dlc_1/dlc_1_data.gd")
	_add_translations()


func _ready()->void:
	_register_custom_effects()
	_load_dissonance_content()
	DissonanceDifficultyRecords.restore_records()
	call_deferred("_register_dissonance_challenges")
	call_deferred("_normalize_dissonance_character_difficulty_states")
	call_deferred("_normalize_dissonance_character_unlock_states")
	call_deferred("_add_conch_starting_weapons")
	call_deferred("_normalize_stardust_unlock_state")
	call_deferred("_normalize_cash_cow_unlock_state")
	call_deferred("_normalize_black_notebook_unlock_state")
	call_deferred("_normalize_disturbing_photo_unlock_state")
	call_deferred("_normalize_conch_unlock_state")
	if ProgressData.has_signal("dlc_activated"):
		var _dlc_activated = ProgressData.connect("dlc_activated", self, "_on_dlc_activated")
	call_deferred("_load_dlc_content_if_available")
	ModLoaderLog.info("Ready", DISSONANCE_LOG)


func _load_dissonance_content()->void:
	_load_content_data_safe(dir + "content_data/dissonance_characters.tres")
	_load_content_data_safe(dir + "content_data/dissonance_conch.tres")


func _load_dlc_content_if_available() -> void:
	if dlc_content_loaded:
		return
	if not _is_abyssal_terrors_available():
		return

	if not _load_content_data_safe(dir + "content_data/dissonance_dlc_content.tres"):
		return
	dlc_content_loaded = true

	_install_dlc_content_if_needed()
	_apply_dlc_weapon_sets()
	_normalize_baton_unlock_state()
	ItemService.init_unlocked_pool()
	_add_dlc_starting_weapons()
	_add_conch_starting_weapons()


func _on_dlc_activated(dlc_id: String) -> void:
	if dlc_id != ABYSSAL_TERRORS_DLC_ID:
		return
	_load_dlc_content_if_available()


func _load_content_data_safe(content_path: String) -> bool:
	var content_data = load(content_path)
	if content_data == null:
		ModLoaderLog.error("Could not load ContentData: " + content_path, DISSONANCE_LOG)
		return false

	_install_content_data(content_data)
	return true


func _install_content_data(content_data) -> void:
	_add_content_resources(content_data.items, ItemService.items, "my_id")
	_add_content_resources(content_data.weapons, ItemService.weapons, "my_id")
	_add_content_resources(content_data.characters, ItemService.characters, "my_id")
	_add_content_resources(content_data.sets, ItemService.sets, "my_id")
	_add_content_resources(content_data.upgrades, ItemService.upgrades, "my_id")
	_add_content_resources(content_data.consumables, ItemService.consumables, "my_id")
	_add_content_resources(content_data.elites, ItemService.elites, "my_id")
	_add_content_resources(content_data.difficulties, ItemService.difficulties, "my_id")

	for challenge in content_data.challenges:
		_register_challenge_resource(challenge)

	_add_debug_resources(content_data.debug_items, DebugService.debug_items)
	_add_debug_resources(content_data.debug_weapons, DebugService.debug_weapons)
	_link_weapon_upgrades(content_data.weapons)
	_apply_content_weapon_characters(content_data.weapons, content_data.weapons_characters)
	_add_unlocked_by_default_for_content_data(content_data)
	ItemService.init_unlocked_pool()


func _add_content_resources(resources: Array, target: Array, id_property: String) -> void:
	for resource in resources:
		if resource == null:
			continue
		_generate_resource_hashes(resource)
		if not _has_resource_with_id(target, id_property, resource.get(id_property)):
			target.push_back(resource)


func _register_challenge_resource(challenge) -> void:
	if challenge == null:
		return
	_generate_resource_hashes(challenge)
	ChallengeService.hash_to_id[challenge.my_id_hash] = challenge.my_id
	if not _has_resource_with_id(ChallengeService.challenges, "my_id", challenge.my_id):
		ChallengeService.challenges.push_back(challenge)
	ChallengeService._challenge_map.clear()


func _add_debug_resources(resources: Array, target: Array) -> void:
	for resource in resources:
		if resource == null:
			continue
		_generate_resource_hashes(resource)
		if not _has_resource_with_id(target, "my_id", resource.my_id):
			target.push_back(resource)


func _link_weapon_upgrades(weapons: Array) -> void:
	for weapon in weapons:
		if weapon != null and weapon.upgrades_into != null:
			weapon.upgrades_into.previous_upgrade = weapon


func _apply_content_weapon_characters(weapons: Array, weapons_characters: Array) -> void:
	for weapon_index in weapons_characters.size():
		if weapon_index >= weapons.size():
			continue
		var weapon = weapons[weapon_index]
		if weapon == null:
			continue
		for character in weapons_characters[weapon_index]:
			if character == null:
				continue
			_add_starting_weapon_to_character(character.my_id, weapon)


func _add_unlocked_by_default_for_content_data(content_data) -> void:
	for item in content_data.items:
		if item != null and item.unlocked_by_default and not ProgressData.items_unlocked.has(item.my_id_hash):
			ProgressData.items_unlocked.push_back(item.my_id_hash)

	for weapon in content_data.weapons:
		if weapon != null and weapon.unlocked_by_default and not ProgressData.weapons_unlocked.has(weapon.weapon_id_hash):
			ProgressData.weapons_unlocked.push_back(weapon.weapon_id_hash)

	for character in content_data.characters:
		if character == null:
			continue
		if character.unlocked_by_default and not ProgressData.characters_unlocked.has(character.my_id_hash):
			ProgressData.characters_unlocked.push_back(character.my_id_hash)
		_ensure_character_difficulty_info(character)

	for upgrade in content_data.upgrades:
		if upgrade != null and upgrade.unlocked_by_default and not ProgressData.upgrades_unlocked.has(upgrade.upgrade_id_hash):
			ProgressData.upgrades_unlocked.push_back(upgrade.upgrade_id_hash)

	for consumable in content_data.consumables:
		if consumable != null and consumable.unlocked_by_default and not ProgressData.consumables_unlocked.has(consumable.my_id_hash):
			ProgressData.consumables_unlocked.push_back(consumable.my_id_hash)


func _ensure_character_difficulty_info(character: CharacterData) -> void:
	if character == null:
		return
	if DissonanceDifficultyRecords.is_dissonance_character_id(character.my_id):
		DissonanceDifficultyRecords.restore_records()
		return
	_ensure_character_difficulty_info_for_id(character.my_id)


func _normalize_dissonance_character_difficulty_states() -> void:
	DissonanceDifficultyRecords.restore_records()


func _ensure_character_difficulty_info_for_id(character_id: String) -> void:
	var character_diff_info = _get_or_create_character_difficulty_info(character_id)
	var existing_zone_ids := []

	for zone_diff_info in character_diff_info.zones_difficulty_info:
		existing_zone_ids.push_back(zone_diff_info.zone_id)

	for zone in ZoneService.zones:
		if zone.unlocked_by_default and not existing_zone_ids.has(zone.my_id):
			character_diff_info.zones_difficulty_info.push_back(ZoneDifficultyInfo.new(zone.my_id))


func _get_or_create_character_difficulty_info(character_id: String):
	var character_hash = Keys.generate_hash(character_id)
	var character_diff_info = null
	var duplicate_infos := []

	for difficulty_info in ProgressData.difficulties_unlocked:
		if difficulty_info == null:
			continue
		if difficulty_info.character_id != character_id and difficulty_info.character_id_hash != character_hash:
			continue
		if character_diff_info == null:
			character_diff_info = difficulty_info
		else:
			duplicate_infos.push_back(difficulty_info)

	if character_diff_info == null:
		character_diff_info = CharacterDifficultyInfo.new(character_id)
		ProgressData.difficulties_unlocked.push_back(character_diff_info)
	else:
		character_diff_info.character_id = character_id
		character_diff_info.character_id_hash = character_hash

	for duplicate_info in duplicate_infos:
		_merge_character_difficulty_info(character_diff_info, duplicate_info)
		ProgressData.difficulties_unlocked.erase(duplicate_info)

	return character_diff_info


func _merge_character_difficulty_info(target_info, source_info) -> void:
	for source_zone_info in source_info.zones_difficulty_info:
		var target_zone_info = _get_zone_difficulty_info(target_info, source_zone_info.zone_id)
		if target_zone_info == null:
			target_info.zones_difficulty_info.push_back(source_zone_info)
		else:
			target_zone_info.deserialize_and_merge_take_max(source_zone_info.serialize())


func _get_zone_difficulty_info(character_diff_info, zone_id: int):
	for zone_diff_info in character_diff_info.zones_difficulty_info:
		if zone_diff_info.zone_id == zone_id:
			return zone_diff_info
	return null


func _generate_resource_hashes(resource) -> void:
	if resource != null and resource.has_method("_generate_hashes"):
		resource._generate_hashes()


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

	var poet_curse_reroll_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/poet/poet_curse_shop_reroll_effect.gd")
	if poet_curse_reroll_effect != null and not _has_effect_with_id(poet_curse_reroll_effect.get_id()):
		ItemService.effects.push_back(poet_curse_reroll_effect)

	var poet_enemy_scaling_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/poet/poet_enemy_scaling_effect.gd")
	if poet_enemy_scaling_effect != null and not _has_effect_with_id(poet_enemy_scaling_effect.get_id()):
		ItemService.effects.push_back(poet_enemy_scaling_effect)

	var influencer_ban_harvesting_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/influencer/influencer_ban_harvesting_effect.gd")
	if influencer_ban_harvesting_effect != null and not _has_effect_with_id(influencer_ban_harvesting_effect.get_id()):
		ItemService.effects.push_back(influencer_ban_harvesting_effect)

	var influencer_bonus_ban_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/influencer/influencer_bonus_ban_effect.gd")
	if influencer_bonus_ban_effect != null and not _has_effect_with_id(influencer_bonus_ban_effect.get_id()):
		ItemService.effects.push_back(influencer_bonus_ban_effect)

	var conch_spawn_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/conch_spawn_cursed_enemy_effect.gd")
	if conch_spawn_effect != null and not _has_effect_with_id(conch_spawn_effect.get_id()):
		ItemService.effects.push_back(conch_spawn_effect)

	var cash_cow_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_effect.gd")
	if cash_cow_effect != null and not _has_effect_with_id(cash_cow_effect.get_id()):
		ItemService.effects.push_back(cash_cow_effect)

	var black_notebook_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/items/black_notebook/black_notebook_xp_from_cursed_enemy_effect.gd")
	if black_notebook_effect != null and not _has_effect_with_id(black_notebook_effect.get_id()):
		ItemService.effects.push_back(black_notebook_effect)

	var disturbing_photo_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/items/disturbing_photo/disturbing_photo_ban_effect.gd")
	if disturbing_photo_effect != null and not _has_effect_with_id(disturbing_photo_effect.get_id()):
		ItemService.effects.push_back(disturbing_photo_effect)

	var producer_pet_affinity_effect = load("res://mods-unpacked/RyehJael-Dissonance/content/characters/producer/producer_pet_affinity_effect.gd")
	if producer_pet_affinity_effect != null and not _has_effect_with_id(producer_pet_affinity_effect.get_id()):
		ItemService.effects.push_back(producer_pet_affinity_effect)


func _register_dissonance_challenges() -> void:
	for challenge_path in [
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_aeonian.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_influencer.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_poet.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_producer.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_conductor.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_siren.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_aeonian.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_conductor.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_influencer.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_poet.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_producer.tres",
		"res://mods-unpacked/RyehJael-Dissonance/content/challenges/chal_unlock_siren.tres"
	]:
		var challenge = load(challenge_path)
		if challenge == null:
			continue
		challenge._generate_hashes()
		ChallengeService.hash_to_id[challenge.my_id_hash] = challenge.my_id
		if not _has_resource_with_id(ChallengeService.challenges, "my_id", challenge.my_id):
			ChallengeService.challenges.push_back(challenge)
	ChallengeService._challenge_map.clear()


func _normalize_dissonance_character_unlock_states() -> void:
	for character_id in DISSONANCE_CHARACTER_IDS:
		var challenge_id = "chal_unlock_" + character_id.replace("character_", "")
		_normalize_dissonance_character_unlock(character_id, challenge_id)


func _normalize_dissonance_character_unlock(character_id: String, challenge_id: String) -> void:
	var character_hash = Keys.generate_hash(character_id)
	var challenge_hash = Keys.generate_hash(challenge_id)
	var is_unlocked = ProgressData.is_unlock_all_save() or ChallengeService.is_challenge_completed(challenge_hash)

	if ProgressData.characters_unlocked.has(character_id):
		ProgressData.characters_unlocked.erase(character_id)
	if ProgressData.characters_unlocked.has(character_hash):
		ProgressData.characters_unlocked.erase(character_hash)

	if is_unlocked:
		ProgressData.characters_unlocked.push_back(character_hash)


func _has_effect_with_id(effect_id: String) -> bool:
	for effect in ItemService.effects:
		if effect != null and effect.get_id() == effect_id:
			return true
	return false


func _install_dlc_content_if_needed() -> void:
	var baton_weapons = [
		_load_optional_resource(DISSONANCE_BATON_WEAPON_PATHS[0]),
		_load_optional_resource(DISSONANCE_BATON_WEAPON_PATHS[1]),
		_load_optional_resource(DISSONANCE_BATON_WEAPON_PATHS[2]),
		_load_optional_resource(DISSONANCE_BATON_WEAPON_PATHS[3])
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
	if not _is_abyssal_terrors_available():
		return

	var lute_weapon = _load_optional_resource(DLC_LUTE_WEAPON_PATH)
	if lute_weapon != null:
		_add_starting_weapon_to_character("character_conductor", lute_weapon)
		_add_starting_weapon_to_character("character_siren", lute_weapon)
		_add_starting_weapon_to_character("character_poet", lute_weapon)

	var flute_weapon = _load_optional_resource(DLC_FLUTE_WEAPON_PATH)
	if flute_weapon != null:
		_add_starting_weapon_to_character("character_siren", flute_weapon)
		_add_starting_weapon_to_character("character_poet", flute_weapon)

	var hiking_stick_weapon = _load_optional_resource(DLC_HIKING_STICK_WEAPON_PATH)
	if hiking_stick_weapon != null:
		_add_starting_weapon_to_character("character_siren", hiking_stick_weapon)

	var baton_weapon = _load_optional_resource(DISSONANCE_BATON_WEAPON_PATH)
	if baton_weapon != null:
		_add_starting_weapon_to_character("character_conductor", baton_weapon)


func _apply_dlc_weapon_sets() -> void:
	var musical_set = _load_optional_resource(DLC_MUSICAL_SET_PATH)
	var naval_set = _load_optional_resource(DLC_NAVAL_SET_PATH)

	for weapon_path in DISSONANCE_CONCH_WEAPON_PATHS:
		var conch_weapon = _load_optional_resource(weapon_path)
		if conch_weapon == null:
			continue
		if musical_set != null:
			_add_set_to_weapon(conch_weapon, musical_set)
		if naval_set != null:
			_add_set_to_weapon(conch_weapon, naval_set)

	if musical_set == null:
		return

	for weapon_path in DISSONANCE_BATON_WEAPON_PATHS:
		var baton_weapon = _load_optional_resource(weapon_path)
		if baton_weapon != null:
			_add_set_to_weapon(baton_weapon, musical_set)


func _add_set_to_weapon(weapon: WeaponData, set_data: Resource) -> void:
	_generate_resource_hashes(set_data)
	for existing_set in weapon.sets:
		if existing_set != null and existing_set.get("my_id") == set_data.get("my_id"):
			return
	weapon.sets.push_back(set_data)


func _add_conch_starting_weapons() -> void:
	var conch_weapon = load("res://mods-unpacked/RyehJael-Dissonance/content/weapons/ranged/conch/1/conch_data.tres")
	if conch_weapon == null:
		return

	for character_id in [
		"character_siren",
		"character_romantic",
		"character_creature",
		"character_sailor",
		"character_aeonian",
		"character_loud"
	]:
		_add_starting_weapon_to_character(character_id, conch_weapon)


func _add_starting_weapon_to_character(character_id: String, weapon: WeaponData) -> void:
	var character = _get_character_by_id(character_id)
	if character == null:
		return

	for starting_weapon in character.starting_weapons:
		if starting_weapon != null and starting_weapon.my_id == weapon.my_id:
			return

	character.starting_weapons.push_back(weapon)


func _get_character_by_id(character_id: String) -> CharacterData:
	for character in ItemService.characters:
		if character != null and character.my_id == character_id:
			return character
	return null


func _normalize_baton_unlock_state() -> void:
	if not _is_abyssal_terrors_available():
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


func _normalize_cash_cow_unlock_state() -> void:
	var cash_cow_item_id = "item_cash_cow"
	var cash_cow_item_hash = Keys.generate_hash(cash_cow_item_id)

	if ProgressData.items_unlocked.has(cash_cow_item_id):
		ProgressData.items_unlocked.erase(cash_cow_item_id)
	if ProgressData.items_unlocked.has(cash_cow_item_hash):
		ProgressData.items_unlocked.erase(cash_cow_item_hash)

	var producer_challenge_hash = Keys.generate_hash("chal_producer")
	var should_unlock_from_challenge = ProgressData.is_unlock_all_save() or ChallengeService.is_challenge_completed(producer_challenge_hash)
	var should_unlock_from_producer_clear = false
	var producer_hash = Keys.generate_hash("character_producer")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(producer_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_producer_clear = true
			break

	if should_unlock_from_challenge or should_unlock_from_producer_clear:
		ProgressData.items_unlocked.push_back(cash_cow_item_hash)
		ItemService.init_unlocked_pool()


func _normalize_black_notebook_unlock_state() -> void:
	var black_notebook_item_id = "item_black_notebook"
	var black_notebook_item_hash = Keys.generate_hash(black_notebook_item_id)

	if ProgressData.items_unlocked.has(black_notebook_item_id):
		ProgressData.items_unlocked.erase(black_notebook_item_id)
		if not ProgressData.items_unlocked.has(black_notebook_item_hash):
			ProgressData.items_unlocked.push_back(black_notebook_item_hash)

	var poet_challenge_hash = Keys.generate_hash("chal_poet")
	var should_unlock_from_challenge = ProgressData.is_unlock_all_save() or ChallengeService.is_challenge_completed(poet_challenge_hash)
	var should_unlock_from_poet_clear = false
	var poet_hash = Keys.generate_hash("character_poet")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(poet_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_poet_clear = true
			break

	if (should_unlock_from_challenge or should_unlock_from_poet_clear) and not ProgressData.items_unlocked.has(black_notebook_item_hash):
		ProgressData.items_unlocked.push_back(black_notebook_item_hash)
		ItemService.init_unlocked_pool()


func _normalize_disturbing_photo_unlock_state() -> void:
	var disturbing_photo_item_id = "item_disturbing_photo"
	var disturbing_photo_item_hash = Keys.generate_hash(disturbing_photo_item_id)

	if ProgressData.items_unlocked.has(disturbing_photo_item_id):
		ProgressData.items_unlocked.erase(disturbing_photo_item_id)
	if ProgressData.items_unlocked.has(disturbing_photo_item_hash):
		ProgressData.items_unlocked.erase(disturbing_photo_item_hash)

	var influencer_challenge_hash = Keys.generate_hash("chal_influencer")
	var should_unlock_from_challenge = ProgressData.is_unlock_all_save() or ChallengeService.is_challenge_completed(influencer_challenge_hash)
	var should_unlock_from_influencer_clear = false
	var influencer_hash = Keys.generate_hash("character_influencer")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(influencer_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_influencer_clear = true
			break

	if should_unlock_from_challenge or should_unlock_from_influencer_clear:
		ProgressData.items_unlocked.push_back(disturbing_photo_item_hash)
		ItemService.init_unlocked_pool()


func _normalize_conch_unlock_state() -> void:
	var conch_weapon_id = "weapon_conch"
	var conch_weapon_hash = Keys.generate_hash(conch_weapon_id)

	if ProgressData.weapons_unlocked.has(conch_weapon_id):
		ProgressData.weapons_unlocked.erase(conch_weapon_id)
		if not ProgressData.weapons_unlocked.has(conch_weapon_hash):
			ProgressData.weapons_unlocked.push_back(conch_weapon_hash)

	var siren_challenge_hash = Keys.generate_hash("chal_siren")
	var should_unlock_from_challenge = ChallengeService.is_challenge_completed(siren_challenge_hash)
	var should_unlock_from_siren_clear = false
	var siren_hash = Keys.generate_hash("character_siren")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(siren_hash, zone_id)
		if diff_info != null and diff_info.max_difficulty_beaten.difficulty_value >= 0:
			should_unlock_from_siren_clear = true
			break

	if (should_unlock_from_challenge or should_unlock_from_siren_clear) and not ProgressData.weapons_unlocked.has(conch_weapon_hash):
		ProgressData.weapons_unlocked.push_back(conch_weapon_hash)
		ItemService.init_unlocked_pool()


func _is_abyssal_terrors_available() -> bool:
	return (
		_resource_exists(DLC_1_DATA_PATH)
		and ProgressData.has_method("is_dlc_available_and_active")
		and ProgressData.is_dlc_available_and_active(ABYSSAL_TERRORS_DLC_ID)
	)


func _load_optional_resource(path: String):
	if not _resource_exists(path):
		return null
	return load(path)


func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)
