#using scripts\shared\system_shared;
#using scripts\shared\clientfield_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace zm_hotel_quest;

REGISTER_SYSTEM("zm_hotel_quest", &__init__, undefined)

function __init__(){
	registerClientfields();
}

function registerClientfields(){
	clientfield::register("toplayer", "set_freerun", VERSION_SHIP, 1, "int", &setFreerunMovement, 0, 0);
}

//clientfield: player
//call on: level
function setFreerunMovement(n_local_client, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump){
	if(newVal == 1){
		SetDvar( "doublejump_enabled", 1 );
	    SetDvar( "juke_enabled", 1 );
	    SetDvar( "playerEnergy_enabled", 1 );
	    SetDvar( "wallrun_enabled", 1 );
	    SetDvar( "sprintLeap_enabled", 1 );
	    SetDvar( "traverse_mode", 3 );
	    SetDvar( "weaponrest_enabled", 1 );
	}else if(newVal == 0){
		SetDvar( "doublejump_enabled", 0 );
	    SetDvar( "juke_enabled", 0 );
	    SetDvar( "playerEnergy_enabled", 0 );
	    SetDvar( "wallrun_enabled", 0 );
	    SetDvar( "sprintLeap_enabled", 0 );
	    SetDvar( "traverse_mode", 2 );
	    SetDvar( "weaponrest_enabled", 0 );
	}
}

