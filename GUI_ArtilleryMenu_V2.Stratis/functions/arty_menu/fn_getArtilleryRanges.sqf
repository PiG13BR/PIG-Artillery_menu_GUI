/*  
    File: fn_getArtilleryRanges.sqf
    Author: Antistasi Dev Team - https://github.com/SilenceIsFatto/A3-Antistasi-Ultimate/blob/stable/A3A/addons/core/functions/Supports/fn_getArtilleryRanges.sqf
    Date: -
    Last Update: -

    Description:
        Find minimum and maximum ranges for artillery type
    
    Parameter(s):
        Classname - classname of artillery vehicle - [STRING, Defaults to ""]
        Classname - classname of artillery magazine - [STRING, Defaults to ""]

    Return(s):
        Minimum range in meters [SCALAR] and Maximum range in meters [SCALAR] - [ARRAY]
*/

params [
    ["_vehType", "", [""]], 
    ["_shellType", "", [""]]
];

if ((_vehType isEqualTo "") || {_shellType isEqualTo ""}) exitWith {};

private _turretCfg = call {
    private _allTurrets = configProperties [configFile >> "CfgVehicles" >> _vehType >> "Turrets"];
    private _idx = _allTurrets findIf { getNumber (_x >> "elevationMode") == 3 };       // no idea if this is a valid check
    /* if (_idx == -1) exitWith {
        Error_1("Artillery turret not found on %1", _vehType);
        configFile >> "CfgVehicles" >> _vehType >> "Turrets" >> "MainTurret";
    }; */
    _allTurrets # _idx;
};

// Try mags for pylon weapons, otherwise assume the turret weapon is valid
private _weapon = getText (configfile >> "CfgMagazines" >> _shellType >> "pylonWeapon");
if (_weapon == "") then { _weapon = getArray (_turretCfg >> "Weapons") # 0 };
private _weaponCfg = configFile >> "CfgWeapons" >> _weapon;

// Assume that there's no speed override on weapon, probably true for arty
private _initSpeed = getNumber (configFile >> "CfgMagazines" >> _shellType >> "initSpeed");
private _maxElev = getNumber (_turretCfg >> "maxElev");
// Simple formula works because Arma doesn't calculate air resistance for artillery
private _maxRange = (_initSpeed)^2 * sin (2*45) / 9.807;

// Assumes first fire mode is closest range, probably true because artillery computer
private _minCharge = getNumber (_weaponCfg >> getArray (_weaponCfg >> "modes")#0 >> "artilleryCharge");
if (_minCharge == 0) then { [format["Artillery charge lookup failed for %1", _vehType]] call bis_fnc_error; _minCharge = 1 };
private _minRange = (_minCharge * _initSpeed)^2 * sin (2*_maxElev) / 9.807;

[_minRange+200, _maxRange-200];     // make sure we can spread shots
