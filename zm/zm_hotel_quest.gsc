#using scripts\codescripts\struct;

#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\array_shared;
#using scripts\shared\util_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\clientfield_shared;

#using scripts\zm\_zm_zonemgr;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_blockers;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_spawner;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#define REWARD_DOOR_TIME	1.5
#define Z_HOLDOUT_HEALTH 2000

#namespace zm_hotel_quest;

function autoexec __init__system__(){
	_arr = array("zm_zonemgr");
	system::register("zm_hotel_quest", &__init__, &__main__, _arr);
}

function __init__(){
	registerClientfields();

	//init trials
	level.console_trials = array(&freerun1, &freerun2, &holdOut1, &holdOut2);
  
	//get consoles
	level.quest_consoles = GetEntArray("quest_console", "targetname");
	array::thread_all(level.quest_consoles, &questConsoleInit);
}

function __main__(){
	
	//waitfor power
	level flag::wait_till("power_on");
	wait(0.05);
	array::thread_all(level.quest_consoles, &questConsoleWaitFor);
	wait(0.05);
	for(i = 0; i < 4; i++){
		exploder::exploder("red_light_"+i);
	}

	//enable zones for trials
	zm_zonemgr::zone_init("trial_zone");
	zm_zonemgr::enable_zone("trial_zone");

	//enable holdout zones
	zm_zonemgr::zone_init("holdout1_zone");
	zm_zonemgr::enable_zone("holdout1_zone");

	zm_zonemgr::zone_init("holdout2_zone");
	zm_zonemgr::enable_zone("houldout2_zone");
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

Reward Door:
Each light should be a unique exploder
	Red should default to Off
		red_light_0
		red_light_1
		etc.
	Green should default to Off
		green_light_0
		green_light_1
		etc.
*/

function registerClientfields(){
	clientfield::register("toplayer", "set_freerun", VERSION_SHIP, 1, "int");
}

//call on: quest console trig
function questConsoleInit(){
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
}

//call on: quest console trig
function questConsoleWaitFor(){
	self notify("not_waiting");
	self endon("not_waiting");
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
		//self notify("not_waiting");
		self SetHintString("This console is locked");
	}
}

//call on: quest console trig
function unlock(){
	if(!self.complete){
		self.waiting = true;
		self SetHintString("Press ^3[{+activate}]^7 to begin trial");
		//self thread questConsoleWaitFor();
	}
}

//call on: quest console trig
//returns: true if beaten, false if failed
function doTrial(player){

	//stop zombie spawns
	level thread nukeAllZombies();
	level flag::clear("spawn_zombies");
	//later set to respawn if not solo or in holdout function

	//PLAYER ANIM
	
	//IF NOT SOLO
	pois = [];
	if(true){
		level thread respawnZAfterTime(5);
		pois = self thread zombiesTargetConsole();
		level thread holdOutSpawning();
	}

	trial_index = RandomInt(level.console_trials.size);
	won = player [[level.console_trials[trial_index]]]();
	wait(0.05);
	foreach(poi in pois){
		poi zombieUnTargetConsole();
	}
	//stop zombie spawns
	level thread nukeAllZombies();
	level flag::clear("spawn_zombies");

	if(won){
		//array::remove_index(level.console_trials, trial_index);
		ArrayRemoveIndex(level.console_trials, trial_index, false);
		self spawnReward();
		//unlock a door stage

		level thread doorUnlock();
	}

	level thread respawnZAfterTime(5);
	return won;
}

function private respawnZAfterTime(time = 5){
	wait(time);
	level flag::set("spawn_zombies");
}

//call on: console trig
function spawnReward(){
	reward_point = undefined;
	//script_origins
	trgs = GetEntArray(self.target, "targetname");
	foreach(trg in trgs){
		if(isdefined(trg.script_noteworthy) && trg.script_noteworthy=="reward_point"){
			reward_point = trg;
			break;
		}
	}
	zm_powerups::specific_powerup_drop("free_perk", trg.origin);
}

//call on: level
function doorUnlock(){
	if(!isdefined(level.reward_door_stage)){
		//inits if not existent yet
		level.reward_door_stage = -1;
	}
	level.reward_door_stage ++;
	i = level.reward_door_stage;
	exploder::stop_exploder("red_light_"+i);
	wait(0.05);
	exploder::exploder("green_light_"+i);
	if(level.reward_door_stage >= 3){

		reward_door = GetEnt("reward_door", "script_flag");
		reward_door thread zm_blockers::door_opened(0);
	}
}

