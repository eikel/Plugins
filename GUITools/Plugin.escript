/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return new Plugin({
			Plugin.NAME : "GUITools",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Collection of gui tools.",
			Plugin.AUTHORS : "Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : [
				'GUITools/Logo','GUITools/MessageWindow','GUITools/OSD',
			]
});

// ------------------------------------------------------------------------------
