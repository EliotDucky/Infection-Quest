#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

function autoexec __init__system__(){
	system::register("zm_hotel_quest", &__init__, undefined, undefined);
}

function __init__(){
	clientfield::register("world", "client_movement", VERSION_SHIP, 1, "int", &setClientMovement, 0, 0);
}

function setClientMovement(local_client_num, old_val, new_val, b_new_ent, b_initial_snap, field_name, b_was_time_jump){
	if(new_val){
		SetDvar("doublejump_enabled", 1);
		SetDvar("juke_enabled", 1);
		SetDvar("playerEnergy_enabled", 1);
		SetDvar("wallrun_enabled", 1);
		SetDvar("sprintLeap_enabled", 1);
	}
}