//call on: console trig
function zombiesTargetConsole(){
	points = GetEntArray(self.target, "targetname");
	for(i = 0; i<points.size; i++){
		if (!(isdefined(points[i].script_noteworthy) && points[i].script_noteworthy == "poi")){
			array::remove_index(points, i);
		}
	}
	foreach(point in points){
		point zm_utility::create_zombie_point_of_interest(10000);
		point.attract_to_origin = true;
	}
	return points;
}

//call on: console trigger point of interest
function zombieUnTargetConsole(){
	self zm_utility::deactivate_zombie_point_of_interest();
}

//call On: player
function freerun1(){
	IPrintLnBold("freerun1");
	time_limit = 120; //seconds
	start_struct = struct::get("freerun1", "targetname");
	IPrintLnBold(start_struct.origin);
	completion_trigs = GetEntArray("freerun1_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	checkpoints = GetEntArray("freerun1_checkpoint", "targetname");
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs, checkpoints);
}

//call On: player
function freerun2(){
	IPrintLnBold("freerun2");
	time_limit = 120; //seconds
	start_struct = struct::get("freerun2", "targetname");
	IPrintLnBold(start_struct.origin);
	completion_trigs = GetEntArray("freerun2_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	checkpoints = GetEntArray("freerun2_checkpoint", "targetname");
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs, checkpoints);
}

//call On: the player
function freeRun(start_struct, time_limit, completion_trigs, chasm_trigs, checkpoints){
	//ENABLE FREERUN PLAYER MOVEMENT

	self.freerun_won = false;
	map_struct = Spawn("script_origin", self.origin);
	map_struct.angles = self.angles;
	//teleport player to start
	self playerTeleport(start_struct);
	//if player touches any chasm trig, teleport them back to the start
	self.freerun_checkpoint = start_struct;
	array::thread_all(chasm_trigs, &chasmWaitFor, self);
	//waittill player touches any completion trig
	array::thread_all(completion_trigs, &completionWaitFor, map_struct, self);
	array::thread_all(checkpoints, &checkPointWaitFor);
	self thread freerunTimer(time_limit);
	self thread freerunMovement();
	self waittill("freerun_done");
	self playerTeleport(map_struct);
	return self.freerun_won;
}

