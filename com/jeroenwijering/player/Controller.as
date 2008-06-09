/**
* Process all input from the views and modifies the model.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.*;
import flash.display.MovieClip;
import flash.events.*;
import flash.geom.Rectangle;
import flash.net.*;
import flash.system.Capabilities;


public class Controller extends EventDispatcher {


	/** Configuration object **/
	private var config:Object;
	/** Reference to the skin; for stage event subscription. **/
	private var skin:MovieClip;
	/** Object that manages the playlist. **/
	private var playlister:Playlister;
	/** Reference to the player's model. **/
	private var model:Model;
	/** Reference to the player's view. **/
	private var view:View;
	/** object that povides randomization. **/
	private var randomizer:Randomizer;


	/** Constructor, set up stage and playlist listeners. **/
	public function Controller(cfg:Object,skn:MovieClip) {
		config = cfg;
		skin = skn;
		skin.stage.scaleMode = "noScale";
		skin.stage.align = "TL";
		skin.stage.addEventListener(Event.RESIZE,resizeHandler);
		playlister = new Playlister();
		playlister.addEventListener(Event.COMPLETE,playlistHandler);
		playlister.addEventListener(ErrorEvent.ERROR,errorHandler);
	};


	/** Register view and model with controller, start loading playlist. **/
	public function start(mdl:Model,vie:View) {
		model= mdl;
		model.addEventListener(ModelEvent.META,metaHandler);
		model.addEventListener(ModelEvent.TIME,metaHandler);
		view = vie;
		view.addEventListener(ViewEvent.CAPTION,captionHandler);
		view.addEventListener(ViewEvent.FULLSCREEN,fullscreenHandler);
		view.addEventListener(ViewEvent.ITEM,itemHandler);
		view.addEventListener(ViewEvent.LINK,linkHandler);
		view.addEventListener(ViewEvent.LOAD,loadHandler);
		view.addEventListener(ViewEvent.MUTE,muteHandler);
		view.addEventListener(ViewEvent.NEXT,nextHandler);
		view.addEventListener(ViewEvent.PLAY,playHandler);
		view.addEventListener(ViewEvent.PREV,prevHandler);
		view.addEventListener(ViewEvent.QUALITY,qualityHandler);
		view.addEventListener(ViewEvent.SEEK,seekHandler);
		view.addEventListener(ViewEvent.STOP,stopHandler);
		view.addEventListener(ViewEvent.VOLUME,volumeHandler);
		resizeHandler(new Event(Event.RESIZE));
		playlister.load(config);
	};


	/** Save new state of the dub/caption switches. **/
	private function captionHandler(evt:ViewEvent) {
		if(evt.data.state && evt.data.state != config['caption']) { 
			config['caption'] = evt.data.state;
		} else { 
			config['caption'] = !config['caption'];
		}
		Configger.saveCookie('caption',config['caption']);
		dispatchEvent(new ControllerEvent(ControllerEvent.CAPTION,{state:config['caption']}));
	};


	/** Catch errors dispatched by the playlister. **/
	private function errorHandler(evt:ErrorEvent) {
		dispatchEvent(new ControllerEvent(ControllerEvent.ERROR,{message:evt.text}));
	};


	/** Switch fullscreen state. **/
	private function fullscreenHandler(evt:ViewEvent) {
		if(skin.stage.displayState == 'fullScreen') {
			skin.stage.displayState = 'normal';
		} else {
			skin.stage["fullScreenSourceRect"] = new Rectangle(0,0,
				Capabilities.screenResolutionX,Capabilities.screenResolutionY);
			skin.stage.displayState = 'fullScreen';
		}
	};


	/** Jump to a userdefined item in the playlist. **/
	private function itemHandler(evt:ViewEvent) {
		if(playlist[config['item']]['author'] == 'commercial') { return; }
		var itm = evt.data.index;
		if (itm < 0) {
			playItem(0);
		} else if (itm > playlist.length-1) { 
			playItem(playlist.length-1);
		} else if (!isNaN(itm)) {
			playItem(itm);
		}
	};


	/** Jump to the link of a playlistitem. **/
	private function linkHandler(evt:ViewEvent) {
		var itm = evt.data.index;
		if (itm  == undefined) {
			itm = config['item'];
		}
		var lnk = playlist[itm]['link'];
		if(lnk != undefined) {
			navigateToURL(new URLRequest(lnk),config['linktarget']);
		}
	};


	/** Load a new playlist. **/
	private function loadHandler(evt:ViewEvent) {
		try {
			playlister.load(evt.data.object);
		} catch (err:Error) {
			dispatchEvent(new ControllerEvent(ControllerEvent.ERROR,{message:err.message}));
		}
	};



	/** Update playlist item duration. **/
	private function metaHandler(evt:ModelEvent) {
		if(evt.data.duration) {
			var dur = Math.round(evt.data.duration*10)/10
			playlister.update(config['item'],'duration',dur);
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function muteHandler(evt:ViewEvent) {
		if(evt.data.state) {
			if(evt.data.state == config['mute']) {
				return;
			} else { 
				config['mute'] = evt.data.state;
			}
		} else {
			config['mute'] = !config['mute'];
		}
		Configger.saveCookie('mute',config['mute']);
		dispatchEvent(new ControllerEvent(ControllerEvent.MUTE,{state:config['mute']}));
	};


	/** Jump to the next item in the playlist. **/
	private function nextHandler(evt:ViewEvent) {
		if(playlist[config['item']]['author'] == 'commercial') { return; }
		if(config['shuffle'] == true) { 
			playItem(randomizer.pick());
		} else if (config['item'] == playlist.length - 1) {
			playItem(0);
		} else { 
			playItem(config['item']+1);
		}
	};


	/** change the playback state. **/
	private function playHandler(evt:ViewEvent) {
		if(evt.data.state) {
			dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:evt.data.state}));
		} else if(config['state'] == ModelStates.PLAYING || config['state'] == ModelStates.BUFFERING) {
			dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:false}));
		} else { 
			dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:true}));
		}
	};


	/** Direct the model to play a new item. **/
	private function playItem(nbr:Number) {
		if(config['item'] != nbr) {
			config['item'] = nbr;
			dispatchEvent(new ControllerEvent(ControllerEvent.ITEM,{index:config['item']}));
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:true}));
	};


	/** Manage playback state changes **/
	private function playlistHandler(evt:Event) {
		dispatchEvent(new ControllerEvent(ControllerEvent.PLAYLIST,{playlist:playlist}));
		if(config['shuffle'] == true) {
			randomizer = new Randomizer(playlist.length);
			config['item'] = randomizer.pick();
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.ITEM,{index:config['item']}));
		if(config['autostart'] == true) {
			dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:true}));
		}
	};


	/** Jump to the previous item in the playlist. **/
	private function prevHandler(evt:ViewEvent) {
		if(playlist[config['item']]['author'] == 'commercial') { return; }
		if(config['shuffle'] == true) { 
			playItem(randomizer.back());
		} else if (config['item'] == 0) {
			playItem(playlist.length-1);
		} else { 
			playItem(config['item']-1);
		}
	};


	/** Switch playback quality. **/
	private function qualityHandler(evt:ViewEvent) {
		if(evt.data.state && evt.data.state != config['quality']) {
			config['quality'] = evt.data.state;
		} else {
			config['quality'] = !config['quality'];
		}
		Configger.saveCookie('quality',config['quality']);
		dispatchEvent(new ControllerEvent(ControllerEvent.QUALITY,{state:config['quality']}));
	};


	/** Forward a resizing of the stage. **/
	private function resizeHandler(evt:Event) {
		var dat = {
			height:skin.stage.stageHeight,
			width:skin.stage.stageWidth,
			fullscreen:false
		};
		if(config['controlbar'] == 'bottom') {
			dat.height -= config['controlbarsize'];
		}
		if(config['playlist'] == 'right') {
			dat.width -= config['playlistsize'];
		} else if(config['playlist'] == 'bottom') {
			dat.height -= config['playlistsize'];
		}
		if(skin.stage.displayState == 'fullScreen') {
			dat.fullscreen = true;
			dat.height = skin.stage.stageHeight;
			dat.width = skin.stage.stageWidth;
		}
		config['height'] = dat.height;
		config['width'] = dat.width;
		dispatchEvent(new ControllerEvent(ControllerEvent.RESIZE,dat));
	};


	/** Seek to a specific part in a mediafile. **/
	private function seekHandler(evt:ViewEvent) {
		if(playlist[config['item']]['author'] == 'commercial') { return; }
		var pos = evt.data.position;
		if(pos < 2) { pos = 0; }
		if(playlist[config['item']]['duration'] > 0) {
			dispatchEvent(new ControllerEvent(ControllerEvent.SEEK,{position:pos}));
		}
	};


	/** Stop all playback and bufering. **/
	private function stopHandler(evt:ViewEvent) {
		dispatchEvent(new ControllerEvent(ControllerEvent.STOP));
	};


	/** Manage playback state changes **/
	private function stateHandler(evt:ModelEvent) {
		if(evt.data.newstate == ModelStates.COMPLETED && (config['repeat'] == true ||
			(config['shuffle'] == true && randomizer.length > 0) || 
			(config['shuffle'] == false && config['item'] < playlist.length-1))) {
			if(config['shuffle'] == true) {
				playItem(randomizer.pick());
			} else if(config['item'] == playlist.length-1) {
				playItem(0);
			} else {
				playItem(config['item']+1);
			}
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function volumeHandler(evt:ViewEvent) {
		var vol = evt.data.percentage;
		if (vol < 1) {
			muteHandler(new ViewEvent(ViewEvent.MUTE,{state:true}));
		} else if (!isNaN(vol) && vol < 101) {
			if(config['mute'] == true) { 
				muteHandler(new ViewEvent(ViewEvent.MUTE,{state:false}));
			}
			config['volume'] = vol;
			Configger.saveCookie('volume',vol);
			dispatchEvent(new ControllerEvent(ControllerEvent.VOLUME,{percentage:vol}));
		}
	}; 


	/** Getter for the playlist. **/
	public function get playlist():Array {
		return playlister.playlist;
	};


}


}