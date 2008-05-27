/**
* Display a controlbar and direct the search externally.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
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
	/** A list with all controls docked to the left. **/
	private var left:Array;
	/** A list with all controls docked to the right. **/
	private var right:Array;
	/** Reference to the controlbar **/
	private var bar:MovieClip;
	/** Save whether slading is enabled. **/
	private var sliding:Boolean;
	/** Timeout for hiding the bar. **/
	private var hiding:Number;


	/** Constructor. **/
	public function ControlbarView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.CAPTION,captionHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		bar = view.skin['controlbar'];
		bar.addEventListener(MouseEvent.CLICK, clickHandler);
		bar.timeSlider.addEventListener(MouseEvent.MOUSE_DOWN,timeslideHandler);
		bar.timeSlider.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		bar.volumeSlider.addEventListener(MouseEvent.MOUSE_DOWN,volumeslideHandler);
		bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		checkButtons();
		loadedHandler(new ModelEvent(ModelEvent.LOADED,{loaded:0,total:0}));
		captionHandler(new ControllerEvent(ControllerEvent.CAPTION,{percentage:view.config['caption']}));
		muteHandler(new ControllerEvent(ControllerEvent.MUTE,{state:view.config['mute']}));
		stateHandler(new ModelEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE}));
		timeHandler(new ModelEvent(ModelEvent.TIME,{position:0,duration:0}));
		volumeHandler(new ControllerEvent(ControllerEvent.VOLUME,{percentage:view.config['volume']}));
	};


	/** Handle a change in the current item **/
	private function captionHandler(evt:ControllerEvent) {
		if(evt.data.state == true) { 
			bar.captionButton.icn.visible = true;
			bar.captionButton.alt.visible = false;
		} else {
			bar.captionButton.icn.visible = false;
			bar.captionButton.alt.visible = true;
		}
	};


	/** Check which buttons are available and save their positions. **/
	private function checkButtons() {
		var mid = bar.width/2;
		left = new Array();
		right = new Array();
		for(var i=0; i<bar.numChildren; i++) {
			var clp = bar.getChildAt(i);
			clp.buttonMode = true;
			clp.mouseChildren = false;
			if(clp.x < mid) {
				left.push({c:clp,x:clp.x,n:clp.name,w:clp.width});
			} else {
				right.push({c:clp,x:clp.x,n:clp.name,w:clp.width});
			}
		}
		left.sortOn(['x','n'],[Array.NUMERIC,Array.CASEINSENSITIVE]);
		right.sortOn('x',Array.DESCENDING | Array.NUMERIC);
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


	/** Returns whether the control should be hidden. **/
	private function hideButton(nam:String):Boolean {
		var obj = view.playlist[view.config['item']];
		switch(nam) {
			case 'prevButton':
			case 'nextButton':
				if(view.playlist.length < 2) {
					return true;
				}
				break;
			case 'elapsedText':
			case 'remainingText':
			case 'totalText':
				if(bar.back.width < 200) {
					return true;
				}
				break;
			case 'linkButton':
				if(!obj || !obj['link']) {
					return true;
				}
				break;
			case 'fullscreenButton':
				if(view.config['fullscreen'] == false || bar.stage.displayState == null) {
					return true;
				}
				break;
			case 'captionButton':
				if(!obj || !obj['captions']) {
					return true;
				}
				break;
		}
		return false;
	};


	/** Handle a change in the current item **/
	private function itemHandler(evt:ControllerEvent) {
		setButtons();
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
		var wid = bar.timeSlider.bck.width;
		bar.timeSlider.bar.x = Math.round(pc2*wid);
		bar.timeSlider.bar.width = Math.round(pc1*wid);  
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
			bar.muteButton.icn.visible = false;
			bar.muteButton.alt.visible = true;
			bar.volumeSlider.bar.visible = false;
		} else {
			bar.muteButton.icn.visible = true;
			bar.muteButton.alt.visible = false;
			bar.volumeSlider.bar.visible = true;
		}
	};


	/** Handle mouseouts from all buttons **/
	private function outHandler(evt:MouseEvent) {
		if(sliding) { clickHandler(evt); }
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		if(view.config['controlbar'] == 'above' || evt.data.fullscreen == true) {
			bar.y = evt.data.height - view.config['controlbarsize']*2;
			if(evt.data.width > 640) { 
				bar.x = Math.round(evt.data.width/2 - 300);
				bar.back.width = 600;
			} else { 
				bar.x = view.config['controlbarsize'];
				bar.back.width = evt.data.width - view.config['controlbarsize']*2;
			}
		} else {
			bar.x = 0;
			bar.back.width = evt.data.width;
			bar.y = evt.data.height;
			if(view.config['playlist'] == 'right') { 
				bar.back.width += view.config['playlistsize'];
			}
		}
		if(evt.data.fullscreen == true) { 
			bar.fullscreenButton.icn.visible = false;
			bar.fullscreenButton.alt.visible = true;
		} else { 
			bar.fullscreenButton.icn.visible = true;
			bar.fullscreenButton.alt.visible = false;
		}
		setButtons();
	};


	/** Send the new scrub position to the controller **/
	private function sendScrub(evt:MouseEvent) {
		bar.timeSlider.icn.stopDrag();
		var xps = bar.timeSlider.icn.x - bar.timeSlider.bck.x;
		var dur = view.playlist[view.config['item']]['duration'];
		var pct = Math.round(xps*dur*10/bar.timeSlider.bck.width)/10;
		view.sendEvent(ViewEvent.SEEK,pct);
	}


	/** Send the new volume to the controlbar **/
	private function sendVolume(evt:MouseEvent) {
		bar.volumeSlider.icn.stopDrag();
		var xps = bar.volumeSlider.icn.x - bar.volumeSlider.sld.x;
		var pct = Math.round(xps*100/bar.volumeSlider.sld.width);
		view.sendEvent(ViewEvent.VOLUME,pct);
	};


	/** Set all buttons to their correct positions. **/
	private function setButtons() {
		var rdf = bar.back.width-left[0].w;
		var ldf = 0;
		for(var i=0; i<right.length; i++) {
			if(hideButton(right[i].n)) {
				right[i].c.visible = false;
				rdf += right[i-1].x - right[i].x;
			} else { 
				right[i].c.visible = true;
				right[i].c.x = right[i].x + rdf;
			}
		}
		for(var j=0; j<left.length; j++) {
			if(hideButton(left[j].n)) {
				left[j].c.visible = false;
				ldf += left[j+1].x - left[j].x;
			} else {
				left[j].c.visible = true;
				left[j].c.x = left[j].x - ldf;
			}
			if(left[j].n == 'timeSlider') {
				var old = bar.timeSlider.bck.width;
				var wid = left[j].w+rdf+ldf;
				bar.timeSlider.bck.width = wid;
				bar.timeSlider.bar.width *= wid/old;
				bar.timeSlider.bar.x *= wid/old;
				bar.timeSlider.icn.x = Math.round(bar.timeSlider.icn.x*wid/old);
			}
		}
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent) {
		switch(evt.data.newstate) { 
			case ModelStates.PLAYING:
				if(view.config['controlbar'] == 'above') {
					hiding = setTimeout(moveTimeout,1000);
					view.skin.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				}
			case ModelStates.BUFFERING:
				bar.playButton.icn.visible = false;
				bar.playButton.alt.visible = true;
				break;
			default: 
				if(view.config['controlbar'] == 'above') {
					clearTimeout(hiding);
					bar.visible = true;
					view.skin.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				}
				bar.playButton.icn.visible = true;
				bar.playButton.alt.visible = false;
				break;
		}
	}


	/** Process time updates given by the model. **/
	private function timeHandler(evt:ModelEvent) {
		var dur = evt.data.duration;
		try {
			bar.elapsedText.txt.text = Strings.digits(evt.data.position);
			bar.totalText.txt.text = Strings.digits(evt.data.duration);
		} catch(err:Error) {}
		var pct = evt.data.position/evt.data.duration;
		var xps = Math.floor(pct*bar.timeSlider.bck.width);
		if (dur <= 0) {
			bar.timeSlider.icn.visible = false;
		} else {
			bar.timeSlider.icn.visible = true;
			bar.timeSlider.icn.x = xps;
		}
	};


	/** Handle a move over the timeslider **/
	private function timeslideHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.timeSlider.bck.x,bar.timeSlider.icn.y,bar.timeSlider.bck.width,0);
		bar.timeSlider.icn.startDrag(true,rct);
		sliding = true;
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent) {
		bar.volumeSlider.bar.scaleX = evt.data.percentage/100;
	};


	/** Handle a move over the volume bar **/
	private function volumeslideHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.volumeSlider.sld.x,bar.volumeSlider.icn.y,bar.volumeSlider.sld.width,0);
		bar.volumeSlider.icn.startDrag(true,rct);
		sliding = true;
	};


};


}