//call On: chasm trig_multiples
function chasmWaitFor(player){
	player endon("freerun_done");
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
	while(true){
		self waittill("trigger", p);
		IPrintLnBold("chasm");
		p playerTeleport(p.freerun_checkpoint);
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

//call On: Player
//runs with a waittill
function freerunMovement(){
	self clientfield::set_to_player("set_freerun", 1);

	self waittill("freerun_done");

	self clientfield::set_to_player("set_freerun", 0);
}


//call on: checkpoint trigger multiple
function checkPointWaitFor(){
	respawn_point = struct::get(self.target, "targetname");
	self waittill("trigger", player);
	player.freerun_checkpoint = respawn_point;
}

//Holdout

//Main holdout quest function
//Call On: the player
function holdOut(loc_struct, _time = 90){

	map_struct = Spawn("script_origin", self.origin);
	map_struct.angles = self.angles;

	//teleport player to loc_struct
	self playerTeleport(loc_struct);

	//freerun movement
	self thread freerunMovement();

	//max ammo spawning
	spawn_times = [];
	//CHANGE THIS INTERVAL, SO SMALL FOR TESTING ONLY
	for(pwrup_time = 20; pwrup_time < _time; pwrup_time += 20){
		array::add(spawn_times, pwrup_time);
	}
	loc_struct thread holdoutPowerupDrops("full_ammo", spawn_times);

	level thread respawnZAfterTime(0.05);

	//level thread holdOutSpawning(); ONLY ENABLE ON SOLO
	wait(_time);
	level.holdout_active = false;
	self notify("freerun_done");

	self playerTeleport(map_struct);
}

//Use for any defend sequence, not just the holdout
//Call On: level
function holdOutSpawning(){
	//only allow one of these to run at once
	self notify("holdout_spawning");
	self endon("holdout_spawning");
	self endon("disconnect");
	wait(0.05);
	IPrintLnBold("SPAWNING");
	level.holdout_active = true;
	level.no_powerups = true; //turn powerups off
	IPrintLnBold(level.zombie_health); //check it is defined already
	stnd_z_health = level.zombie_health; //store the standard zombie health
	level.zombie_health = Z_HOLDOUT_HEALTH; //max health of new zombies spawning
	stnd_z_speed = level.zombie_move_speed; //store the standard move speed
	level.zombie_move_speed = 100; //71+ is sprint
	while(level.holdout_active){
		//level.zombie_total is the num of zombies left to spawn this round
		if(level.zombie_total <= 30){
			level.zombie_total = 40;
		}
		IPrintLn("spawn queue: "+level.zombie_total);
		wait(2); //no need to wait a frame, can get better performance
	}
	//holdout has ended
	level.zombie_total = 0;
	level.no_powerups = false; //re-enable powerups
	level.zombie_health = stnd_z_health; //reset zombie health to pre-holdout
	//round change shouldn't have happened
	level.zombie_move_speed = stnd_z_speed; //reset zombie move speed
}

//Thread
//Call On: loc struct
function holdoutPowerupDrops(powerup, times_to_spawn){
	points = GetEntArray(self.target, "targetname");
	time = 0.0;
	foreach(spawn_time in times_to_spawn){
		wait(spawn_time - time);
		time += spawn_time;
		IPrintLnBold(time);
		//spawn powerup
		point = array::random(points);
		zm_powerups::specific_powerup_drop(powerup, point.origin);
	}
}

function holdOut1(){
	IPrintLnBold("holdOut1");
	start_struct = struct::get("holdout1", "targetname");
	self holdOut(start_struct);
	return true;
}

function holdOut2(){
	IPrintLnBold("holdOut2");
	start_struct = struct::get("holdout2", "targetname");
	level.holdout_zone = "holdout2_zone";
	self holdOut(start_struct);
	level.holdout_zone = undefined;
	return true;
}



//Call On: Player
function playerTeleport(ent){
	self SetOrigin(ent.origin);
	self SetPlayerAngles(ent.angles);
}

function nukeAllZombies(){
	//Copied from Connor
	a_ai_zombies = GetAITeamArray(level.zombie_team);
	zombie_marked_to_destroy = [];
	foreach(ai_zombie in a_ai_zombies)
	{
		ai_zombie.no_powerups = 1;
		ai_zombie.deathpoints_already_given = 1;
		if(isdefined(ai_zombie.ignore_nuke) && ai_zombie.ignore_nuke)
		{
			continue;
		}
		if(isdefined(ai_zombie.marked_for_death) && ai_zombie.marked_for_death)
		{
			continue;
		}
		if(isdefined(ai_zombie.nuke_damage_func))
		{
			ai_zombie thread [[ai_zombie.nuke_damage_func]]();
			continue;
		}
		if(zm_utility::is_magic_bullet_shield_enabled(ai_zombie))
		{
			continue;
		}
		ai_zombie.marked_for_death = 1;
		ai_zombie.nuked = 1;
		zombie_marked_to_destroy[zombie_marked_to_destroy.size] = ai_zombie;
	}
	foreach(zombie_to_destroy in zombie_marked_to_destroy)
	{
		if(!isdefined(zombie_to_destroy))
		{
			continue;
		}
		if(zm_utility::is_magic_bullet_shield_enabled(zombie_to_destroy))
		{
			continue;
		}
		zombie_to_destroy DoDamage(zombie_to_destroy.health, zombie_to_destroy.origin);
		if(!level flag::get("special_round"))
		{
			level.zombie_total++;
		}
	}
	corpse_array = GetCorpseArray();
	for ( i = 0; i < corpse_array.size; i++ )
	{
		if ( IsDefined( corpse_array[ i ] ) )
		{
			corpse_array[ i ] Delete();
		}
	}
	/*
	a_ai_zombies = GetAITeamArray(level.zombie_team);
	foreach(zombie in a_ai_zombies)
	{
		zombie.delayAmbientVox = true;
	}
	level waittill("flashback_completed");
	foreach(zombie in a_ai_zombies)
	{
		zombie.delayAmbientVox = false;
	}*/
}