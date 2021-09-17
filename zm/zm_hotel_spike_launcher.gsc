#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#using scripts\shared\weapons\_weaponobjects;

#namespace zm_hotel_spike_launcher;

function autoexec __init__system__(){
	_arr = undefined;
	system::register("zm_hotel_spike_launcher", &__init__, &__main__, _arr);
}

function __init__(){
	launcher = GetWeapon("spike_launcher");
	weaponobjects::createSpikeLauncherWatcher(launcher);
}

function __main__(){
	callback::on_connect(&spikeLauncherTutorialWatcher);
}

//Call On: Player
//Callback on spawned
function spikeLauncherTutorialWatcher(){
	wpn_spike_launcher = GetWeapon("spike_launcher");
	self.spike_launcher_tutorial_complete = false;
	w_current = self GetCurrentWeapon();
	while(!self.spike_launcher_tutorial_complete){
		if(w_current == wpn_spike_launcher){
			self detonateWaitTill(wpn_spike_launcher);
		}else{
			self waittill("weapon_change_complete", w_current);
		}
	}
}

//Call On: Player
function detonateWaitTill(wpn_spike_launcher){
	self endon("death");
	self endon("detonate");
	self waittill("weapon_fired", w_current);
	if(w_current == wpn_spike_launcher){
		wait(2);
		IPrintLnBold("HUD TEXT: Press Melee To Detonate"); //HUD TEXT FUNCTION HERE
		//self util::waittill_any("detonate", "last_stand_detonate");
	}
}