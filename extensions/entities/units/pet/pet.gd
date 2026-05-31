extends "res://entities/units/pet/pet.gd"

var dissonance_pet_effect_id := ""


func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	if effect == null:
		return

	dissonance_pet_effect_id = effect.get_id()
	set_meta("dissonance_pet_effect_id", dissonance_pet_effect_id)
