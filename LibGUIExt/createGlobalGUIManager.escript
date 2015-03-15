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


// set a callback used to determine a folder used for caching data (e.g. rastered fonts)
GUI.GUI_Manager.setCacheFolderProvider ::= fn( provider ){
	this._cacheFolderProvider := provider;
};

GUI.GUI_Manager.getCacheFolder ::= fn(){
	return (this.isSet($_cacheFolderProvider) && this._cacheFolderProvider) ? this._cacheFolderProvider() : ".";		
};

//GUI.GUI_Manager.onMouseMove @(init,const) :=  Std.MultiProcedure; // \todo (Cl) not working correctly until now...


//! Creates global guiManager GLOBALS.gui.
return fn(Util.UI.Window window, Util.UI.EventContext eventContext) {
	if(GLOBALS.isSet($gui)&& GLOBALS.gui)
		Runtime.exception("Global GUIManager (GLOBALS.gui) already exists.");
	
	module('./GUIManagerExtensions/initComponentFactories');
	module('./GUIManagerExtensions/initComponentGroupFactories');
	module('./GUIManagerExtensions/initComponentRegistry');
	module('./GUIManagerExtensions/initDialogFactories');
	module('./GUIManagerExtensions/initFontHandling');
	module('./GUIManagerExtensions/initIconHandling');
	module('./GUIManagerExtensions/initMenuHandling');
	module('./GUIManagerExtensions/initNewComponents');
		
	module('./initComponentExtensions');
	
	GLOBALS.gui := new GUI.GUI_Manager(eventContext);
	gui.setWindow(window);
	gui.initDefaultFonts();  // see FontHandling.escript
	gui._destructionMonitor := void; // (optional for debugging) Util.DestructionMonitor
	gui.onMouseMove := new Std.MultiProcedure; // \todo (Cl) replace by @(init) alternative below when Type._supportsInit() is implemented.
	gui.onMouseButton := new Std.MultiProcedure; // \todo (Cl) replace by @(init) alternative below when Type._supportsInit() is implemented.


	GLOBALS.gui.windows := new Map; //! \deprecated
	return gui;
};


// ------------------------------------------------------------------------------------
