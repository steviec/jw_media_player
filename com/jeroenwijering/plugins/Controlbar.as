/**
* Display a controlbar and direct the search externally.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.utils.setTimeout;
import flash.utils.clearTimeout;
import flash.ui.Mouse;


public class Controlbar implements PluginInterface {


	/** Reference to the view. **/
	private var view:AbstractView;
	/** Reference to the controlbar **/
	private var bar:MovieClip;
	/** Fullscreen controlbar margin. **/
	private var margin:Number;
	/** A list with all controls. **/
	private var stacker:Stacker;
	/** Timeout for hiding the bar. **/
	private var hiding:Number;
	/** When scrubbing, icon shouldn't be set. **/
	private var scrubbing:Boolean;
	/** Color object for frontcolor. **/
	private var front:ColorTransform;
	/** Color object for lightcolor. **/
	private var light:ColorTransform;
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
	/** The actions for all sliders **/ 
	private var SLIDERS = {
		timeSlider:'SEEK',
		volumeSlider:'VOLUME'
	}


	/** Constructor. **/
	public function Controlbar():void {};


	/** Initialize from view. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,itemHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
		bar = view.skin['controlbar'];
		margin = bar.x;
		stacker = new Stacker(bar);
		setButtons();
		setColors();
		itemHandler();
		muteHandler();
		volumeHandler();
		loadedHandler();
		timeHandler();
		stateHandler();
		resizeHandler();
	};


	/** Handle clicks from all buttons. **/
	private function clickHandler(evt:MouseEvent):void {
		view.sendEvent(BUTTONS[evt.target.name]);
	};


	/** Handle mouse presses on sliders. **/
	private function downHandler(evt:MouseEvent):void {
		var tgt = evt.target;
		var rct = new Rectangle(tgt.rail.x,tgt.icon.y,tgt.rail.width-tgt.icon.width,0);
		tgt.icon.startDrag(true,rct);
		scrubbing = true;
    	bar.stage.addEventListener(MouseEvent.MOUSE_UP,upHandler);
	};


	/** Fix the timeline display. **/
	private function fixTime():void {
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
	private function itemHandler(evt:ControllerEvent=null):void {
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
	private function loadedHandler(evt:ModelEvent=null):void {
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
	private function moveHandler(evt:MouseEvent=null):void {
		if(bar.alpha == 0) { Animations.fade(bar,1); }
		clearTimeout(hiding);
		hiding = setTimeout(moveTimeout,1000);
		Mouse.show();
	};


	/** Hide above controlbar again when move has timed out. **/
	private function moveTimeout():void {
		if((bar.mouseY<0 || bar.mouseY>bar.height)  && bar.alpha == 1) {
			Animations.fade(bar,0);
			Mouse.hide();
		}
	};


	/** Show a mute icon if playing. **/
	private function muteHandler(evt:ControllerEvent=null):void {
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
	private function outHandler(evt:MouseEvent):void {
		if(front) { 
			bar[evt.target.name]['icon'].transform.colorTransform = front;
		} else {
			bar[evt.target.name].gotoAndPlay('out');
		}
	};


	/** Handle clicks from all buttons **/
	private function overHandler(evt:MouseEvent):void {
		if(light) { 
			bar[evt.target.name]['icon'].transform.colorTransform = light;
		} else {
			bar[evt.target.name].gotoAndPlay('over');
		}
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		var wid = stacker.width;
		if(view.config['controlbar'] == 'over' || (evt && evt.data.fullscreen == true)) {
			bar.y = view.config['height'] - view.config['controlbarsize'] - margin;
			bar.x = margin;
			wid = view.config['width'] - 2*margin;
			bar.back.alpha = 0.75;
		} else if(view.config['controlbar'] == 'bottom') {
			bar.x = 0;
			bar.back.alpha = 1;
			wid = view.config['width'];
			bar.y = view.config['height'];
			if(view.config['playlist'] == 'right') {
				wid += view.config['playlistsize'];
			}
		} else {
			bar.visible = false;
		}
		try { 
			bar.fullscreenButton.visible = false;
			bar.normalscreenButton.visible = false;
			if(bar.stage['displayState']) {
				if(evt && evt.data.fullscreen == true) {
					bar.fullscreenButton.visible = false;
					bar.normalscreenButton.visible = true;
				} else {
					bar.fullscreenButton.visible = true;
					bar.normalscreenButton.visible = false;
				}
			} 
		} catch (err:Error) {}
		try {
			if (wid < 250) {
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
	private function setButtons():void {
		for(var btn in BUTTONS) {
			if(bar[btn]) {
				bar[btn].mouseChildren = false;
				bar[btn].buttonMode = true;
				bar[btn].addEventListener(MouseEvent.CLICK, clickHandler);
				bar[btn].addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				bar[btn].addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			}
		}
		for(var sld in SLIDERS) {
			if(bar[sld]) {
				bar[sld].mouseChildren = false;
				bar[sld].buttonMode = true;
				bar[sld].addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
				bar[sld].addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				bar[sld].addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			}
		}
	};


	/** Init the colors. **/
	private function setColors():void {
		if(view.config['backcolor']) { 
			var clr = new ColorTransform();
			clr.color = '0x'+view.config['backcolor'].substr(-6);
			bar.back.transform.colorTransform = clr;
		}
		if(view.config['frontcolor']) {
			try {
				front = new ColorTransform();
				front.color = uint('0x'+view.config['frontcolor'].substr(-6));
				for(var btn in BUTTONS) {
					if(bar[btn]) {
						bar[btn]['icon'].transform.colorTransform = front;
					}
				}
				for(var sld in SLIDERS) {
					if(bar[sld]) {
						bar[sld]['icon'].transform.colorTransform = front;
						bar[sld]['mark'].transform.colorTransform = front;
						bar[sld]['rail'].transform.colorTransform = front;
					}
				}
				bar.elapsedText.textColor = front.color;
				bar.totalText.textColor = front.color;
			} catch (err:Error) {}
		}
		if(view.config['lightcolor']) {
			light = new ColorTransform();
			light.color = uint('0x'+view.config['lightcolor'].substr(-6));
		}
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent=undefined):void {
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
	private function timeHandler(evt:ModelEvent=null):void {
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


	/** Handle mouse releases on sliders. **/
	private function upHandler(evt:MouseEvent):void {
		var tgt = evt.target;
		var mpl = 0;
		tgt.icon.stopDrag();
		scrubbing = false;
    	bar.stage.removeEventListener(MouseEvent.MOUSE_UP,upHandler);
		if(tgt.name == 'timeSlider' && view.playlist.length) {
			mpl = view.playlist[view.config['item']]['duration'];
		} else if(tgt.name == 'volumeSlider') { 
			mpl = 100;
		}
		var pct = (tgt.icon.x-tgt.rail.x) / (tgt.rail.width-tgt.icon.width) * mpl;
		view.sendEvent(SLIDERS[tgt.name],Math.round(pct));
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent=null):void {
		try { 
			var vsl = bar.volumeSlider;
			vsl.mark.width = view.config['volume']*(vsl.rail.width-vsl.icon.width/2)/100;
			vsl.icon.x = vsl.mark.x + view.config['volume']*(vsl.rail.width-vsl.icon.width)/100;
		} catch (err:Error) {}
	};


};


}