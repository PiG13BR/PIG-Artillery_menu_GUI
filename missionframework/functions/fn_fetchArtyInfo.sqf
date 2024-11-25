/*  
    File: fn_fetchArtyInfo.sqf
    Author: PiG13BR - https://github.com/PiG13BR
    Date: 24-02-07
    Last Update: 24-25-11

    Description:
        Get all the information about the artillery units to fill the list boxes of the artillery menu
    
    Parameter(s):
        -

    Return(s):
        -
*/

createDialog "PIG_RscArtyMenu";

// Always clear the main list box
lbClear 2100;

// Update the artillery list. Check if the unit is alive and has crew on it.
PIG_artillery_support = PIG_artillery_support select {(alive _x) && (count (fullCrew [_x, "gunner", false]) != 0)};

// Check if there are artillery vehicles inside the PIG_artillery_support
if (count PIG_artillery_support == 0) exitWith {
	hint localize "STR_ARTY_AVAILABLE";
};

// Get the name of each artillery in PIG_artillery_support and add to the first list box
{	
	_type = typeOf _x;
	// Filter the list with only artillery units. Those units have "artilleryScanner = 1" under CfgVehicles;
	if ((getNumber(configfile >> "CfgVehicles" >> _type >> "artilleryScanner") > 0)) then {
		private _name = getText(configFile >> "CfgVehicles" >> _type >> "displayName");
		_name = _name + " " + "(" + (groupID (group _x)) + ")"; // Update with the group ID
		lbAdd [2100, _name];
		// Store list box data
		lbSetData [2100, _forEachIndex, _type];
	}
}forEach PIG_artillery_support;

// Artillery position marker
createMarkerLocal ["artySel_marker", markers_reset];
"artySel_marker" setMarkerTypeLocal "b_art";
"artySel_marker" setMarkerColorLocal "ColorBLUFOR";
"artySel_marker" setMarkerSize [1.2, 1.2]; // Make it a little bigger

ctrlEnable [1600, false]; // Disable fire button as default

// Add control event handler to the artillery list box
(displayCtrl 2100) ctrlAddEventHandler ["LBSelChanged",{
	params ["_control", "_lbCurSel", "_lbSelection"];

	// Clear the second list box
	lbClear 2101;

	// Get artillery list box data
	_arty = lbData [2100,_lbCurSel];

	// Get the selected artillery object and store it in a variable to be used later
	_gun = (PIG_artillery_support select {typeOf _x == _arty}) # 0;
	"artySel_marker" setMarkerPosLocal (_gun);
	"artySel_marker" setMarkerText (getText (configFile >> "CfgVehicles" >> typeOf _gun >> "displayName")) + " " + "(" + (groupId (group _gun)) + ")";
	uiNamespace setVariable ["artySelected", _gun];

	// Get artillery ammo
	_ammo = getArtilleryAmmo [_gun];

	// Add the name of the available magazines to the second list box
	{
		_name = getText(configFile >> "CfgMagazines" >> _x >> "displayName");
		lbAdd [2101, _name];
		lbSetData [2101, _forEachIndex,_x];
	}forEach _ammo;
}];

// Add control event handler for the ammo list box
(displayCtrl 2101) ctrlAddEventHandler ["LBSelChanged",{
	params ["_control", "_lbCurSel", "_lbSelection"];

	// Clear the third list box
	lbClear 2102;

	// Get the artillery object from the stored variable
	_arty = uiNamespace getVariable "artySelected";
	// Check avaiable magazines and how many rounds per magazine
	_magArray = magazinesAmmo _arty;
	// Select only rounds left for the selected magazine (The order of the _magArray respects the order of the list box)
	// If some magazine is empty, the array in _magArray will be deleted.
	_rounds = (_magArray select _lbCurSel) select 1;
	_allRounds = [];

	// Add how many rounds the player can select for the magazine selected in the second list box. From 1 to the number of rounds.
	for "_i" from 1 to _rounds do {
		lbAdd [2102, str _i];
		_allRounds pushBack _i;
	};
	
	// Store the data to be used later
	{
		lbSetValue [2102, _forEachIndex, _x];
	}forEach _allRounds;

}];

