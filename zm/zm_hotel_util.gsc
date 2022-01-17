#using scripts\shared\array_shared;

#insert scripts\zm\_zm_powerups.gsh;

#namespace zm_hotel_util;

function addPowerupTimeoutOverride(func){
	DEFAULT(level.powerup_timeout_custom_functions, array());
	array::add(level.powerup_timeout_custom_functions, func);
}

//Call On: spawned powerup
function powerupTimeoutCustomTime(){
	time = undefined;
	foreach(func in level.powerup_timeout_custom_functions){
		time = self [[func]]();
		if(isdefined(time)){
			break;
		}
	}
	if(!isdefined(time)){
		time = N_POWERUP_DEFAULT_TIME;
	}
	return time;
}