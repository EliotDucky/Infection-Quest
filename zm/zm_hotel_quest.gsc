#using scripts\codescripts\struct;

#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\array_shared;
#using scripts\shared\util_shared;

#using scripts\zm\_zm_zonemgr;
//#using scripts\zm\_zm_attackables;
#using scripts\zm\_zm_utility;

#insert scripts\shared\shared.gsh;

#namespace zm_hotel_quest;

REGISTER_SYSTEM("zm_hotel_quest", &__init__, undefined)

function __init__(){
	//init trials
	level.console_trials = array(&freerun1, &freerun2, &holdOut1, &holdOut2);

	//get consoles
	level.quest_consoles = GetEntArray("quest_console", "targetname");
	array::thread_all(level.quest_consoles, &questConsoleInit);

	//get attackables - consider replacing with zm_ultility point of interest
	//level.console_attackables = struct::get_array("console_attackable", "targetname");

	//waitfor power
	wait(0.05);
	level flag::wait_till("power_on");
	array::thread_all(level.quest_consoles, &questConsoleWaitFor);

	//enable zones for trials
	zm_zonemgr::zone_init("trial_zone");
	zm_zonemgr::enable_zone("trial_zone");
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

			if(self doTrial()){
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
function doTrial(){

	//console_attackable = undefined;
	//IF NOT SOLO
	if(true){
		attractor_dist = 1024;
		num_attractors = 96;
		poi_value = 10000;
		attract_dist_diff = 5;
		self thread zombiesTargetConsole(attractor_dist, num_attractors, poi_value, attract_dist_diff);
		wait(0.05);
	}else{
		//despawn all zombies and stop them spawning
	}

	trial_index = RandomInt(level.console_trials.size);
	won = self [[level.console_trials[trial_index]]]();
	wait(0.05);
	self zombieUnTargetConsole();
	/*
	if(isdefined(console_attackable)){
		//console_attackable zm_attackables::deactivate();
	}
	*/

	if(won){
		array::remove_index(level.console_trials, trial_index);
	}
}

//call on: console trigger
/* looping version
function zombiesTargetConsole(attractor_dist, num_attractors, poi_value){
	self.target_console = true;
	while(self.target_console){
		self zm_utility::create_zombie_point_of_interest(attractor_dist, num_attractors, poi_value);
		wait(0.05);
	}
}*/

function zombiesTargetConsole(attractor_dist, num_attractors, poi_value, attract_dist_diff){
	self zm_utility::create_zombie_point_of_interest(attractor_dist, num_attractors, poi_value);
	self.attract_to_origin = true;
	self thread zm_utility::create_zombie_point_of_interest_attractor_positions( 4, attract_dist_diff );
	self thread zm_utility::wait_for_attractor_positions_complete();
	IPrintLnBold("targeting");
}

//call on: console trigger
function zombieUnTargetConsole(){
	//self notify("untarget");
	//self.under_attack = false;
}

function freerun1(){
	IPrintLnBold("freerun1");
	time_limit = 120; //seconds
	start_struct = GetEnt("freerun1", "targetname");
	completion_trigs = GetEntArray("freerun1_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs);
}

function freerun2(){
	IPrintLnBold("freerun2");
	time_limit = 120; //seconds
	start_struct = GetEnt("freerun2", "targetname");
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
	self SetOrigin(start_struct GetOrigin());
	self SetPlayerAngles(start_struct.angles);
	//if player touches any chasm trig, teleport them back to the start
	array::thread_all(chasm_trigs, &chasmWaitFor, start_struct, self);
	//waittill player touches any completion trig
	array::thread_all(completion_trigs, &completionWaitFor, map_struct, self);
	self thread freerunTimer(time_limit);
	self waittill("freerun_done");
	self SetOrigin(map_struct.origin);
	self.angles = map_struct.angles;
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
		player SetOrigin(start_struct.origin);
		wait(0.05);
		//p.angles = start_struct.angles;
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
	self notify("freerun_done"); 
}

function holdOut1(){
	IPrintLnBold("holdOut1");
	wait(10);
	return true;
}

function holdOut2(){
	IPrintLnBold("holdOut1");
	wait(10);
	return true;
}