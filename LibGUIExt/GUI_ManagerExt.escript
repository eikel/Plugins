/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 // ------------------------------------------------------------------------------
// GUI Manager extensions

/*! ---o
	Convert the given @p screen position in window coordinates into gui coordinates.
	Normally, this just returns the same value as Geometry.Vec2. 
	To transform a coordinate transformation, replace this method.
	\note Always use this method to convert the coordinate of a ui-event!
*/
GUI.GUI_Manager.screenPosToGUIPos ::= fn( screenPos ){
	var guiPos = new Geometry.Vec2(screenPos);
	return guiPos;
};

/*! ---o
	Convert the given @p gui position in window coordinates into screen coordinates.
	Normally, this just returns the same value as Geometry.Vec2. 
	To transform a coordinate transformation, replace this method.
	\note Use this method to convert events generated by gui itself (e.b. c.onMouseButton(evt))
*/
GUI.GUI_Manager.guiPosToScreenPos ::= fn( guiPos ){
	var screenPos = new Geometry.Vec2(guiPos);
	return new Geometry.Vec2(screenPos);
};

GUI.GUI_Manager.registerPreset ::= fn(String id, presetProvider){
	if(!this.isSet($_presets))
		this._presets @(private) := new Map;
	this._presets[id] = presetProvider;
};

GUI.GUI_Manager.getPreset ::= fn(String id){
	var preset;
	if(this.isSet($_presets)){
		if(id.beginsWith('/'))
			id = id.substr(1);
		else if(id.beginsWith('./'))
			id = id.substr(2);
		preset = this._presets[id];
		if(preset.isA(Map)){
			return preset.clone();
		}else if(preset){
			return preset().clone();
		}
	}
	return preset;
};


module('./GUIManagerExtensions/initComponentFactories');
module('./GUIManagerExtensions/initComponentGroupFactories');
module('./GUIManagerExtensions/initComponentRegistry');
module('./GUIManagerExtensions/initDialogFactories');
module('./GUIManagerExtensions/initFontHandling');
module('./GUIManagerExtensions/initIconHandling');
module('./GUIManagerExtensions/initMenuHandling');
module('./GUIManagerExtensions/initNewComponents');
	
module('./initComponentExtensions');

GUI.GUI_Manager.onMouseMove @(init,const) :=  Std.MultiProcedure; 
GUI.GUI_Manager.onMouseButton @(init,const) :=  Std.MultiProcedure; 
GUI.GUI_Manager._destructionMonitor := void;


return GUI.GUI_Manager;

// ------------------------------------------------------------------------------------