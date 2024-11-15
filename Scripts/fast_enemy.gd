extends CharacterBody3D

var health=50
var finished_walk = false
var can_attack = true
@onready var animation_player = $AnimationPlayer

func _physics_process(delta):
	# Dodaj grawitację do osi Y prędkości
	if finished_walk:
		play_attack_animation()
		if can_attack:
			can_attack=false
			$"Attack CD".start()
	else:
		play_run_animation()
		
	

func play_attack_animation():
	if animation_player.current_animation != "1H_Melee_Attack_Slice_Diagonal":
		animation_player.play("1H_Melee_Attack_Slice_Diagonal")

func play_run_animation():
	if animation_player.current_animation != "Running_A":
		animation_player.play("Running_A")
	
#func attack():
#	finished_walk = true

#Function that happens when mob is struck with arrow/spell/canon
func take_damage(damage: int) -> void:
	health-=damage
	if(health<=0):
		get_parent_node_3d().delete_object()

#Resetting attacking 
func _on_attack_cd_timeout() -> void:
	take_damage(50)
	can_attack=true