/**
* Display a controlbar and direct the search externally.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.Stacker;
import com.jeroenwijering.utils.Strings;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.utils.setTimeout;
import flash.utils.clearTimeout;
import fl.transitions.*;
import fl.transitions.easing.*;


public class ControlbarView {


	/** Reference to the view. **/
	private var view:View;
	/** A list with all controls. **/
	private var stacker:Stacker;
	/** Reference to the controlbar **/
	private var bar:MovieClip;
	/** Save whether sliding is enabled. **/
	private var sliding:Boolean;
	/** Timeout for hiding the bar. **/
	private var hiding:Number;


	/** Constructor. **/
	public function ControlbarView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		bar = view.skin['controlbar'];
		stacker = new Stacker(bar);
		bar.addEventListener(MouseEvent.CLICK, clickHandler);
		bar.timeSlider.addEventListener(MouseEvent.MOUSE_DOWN,timeslideHandler);
		bar.timeSlider.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		bar.volumeSlider.addEventListener(MouseEvent.MOUSE_DOWN,volumeslideHandler);
		bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		loadedHandler(new ModelEvent(ModelEvent.LOADED,{loaded:0,total:0}));
		muteHandler(new ControllerEvent(ControllerEvent.MUTE,{state:view.config['mute']}));
		stateHandler(new ModelEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE}));
		timeHandler(new ModelEvent(ModelEvent.TIME,{position:0,duration:0}));
		volumeHandler(new ControllerEvent(ControllerEvent.VOLUME,{percentage:view.config['volume']}));
	};


	/** Handle clicks from all buttons **/
	private function clickHandler(evt:MouseEvent) {
		if(evt.target.name.indexOf('Button') > 0) {
			var str = evt.target.name.substr(0,-6).toUpperCase();
			view.sendEvent(str);
		} else if (evt.target.name == 'timeSlider') {
			sendScrub(evt);
		} else if (evt.target.name == 'volumeSlider') {
			sendVolume(evt);
		}
		sliding = false;
	};


	/** Handle a change in the current item **/
	private function itemHandler(evt:ControllerEvent) {
		if(view.playlist.length > 1) { 
			bar.prevButton.visible = bar.nextButton.visible = true;
		} else {
			bar.prevButton.visible = bar.nextButton.visible = false;
		}
		if(view.playlist[view.config['item']]['link']) { 
			bar.linkButton.visible = true;
		} else { 
			bar.linkButton.visible = false;
		}
		if(view.config['digits'] == false) {
			bar.elapsedText.visible = bar.totalText.visible = false;
		} else { 
			bar.elapsedText.visible = bar.totalText.visible = true;
		}
	};


	/** Process bytesloaded updates given by the model. **/
	private function loadedHandler(evt:ModelEvent) {
		var pc1 = 0;
		if(evt.data.total > 0) {
			pc1 = evt.data.loaded/evt.data.total;
		}
		var pc2 = 0;
		if(evt.data.offset) {
			pc2 = evt.data.offset/evt.data.total;
		}
		try {
			var wid = bar.timeSlider.rail.width;
			bar.timeSlider.mark.x = Math.round(pc2*wid);
			bar.timeSlider.mark.width = Math.round(pc1*wid);  
		} catch (err:Error) {}
	};


	/** Show above controlbar on mousemove. **/
	private function moveHandler(evt:MouseEvent) {
		bar.visible = true;
		clearTimeout(hiding);
		hiding = setTimeout(moveTimeout,1000);
	};


	/** Hide above controlbar again when move has timed out. **/
	private function moveTimeout() {
		if(bar.mouseY < -10) {
			bar.visible = false;
		}
	};


	/** Show a mute icon if playing. **/
	private function muteHandler(evt:ControllerEvent) {
		if(evt.data.state == true) { 
			bar.muteButton.visible = false;
			bar.unmuteButton.visible = true;
			bar.volumeSlider.mark.visible = false;
		} else {
			bar.muteButton.visible = true;
			bar.unmuteButton.visible = false;
			bar.volumeSlider.mark.visible = true;
		}
	};


	/** Handle mouseouts from all buttons **/
	private function outHandler(evt:MouseEvent) {
		if(sliding) { clickHandler(evt); }
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		var wid = stacker.width;
		if(view.config['controlbar'] == 'over' || evt.data.fullscreen == true) {
			bar.y = evt.data.height - view.config['controlbarsize']*2;
			if(evt.data.width > 640) { 
				bar.x = Math.round(evt.data.width/2-300);
				wid = 600;
			} else { 
				bar.x = view.config['controlbarsize'];
				wid = evt.data.width - view.config['controlbarsize']*2;
			}
		} else {
			bar.x = 0;
			wid = evt.data.width;
			bar.y = evt.data.height;
			if(view.config['playlist'] == 'right') {
				wid += view.config['playlistsize'];
			}
		}
		if(view.config['fullscreen'] == false || bar.stage.displayState == null) {
			bar.fullscreenButton.visible = false;
			bar.normalscreenButton.visible = false;
		} else if(evt.data.fullscreen == true) {
			bar.fullscreenButton.visible = false;
			bar.normalscreenButton.visible = true;
		} else {
			bar.fullscreenButton.visible = false;
			bar.normalscreenButton.visible = true;
		}
		stacker.rearrange(wid);
		bar.timeSlider.icon.scaleX = 1/bar.timeSlider.scaleX;
	};


	/** Send the new scrub position to the controller **/
	private function sendScrub(evt:MouseEvent) {
		bar.timeSlider.icon.stopDrag();
		var xps = bar.timeSlider.icon.x - bar.timeSlider.rail.x;
		var dur = view.playlist[view.config['item']]['duration'];
		var pct = Math.round(xps*dur*10/bar.timeSlider.rail.width)/10;
		view.sendEvent(ViewEvent.SEEK,pct);
	}


	/** Send the new volume to the controlbar **/
	private function sendVolume(evt:MouseEvent) {
		bar.volumeSlider.icon.stopDrag();
		var xps = bar.volumeSlider.icon.x - bar.volumeSlider.rail.x;
		var pct = Math.round(xps*100/bar.volumeSlider.mark.width);
		view.sendEvent(ViewEvent.VOLUME,pct);
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent) {
		switch(evt.data.newstate) { 
			case ModelStates.PLAYING:
				if(view.config['controlbar'] == 'over') {
					hiding = setTimeout(moveTimeout,1000);
					view.skin.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				}
			case ModelStates.BUFFERING:
				bar.playButton.visible = false;
				bar.pauseButton.visible = true;
				break;
			default: 
				if(view.config['controlbar'] == 'over') {
					clearTimeout(hiding);
					bar.visible = true;
					view.skin.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				}
				bar.playButton.visible = true;
				bar.pauseButton.visible = false;
				break;
		}
	}


	/** Process time updates given by the model. **/
	private function timeHandler(evt:ModelEvent) {
		var dur = evt.data.duration;
		bar.elapsedText.field.text = Strings.digits(evt.data.position);
		bar.totalText.field.text = Strings.digits(evt.data.duration)
		var pct = evt.data.position/evt.data.duration;
		var xps = Math.floor(pct*bar.timeSlider.rail.width);
		if (dur <= 0) {
			bar.timeSlider.icon.visible = false;
		} else {
			bar.timeSlider.icon.visible = true;
			bar.timeSlider.icon.x = xps;
		}
	};


	/** Handle a move over the timeslider **/
	private function timeslideHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.timeSlider.rail.x,bar.timeSlider.icon.y,bar.timeSlider.rail.width,0);
		bar.timeSlider.icon.startDrag(true,rct);
		sliding = true;
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent) {
		bar.volumeSlider.mark.scaleX = evt.data.percentage/100;
	};


	/** Handle a move over the volume bar **/
	private function volumeslideHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.volumeSlider.rail.x,bar.volumeSlider.icon.y,bar.volumeSlider.rail.width,0);
		bar.volumeSlider.icon.startDrag(true,rct);
		sliding = true;
	};


};


}