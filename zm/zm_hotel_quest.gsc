#using scripts\codescripts\struct;

#using scripts\shared\ai_shared;
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
#using scripts\zm\_zm_weapons;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\zm_powerup_player_ammo;
#insert scripts\zm\zm_hotel_quest.gsh;

#namespace zm_hotel_quest;

function autoexec __init__system__(){
	_arr = array("zm_zonemgr");
	system::register("zm_hotel_quest", &__init__, &__main__, _arr);
}

function __init__(){

	//init trials
	level.console_trials = array(&freerun1, &freerun2, &holdOut1, &holdOut2);
  
	//get consoles
	level.quest_consoles = GetEntArray("quest_console", "targetname");
	array::thread_all(level.quest_consoles, &questConsoleInit);
	level.weapon_fists = GetWeapon("bare_hands");
	consoleAttackAnims();
}

function __main__(){
	
	//waitfor power
	level flag::wait_till("power_on");
	level thread setServerMovement();
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

function setServerMovement(){
	SetDvar( "doublejump_enabled", 1 );
	SetDvar( "juke_enabled", 1 );
	SetDvar( "playerEnergy_enabled", 1 );
	SetDvar( "wallrun_enabled", 1 );
	SetDvar( "sprintLeap_enabled", 1 );
	foreach(player in GetPlayers()){
		player AllowDoubleJump(false);
		player AllowWallRun(false);
		player SetMoveSpeedScale(1);
		player SetSprintCooldown(0);
		player SetSprintDuration(4);
	}
}

//call on: quest console trig
function questConsoleInit(){
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
}

function consoleAttackAnims(){
	level.console_attack_anims = [];
	//Dictionary for different gib and movement states
	_twos = array("ad", "au");
	_types = array("attack");
	level.console_attack_anims["stand"] = createZAnimList("", _twos, _types, 4);
	level.console_attack_anims["run"] = createZAnimList("run", _twos, _types, 4);
	level.console_attack_anims["walk"] = createZAnimList("walk", _twos, _types, 4);

	_twos = array("");
	level.console_attack_anims["crawl"] = createZAnimList("crawl", _twos, _types, 2);

	_twos = array("ad");
	level.console_attack_anims["fwd"] = createZAnimList("fwd", _twos, _types, 2);
}

function private createAnimName(archetype, move, _two, _type, index){
	archetype = stringies(archetype);
	move = stringies(move);
	_two = stringies(_two);
	_type = stringies(_type);
	str = "ai_"+archetype+"base_"+move+_two+_type+"v"+index;
	return str;
}

function private createZAnimList(move, _twos, _types, num_per_move){
	archetype = "zombie";
	names = [];
	num = num_per_move;
	for(i=1; i<num; i++){
		foreach(_type in _types){
			foreach(_two in _twos){
				name = createAnimName(archetype, move, _two, _type, i);
				array::add(names, name);
			}
		}
	}
	return names;
}

function stringies(str){
	if(str != ""){
		str += "_";
	}
	return str;
}

//call on: quest console trig
function questConsoleWaitFor(){
	self notify("not_waiting");
	self endon("not_waiting");
	self SetHintString("Press ^3[{+activate}]^7 to begin trial");
	self.waiting = true;
	self.complete = false;
	while(self.waiting){
		self waittill("trigger", player);
		if(self.waiting){ //check to make sure it is still waiting
			//deactivate other consoles
			array::thread_all(level.quest_consoles, &temporaryLock, self);
			self SetHintString("");

			if(self doTrial(player)){
				self.complete = true;
				self.waiting = false;
			}
			wait(0.05);
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
	
	solo = GetPlayers().size <= 1;
	pois = [];
	if(!solo){
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
	level.holdout_active = false;
	level thread nukeAllZombies();
	level flag::clear("spawn_zombies");

	if(won){
		//array::remove_index(level.console_trials, trial_index);
		ArrayRemoveIndex(level.console_trials, trial_index, false);
		self thread spawnReward();
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
	points = GetEntArray(self.target, "targetname");
	foreach(point in points){
		if(isdefined(point.script_noteworthy) && point.script_noteworthy=="r"){
			reward_point = point;
			break;
		}
	}
	zm_powerups::specific_powerup_drop("free_perk", reward_point.origin);
	wait(0.05);
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
			ArrayRemoveIndex(points, i, false);
		}
	}
	IPrintLnBold(points.size);
	foreach(point in points){
		point zm_utility::create_zombie_point_of_interest(ZOMBIE_POI_RANK);
		point.attract_to_origin = true;
	}
	self thread zombieAttackConsole();
	return points;
}

//call on: console trigger point of interest
function zombieUnTargetConsole(){
	self zm_utility::deactivate_zombie_point_of_interest();
	level notify("zombie_attack_console_end");
}

//call on: console trig
//based on zm_island_skullweapon_quest.gsc line 435
function zombieAttackConsole(){
	level endon("zombie_attack_console_end");
	while(true){
		enemies = GetAITeamArray(level.zombie_team);
		foreach(ai in enemies){
			b_attack = ai.archetype == "zombie";
			b_attack &= !IS_TRUE(ai.attacking_console);
			b_attack &= IsAlive(ai) && !IS_TRUE(ai.aat_turned);
			b_attack &= DistanceSquared(ai.origin, self.origin) <= CONSOLE_ATTACK_SQ_RAD;
			if(b_attack){
				ai.attacking_console = true;
				self thread zombieAttackConsoleAnim(ai);
			}
		}
		wait(0.05);
	}
}

//call on: console trig
function zombieAttackConsoleAnim(ai){
	level endon("zombie_attack_console_end");
	ai ai::set_ignoreall(1);
	while(IsAlive(ai)){
		ai LookAtEntity(self);
		attack_anim = randomAttackAnim(ai);
		attack_anim_time = GetAnimLength(attack_anim);
		ai AnimScripted("melee", ai.origin,
			ai.angles, attack_anim, "normal",
			undefined, undefined, 0.5, 0.5);
		//PLAY HIT SOUND
		wait(attack_anim_time + 1);
	}
}

function randomAttackAnim(ai){
	_anim = "";
	move = "stand";
	if(IS_TRUE(ai.missingLegs)){
		move = "crawl";
	}

	return array::random(level.console_attack_anims[move]);
}

//call On: player
function freerun1(){
	time_limit = 120; //seconds
	start_struct = struct::get("freerun1", "targetname");
	completion_trigs = GetEntArray("freerun1_complete", "targetname"); //trigger_multiple
	chasm_trigs = GetEntArray("chasm_trigger", "targetname"); //trigger_multiple
	checkpoints = GetEntArray("freerun1_checkpoint", "targetname");
	return self freeRun(start_struct, time_limit, completion_trigs, chasm_trigs, checkpoints);
}

//call On: player
function freerun2(){
	time_limit = 120; //seconds
	start_struct = struct::get("freerun2", "targetname");
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
	self thread freerunLoadout(level.weapon_fists);
	self waittill("freerun_done");
	self playerTeleport(map_struct);
	return self.freerun_won;
}

//call On: player
function freerunLoadout(replacement_wpn){
	current_weapon = self GetCurrentWeapon();
	weapons = self GetWeaponsList();
	weapon_info = [];
	//index of weapons lines up with weapon info
	foreach(weapon in weapons){
		base = zm_weapons::get_nonalternate_weapon(weapon);
		if(base != weapon){
			continue;
		}
		info = SpawnStruct();
		info.weapon = weapon;
		info.clip_size = self GetWeaponAmmoClip(weapon);
		info.left_clip_size = -1;
		if(weapon.dualWieldWeapon != level.weaponNone){
			info.left_clip_size = self GetWeaponAmmoClip(weapon.dualWieldWeapon);
		}
		info.stock_size = self GetWeaponAmmoStock(weapon);

		array::add(weapon_info, info);
		self zm_weapons::weapon_take(weapon);
	}

	rplc_wpn = self zm_weapons::weapon_give(replacement_wpn);
	self SwitchToWeapon(rplc_wpn);

	self waittill("freerun_done");

	self zm_weapons::weapon_take(rplc_wpn);

	foreach(info in weapon_info){
		wpn = self zm_weapons::weapon_give(info.weapon);
		self SetWeaponAmmoClip(wpn, info.clip_size);
		dual_wield = wpn.dualWieldWeapon;
		if(level.weaponNone != dual_wield && isdefined(info.left_clip_size)){
			self SetWeaponAmmoClip(dual_wield, info.left_clip_size);
		}
		self SetWeaponAmmoStock(wpn, info.stock_size);
	}
	self SwitchToWeapon(current_weapon);
}

//call On: chasm trig_multiples
function chasmWaitFor(player){
	player endon("freerun_done");
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
	while(true){
		self waittill("trigger", p);
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
	player.freerun_won = true;
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
	self AllowDoubleJump(true);
	self AllowWallRun(true);
	self SetSprintDuration(999);
	self thread energyMonitor();

	self waittill("freerun_done");

	self AllowDoubleJump(false);
	self AllowWallRun(false);	
	self SetSprintDuration(4);
}

//calls On: Player
function energyMonitor(){
	self endon("death");
	self endon("disconnect");
	self endon("freerun_done");
	while(true){
		if(self IsOnGround() || self IsWallRunning()){
			self SetDoubleJumpEnergy(200);
		}
		wait(0.05);
	}
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
	spawn_times = HOLDOUT_PWRUP_TIMES;
	loc_struct thread holdoutPowerupDrops("player_ammo", spawn_times);

	//loadout
	wpn = array::random(HOLDOUT_WPNS);
	wpn = GetWeapon(wpn);
	self thread freerunLoadout(wpn);
	solo = GetPlayers().size <= 1;
	if(solo){
		//do these if not done in the main doTrial function
		level thread respawnZAfterTime(0.05);
		level thread holdOutSpawning();
	}
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
		time = spawn_time;
		IPrintLnBold(time);
		//spawn powerup
		point = array::random(points);
		zm_powerups::specific_powerup_drop(powerup, point.origin);
	}
}

function holdOut1(){
	start_struct = struct::get("holdout1", "targetname");
	self holdOut(start_struct, HOLDOUT_TIME);
	return true;
}

function holdOut2(){
	start_struct = struct::get("holdout2", "targetname");
	self holdOut(start_struct, HOLDOUT_TIME);
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