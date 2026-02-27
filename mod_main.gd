extends Node

const MOD_DIR = "RyehJael-Dissonance/"
const DISSONANCE_LOG = "RyehJael-Dissonance"

var dir = ""
var ext_dir = ""


func _init():
	ModLoaderLog.info("Init", DISSONANCE_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	ext_dir = dir + "extensions/"

	ModLoaderMod.install_script_extension(ext_dir + "singletons/run_data.gd")


func _ready()->void:
	_load_dissonance_content()
	ModLoaderLog.info("Ready", DISSONANCE_LOG)


func _load_dissonance_content()->void:
	var content_loader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	content_loader.load_data(dir + "content_data/dissonance_characters.tres", DISSONANCE_LOG)
