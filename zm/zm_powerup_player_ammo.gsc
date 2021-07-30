#using scripts\shared\laststand_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_placeable_mine;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;

#namespace zm_powerup_player_ammo;

REGISTER_SYSTEM( "zm_powerup_player_ammo", &__init__, undefined )

function __init__(){
	zm_powerups::register_powerup("player_ammo", &powerupPlayerAmmo);
	zm_powerups::add_zombie_powerup( "player_ammo",
									"p7_zm_power_up_max_ammo",
								 	&"ZOMBIE_POWERUP_MAX_AMMO",
								 	&zm_powerups::func_should_never_drop,
								 	true,
								 	false,
								 	false);
	zm_powerups::powerup_set_player_specific("player_ammo", true);
}

//self is the dropped ammo powerup
function powerupPlayerAmmo(player){
	valid = !player laststand::player_is_in_laststand();
	valid &= (!isdefined(level.check_player_is_ready_for_ammo) || ![[level.check_player_is_ready_for_ammo]](player));
	if(valid){
		primaries = player GetWeaponsList(true);
		player notify("zmb_max_ammo");
		player notify("zmb_lost_knife");
		player zm_placeable_mine::disable_all_prompts_for_player();
		foreach(weapon in primaries){
			_cont = level.headshots_only && zm_utility::is_lethal_grenade(weapon);
			_cont |= isdefined(level.zombie_include_equipment) && isdefined(level.zombie_include_equipment[weapon]) && !IS_TRUE(level.zombie_equipment[weapon].refill_max_ammo);
			_cont |= isdefined(level.zombie_weapons_no_max_ammo) && isdefined(level.zombie_weapons_no_max_ammo[weapon.name]);
			_cont |= zm_utility::is_hero_weapon(weapon);
			if(!_cont){
				if(player HasWeapon(weapon)){
					player GiveMaxAmmo(weapon);
				}
			}
		}
		level PlaySoundToPlayer("zmb_full_ammo", player);
		LUINotifyEvent(player,  &"zombie_notification", 1, self.hint);
	}
}
