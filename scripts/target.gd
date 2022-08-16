extends Spatial

func _ready() -> void:
	$HitMesh.hide()
	$UnhitMesh.show()
	add_to_group("targets")

func got_hit() -> void:
	$HitMesh.show()
	$UnhitMesh.hide()
	remove_from_group("targets")
	$HitParticles.show()
	$HitParticles/Timer.start(.3)
	get_tree().get_current_scene().update_target_count()

func _on_Timer_timeout() -> void:
	$HitParticles.set_one_shot(true)
