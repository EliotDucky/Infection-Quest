#using scripts\codescripts\struct;

#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\array_shared;
#using scripts\shared\util_shared;

#using scripts\zm\_zm_zonemgr;

#insert scripts\shared\shared.gsh;

#define Z_HOLDOUT_HEALTH 2000

#namespace zm_hotel_quest;

function autoexec __init__system__(){
	_arr = array("zm_zonemgr");
	system::register("zm_hotel_quest", &__init__, &__main__, _arr);
}

function __init__(){
	//init trials
	level.console_trials = array(&holdOut1);
	//level.console_trials = array(&freerun1, &freerun2);

	//get consoles
	level.quest_consoles = GetEntArray("quest_console", "targetname");
	array::thread_all(level.quest_consoles, &questConsoleInit);

	
}

function __main__(){
	
	//waitfor power
	level flag::wait_till("power_on");
	array::thread_all(level.quest_consoles, &questConsoleWaitFor);

	//enable zones for trials
	zm_zonemgr::zone_init("trial_zone");
	zm_zonemgr::enable_zone("trial_zone");

	//enable holdout zones
	zm_zonemgr::zone_init("holdout1_zone");
	zm_zonemgr::enable_zone("holdout1_zone");

	//zm_zonemgr::zone_init("holdout2_zone");
	//zm_zonemgr::enable_zone("houldout2_zone");
}

/*
Quest console: trigger_use, targetname: "quest_console", target: struct quest reward
PRECACHE HINT STRINGS
properties:
	.waiting - true when can be activated
	.complete - true when this has been beaten

Trial Zones: info_volume, script_noteworthy: "player_volume", targetname: "trial_zone"
Freerun Setup:
	start point: script_origin, targetname: "freerun[num]" (e.g. "freerun1")
	endpoint: trigger_multiple, targetname: "freerun[num]_complete"
	all chasms: trigger_multiple, targetname: "chasm_trigger"
*/

//call on: quest console trig
function questConsoleInit(){
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
}

//call on: quest console trig
function questConsoleWaitFor(){
	self SetHintString("Press ^3[{+activate}]^7 to begin trial");
	self.waiting = true;
	while(self.waiting){
		self waittill("trigger", player);
		if(self.waiting){ //check to make sure it is still waiting
			//deactivate other consoles
			array::thread_all(level.quest_consoles, &temporaryLock, self);
			self SetHintString("");

			if(self doTrial(player)){
				self.complete = true;
			}
			array::thread_all(level.quest_consoles, &unlock);
		}
		
	}
}

//call on: quest console trig
function temporaryLock(exception){
	//exception is the console which has just been activated
	if(!(self == exception || self.complete)){
		self.waiting = false;
		self SetHintString("This console is locked");
	}
}

//call on: quest console trig
function unlock(){
	if(!self.complete){
		self.waiting = true;
		self SetHintString("Press ^3[{+activate}]^7 to begin trial");
	}
}

//call on: quest console trig
//returns: true if beaten, false if failed
function doTrial(player){

	//IF NOT SOLO
	if(true){
		self thread zombiesTargetConsole();
	}else{
		//despawn all zombies and stop them spawning
	}

	trial_index = RandomInt(level.console_trials.size);
	won = player [[level.console_trials[trial_index]]]();
	wait(0.05);
	self zombieUnTargetConsole();

	if(won){
		//array::remove_index(level.console_trials, trial_index);
		ArrayRemoveIndex(level.console_trials, trial_index, false);
	}
}

function zombiesTargetConsole(){
}

//call on: console trigger
function zombieUnTargetConsole(){
}

//call On: player
function freerun1(){
	IPrintLnBold("freerun1");
	time_limit = 120; //seconds
	start_struct = struct::get("freerun1", "targetname");
	IPrintLnBold(start_struct.origin);
	completion_trigs = GetEntArray("freerun1_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs);
}

//call On: player
function freerun2(){
	IPrintLnBold("freerun2");
	time_limit = 120; //seconds
	start_struct = struct::get("freerun2", "targetname");
	IPrintLnBold(start_struct.origin);
	completion_trigs = GetEntArray("freerun2_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs);
}

//call On: the player
function freeRun(start_struct, time_limit, completion_trigs, chasm_trigs){
	//ENABLE FREERUN PLAYER MOVEMENT

	self.freerun_won = false;
	map_struct = Spawn("script_origin", self.origin);
	map_struct.angles = self.angles;
	//teleport player to start
	self playerTeleport(start_struct);
	//if player touches any chasm trig, teleport them back to the start
	array::thread_all(chasm_trigs, &chasmWaitFor, start_struct, self);
	//waittill player touches any completion trig
	array::thread_all(completion_trigs, &completionWaitFor, map_struct, self);
	self thread freerunTimer(time_limit);
	self waittill("freerun_done");
	self playerTeleport(map_struct);
	return self.freerun_won;
}

//call On: chasm trig_multiples
function chasmWaitFor(start_struct, player){
	player endon("freerun_done");
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
	while(true){
		self waittill("trigger", p);
		IPrintLnBold("chasm");
		p playerTeleport(start_struct);
		wait(0.05);
	}
}

//call On: completion trig_multiples
function completionWaitFor(map_struct, player){
	player endon("freerun_done");
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
	self waittill("trigger", p);
	IPrintLnBold(self.origin + " " +player.origin);
	player.freerun_won = true;
	//IPrintLnBold("WON");
	wait(10);
	player notify("freerun_done");
}

//call On: player in freerun
function freerunTimer(limit){
	self endon("freerun_done");
	t = limit;
	while(t > 0 && !self.freerun_won){
		wait(0.05);
		t -= 0.05;
		if(RandomInt(600) == 1){
			IPrintLnBold("Freerun Time: " + t + " seconds");
		}
	}
	IPrintLnBold("time limit over");
	self notify("freerun_done"); 
}

//Holdout

//Main holdout quest function
//Call On: the player
function holdOut(loc_struct, holdout_zone, _time = 90){

	map_struct = Spawn("script_origin", self.origin);
	map_struct.angles = self.angles;

	//teleport player to loc_struct
	self playerTeleport(loc_struct);

	//give time to adjust
	wait(5);

	level thread holdOutSpawning(holdout_zone, Z_HOLDOUT_HEALTH);
	wait(_time);
	level.holdout_active = false;

	self playerTeleport(map_struct);
}

//Call On: level
function holdOutSpawning(holdout_zone, zombie_health = 2000){
	self endon("disconnect");

	level.holdout_active = true;
	while(level.holdout_active){
		//level.zombie_total is the num of zombies left to spawn this round
		if(level.zombie_total <= 20){
			level.zombie_total = 60;
		}

		//get zombies in this zone
		all_zombs = GetAITeamArray( "axis" );
		foreach(zomb in all_zombs){
			if(zomb zm_zonemgr::entity_in_zone(holdout_zone)){
				zomb.no_powerups = true; //doesn't drop powerups
				zomb.maxhealth = zombie_health;
				zombie.zombie_move_speed = "sprint";
			}
			wait(0.05);
		}
	}
	//holdout has ended
	level.zombie_total = 0;
}

//call On: Player
function holdOut1(){
	IPrintLnBold("holdOut1");
	start_struct = struct::get("holdout1", "targetname");
	self holdOut(start_struct, "holdout1_zone");
	return true;
}

function holdOut2(){
	IPrintLnBold("holdOut2");
	wait(10);
	return true;
}

//Call On: Player
function playerTeleport(ent){
	self SetOrigin(ent.origin);
	self SetPlayerAngles(ent.angles);
}