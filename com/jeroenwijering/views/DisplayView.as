﻿/**
* Interface for all display elements.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.Draw;
import com.jeroenwijering.utils.Strings;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.URLRequest;


public class DisplayView {


	/** Reference to the MVC view. **/
	private var view:View;
	/** Reference to the display MC. **/
	private var display:MovieClip;
	/** Loader object for loading a logo. **/
	private var loader:Loader;
	/** The margins of the logo. **/
	private var margins:Array;
	/** The latest playback state **/
	private var state:String;
	/** A list of all the icons. **/
	private var ICONS:Array = new Array(
		'playIcon',
		'errorIcon',
		'bufferIcon',
		'linkIcon',
		'fullscreenIcon',
		'muteIcon'
	);


	/** Constructor; add all needed listeners. **/
	public function DisplayView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.ERROR,errorHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.BUFFER,bufferHandler);
		view.addModelListener(ModelEvent.ERROR,errorHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addViewListener(ModelEvent.ERROR,errorHandler);
		display = view.skin['display'];
		display.addEventListener(MouseEvent.CLICK,clickHandler);
		display.mouseChildren = false;
		display.buttonMode = true;
		Draw.clear(display.logo);
		if(view.config['logo']) { setLogo(); }
		setIcon('bufferIcon');
	};


	/** Receive buffer updates. **/
	private function bufferHandler(evt:ModelEvent) {
		if(evt.data.percentage == 0) {
			display.bufferIcon.txt.text = "";
		} else { 
			display.bufferIcon.txt.text = Strings.zero(evt.data.percentage);
		}
	};


	/** Process a click on the display. **/
	private function clickHandler(evt:MouseEvent) {
		if(view.config.displayclick != 'none') {
			view.sendEvent(view.config['displayclick']);
		}
	};


	/** Receive and print errors. **/
	private function errorHandler(evt) {
		display.errorIcon.msg.text = evt.data.message;
		setIcon('errorIcon');
	};


	/** Show a mute icon if playing. **/
	private function itemHandler(evt:ControllerEvent) {
		if(view.config['texts'] == true) {
			display.texts.title.text = view.playlist[evt.data.index]['title'];
			display.texts.author.text = view.playlist[evt.data.index]['author'];
		} else {
			display.texts.visible = false;
		}
	};


	/** Logo loaded; now position it **/
	private function logoHandler(evt:Event) {
		if(margins[0] > margins[2]) { 
			display.logo.x = display.back.width - margins[2] - display.logo.width;
		} else {
			display.logo.x = margins[0];
		}
		if(margins[1] > margins[3]) {
			display.logo.y = display.back.height - margins[3] - display.logo.height;
		} else {
			display.logo.y = margins[1];
		}
	};


	/** Show a mute icon if playing. **/
	private function muteHandler(evt:ControllerEvent) {
		if(state == ModelStates.PLAYING) {
			if(evt.data.state == true) {
				setIcon('muteIcon');
			} else {
				setIcon();
			}
		}
	};


	/** Receive resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		var wid = evt.data.width;
		var hei = evt.data.height;
		display.back.width = display.mediaMask.width = wid;
		display.back.height = display.mediaMask.height =  hei;
		if(view.config['texts']) { 
			display.texts.back.width = display.texts.title.width = display.texts.author.width = wid;
		}
		for(var i in ICONS) {
			display[ICONS[i]].x = Math.round(wid/2);
			display[ICONS[i]].y = Math.round(hei/2);
		}
		if(view.config['logo']) {
			logoHandler(new Event(Event.COMPLETE));
		}
	};


	/** Set a specific icon in the display. **/
	private function setIcon(icn:String=undefined) {
		for(var i in ICONS) {
			if(icn == ICONS[i]) {
				display[ICONS[i]].visible = true;
			} else {
				display[ICONS[i]].visible = false;
			}
		}
	};


	/** Setup the logo loading. **/
	private function setLogo() {
		margins = new Array(
			display.logo.x,
			display.logo.y,
			display.back.width - display.logo.x - display.logo.width,
			display.back.height - display.logo.y - display.logo.height
		);
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE,logoHandler);
		display.logo.addChild(loader);
		loader.load(new URLRequest(view.config['logo']));
	};


	/** Handle a change in playback state. **/
	private function stateHandler(evt:ModelEvent) {
		state = evt.data.newstate;
		if(state == ModelStates.PLAYING) {
			if(view.config['mute'] == true) {
				setIcon('muteIcon');
			} else {
				setIcon();
			}
		} else if (state == ModelStates.BUFFERING) {
			setIcon('bufferIcon');
		} else {
			if(view.config['playlist'] == 'above') {
				setIcon();
				return;
			}
			switch(view.config.displayclick) {
				case 'fullscreen':
					setIcon('fullscreenIcon');
					break;
				case 'play':
					setIcon('playIcon');
					break;
				case 'link':
					setIcon('linkIcon');
					break;
				case 'mute':
					setIcon('muteIcon');
					break;
				default:
					setIcon();
					break;
			}
		}
	};


};


}