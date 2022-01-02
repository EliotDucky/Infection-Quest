#using scripts\shared\array_shared;
#using scripts\shared\system_shared;

#using scripts\zm\_zm_hero_weapon;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_utility;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#define PREFIX		"hero"

#namespace zm_hotel_rewards;

function autoexec __init__system__(){
	_arr = array();
	system::register("zm_hotel_rewards", &__init__, &__main__, _arr);
}

function __init__(){
	trigs = GetEntArray("reward_room_trig", "targetname");
	array::thread_all(trigs, &trigWaitFor);
}

function __main__(){
}

//call on: reward trig
function trigWaitFor(){
	if(isdefined(self.script_string)){
		wpn_name = PREFIX + "_" + self.script_string;
		wpn = GetWeapon(wpn_name);
		d_name = MakeLocalizedString(wpn.displayname);
		self SetCursorHint("HINT_NOICON");
		self SetHintString("Press ^3[{+activate}]^7 for "+d_name);
		for(;;){
			self waittill("trigger", player);
			IPrintLnBold(wpn_name);
			if(player zm_utility::get_player_hero_weapon() === wpn){
				//player is trying to take same weapon - go back to waittill
				continue;
			}
			//Stop energy being reset to zero when weapon taken
			power = 100;
			if(player zm_utility::has_player_hero_weapon()){
				power = player GadgetPowerGet(0);
			}
			//zm_weapons::weapon_give takes any old hero wpns first

			//give specialist weapon
			player zm_weapons::weapon_give(wpn);
			player GadgetPowerSet(0, power);
			player.hero_power = power;
		}
	}
}