// Add on mouse button down EH for the control map
(displayCtrl 51) ctrlAddEventHandler ["MouseButtonDown", { 
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	if (_button == 0) then {
		getMousePosition params ["_mouseX", "_mouseY"];
		
		PIG_fireArtyPos = (_displayOrControl ctrlMapScreenToWorld [_mouseX, _mouseY]);

		_createMarker = createMarkerLocal ["marker_arty", PIG_fireArtyPos];
		"marker_arty" setMarkerTypeLocal "hd_objective";
		"marker_arty" setMarkerTextLocal (localize "STR_ARTY_MARKER_TARGET");
		"marker_arty" setMarkerPos PIG_fireArtyPos;
	}
}];

// Draw EH fires per frame. Use this to draw lines in the map and check list boxes selections.
(displayCtrl 51) ctrlAddEventHandler ["Draw",{
	params ["_controlOrDisplay"];
	_pos = PIG_fireArtyPos;
	_gun = uiNamespace getVariable "artySelected";
	_ranges = [(typeOf _gun), lbData [2101, (lbCurSel 2101)]] call PIG_fnc_getArtilleryRanges;
	_ranges params ["_min", "_max"];
	
	if ((!isNil "_pos") && {!isNull _gun}) then {
		// Draws line from artillery gun to target position
		_controlOrDisplay drawLine [getPos _gun, _pos, [0, 0, 0, 1]];

		// Draws an ellipse that represents min range for the artillery gun
		_controlOrDisplay drawEllipse [
			_gun, _min, _min, 0, [0, 0, 0, 1], ""
		];
		// Draws an ellipse that represents max range for the artillery gun
		_controlOrDisplay drawEllipse [
			_gun, _max, _max, 0, [0, 0, 0, 1], ""
		];
	};

	private _inRange = false;
	// Check range
	if (((PIG_fireArtyPos distance2d _gun) < _min) || {(PIG_fireArtyPos distance2d _gun) > _max}) then {
		_inRange = false;
	} else {
		_inRange = true;
	};

	private _listBoxesSel = false;
	// Check list boxes selections
	if ((lbCurSel 2100 == -1) || {lbCurSel 2101 == -1} || {lbCurSel 2102 == -1}) then {
		_listBoxesSel = false;
	} else {
		// All list boxes a value selected
		_listBoxesSel = true;
	};

	// Disable/enable fire button
	if (_inRange && {_listBoxesSel}) then {
		ctrlEnable [1600, true]; // Enable fire button
		(displayCtrl 1600) ctrlSetTooltip "";
	} else {
		ctrlEnable [1600, false]; // Disable fire button
		(displayCtrl 1600) ctrlSetTooltip "Fire Disabled/Not in range";
	};
}];

// Fire button
(displayCtrl 1600) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];

	// Check if the artillery is selected
	private _indexArty = lbCurSel 2100;
	if (_indexArty == -1) exitWith {hint localize "STR_SELECT_ARTY";};
	// Get the selected artillery object
	private _arty = uiNamespace getVariable "artySelected";

	// Check if the ammunition is selected
	private _indexAmmo = lbCurSel 2101;
	if (_indexAmmo == -1) exitWith {hint localize "STR_SELECT_AMMO";};
	// Get the selected artillery ammo
	_ammo = lbData [2101,_indexAmmo]; 

	// Check how many rounds
	private _indexRound = lbCurSel 2102;
	if (_indexRound == -1) exitWith {hint localize "STR_SELECT_ROUNDS";};
	// Get the selected rounds
	_rounds = lbValue [2102,_indexRound];

	// Check if the player clicked on the map
	if (isNil "PIG_fireArtyPos") exitWith {hint localize "STR_SELECT_POSITION";};
	// Get marker position and it's elevation (Legion)
	_targetPos = getMarkerPos ["marker_arty", true];

	//_clientId = clientOwner;
	[_arty, _ammo, _rounds, _targetPos] remoteExec ["PIG_fnc_fireArty", 2];

	// Delete the placeholder target marker
	deleteMarkerLocal "marker_arty";

	// Delete pos variable
	PIG_fireArtyPos = nil;
}];

// On Display/Dialog closed
(findDisplay 1000) displayAddEventHandler ["Unload",{
	params ["_display", "_closedChildDisplay", "_exitCode"];

	// Clear variables
	PIG_fireArtyPos = nil;
	uiNamespace setVariable ['artySelected', nil];
	deleteMarkerLocal 'artySel_marker'; 
	deleteMarkerLocal 'marker_arty';
}];

