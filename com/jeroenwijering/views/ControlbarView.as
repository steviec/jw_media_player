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
import flash.ui.Mouse;


public class ControlbarView {


	/** Reference to the view. **/
	private var view:View;
	/** Reference to the controlbar **/
	private var bar:MovieClip;
	/** Fullscreen controlbar margin. **/
	private var margin:Number;
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
	/** When scrubbing, icon shouldn't be set. **/
	private var scrubbing:Boolean;


	/** Constructor. **/
	public function ControlbarView(vie:View) {
		view = vie;
		if(!view.skin['controlbar']) { return; }
		bar = view.skin['controlbar'];
		margin = bar.x;
		stacker = new Stacker(bar);
		setButtons();
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,itemHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
		itemHandler();
		muteHandler();
		volumeHandler();
		loadedHandler();
		timeHandler();
		stateHandler();
		resizeHandler();
	};


	/** Handle clicks from all buttons. **/
	private function clickHandler(evt:MouseEvent) {
		view.sendEvent(BUTTONS[evt.target.name]);
	};


	/** Fix the timeline display. **/
	private function fixTime() {
		try {
			var scp = bar.timeSlider.scaleX;
			bar.timeSlider.scaleX = 1;
			bar.timeSlider.icon.x = scp*bar.timeSlider.icon.x;
			bar.timeSlider.mark.x = scp*bar.timeSlider.mark.x;
			bar.timeSlider.mark.width = scp*bar.timeSlider.mark.width;
			bar.timeSlider.rail.width = scp*bar.timeSlider.rail.width;
		} catch (err:Error) {}
	};


	/** Handle a change in the current item **/
	private function itemHandler(evt:ControllerEvent=null) {
		try {
			if(view.playlist && view.playlist.length > 1) {
				bar.prevButton.visible = bar.nextButton.visible = true;
			} else {
				bar.prevButton.visible = bar.nextButton.visible = false;
			}
		} catch (err:Error) {}
		try {
			if(view.playlist && view.playlist[view.config['item']]['link']) {
				bar.linkButton.visible = true;
			} else { 
				bar.linkButton.visible = false;
			}
		} catch (err:Error) {}
		timeHandler();
		stacker.rearrange();
		fixTime();
	};


	/** Process bytesloaded updates given by the model. **/
	private function loadedHandler(evt:ModelEvent=null) {
		var pc1 = 0;
		if(evt && evt.data.total > 0) {
			pc1 = evt.data.loaded/evt.data.total;
		}
		var pc2 = 0;
		if(evt && evt.data.offset) {
			pc2 = evt.data.offset/evt.data.total;
		}
		try {
			var wid = bar.timeSlider.rail.width;
			bar.timeSlider.mark.x = pc2*wid;
			bar.timeSlider.mark.width = pc1*wid;
		} catch (err:Error) {}
	};


	/** Show above controlbar on mousemove. **/
	private function moveHandler(evt:MouseEvent=null) {
		if(bar.alpha == 0) { Animations.fade(bar,1); }
		clearTimeout(hiding);
		hiding = setTimeout(moveTimeout,1000);
		Mouse.show();
	};


	/** Hide above controlbar again when move has timed out. **/
	private function moveTimeout() {
		if((bar.mouseY<0 || bar.mouseY>bar.height)  && bar.alpha == 1) {
			Animations.fade(bar,0);
			Mouse.hide();
		}
	};


