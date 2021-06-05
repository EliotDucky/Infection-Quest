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
| target 		| *reward struct targetname* 	  	|
| script_int 	| *unique integer from 0 upwards* 	|

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