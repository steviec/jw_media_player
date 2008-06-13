/**
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
		'muteIcon'
	);


	/** Constructor; add all needed listeners. **/
	public function DisplayView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.ERROR,errorHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.BUFFER,bufferHandler);
		view.addModelListener(ModelEvent.ERROR,errorHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addViewListener(ModelEvent.ERROR,errorHandler);
		display = view.skin['display'];
		if(view.config['displayclick'] != 'none') {
			display.addEventListener(MouseEvent.CLICK,clickHandler);
			display.buttonMode = true;
		}
		display.mouseChildren = false;
		try { 
			Draw.clear(display.logo);
			if(view.config['logo']) { setLogo(); }
		} catch (err:Error) {}
		setIcon();
	};


	/** Receive buffer updates. **/
	private function bufferHandler(evt:ModelEvent) {
		if(display.bufferIcon.txt) { 
			if(evt.data.percentage > 0) { 
				display.bufferIcon.txt.text = Strings.zero(evt.data.percentage);
			} else {
				display.bufferIcon.txt.text = '';
			}
		}
	};


	/** Process a click on the display. **/
	private function clickHandler(evt:MouseEvent) {
		view.sendEvent(view.config['displayclick']);
	};


	/** Receive and print errors. **/
	private function errorHandler(evt) {
		setIcon('errorIcon');
	};


	/** Logo loaded; now position it. **/
	private function logoHandler(evt:Event) {
		if(margins[0] > margins[2]) { 
			display.logo.x = display.back.width- margins[2]-display.logo.width;
		} else {
			display.logo.x = margins[0];
		}
		if(margins[1] > margins[3]) {
			display.logo.y = display.back.height- margins[3]-display.logo.height;
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
		if(hei > 0) { 
			display.visible = true;
		} else { 
			display.visible = false;
		}
		display.back.width  = wid;
		display.back.height = hei;
		try { 
			display.masker.width = wid;
			display.masker.height = hei;
		} catch (err:Error) {}
		for(var i in ICONS) {
			try { 
				display[ICONS[i]].x = Math.round(wid/2);
				display[ICONS[i]].y = Math.round(hei/2);
			} catch (err:Error) {}
		}
		if(view.config['logo']) {
			logoHandler(new Event(Event.COMPLETE));
		}
	};


	/** Set a specific icon in the display. **/
	private function setIcon(icn:String=undefined) {
		for(var i in ICONS) {
			if(display[ICONS[i]]) { 
				if(icn == ICONS[i]) {
					display[ICONS[i]].visible = true; 
				} else {
					display[ICONS[i]].visible = false; 
				}
			}
		}
	};


	/** Setup the logo loading. **/
	private function setLogo() {
		margins = new Array(
			display.logo.x,
			display.logo.y,
			display.back.width-display.logo.x-display.logo.width,
			display.back.height-display.logo.y-display.logo.height
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
			switch(view.config.displayclick) {
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