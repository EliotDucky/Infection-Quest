#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\system_shared;

#using scripts\zm\_zm_hero_weapon;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_perks.gsh;

#define PREFIX		"hero"

#namespace zm_hotel_rewards;

function autoexec __init__system__(){
	_arr = array();
	system::register("zm_hotel_rewards", &__init__, &__main__, _arr);
}

function __init__(){
	trigs = GetEntArray("reward_room_trig", "targetname");
	array::thread_all(trigs, &trigWaitFor);
	level thread setupPerkRewards();
}

//thread
function setupPerkRewards(){
	wait(1);
	DEFAULT(level._custom_perks, array());
	perks = array(PERK_DEAD_SHOT, PERK_ELECTRIC_CHERRY, PERK_WIDOWS_WINE);
	perk_trigs = GetEntArray("zombie_vending", "targetname");
	_temp = [];
	foreach(perk_trig in perk_trigs){
		if(isdefined(perk_trig.script_noteworthy) && array::contains(perks, perk_trig.script_noteworthy)){
			array::add(_temp, perk_trig);
		}
	}
	perk_trigs = _temp;
	level flag::wait_till("power_on");
	foreach(perk in perks){
		DEFAULT(level._custom_perks[perk], SpawnStruct());
		level._custom_perks[perk].cost = 0;
	}
	wait(0.05);
	foreach(perk_trig in perk_trigs){
		perk_trig zm_perks::reset_vending_hint_string();
	}
	foreach(perk in perks){
		level notify(perk+"_power_on");
		wait(0.5);
	}
}

function __main__(){}

//call on: reward trig
function trigWaitFor(){
	if(isdefined(self.script_string)){
		wpn_name = PREFIX + "_" + self.script_string;
		wpn = GetWeapon(wpn_name);
		d_name = MakeLocalizedString(wpn.displayname);
		self SetCursorHint("HINT_NOICON");
		self SetHintString("Press ^3[{+activate}]^7 for "+d_name);
		if(isdefined(self.target)){
			model = GetEnt(self.target, "targetname");
			model thread rotateModel();
		}
		for(;;){
			self waittill("trigger", player);
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
			wait(0.05);
			player GadgetPowerSet(0, power);
			player.hero_power = power;
		}
	}
}

//call on reward model
function rotateModel(){
	for(;;){
		self RotateYaw(180, 2);
		self waittill("rotatedone");
	}
}