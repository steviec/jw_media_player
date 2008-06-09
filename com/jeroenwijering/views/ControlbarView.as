/**
* Display a controlbar and direct the search externally.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.*;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.utils.setTimeout;
import flash.utils.clearTimeout;


public class ControlbarView {


	/** Reference to the view. **/
	private var view:View;
	/** Reference to the controlbar **/
	private var bar:MovieClip;
	/** A list with all controls. **/
	private var stacker:Stacker;
	/** Timeout for hiding the bar. **/
	private var hiding:Number;
	/** The actions for all controlbar buttons. **/
	private var BUTTONS = {
		playButton:'PLAY',
		pauseButton:'PLAY',
		stopButton:'STOP',
		prevButton:'PREV',
		nextButton:'NEXT',
		linkButton:'LINK',
		fullscreenButton:'FULLSCREEN',
		normalscreenButton:'FULLSCREEN',
		muteButton:'MUTE',
		unmuteButton:'MUTE'
	};


	/** Constructor. **/
	public function ControlbarView(vie:View) {
		view = vie;
		bar = view.skin['controlbar'];
		stacker = new Stacker(bar);
		setButtons();
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		loadedHandler(new ModelEvent(ModelEvent.LOADED,{loaded:0,total:0}));
		view.addModelListener(ModelEvent.STATE,stateHandler);
		stateHandler(new ModelEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE}));
		view.addModelListener(ModelEvent.TIME,timeHandler);
		timeHandler(new ModelEvent(ModelEvent.TIME,{position:0,duration:0}));
		if(bar['muteButton']) { 
			view.addControllerListener(ControllerEvent.MUTE,muteHandler);
			muteHandler(new ControllerEvent(ControllerEvent.MUTE,{state:view.config['mute']}));
		}
		if(bar['volumeSlider']) { 
			view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
			volumeHandler(new ControllerEvent(ControllerEvent.VOLUME,{percentage:view.config['volume']}));
		}
	};


	/** Handle clicks from all buttons. **/
	private function clickHandler(evt:MouseEvent) {
		view.sendEvent(BUTTONS[evt.target.name]);
	};


	/** Fix the timeline display. **/
	private function fixTime() {
		var scp = bar.timeSlider.scaleX;
		bar.timeSlider.scaleX = 1;
		bar.timeSlider.icon.x = Math.round(scp*bar.timeSlider.icon.x);
		bar.timeSlider.mark.x = Math.round(scp*bar.timeSlider.mark.x);
		bar.timeSlider.mark.width = Math.round(scp*bar.timeSlider.mark.width);
		bar.timeSlider.rail.width = Math.round(scp*bar.timeSlider.rail.width);
	};


	/** Handle a change in the current item **/
	private function itemHandler(evt:ControllerEvent) {
		if(bar['prevButton'] && bar['nextButton']) { 
			if(view.playlist.length > 1) { 
				bar.prevButton.visible = bar.nextButton.visible = true;
			} else {
				bar.prevButton.visible = bar.nextButton.visible = false;
			}
		}
		if(bar['linkButton']) { 
			if(view.playlist[view.config['item']]['link']) { 
				bar.linkButton.visible = true;
			} else { 
				bar.linkButton.visible = false;
			}
		}
		stacker.rearrange();
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
		Animations.fade(bar,1);
		clearTimeout(hiding);
		hiding = setTimeout(moveTimeout,1000);
	};


	/** Hide above controlbar again when move has timed out. **/
	private function moveTimeout() {
		if(bar.mouseY < -10) {
			Animations.fade(bar,0);
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
		bar[evt.target.name].gotoAndPlay('out');
	};


	/** Handle clicks from all buttons **/
	private function overHandler(evt:MouseEvent) {
		bar[evt.target.name].gotoAndPlay('over');
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		var wid = stacker.width;
		if(view.config['controlbar'] == 'over' || evt.data.fullscreen == true) {
			bar.y = evt.data.height - view.config['controlbarheight']*2;
			if(evt.data.width > 640) { 
				bar.x = Math.round(evt.data.width/2-300);
				wid = 600;
			} else { 
				bar.x = view.config['controlbarheight'];
				wid = evt.data.width - view.config['controlbarheight']*2;
			}
		} else {
			bar.x = 0;
			wid = evt.data.width;
			bar.y = evt.data.height;
			if(view.config['playlist'] == 'right') {
				wid += view.config['playlistsize'];
			}
		}
		if(bar.fullscreenButton) {
			if(view.config['fullscreen'] == false || bar.stage.displayState == null) {
				bar.fullscreenButton.visible = false;
				bar.normalscreenButton.visible = false;
			} else if(evt.data.fullscreen == true) {
				bar.fullscreenButton.visible = false;
				bar.normalscreenButton.visible = true;
			} else {
				bar.fullscreenButton.visible = true;
				bar.normalscreenButton.visible = false;
			}
		}
		stacker.rearrange(wid);
		fixTime();
	};


	/** Clickhandler for all buttons. **/
	private function setButtons() {
		for(var itm in BUTTONS) { 
			if(bar[itm]) {
				bar[itm].mouseChildren = false;
				bar[itm].buttonMode = true;
				bar[itm].addEventListener(MouseEvent.CLICK, clickHandler);
				bar[itm].addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				bar[itm].addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			}
		}
		try {
			bar.timeSlider.mouseChildren = false;
			bar.timeSlider.buttonMode = true;
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_DOWN,timedownHandler);
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_OUT,timeoutHandler);
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_OVER,timeoverHandler);
		} catch (err:Error) {}
		try {
			bar.volumeSlider.mouseChildren = false;
			bar.volumeSlider.buttonMode = true;
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_DOWN,volumedownHandler);
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OUT,volumeoutHandler);
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OVER,volumeoverHandler);
		} catch (err:Error) {}
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent) {
		switch(evt.data.newstate) { 
			case ModelStates.PLAYING:
				if(view.config['controlbar'] == 'over' || bar.stage.displayState == 'fullScreen') {
					hiding = setTimeout(moveTimeout,1000);
					view.skin.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				}
			case ModelStates.BUFFERING:
				bar.playButton.visible = false;
				bar.pauseButton.visible = true;
				break;
			default: 
				if(view.config['controlbar'] == 'over' || bar.stage.displayState == 'fullScreen') {
					clearTimeout(hiding);
					Animations.fade(bar,1);
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
		if(bar.elapsedText) {
			bar.elapsedText.text = Strings.digits(evt.data.position);
		}
		if(evt.data.duration > 0 && bar.totalText) { 
			bar.totalText.text = Strings.digits(evt.data.duration);
		}
		var pct = evt.data.position/evt.data.duration;
		var xps = Math.round(pct*bar.timeSlider.rail.width);
		if (dur <= 0) {
			bar.timeSlider.icon.visible = false;
		} else {
			bar.timeSlider.icon.visible = true;
			bar.timeSlider.icon.x = xps;
		}
	};


	/** Handle a press on the timeslider **/
	private function timedownHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.timeSlider.rail.x,bar.timeSlider.icon.y,bar.timeSlider.rail.width,0);
		bar.timeSlider.icon.startDrag(true,rct);
    	bar.stage.addEventListener(MouseEvent.MOUSE_UP,timeupHandler);
	};

	/** Handle a move out the timeslider **/
	private function timeoutHandler(evt:MouseEvent) {
		bar.timeSlider.icon.gotoAndPlay('out');
	};


	/** Handle a press release on the timeslider **/
	private function timeupHandler(evt:MouseEvent) {
		bar.timeSlider.icon.stopDrag();
    	bar.stage.removeEventListener(MouseEvent.MOUSE_UP,timeupHandler);
		var xps = bar.timeSlider.icon.x - bar.timeSlider.rail.x;
		var dur = view.playlist[view.config['item']]['duration'];
		var pct = Math.round(xps*dur*10/bar.timeSlider.rail.width)/10;
		view.sendEvent(ViewEvent.SEEK,pct);
	};


	/** Handle a move over the timeslider **/
	private function timeoverHandler(evt:MouseEvent) {
		bar.timeSlider.icon.gotoAndPlay('over');
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent) {
		bar.volumeSlider.mark.scaleX = evt.data.percentage/100;
	};


	/** Handle a move over the volumebar **/
	private function volumedownHandler(evt:MouseEvent) {
		var rct = new Rectangle(bar.volumeSlider.rail.x,bar.volumeSlider.icon.y,bar.volumeSlider.rail.width,0);
		bar.volumeSlider.icon.startDrag(true,rct);
		bar.stage.addEventListener(MouseEvent.MOUSE_UP,volumeupHandler);
	};


	/** Handle a move out the volumebar. **/
	private function volumeoutHandler(evt:MouseEvent) {
		bar.volumeSlider.icon.gotoAndPlay('out');
	};


	/** Handle a move over the volumebar. **/
	private function volumeoverHandler(evt:MouseEvent) {
		bar.volumeSlider.icon.gotoAndPlay('over');
	};


	/** Handle a press release on the volumebar. **/
	private function volumeupHandler(evt:MouseEvent) {
		bar.volumeSlider.icon.stopDrag();
    	bar.stage.removeEventListener(MouseEvent.MOUSE_UP,volumeupHandler);
		var xps = bar.volumeSlider.icon.x - bar.volumeSlider.rail.x;
		var pct = Math.round(xps*100/bar.volumeSlider.rail.width);
		view.sendEvent(ViewEvent.VOLUME,pct);
	};


};


}