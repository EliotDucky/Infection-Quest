# Infection/Hotel v3 Easter Egg Quest Script Setup Instructions

## Consoles

- Trigger to press activate on to iniate a trial
- Place at use height in front of console model
- Hintstring will not display until power turned on
- Will be disabled on all consoles whilst a trial is ongoing

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_use 						|
| targetname	| quest_console						|
| target 		| *reward origin targetname* 	  	|
| script_int 	| *unique integer from 0 upwards* 	|

- To teleport, set up a buffer location in a box

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_origin 					|
| targetname	| teleport_buffer					|

- Teleport box also requires a zone

| Key 					| Value 							|
| ---------------------:|:--------------------------------- |
| classname				| info_volume 						|
| targetname			| tele_zone 						|
| script_noteworthy 	| player_volume 					|

## Freerun

(example for "Freerun 1")

- Setup inside a player volume called trial zone, same for both freeruns

| Key 					| Value 							|
| ---------------------:|:--------------------------------- |
| classname				| info_volume 						|
| targetname			| trial_zone 						|
| script_noteworthy 	| player_volume 					|

- Start point:

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_struct						|
| targetname	| freerun1 							|
| origin		| *location to teleport player to* 	|
| angles 		| *direction for player to face* 	|

- Chasm: Place as many as you like under the freerun area.
If the player touches this, they will be teleported back to a checkpoint.

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_multiple					|
| targetname	| chasm_trigger 					|

- Checkpoints require trigger multiples for the activation location
and a struct placed in the ground for teleporting back to if they fall into the chasm.

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_multiple					|
| targetname	| freerun1_checkpoint 				|
| target 		| *targetname of respawn struct* 	|

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_struct						|
| targetname	| *respawn struct unique name* 		|

- Finishing line:

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_multiple					|
| targetname	| freerun1_complete 				|

## Rewards

- Exploders (example for light 0)

Red Light

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| name 			| red_light_0						|
| default_state | On								|

Green Light (yes, this should be on - it is turned off through script)

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| name 			| green_light_0						|
| default_state | On								|

- Reward door.

Setup a door trigger outside of the playspace.

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_use						|
| targetname	| zombie_door 						|
| script_flag	| reward_door						|
| target		| reward_door 						|

Setup model or brush how you would a normal door,
use clips as you would in a normal door, (example):

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_brushmodel					|
| targetname	| reward_door 						|
| script_string	| move								|
| script_vector	| 0 0 -100 							|

- Rewards door camera position (camera placed here as the door opens)
- Height should be about 72 off the ground

| Key           | Value                             |
| -------------:|:--------------------------------- |
| classname     | script_origin                     |
| targetname    | reward_door_cam                   |

- Perk drop rewards with `script_notworthy: "r"`

| Key 				| Value 							|
| -----------------:|:--------------------------------- |
| classname			| script_origin						|
| targetname		| *unique name targeted by console* |
| script_noteworthy	| r									|

- Add rewards script path to zone

`scriptparsetree,scripts/zm/zm_hotel_rewards.gsc`

- Create a trigger in radiant for each reward

| Key		    | Value							     |
| -------------:|:---------------------------------  |
| classname	    | trigger_use					     |
| targetname	| reward_room_trig				     |
| script_string | *wpn_name (without "hero")*		 |
| target		| *model to display*		         |

| Key           | Value                              |
| -------------:|:---------------------------------  |
| classname     | script_model                       |
| targetname    | *target of trigger*                |

- Perk reward trigger

| Key               | Value                                 |
| -----------------:|:---------------------------------     |
| classname         | trigger_use                           |
| targetname        | zombie_vending                        |
| script_noteworthy | *specialty_name* (incl. "specialty")  |

## Holdout

Each holdout island requires:

(example for holdout 1)

- Struct for player to teleport to:

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_struct						|
| targetname	| holdout1 							|
| origin		| *location to teleport player to* 	|
| angles 		| *direction for player to face* 	|
| target 		| holdout1_powerups 				|

- Zone volume covering holdout area and zombie spawners:

| Key 					| Value 							|
| ---------------------:|:--------------------------------- |
| classname				| info_volume 						|
| targetname			| holdout1_zone 					|
| target 				| holdout1_spawners				  	|
| script_noteworthy 	| player_volume 					|

- Zombie spawn points:

| Key 					| Value 							|
| ---------------------:|:--------------------------------- |
| classname				| script_struct						|
| targetname			| holdout1_spawners					|
| script_string			| find_flesh **or** receiver_name  	|
| script_noteworthy 	| riser_location 					|

- Pathnode placed on floor to generate navmesh

- Script_origins placed where max ammos or other drops should spawn periodically
- Add Player Ammo scripts to zone

Remember that powerups spawn ~56 units above where they're told to


| Key 					| Value 							|
| ---------------------:|:--------------------------------- |
| classname				| script_origin						|
| targetname			| holdout1_powerups					|
| origin				| location to spawn powerup			|

- Define zombie health during the holdout in the GSH file
- Create an array of weapons and attachments for the holdout loadouts
	- one will be selected randomly

- Place dog spawners for the zombies to run to whilst the player is down for 5 seconds

- Add a chasm trigger before the bottom of the zone's info volume. If the player touches this,
 they will be downed and teleported back to the start point (script_origin) of this holdout

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| trigger_multiple					|
| targetname	| chasm_trigger 					|
| script_string	| holdout 							|

## Console Defences

- To attract zombies to the console, place as many script_origins as desired around it

| Key 					| Value 								|
| ---------------------:|:------------------------------------- |
| classname				| script_origin							|
| targetname			| *same as target of console trigger* 	|
| origin				| location to attract zombies to		|
| script_noteworthy		| poi									|

- To display flashing lights indicating console health & normal status lights,
 include targeted script_origins around it

| Key 					| Value 								|
| ---------------------:|:------------------------------------- |
| classname				| script_origin							|
| targetname			| *same as target of console trigger* 	|
| origin				| location to play lights on 			|
| script_noteworthy		| light_loc								|

- The flashing light FX names should be registered in zone

## Spike Launcher

- Add to zone

```
//Spike Launcher
weapon,spike_launcher_zm
weapon,spike_charge_zm
scriptparsetree,scripts/zm/zm_hotel_spike_launcher.gsc
```

- In `mapname.csc`

```
#using scripts\shared\weapons\spike_charge;
```

- In `mapname.gsc`

```
#using scripts\zm\zm_hotel_spike_launcher;
```