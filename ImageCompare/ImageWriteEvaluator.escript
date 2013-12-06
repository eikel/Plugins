/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

MinSG.ImageWriteEvaluator := new Type(MinSG.ScriptedEvaluator);

MinSG.ImageWriteEvaluator._constructor ::= fn() {
	this.fbo := new Rendering.FBO();

	this.imageDirectory := DataWrapper.createFromConfig(PADrend.configCache, 'MinSG.ImageCompare.writeDirectory', "");
	this.imageCounter := DataWrapper.createFromValue(0);
};

MinSG.ImageWriteEvaluator.beginMeasure @(override)::= fn() {
	return this;
};

MinSG.ImageWriteEvaluator.endMeasure @(override) ::= fn(MinSG.FrameContext frameContext) {
	return this;
};

MinSG.ImageWriteEvaluator.measure @(override) ::= fn(MinSG.FrameContext frameContext, MinSG.Node node, Geometry.Rect rect) {
	var width = rect.getWidth();
	var height = rect.getHeight();
	
	var colorTexture = Rendering.createStdTexture(width, height, true);
	var depthTexture = Rendering.createDepthTexture(width, height);
	
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext, colorTexture);
	fbo.attachDepthTexture(renderingContext, depthTexture);
	
	renderingContext.pushViewport();
	renderingContext.setViewport(rect.getX(), rect.getY(), rect.getWidth(), rect.getHeight());
	PADrend.renderScene(PADrend.getRootNode(), void, PADrend.getRenderingFlags(), PADrend.getBGColor());
	renderingContext.popViewport();
	
	renderingContext.popFBO();
	
	Rendering.saveTexture(renderingContext, colorTexture, this.imageDirectory() + "/" + this.imageCounter() + ".png");
	this.imageCounter(this.imageCounter() + 1);
	
	return this;
};

MinSG.ImageWriteEvaluator.getResults @(override) ::= fn() {
	return [imageCounter()];
};

MinSG.ImageWriteEvaluator.getMaxValue ::= fn() {
	return imageCounter();
};

MinSG.ImageWriteEvaluator.getMode ::= fn() {
	return MinSG.Evaluator.SINGLE_VALUE;
};

MinSG.ImageWriteEvaluator.setMode ::= fn(dummy) {
};

MinSG.ImageWriteEvaluator.getEvaluatorTypeName ::= fn() {
	return "ImageWriteEvaluator";
};

MinSG.ImageWriteEvaluator.createConfigPanel ::= fn() {
	// parent::createConfigPanel()
	var panel = (this -> MinSG.Evaluator.createConfigPanel)();

	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"Image directory",
		GUI.TOOLTIP			:	"Directory in which the images will be written",
		GUI.DATA_WRAPPER	:	this.imageDirectory,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_NUMBER,
		GUI.LABEL			:	"Image counter",
		GUI.TOOLTIP			:	"Counter that is increased for every written image by one and used as file name",
		GUI.DATA_WRAPPER	:	this.imageCounter,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	return panel;
};