player addAction [["<img size='2' image='a3\ui_f\data\gui\cfg\communicationmenu\artillery_ca.paa'/>", "<t size='1.3' color='#8D5C07'>", localize "STR_ARTY_MENU_ACTION","</t>"] joinString "", {
	
	[] call PIG_fnc_fetchArtyInfo;
	}, nil, 1.5, true, true, "", 
	"isNull (objectParent _this) && 
	leader _this == _this && {
	alive _this
	}" 
	]