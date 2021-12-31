#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\zm_hotel_quest.gsh;

#precache("client_fx", CONSOLE_LIGHT_FX_RED);
#precache("client_fx", CONSOLE_LIGHT_FX_AMBER);
#precache("client_fx", CONSOLE_LIGHT_FX_GREEN);
#precache("client_fx", CONSOLE_LIGHT_FX_BLUE);
#precache("client_fx", CONSOLE_LIGHT_FX_PURPLE);

function autoexec __init__system__(){
	system::register("zm_hotel_quest", &__init__, undefined, undefined);
}

function __init__(){
	clientfield::register("world", "client_movement", VERSION_SHIP, 1, "int", &setClientMovement, 0, 0);
	clientfield::register("scriptmover", "console_health_light", VERSION_SHIP, 3, "int", &consoleHealthLight, 0, 0);
	precacheFX();
}

function precacheFX(){
	DEFAULT(level._effect, []);
	level._effect["console_health_light_red"] = CONSOLE_LIGHT_FX_RED;
	level._effect["console_health_light_amber"] = CONSOLE_LIGHT_FX_AMBER;
	level._effect["console_health_light_green"] = CONSOLE_LIGHT_FX_GREEN;
	level._effect["console_health_light_blue"] = CONSOLE_LIGHT_FX_BLUE;
	level._effect["console_health_light_purple"] = CONSOLE_LIGHT_FX_PURPLE;
}

function consoleHealthLight(lcn, old_val, new_val, b_new_ent, b_initial_snap, field_name, b_was_time_jump){
	//0 - stop playing all
	//1 - green
	//2 - amber
	//3 - red
	//4 - blue
	//5 - purple
	if(isdefined(self)){
		if(isdefined(self.console_health_light)){
			StopFX(lcn, self.console_health_light);
		}
		if(new_val > 0){
			new_col = getColourFromNum(new_val);
			_fx = level._effect["console_health_light_"+new_col];
			self.console_health_light = PlayFX(lcn, _fx, self.origin);
		}
	}
}

function private getColourFromNum(num){
	colour = "";
	switch(num){
		case 5:
			colour = "purple";
			break;
		case 4:
			colour = "blue";
			break;
		case 3:
			colour = "red";
			break;
		case 2:
			colour = "amber";
			break;
		case 1:
			colour = "green";
			break;
	}
	return colour;
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