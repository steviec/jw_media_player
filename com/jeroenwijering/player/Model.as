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
	/** The list with all active models. **/
	private var models:Object = {};
	/** Currently active model. **/
	private var currentModel:String;
	/** Currently active mediafile. **/
	private var currentURL:String;
	/** Currently active thumbnail. **/
	private var currentThumb:String;
	/** Loader for the preview image. **/
	private var loader:Loader;
	/** show thumbnails (in case of audio). **/
	private var showthumb:Boolean;


	/** Constructor, save arrays and set currentItem. **/
	public function Model(cfg:Object,skn:MovieClip,ctr:Controller) {
		config = cfg;
		skin = skn;
		controller = ctr;
		controller.addEventListener(ControllerEvent.ITEM,itemHandler);
		controller.addEventListener(ControllerEvent.MUTE,muteHandler);
		controller.addEventListener(ControllerEvent.PLAY,playHandler);
		controller.addEventListener(ControllerEvent.PLAYLIST,playlistHandler);
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
		var typ = playlist[evt.data.index]['type'];
		var url = playlist[evt.data.index]['file'];
		trace(playlist[evt.data.index]['start']);
		if(models[typ] && typ == currentModel) {
			if(url == currentURL && typ != 'rtmp') {
				models[typ].seek(playlist[evt.data.index]['start']);
			} else {
				models[typ].load();
				currentURL = url;
			}
		} else {
			if (currentModel) {
				stopHandler();
			}
			if(!models[typ]) { 
				loadModel(typ); 
			}
			models[typ].load();
			currentModel = typ;
			currentURL = url;
		}
		thumbLoader();
	};


	/** Setup a new model. **/
	private function loadModel(typ:String) {
		switch(typ) {
			case 'camera':
				models[typ] = new CameraModel(this);
				break;
			case 'image':
				models[typ] = new ImageModel(this);
				break;
			case 'rtmp':
				models[typ] = new RTMPModel(this);
				break;
			case 'sound':
				models[typ] = new SoundModel(this);
				break;
			case 'video':
				if(config['streamscript']) {
					models[typ] = new HTTPModel(this);
				} else {
					models[typ] = new VideoModel(this);
				}
				break;
			case 'youtube':
				models[typ] = new YoutubeModel(this);
				break;
		}
	};

	/** Place a loaded mediafile on stage **/
	public function mediaHandler(chd:DisplayObject=undefined) {
		var obj = skin.display.media;
		Draw.clear(obj);
		if(chd) { 
			showthumb = false;
			obj.addChild(chd);
			Stretcher.stretch(obj,config['width'],config['height'],config['stretching']);
		} else { 
			skin.display.thumb.visible = true;
			skin.display.media.visible = false;
			showthumb = true;
		}
	};


	/** Load the configuration array. **/
	private function muteHandler(evt:ControllerEvent) {
		if(currentModel && evt.data.state == true) {
			models[currentModel].volume(0); 
		} else if(currentModel && evt.data.state == false) {
			models[currentModel].volume(config['volume']);
		}
	};


	/** Togge the playback state. **/
	private function playHandler(evt:ControllerEvent) {
		if(currentModel && evt.data.state == true) {
			models[currentModel].play();
		} else { 
			models[currentModel].pause();
		}
	};


	/** Send an idle with new playlist. **/
	private function playlistHandler(evt:ControllerEvent) {
		if(currentModel) {
			stopHandler();
		} else { 
			sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
		}
		thumbLoader();
	};


	/** Toggle the playback quality. **/
	private function qualityHandler(evt:ControllerEvent) {
		if(currentModel) {
			models[currentModel].quality(evt.data.state);
		}
	};


	/** Resize the media and thumb. **/
	private function resizeHandler(evt:ControllerEvent) {
		Stretcher.stretch(skin.display.thumb,evt.data.width,evt.data.height,config['stretching']);
		Stretcher.stretch(skin.display.media,evt.data.width,evt.data.height,config['stretching']);
	};


	/** Seek inside a file. **/
	private function seekHandler(evt:ControllerEvent) {
		if(currentModel) {
			models[currentModel].seek(evt.data.position);
		}
	};


	/** Load the configuration array. **/
	private function stopHandler(evt:ControllerEvent=undefined) {
		currentURL = undefined;
		if(currentModel) {
			models[currentModel].stop();
		}
		sendEvent(ModelEvent.LOADED,{loaded:0,total:0});
		sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/**  Dispatch events. State switch is saved. **/
	public function sendEvent(typ:String,dat:Object) {
		if(typ == ModelEvent.STATE && dat.newstate != config['state']) {
			if(dat.newstate == ModelStates.IDLE || dat.newstate == ModelStates.COMPLETED) {
				skin.display.thumb.visible = true;
				skin.display.media.visible = false;
				sendEvent(ModelEvent.TIME,{
					position:playlist[config['item']]['start'],
					duration:playlist[config['item']]['duration']
				});
			} else if (showthumb == false) {
				skin.display.thumb.visible = false;
				skin.display.media.visible = true;
			}
			dat.oldstate = config['state'];
			config['state'] = dat.newstate;
			dispatchEvent(new ModelEvent(typ,dat));
		} else if (typ != ModelEvent.STATE) {
			dispatchEvent(new ModelEvent(typ,dat));
		}
	};


	/** Load a thumb on stage. **/
	private function thumbLoader() {
		var img = playlist[config['item']]['image'];
		if(currentThumb != img) {
			if(img) {
				loader.load(new URLRequest(img));
				currentThumb = img;
			} else {
				Draw.clear(skin.display.thumb);
				currentThumb = undefined;
			}
		}
	};

	/** Place a loaded thumb on stage. **/
	private function thumbHandler(evt:Event) {
		var obj = skin.display.thumb;
		Draw.clear(obj);
		obj.addChild(loader);
		Bitmap(loader.content).smoothing = config['quality'];
		Stretcher.stretch(obj,config['width'],config['height'],config['stretching']);
	};


	/** Load the configuration array. **/
	private function volumeHandler(evt:ControllerEvent) {
		if(currentModel) {
			models[currentModel].volume(evt.data.percentage);
		}
	};


	/** Getter for the playlist **/
	public function get playlist():Array {
		return controller.playlist;
	};


}


}