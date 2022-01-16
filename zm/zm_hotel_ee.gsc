#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_utility.gsh;

#using scripts\zm\_load;
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;

#insert scripts\zm\_zm_powerups.gsh;

#using scripts\shared\ai\zombie_utility;

//Perks
#using scripts\zm\_zm_pack_a_punch;
#using scripts\zm\_zm_pack_a_punch_util;
#using scripts\zm\_zm_perk_additionalprimaryweapon;
#using scripts\zm\_zm_perk_doubletap2;
#using scripts\zm\_zm_perk_deadshot;
#using scripts\zm\_zm_perk_juggernaut;
#using scripts\zm\_zm_perk_quick_revive;
#using scripts\zm\_zm_perk_sleight_of_hand;
#using scripts\zm\_zm_perk_staminup;

//Powerups
#using scripts\zm\_zm_powerup_double_points;
#using scripts\zm\_zm_powerup_carpenter;
#using scripts\zm\_zm_powerup_fire_sale;
#using scripts\zm\_zm_powerup_free_perk;
#using scripts\zm\_zm_powerup_full_ammo;
#using scripts\zm\_zm_powerup_insta_kill;
#using scripts\zm\_zm_powerup_nuke;
//#using scripts\zm\_zm_powerup_weapon_minigun;

//Traps
#using scripts\zm\_zm_trap_electric;

//Quests
#using scripts\zm\zm_hotel_quest;

//Spike Launcher
#using scripts\zm\weapons\zm_weap_spike_launcher\zm_weap_spike_launcher;

//Reward Weapons
#using scripts\zm\_zm_hero_weapon;
#using scripts\zm\_zm_weap_annihilator;
#using scripts\zm\_zm_weap_gravityspikes;

#using scripts\zm\zm_usermap;

#namespace zm_hotel;

//*****************************************************************************
// MAIN
//*****************************************************************************

function main()
{
	level.dog_rounds_allowed = 0;
	
	zm_usermap::main();
	level.giveCustomCharacters =&giveCustomCharacters;
	level._zombie_custom_add_weapons =&custom_add_weapons;
	
	//Setup the levels Zombie Zone Volumes
	level.zones = [];
	level.zone_manager_init_func =&usermap_test_zone_init;
	//init_zones[0] = "start_zone";
	init_zones = Array("start_zone", "holdout1_zone", "holdout2_zone");
	level thread zm_zonemgr::manage_zones( init_zones );

	level.pathdist_type = PATHDIST_ORIGINAL;

	level.player_starting_points = 30000;

	zm_weap_spike_launcher::setSpikeAttractDist(512);

	level._powerup_timeout_custom_time = &powerupTimeoutCustomTime;

	thread scriptbundleTest();
}

function usermap_test_zone_init()
{
	level flag::init( "always_on" );
	level flag::set( "always_on" );
}	

function custom_add_weapons()
{
	zm_weapons::load_weapon_spec_from_table("gamedata/weapons/zm/zm_levelcommon_weapons.csv", 1);
}

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

function giveCustomCharacters()
{
	if( isdefined(level.hotjoin_player_setup) && [[level.hotjoin_player_setup]]("c_zom_farmgirl_viewhands") )
	{
		return;
	}
	
	self DetachAll();
	
	// Only Set Character Index If Not Defined, Since This Thread Gets Called Each Time Player Respawns
	//-------------------------------------------------------------------------------------------------
	if ( !isdefined( self.characterIndex ) )
	{
		self.characterIndex = assign_lowest_unused_character_index();
	}
	
	self.favorite_wall_weapons_list = [];
	self.talks_in_danger = false;	
	
	self SetCharacterBodyType( self.characterIndex );
	self SetCharacterBodyStyle( 0 );
	self SetCharacterHelmetStyle( 0 );
	self thread zm_usermap::set_exert_id();
	
}

function assign_lowest_unused_character_index()
{
	//get the lowest unused character index
	charindexarray = [];
	charindexarray[0] = 0;// - Dempsey )
	charindexarray[1] = 1;// - Nikolai )
	charindexarray[2] = 2;// - Richtofen )
	charindexarray[3] = 3;// - Takeo )
	
	players = GetPlayers();
	if ( players.size == 1 )
	{
		charindexarray = array::randomize( charindexarray );
		if ( charindexarray[0] == 2 )
		{
			level.has_richtofen = true;	
		}

		return charindexarray[0];
	}
	else // 2 or more players just assign the lowest unused value
	{
		n_characters_defined = 0;

		foreach ( player in players )
		{
			if ( isDefined( player.characterIndex ) )
			{
				ArrayRemoveValue( charindexarray, player.characterIndex, false );
				n_characters_defined++;
			}
		}
		
		if ( charindexarray.size > 0 )
		{	
			// Randomize the array
			charindexarray = array::randomize(charindexarray);
			if ( charindexarray[0] == 2 )
			{
				level.has_richtofen = true;	
			}

			return charindexarray[0];
		}
	}

	//failsafe
	return 0;
}

//Call On: level
function scriptbundleTest(){
	trig = GetEnt("scriptbundle_test", "targetname");
	trig SetHintString("Press ^3[{+activate}]^7 to test scene");
	trig SetCursorHint("HINT_NOICON");
	while(true){
		trig waittill("trigger", player);
		IPrintLnBold("play");
		player thread scene::play("cin_gen_player_hack_start", player);
		player clientfield::set_to_player("sndCCHacking", 1);
		wait(2);
		player clientfield::set_to_player( "sndCCHacking", 0);
		player scene::play("cin_gen_player_hack_finish", player);
	}
}