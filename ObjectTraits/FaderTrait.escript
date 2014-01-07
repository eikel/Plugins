/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/Fader');
declareNamespace($ObjectTraits);
ObjectTraits.Fader := trait;

trait.onInit += fn(node){
	PADrend.message("Fade...");
	node.fadeTime := DataWrapper.createFromValue(1);
	node.fadeTime := DataWrapper.createFromValue(1);
	node.onClick := fn(evt){
		this.deactivate();
		PADrend.planTask(this.fadeTime(),this->activate);
	};		
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node){
		return [ "Fader trait",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Time",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.fadeTime //! \see ObjectTraits.Fader
			}
		];
	});
});

return trait;
