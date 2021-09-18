#using scripts\shared\callbacks_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#using scripts\shared\weapons\_weaponobjects;

#namespace zm_hotel_spike_launcher;

function autoexec __init__system__(){
	_arr = undefined;
	system::register("zm_hotel_spike_launcher", &__init__, &__main__, _arr);
}

function __init__(){
}

function __main__(){
	callback::on_connect(&spikeLauncherTutorialWatcher);
	callback::on_connect(&spikeLauncherWatcher);
}

//Call On: Player
function spikeLauncherWatcher(){
	self weaponobjects::createSpikeLauncherWatcher("spike_launcher");
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
		self thread spikeLauncherTutorialHUD();
		self util::waittill_any("detonate", "last_stand_detonate");
		self.spike_launcher_tutorial_complete = true;
	}
}

//Call On: Player
function spikeLauncherTutorialHUD(){
	self notify("spike_launcher_HUD");
	self endon("spike_launcher_HUD");
	font = "default";
	fontscale = 2;
	if(level.Splitscreen && !level.hidef){
		fontscale = 3;
	}
	txt = self hud::createFontString(font, fontscale);
	txt.vertalign = "bottom";
	txt.y = -100;
	txt.alpha = 0;
	txt SetText("PRESS ^3[{+melee}]^7 TO DETONATE SPIKE CHARGE");
	txt FadeOverTime(0.5);
	txt.alpha = 1;

	self util::waittill_any_timeout(20, "detonate", "last_stand_detonate");

	txt FadeOverTime(0.5);
	txt.alpha = 0;
	wait(0.5);
	txt Destroy();
}