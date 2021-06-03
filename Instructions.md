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

## Rewards

## Holdout

Each holdout island requires:

(example for holdout 1)

- Struct for player to teleport to:

| Key 			| Value 							|
| -------------:|:--------------------------------- |
| classname		| script_struct						|
| targetname	| holdout1 							|

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