	/** Show a mute icon if playing. **/
	private function muteHandler(evt:ControllerEvent=null) {
		try {
			if(view.config['mute'] == true) {
				bar.muteButton.visible = false;
				bar.unmuteButton.visible = true;
				bar.volumeSlider.mark.visible = false;
				bar.volumeSlider.icon.x = bar.volumeSlider.rail.x;
			} else {
				bar.muteButton.visible = true;
				bar.unmuteButton.visible = false;
				bar.volumeSlider.mark.visible = true;
				volumeHandler();
			}
		} catch (err:Error) {}
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
	private function resizeHandler(evt:ControllerEvent=null) {
		var wid = stacker.width;
		if(view.config['controlbar'] == 'over' || (evt && evt.data.fullscreen == true)) {
			bar.y = view.config['height'] - view.config['controlbarsize'] - margin;
			bar.x = margin;
			wid = view.config['width'] - 2*margin;
		} else if(view.config['controlbar'] == 'bottom') {
			bar.x = 0;
			wid = view.config['width'];
			bar.y = view.config['height'];
			if(view.config['playlist'] == 'right') {
				wid += view.config['playlistsize'];
			}
		} else {
			bar.visible = false;
		}
		try { 
			var dps = bar.stage['displayState'];
			if(view.config['fullscreen']==false || dps==null) {
				bar.fullscreenButton.visible = false;
				bar.normalscreenButton.visible = false;
			} else if(evt && evt.data.fullscreen == true) {
				bar.fullscreenButton.visible = false;
				bar.normalscreenButton.visible = true;
			} else {
				bar.fullscreenButton.visible = true;
				bar.normalscreenButton.visible = false;
			}
		} catch (err:Error) {}
		try {
			if (wid < 200) {
				bar.elapsedText.visible = bar.totalText.visible = false;
			} else { 
				bar.elapsedText.visible = bar.totalText.visible = true;
			}
		} catch (err:Error) {}
		stacker.rearrange(wid);
		stateHandler();
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
		if(bar.timeSlider) {
			bar.timeSlider.mouseChildren = false;
			bar.timeSlider.buttonMode = true;
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_DOWN,timedownHandler);
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_OUT,timeoutHandler);
			bar.timeSlider.addEventListener(MouseEvent.MOUSE_OVER,timeoverHandler);
		} 
		if(bar.volumeSlider) {
			bar.volumeSlider.mouseChildren = false;
			bar.volumeSlider.buttonMode = true;
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_DOWN,volumedownHandler);
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OUT,volumeoutHandler);
			bar.volumeSlider.addEventListener(MouseEvent.MOUSE_OVER,volumeoverHandler);
		}
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent=undefined) {
		clearTimeout(hiding);
		view.skin.removeEventListener(MouseEvent.MOUSE_MOVE,moveHandler);
		Mouse.show();
		try {
			var dps = bar.stage['displayState'];
		} catch (err:Error) {}
		switch(view.config['state']) { 
			case ModelStates.PLAYING:
			case ModelStates.BUFFERING:
				try { 
					bar.playButton.visible = false;
					bar.pauseButton.visible = true;
				} catch (err:Error) {}
				if(view.config['controlbar'] == 'over' || dps == 'fullScreen') {
					hiding = setTimeout(moveTimeout,1000);
					view.skin.addEventListener(MouseEvent.MOUSE_MOVE,moveHandler);
				} else {
					Animations.fade(bar,1);
				}
				break;
			default:
				try {
					bar.playButton.visible = true;
					bar.pauseButton.visible = false;
				} catch (err:Error) {}
				if(view.config['controlbar'] == 'over' || dps == 'fullScreen') {
					Animations.fade(bar,1);
				}
		}
	};


	/** Process time updates given by the model. **/
	private function timeHandler(evt:ModelEvent=null) {
		var dur = 0;
		var pos = 0;
		if(evt) {
			dur = evt.data.duration;
			pos = evt.data.position;
		} else if(view.playlist) {
			dur = view.playlist[view.config['item']]['duration'];
			pos = view.playlist[view.config['item']]['start'];
		}
		var pct = pos/dur;
		try {
			bar.elapsedText.text = Strings.digits(pos);
			bar.totalText.text = Strings.digits(dur);
		} catch (err:Error) {}
		try {
			var tsl = bar.timeSlider;
			var xps = Math.round(pct*(tsl.rail.width-tsl.icon.width));
			if (dur > 0) {
				bar.timeSlider.icon.visible = true;
				bar.timeSlider.mark.visible = true;
				if(scrubbing != true) {
					bar.timeSlider.icon.x = xps;
				}
			} else {
				bar.timeSlider.icon.visible = false;
				bar.timeSlider.mark.visible = false;
			}
		} catch (err:Error) {}
	};


	/** Handle a press on the timeslider **/
	private function timedownHandler(evt:MouseEvent) {
		var tsl = bar.timeSlider;
		var rct = new Rectangle(0,
			tsl.icon.y,tsl.rail.width-tsl.icon.width,0);
		tsl.icon.startDrag(true,rct);
		scrubbing = true;
    	bar.stage.addEventListener(MouseEvent.MOUSE_UP,timeupHandler);
	};

	/** Handle a move out the timeslider **/
	private function timeoutHandler(evt:MouseEvent) {
		bar.timeSlider.icon.gotoAndPlay('out');
	};


	/** Handle a press release on the timeslider **/
	private function timeupHandler(evt:MouseEvent) {
		bar.timeSlider.icon.stopDrag();
		scrubbing = false;
    	bar.stage.removeEventListener(MouseEvent.MOUSE_UP,timeupHandler);
		var xps = bar.timeSlider.icon.x-bar.timeSlider.rail.x;
		if(view.playlist.length) {
			var dur = view.playlist[view.config['item']]['duration'];
			var pct = Math.round(xps*dur*10/bar.timeSlider.rail.width/10);
			view.sendEvent(ViewEvent.SEEK,pct);
		}
	};


	/** Handle a move over the timeslider **/
	private function timeoverHandler(evt:MouseEvent) {
		bar.timeSlider.icon.gotoAndPlay('over');
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent=null) {
		try { 
			var vsl = bar.volumeSlider;
			vsl.mark.width = view.config['volume']*(vsl.rail.width-vsl.icon.width/2)/100;
			vsl.icon.x = view.config['volume']*(vsl.rail.width-vsl.icon.width)/100;
		} catch (err:Error) {}
	};


	/** Handle a move over the volumebar **/
	private function volumedownHandler(evt:MouseEvent) {
		var vsl = bar.volumeSlider;
		var rct = new Rectangle(vsl.rail.x,vsl.icon.y,vsl.width-vsl.icon.width,0);
		vsl.icon.startDrag(true,rct);
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
		var vsl = bar.volumeSlider;
		vsl.icon.stopDrag();
    	bar.stage.removeEventListener(MouseEvent.MOUSE_UP,volumeupHandler);
		var xps = vsl.icon.x - bar.volumeSlider.rail.x;
		var pct = Math.round(xps*100/(vsl.rail.width-vsl.icon.width));
		view.sendEvent(ViewEvent.VOLUME,pct);
	};


};


}