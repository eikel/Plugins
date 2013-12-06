/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/GUI/Plugin.escript
 **
 **/


//! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI',
		Plugin.DESCRIPTION : "Main application\'s GUI.",
		Plugin.VERSION : 0.6,
		Plugin.AUTHORS : "Claudius, Ralf & Benjamin",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/SceneManagement','PADrend/EventLoop','PADrend/SystemUI','LibGUIExt'],
		Plugin.EXTENSION_POINTS : [	]
});

// -------------------


/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init @(override) := fn(){
	//  Init global GUI Manager
	GUI.init(PADrend.SystemUI.getWindow(), PADrend.getEventContext());
    
	{
		registerExtension( 'PADrend_Init',this->initGUIResources,Extension.HIGH_PRIORITY+1);
		
		// right click menu
		if(systemConfig.getValue( 'PADrend.GUI.rightClickMenu',true)){
			registerExtension( 'PADrend_UIEvent',this->fn(evt){
				if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_RIGHT && evt.pressed && !PADrend.getEventContext().isCtrlPressed()){
					gui.openMenu(new Geometry.Vec2(evt.x,evt.y),'PADrend_SceneToolMenu');
				}
				return false;
			});
		}
	}
	loadPlugins([
			__DIR__+"/ConfigWindow.escript",
			__DIR__+"/MainToolbar.escript",
			__DIR__+"/MainWindow.escript",
			__DIR__+"/MessageWindow.escript",
			__DIR__+"/ToolsToolbar.escript" ],true);

	return true;
};


//! [ext:PADrend_Init]
plugin.initGUIResources := fn(){
	
	var resourceFolder = __DIR__+"/../resources";

	gui.loadIconFile( resourceFolder+"/Icons/PADrendDefault.json");
	
	GUI.OPTIONS_MENU_MARKER @(override) := {
		GUI.TYPE : GUI.TYPE_ICON,
		GUI.ICON : '#DownSmall',
		GUI.ICON_COLOR : new Util.Color4ub(0x30,0x30,0x30,0xff)
	};

	// init fonts
	gui.registerFonts({
//		GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.png",
		GUI.FONT_ID_DEFAULT : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_12.fnt",
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",12, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
//		GUI.FONT_ID_DEFAULT : 		GUI.BitmapFont.createFont(resourceFolder+"/Fonts/BAUHS93.ttf",20, " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"),
		GUI.FONT_ID_HEADING : 		resourceFolder+"/Fonts/DejaVu_Sans_14.fnt",
		GUI.FONT_ID_LARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_Codensed_18.fnt",
		GUI.FONT_ID_TOOLTIP : 		resourceFolder+"/Fonts/DejaVu_Sans_10.fnt",
		GUI.FONT_ID_WINDOW_TITLE : 	resourceFolder+"/Fonts/DejaVu_Sans_12.fnt",
		GUI.FONT_ID_XLARGE : 		resourceFolder+"/Fonts/DejaVu_Sans_32_outline_aa.fnt",
		GUI.FONT_ID_HUGE : 			resourceFolder+"/Fonts/DejaVu_Sans_64_outline_aa.fnt",
	});
    
    
    
    gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, Util.loadBitmap(resourceFolder+"/MouseCursors/3dSceneCursor.png"), 0, 0);
    gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_TEXTFIELD, Util.loadBitmap(resourceFolder+"/MouseCursors/TextfieldCursor.png"), 8, 8);
    gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_RESIZEDIAGONAL, Util.loadBitmap(resourceFolder+"/MouseCursors/resizeCursor.png"), 9, 9);
	
	GUI.FileDialog.folderCacheProvider = PADrend.configCache;
};

 
return plugin;
// ------------------------------------------------------------------------------