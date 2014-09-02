/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2011 David Maicher
 * Copyright (C) 2012 Mouns R. Husan Almarrani
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/Plugin.escript
 **
 ** Shows and modifies the properties of nodes of he scene graph.
 ** \note Combination of old StateConfig-, GraphDisplay (by Benjamin Eikel)- and MeshTool-Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor',
		Plugin.DESCRIPTION : "Modifies nodes and states of the scene graph.",
		Plugin.VERSION : 0.2,
		Plugin.REQUIRES : ['PADrend','PADrend/Navigation'],
		Plugin.EXTENSION_POINTS : [
			/* [ext:NodeEditor_OnNodesSelected]
			 * Called whenever the selected nodes change
			 * @param   Array of currently selected nodes (do not change!)
			 * @result  void
			 */
			'NodeEditor_OnNodesSelected'
		]
});


static nodeClipboard = [];
static nodeClipboardMode = $COPY; // || $CUT
static NodeEditor;

plugin.init @(override) := fn() {
	
	NodeEditor = Std.require('NodeEditor/NodeEditor');

	/// Register ExtensionPointHandler:
	registerExtension('PADrend_Init', fn(){	NodeEditor.selectNode(PADrend.getCurrentScene());	});
	registerExtension('PADrend_UIEvent',fn(evt){
		if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON &&
				(evt.button == Util.UI.MOUSE_BUTTON_LEFT || evt.button == Util.UI.MOUSE_BUTTON_RIGHT) &&
				evt.pressed &&
				PADrend.getEventContext().isCtrlPressed()) {

			@(once) static Picking = Util.requirePlugin('PADrend/Picking');

			var node = Picking.pickNode( [evt.x,evt.y] );
			if(node && evt.button == Util.UI.MOUSE_BUTTON_RIGHT)
				node = objectIdentifier(node);

			if(PADrend.getEventContext().isShiftPressed()){
				if(node){
					if(NodeEditor.isNodeSelected(node))
						NodeEditor.unselectNode(node);
					else
						NodeEditor.addSelectedNode(node);
				}
			}else{
				NodeEditor.selectNode(node);
			}
			return true;
		}
		return false;
	});
	
	registerExtension('PADrend_OnSceneSelected', NodeEditor.selectNode); // automatically select the scene
	
	var modules = [
				__DIR__+"/GUI/Plugin.escript",
				__DIR__+"/Transformations.escript",
				__DIR__+"/BehaviourConfig/Plugin.escript" ,
				__DIR__+"/NodeConfig/Plugin.escript" ,
				__DIR__+"/StateConfig/Plugin.escript" ,
				__DIR__+"/Tools/Plugin.escript"
	];

	loadPlugins( modules,true);

	// ----------------------------
	NodeEditor.onSelectionChanged += fn(selectedNodes){		Util.executeExtensions('NodeEditor_OnNodesSelected',selectedNodes);	};

	// ----------------------------
	{	// highlight selected nodes
		static revoce = new Std.MultiProcedure;

		NodeEditor.onSelectionChanged += fn(selectedNodes){		
			revoce();
			if(!selectedNodes.empty())
				revoce += Util.registerExtensionRevocably('PADrend_AfterRenderingPass', [selectedNodes] => highlightNodes );
		};

		static COLOR_BG_NODE = new Util.Color4f(0,0,0,1);
		static COLOR_BG_SEM_OBJ = new Util.Color4f(0,0.4,0,1);
		static COLOR_TEXT_ORIGINAL = new Util.Color4f(1,1,1,1);
		static COLOR_TEXT_INSTANCE = new Util.Color4f(0.9,0.9,0.9,1);

		static highlightNodes = fn(selectedNodes,...){
			var skipAnnotations = selectedNodes.count()>20;
			foreach(selectedNodes as var node){
				if(!node || node==PADrend.getCurrentScene() || node==PADrend.getRootNode())
					continue;

				
				if(!skipAnnotations){
					frameContext.showAnnotation(node,NodeEditor.getString(node),0,true,
												node.isInstance() ? COLOR_TEXT_INSTANCE : COLOR_TEXT_ORIGINAL,
												MinSG.SemanticObjects.isSemanticObject(node) ? COLOR_BG_SEM_OBJ : COLOR_BG_NODE  );
				}

				renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
				renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());

				var bb = node.getBB();

				var blending=new Rendering.BlendingParameters;
				blending.enable();
				blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA, Rendering.BlendFunc.ONE);
				renderingContext.pushAndSetBlending(blending);
				renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LEQUAL);
				renderingContext.pushAndSetLighting(false);
				renderingContext.pushAndSetPolygonOffset(-1.0, -1.0);
				renderingContext.applyChanges();
				Rendering.drawWireframeBox(renderingContext, bb, new Util.Color4f(1.0, 1.0, 1.0, 0.4));
				Rendering.drawBox(renderingContext, bb, new Util.Color4f(1.0, 1.0, 1.0, 0.2));
				renderingContext.popMatrix_modelToCamera();
				renderingContext.popPolygonOffset();
				renderingContext.popLighting();
				renderingContext.popDepthBuffer();
				renderingContext.popBlending();
			}
		};
	}
	// ----------------------------
	// keyboard input
	static keyMap = new Map;	
	registerExtension('PADrend_KeyPressed', fn(evt) {
		var handler = keyMap[evt.key];
		return handler ? handler() : false;
	});

	keyMap[Util.UI.KEY_DELETE] = fn(){				// [entf] delete selected nodes
		var p;
		foreach(NodeEditor.getSelectedNodes() as var node){
			if(node == PADrend.getCurrentScene() || node == PADrend.getRootNode()){
				Runtime.warn("Can't delete active scene or root node.");
				continue;
			}
			p = node.getParent();
			MinSG.destroy(node);
		}
		NodeEditor.selectNode(p);
		return true;
	};
	keyMap[Util.UI.KEY_PAGEUP] = fn(){				// [pgUp] Select parent nodes of selected nodes
		var oldSelection = NodeEditor.getSelectedNodes().clone();
		NodeEditor.selectNode(void);
		foreach(oldSelection as var node){
			if(node.hasParent())
				NodeEditor.addSelectedNode(node.getParent());
		}
		return true;
	};
	keyMap[Util.UI.KEY_PAGEDOWN] = fn(){			// [pgDown] Select child nodes of selected nodes
		var selection = new Set;
		foreach(NodeEditor.getSelectedNodes() as var node){
			foreach(MinSG.getChildNodes(node) as var child){
				selection += child;

				if(selection.count()>=5000){
					Runtime.warn("Number of selected Nodes reached 5000. Stopping here... ");
					NodeEditor.selectNodes(selection.toArray());
					return true;
				}
			}
		}
		NodeEditor.selectNodes(selection.toArray());
		return true;
	};
	keyMap[Util.UI.KEY_HOME] = fn(){				// [pos1] Select current scene
		NodeEditor.selectNode( PADrend.getCurrentScene());
		return true;
	};
	keyMap[Util.UI.KEY_C] = fn(){					// [ctrl] + [c] copy out
		if(PADrend.getEventContext().isCtrlPressed() && !NodeEditor.getSelectedNodes().empty()){
			nodeClipboard = NodeEditor.getSelectedNodes().clone();
			nodeClipboardMode = $COPY;
			PADrend.message(""+nodeClipboard.count()," selected nodes copied to clipboard. ");
			return true;
		}
		return false;
	};
	keyMap[Util.UI.KEY_D] = fn(){					// [ctrl] + [d] duplicate   // \todo USE COMMAND
		if(PADrend.getEventContext().isCtrlPressed()){
			var newNodes = [];
			foreach(NodeEditor.getSelectedNodes() as var node){
				if(!node.hasParent() || !node.getParent().hasParent()){
					PADrend.message("Can't duplicate scene or root.");
				}else{
					var c = node.clone();
					node.getParent() += c;
					newNodes += c;
					Std.require('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree(c);
				}
			}
			PADrend.message(""+newNodes.count()+" nodes duplicated." );
			NodeEditor.selectNodes(newNodes);
			return true;
		}

		return false;
	};	
	keyMap[Util.UI.KEY_J] = fn(){					// [j] Jump to selection
		NodeEditor.jumpToSelection();
		return true;
	};
	keyMap[Util.UI.KEY_X] = fn(){					// [ctrl] + [x] cut out
		if(PADrend.getEventContext().isCtrlPressed() && !NodeEditor.getSelectedNodes().empty()){
			nodeClipboard = NodeEditor.getSelectedNodes().clone();
			nodeClipboardMode = $CUT;
			PADrend.message(""+nodeClipboard.count()," selected nodes cut out. ");
			return true;
		}
		return false;
	};
	keyMap[Util.UI.KEY_V] = fn(){					// [ctrl] + [v] paste \todo check for cycles!!!!!!!!!!!!!!!!!!!!!!!!!1
		if(PADrend.getEventContext().isCtrlPressed()){
			// transformations
			if(NodeEditor.getSelectedNodes().count()!=1 || !(NodeEditor.getSelectedNode()---|>MinSG.GroupNode)){
				Runtime.warn("Select one GroupNode for pasting.");
				return true;
			}
			var parentNode = NodeEditor.getSelectedNode();
			if(nodeClipboardMode == $CUT){
				out("Moving cut out nodes to ",NodeEditor.getString(parentNode),": ");
				foreach(nodeClipboard as var node){

					if(MinSG.isInSubtree(parentNode,node)){
						Runtime.warn("Skipping node to prevent cycle.");
						continue;
					}
					MinSG.changeParentKeepTransformation(node,parentNode);
					out(".");
				}
				NodeEditor.selectNodes(nodeClipboard);
				nodeClipboard.clear();
				out("\n");
			}else{
				out("Copying nodes to ",NodeEditor.getString(parentNode),": ");
				var clones=[];
				foreach(nodeClipboard as var node){

					if(MinSG.isInSubtree(parentNode,node)){
						Runtime.warn("Skipping node to prevent cycle.");
						continue;
					}

					var n2=node.clone();
					MinSG.changeParentKeepTransformation(n2,parentNode);
					clones+=n2;
					Std.require('LibMinSGExt/Traits/PersistentNodeTrait').initTraitsInSubtree(n2);

					out(".");
				}
				NodeEditor.selectNodes(clones);
				out("\n");
			}


			return true;
		}

		return false;
	};

	// [0...9] restore selection
	// [ctrl] + [0...9] store selection
	static storedSelections = [];
	foreach( [Util.UI.KEY_0, Util.UI.KEY_1, Util.UI.KEY_2, Util.UI.KEY_3, Util.UI.KEY_4, Util.UI.KEY_5] as var index,var sym){
		keyMap[sym] = [index] => this->fn(index){
			if(PADrend.getEventContext().isShiftPressed()) // no shift
				return false;

			if(PADrend.getEventContext().isCtrlPressed()){ // store
				outln("Storing current selection at #",index);
				var selection = NodeEditor.getSelectedNodes().clone();
				storedSelections[index] = selection;

				// TEMP This is a temporary solution which is eventually replaced by the scene editor's group management feature
				var ids = [];
				foreach(selection as var node){
					var id = PADrend.getSceneManager().getNameOfRegisteredNode(node);
					if(id)
						ids += id;
				}
				var selectionRegistry = PADrend.getCurrentScene().getNodeAttribute('NodeEditor_selections');
				if(!selectionRegistry)
					selectionRegistry = new Map;

				if(ids.empty()){
					selectionRegistry.unset(index);
				}else{
					selectionRegistry[index] = ids;
				}
				if(selectionRegistry.empty()){
					PADrend.getCurrentScene().unsetNodeAttribute('NodeEditor_selections');
				}else{
					PADrend.getCurrentScene().setNodeAttribute('NodeEditor_selections',selectionRegistry);
				}

			} else {
				var selection = storedSelections[index];
				if(!selection){
					var selectionRegistry = PADrend.getCurrentScene().getNodeAttribute('NodeEditor_selections');
					if(selectionRegistry && selectionRegistry[index]){
						selection = [];
						foreach(selectionRegistry[index] as var nodeId){
							var n = PADrend.getSceneManager().getRegisteredNode(nodeId);
							if(n)
								selection += n;
						}
						storedSelections[index] = selection;
					}
				}
				if(!selection){
					Runtime.warn("No selection stored at #"+index);
				}else{
					if(selection == NodeEditor.getSelectedNodes()){
						NodeEditor.jumpToSelection();
					} else {
						outln("Restoring selection #",index);
						NodeEditor.selectNodes(selection);

					}
				}
			}
			return true;
		};
	}

	// temporary!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	static follower;
	keyMap[Util.UI.KEY_L] = this->fn(){					// [l] Lock to selection
		var dolly = PADrend.getDolly();
		var camera = PADrend.getActiveCamera();
		if(follower){
				PADrend.message("Following Object stopped.");
			follower.active = false;
			follower = void;
			var originalPos = camera.getWorldOrigin();
			camera.setRelPosition(new Geometry.Vec3(0,0,0));
			dolly.moveLocal( dolly.worldDirToLocalDir(originalPos-camera.getWorldOrigin()  ));
		}else if(NodeEditor.getSelectedNode()) {
			PADrend.message("Following Object '"+NodeEditor.getSelectedNode()+"'");
			follower = new ExtObject({
				$active : true,
				$node : NodeEditor.getSelectedNode(),
				$execute : fn(p...){
					if(!active)
						return Extension.REMOVE_EXTENSION;
					PADrend.getDolly().setWorldOrigin(node.getWorldBB().getCenter());
					return Extension.CONTINUE;
				}
			});
			registerExtension('PADrend_AfterFrame',follower->follower.execute);
			camera.setRelPosition(new Geometry.Vec3(0,0,NodeEditor.getSelectedNode().getWorldBB().getDiameter()));
			out(-NodeEditor.getSelectedNode().getWorldBB().getDiameter()*1.5);
		}
		return true;
	};
	// -------------------------------------------


	return true;
};

plugin.setObjectIdentifier := 	fn(fun){		objectIdentifier = fun;	};
static objectIdentifier = fn(node){
	
	var semObj = MinSG.SemanticObjects.isSemanticObject(node) ? node :	MinSG.SemanticObjects.getContainingSemanticObject(node);
	if( semObj ){
		
		//! \todo This should be integrated into the selection method.
		while(true){
			var next = MinSG.SemanticObjects.getContainingSemanticObject(semObj);
			if(!next || NodeEditor.isNodeSelected(next))
				break;
			semObj = next;
		}
		return semObj;
	}

	while( node && node.isInstance()&& node.hasParent()&&node.getParent().isInstance())
		node = node.getParent();
	return node;
};



// -------------------------------

return plugin;
// ------------------------------------------------------------------------------
