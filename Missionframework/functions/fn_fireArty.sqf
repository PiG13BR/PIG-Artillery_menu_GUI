/* 
Author: PiG13BR
fn_fireArty.sqf
Last Update: 24-11-11

Description:
Get the classname of the artillery
Checks if the artillery is busy
Checks if the artillery is in range
Create target markers
Fire the artillery
Deletes the target markers as soon the first rounds lands

Parameter(s):
0 - OBJECT (Artillery)
1 - STRING (Type of ammunition)
2 - NUMBER (Number of rounds to fire)
3 - POSITION ARRAY (Target Position)

Return:
-

[arty1, "32Rnd_155mm_Mo_shells", 3, getMarkerPos "targetPos_refer"] spawn PIG_fnc_fireArty;
*/

params["_arty", "_ammo", "_rounds", "_targetPos"];

_artyClass = typeOf _arty;
private _nameArty = getText(configFile >> "CfgVehicles" >> _artyClass >> "displayName");

if ((gunner _arty) getVariable ["PIG_isGunnerBusy", false]) exitWith {hint localize "STR_ARTY_BUSY";};
//if !(unitReady (gunner _arty)) exitWith {hint localize "STR_ARTY_BUSY"; PIG_fire_button = 0;};

// Check if the target is in artillery range
_isInRange = _targetPos inRangeOfArtillery [[_arty], _ammo];
if !(_isInRange) exitWith {hint localize "STR_ARTY_RANGE"; PIG_fire_button = 0;};

(gunner _arty) setVariable ["PIG_isGunnerBusy", true, true];

// Make always a different name for the markers
_numName = missionNamespace getVariable "numMarkerName";
if (isNil "_numName") then {
	_numName = 0
};
_numName = _numName + 1;
// Always store the number created in the variable so that not repeats on the next time
missionNamespace setVariable ["numMarkerName", _numName];
private _markerName = format["arty_icon_%1",_numName];

_numBorder = missionNamespace getVariable "numMarkerBorder";
if (isNil "_numBorder") then {
	_numBorder = 0
};
_numBorder = _numBorder + 1;
missionNamespace setVariable ["numMarkerBorder", _numBorder];
private _markerBorderName = format["arty_border_%1",_numBorder];

// Get the ETA of the impact (in seconds)
_eta = _arty getArtilleryETA [_targetPos, _ammo];
_eta = round(floor (_eta));

//Create a border marker
_markerBorder = createMarker [_markerBorderName, _targetPos];
_markerBorder setMarkerShape "ELLIPSE";
_markerBorder setMarkerBrush "BDiagonal";
_markerBorder setMarkerSize [75,75];
_markerBorder setMarkerColor "colorRED";

// Create a artillery target marker
_markerIcon = createMarker [_markerName, _targetPos];
_markerIcon setMarkerType "hd_objective";
_markerIcon setMarkerColor "colorRED";
_markerIcon setMarkerShape "ICON";
_markerIcon setMarkerText (localize "STR_ARTY_MARKER_FIRE") + " " + str _nameArty + " " + "(" + str _eta + "s" + ")";

_weaponTurret = (_arty weaponsTurret [0]) select 0;
private _reloadTime = getNumber(ConfigFile >> "CfgWeapons" >> _weaponTurret >> "magazineReloadTime");
if (_reloadTime < 1) then {_reloadTime = 1};

[_arty, _targetPos, _ammo, _rounds, _reloadTime, _eta, _markerIcon, _markerBorder] spawn {
	params["_arty", "_targetPos", "_ammo", "_rounds", "_reloadTime", "_eta", "_markerIcon", "_markerBorder"];
	sleep 1 + (random 5);

	// Actually fire the artillery
	for "_i" from 1 to _rounds do {
		if (local _arty) then {
			_arty doArtilleryFire [_targetPos, _ammo, 1];
		} else {
			[_arty, [_targetPos, _ammo, 1]] remoteExec ["doArtilleryFire", owner _arty];
		};
		sleep (3 + _reloadTime)
	};

	(gunner _arty) setVariable ["PIG_isGunnerBusy", false, true];

	// Sleep based on the impact ETA
	sleep (5 + _eta);
	deleteMarker _markerIcon;
	deleteMarker _markerBorder;
};