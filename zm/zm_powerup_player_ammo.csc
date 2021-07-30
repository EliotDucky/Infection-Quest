#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_powerups;

#namespace zm_powerup_player_ammo;

REGISTER_SYSTEM( "zm_powerup_player_ammo", &__init__, undefined )

function __init__(){
	zm_powerups::include_zombie_powerup("player_ammo");
	zm_powerups::add_zombie_powerup("player_ammo");
}