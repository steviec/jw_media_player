/**
* Wrap all media API's and manage playback.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.*;
import flash.display.*;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.URLRequest;


public class Model extends EventDispatcher {



	/** Object with all configuration variables. **/
	public var config:Object;
	/** Reference to the skin MovieClip. **/
	public var skin:MovieClip;
	/** Reference to the player's controller. **/
	private var controller:Controller;
	/** Currently active model. **/
	private var current:Object;
	/** Current playback state **/
	public var state:String;
	/** Loader for the preview image. **/
	private var loader:Loader;


	/** Constructor, save arrays and set currentItem. **/
	public function Model(cfg:Object,skn:MovieClip,ctr:Controller) {
		config = cfg;
		skin = skn;
		controller = ctr;
		controller.addEventListener(ControllerEvent.ITEM,itemHandler);
		controller.addEventListener(ControllerEvent.MUTE,muteHandler);
		controller.addEventListener(ControllerEvent.PLAY,playHandler);
		controller.addEventListener(ControllerEvent.QUALITY,qualityHandler);
		controller.addEventListener(ControllerEvent.RESIZE,resizeHandler);
		controller.addEventListener(ControllerEvent.SEEK,seekHandler);
		controller.addEventListener(ControllerEvent.STOP,stopHandler);
		controller.addEventListener(ControllerEvent.VOLUME,volumeHandler);
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.INIT,thumbHandler);
	};


	/** Item change: switch the curently active model if there's a new URL **/
	private function itemHandler(evt:ControllerEvent) {
		// skin.display.media.visible = false;
		if(current) { current.stop(); }
		sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
		switch(playlist[evt.data.index]['type']) {
			case 'camera':
				current = new CameraModel(this);
				break;
			case 'image':
				current = new ImageModel(this);
				break;
			case 'rtmp':
				current = new RTMPModel(this);
				break;
			case 'sound':
				current = new SoundModel(this);
				break;
			case 'video':
				if(config['streamscript']) {
					current = new HTTPModel(this);
				} else {
					current = new VideoModel(this);
				}
				break;
			case 'youtube':
				current = new YoutubeModel(this);
				break;
		}
		if(playlist[evt.data.index]['image']) {
			// skin.display.thumb.visible = true;
			loader.load(new URLRequest(playlist[evt.data.index]['image']));
		} else {
			// skin.display.thumb.visible = false;
		}
	};


	/** Place a loaded thumb on stage. **/
	private function thumbHandler(evt:Event) {
		/*
		var obj = skin.display.thumb;
		Draw.clear(obj);
		obj.addChild(loader);
		Bitmap(loader.content).smoothing = config['quality'];
		Stretcher.stretch(obj,config['width'],config['height'],config['stretching']);
		*/
	};


	/** Place a loaded mediafile on stage **/
	public function mediaHandler(chd:DisplayObject) {
		/*
		var obj = skin.display.media;
		Draw.clear(obj);
		obj.addChild(chd);
		Stretcher.stretch(obj,config['width'],config['height'],config['stretching']);
		skin.display.thumb.visible = false;
		skin.display.media.visible = true;
		*/
	};


	/** Load the configuration array. **/
	private function muteHandler(evt:ControllerEvent) {
		if(current && evt.data.state == true) {
			current.volume(0); 
		} else if(current && evt.data.state == false) {
			current.volume(config['volume']);
		}
	};


	/** Togge the playback state. **/
	private function playHandler(evt:ControllerEvent) {
		if(evt.data.state == true) {
			if(state == ModelStates.IDLE) {
				current.load();
			} else if(state != ModelStates.PAUSED) {
				current.seek(playlist[config['item']]['start']);
			} else {
				current.play();
			}
		} else { 
			current.pause();
		}
	};


	/** Toggle the playback quality. **/
	private function qualityHandler(evt:ControllerEvent) {
		current.quality(evt.data.state);
	};


	/** Resize the media and thumb. **/
	private function resizeHandler(evt:ControllerEvent) {
		/*
		Stretcher.stretch(skin.display.thumb,evt.data.width,evt.data.height,config['stretching']);
		Stretcher.stretch(skin.display.media,evt.data.width,evt.data.height,config['stretching']);
		*/
	};


	/** Seek inside a file. **/
	private function seekHandler(evt:ControllerEvent) {
		if(state != ModelStates.IDLE) {
			current.seek(evt.data.position);
		}
	};


	/** Load the configuration array. **/
	private function stopHandler(evt:ControllerEvent) {
		current.stop();
		sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/**  Dispatch events. State switch is saved. **/
	public function sendEvent(typ:String,dat:Object) {
		if(typ == ModelEvent.STATE && dat.newstate != state) {
			dat.oldstate = state;
			state = dat.newstate;
			dispatchEvent(new ModelEvent(typ,dat));
		} else if (typ != ModelEvent.STATE) {
			dispatchEvent(new ModelEvent(typ,dat));
		}
	};


	/** Load the configuration array. **/
	private function volumeHandler(evt:ControllerEvent) {
		current.volume(evt.data.percentage);
	};


	/** Getter for the playlist **/
	public function get playlist():Array { 
		return controller.playlist;
	};


}


}