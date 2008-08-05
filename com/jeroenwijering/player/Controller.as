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
	/** object that provides randomization. **/
	private var randomizer:Randomizer;


	/** Constructor, set up stage and playlist listeners. **/
	public function Controller(cfg:Object,skn:MovieClip) {
		config = cfg;
		skin = skn;
		playlister = new Playlister();
		playlister.addEventListener(Event.COMPLETE,playlistHandler);
		playlister.addEventListener(ErrorEvent.ERROR,errorHandler);
		resizeHandler(new ViewEvent(ViewEvent.RESIZE,{
			width:skin.stage.stageWidth,
			height:skin.stage.stageHeight
		}));
	};


	/** Register view and model with controller, start loading playlist. **/
	public function start(mdl:Model,vie:View) {
		model= mdl;
		model.addEventListener(ModelEvent.META,metaHandler);
		model.addEventListener(ModelEvent.TIME,metaHandler);
		model.addEventListener(ModelEvent.STATE,stateHandler);
		view = vie;
		view.addEventListener(ViewEvent.FULLSCREEN,fullscreenHandler);
		view.addEventListener(ViewEvent.ITEM,itemHandler);
		view.addEventListener(ViewEvent.LINK,linkHandler);
		view.addEventListener(ViewEvent.LOAD,loadHandler);
		view.addEventListener(ViewEvent.MUTE,muteHandler);
		view.addEventListener(ViewEvent.NEXT,nextHandler);
		view.addEventListener(ViewEvent.PLAY,playHandler);
		view.addEventListener(ViewEvent.PREV,prevHandler);
		view.addEventListener(ViewEvent.QUALITY,qualityHandler);
		view.addEventListener(ViewEvent.RESIZE,resizeHandler);
		view.addEventListener(ViewEvent.SEEK,seekHandler);
		view.addEventListener(ViewEvent.STOP,stopHandler);
		view.addEventListener(ViewEvent.VOLUME,volumeHandler);
		resizeHandler(new ViewEvent(ViewEvent.RESIZE, {
			width:skin.stage.stageWidth,
			height:skin.stage.stageHeight
		}));
		if(config['file']) { 
			playlister.load(config); 
		}
	};



	/** Catch errors dispatched by the playlister. **/
	private function errorHandler(evt:ErrorEvent) {
		dispatchEvent(new ControllerEvent(ControllerEvent.ERROR,{message:evt.text}));
	};


	/** Switch fullscreen state. **/
	private function fullscreenHandler(evt:ViewEvent) {
		if(skin.stage['displayState'] == 'fullScreen') {
			skin.stage['displayState'] = 'normal';
		} else {
			fullscreenrect();
			skin.stage['displayState'] = 'fullScreen';
		}
	};


	/** Set the fullscreen rectangle **/
	private function fullscreenrect() {
		try { 
			skin.stage["fullScreenSourceRect"] = new Rectangle(0,0,
				Capabilities.screenResolutionX/2,Capabilities.screenResolutionY/2);
		} catch (err:Error) {}
	};


	/** Jump to a userdefined item in the playlist. **/
	private function itemHandler(evt:ViewEvent) {
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
		stopHandler();
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
		dispatchEvent(new ControllerEvent(ControllerEvent.MUTE,{state:config['mute']}));
	};


	/** Jump to the next item in the playlist. **/
	private function nextHandler(evt:ViewEvent) {
		if(playlist && config['shuffle'] == true) { 
			playItem(randomizer.pick());
		} else if (playlist && config['item'] == playlist.length-1) {
			playItem(0);
		} else if (playlist) { 
			playItem(config['item']+1);
		}
	};


	/** Change the playback state. **/
	private function playHandler(evt:ViewEvent) {
		if(playlist) {
			if(evt.data.state != false && config['state'] == ModelStates.PAUSED) {
				dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:true}));
			} else if (evt.data.state != false && config['state'] == ModelStates.COMPLETED) {
				dispatchEvent(new ControllerEvent(ControllerEvent.SEEK,{position:playlist[config['item']]['start']}));
			} else if(evt.data.state != false && config['state'] == ModelStates.IDLE) {
				playItem();
			} else if (evt.data.state != true &&
				(config['state'] == ModelStates.PLAYING || config['state'] == ModelStates.BUFFERING)) {
				dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:false}));
			}
		}
	};


	/** Direct the model to play a new item. **/
	private function playItem(nbr:Number=undefined) {
		if(nbr > -1) {
			if(playlist[nbr]['file'] == playlist[config['item']]['file']) {
				playlist[nbr]['duration'] = playlist[config['item']]['duration'];
			}
			config['item'] = nbr;
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.ITEM,{index:config['item']}));
	};


	/** Manage loading of a new playlist. **/
	private function playlistHandler(evt:Event) {
		if(config['shuffle'] == true) {
			randomizer = new Randomizer(playlist.length);
			config['item'] = randomizer.pick();
		} else if (config['item'] > playlist.length) {
			config['item'] = playlist.length-1;
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.PLAYLIST,{playlist:playlist}));
		if(config['autostart'] == true) {
			playItem();
		}
	};


	/** Jump to the previous item in the playlist. **/
	private function prevHandler(evt:ViewEvent) {
		if (config['item'] == 0) {
			playItem(playlist.length-1);
		} else { 
			playItem(config['item']-1);
		}
	};


	/** Switch playback quality. **/
	private function qualityHandler(evt:ViewEvent=null) {
		if(evt.data.state != undefined) {
			if(evt.data.state == config['quality']) {
				return;
			} else { 
				config['quality'] = evt.data.state;
			}
		} else {
			config['quality'] = !config['quality'];
		}
		fullscreenrect();
		dispatchEvent(new ControllerEvent(ControllerEvent.QUALITY,{state:config['quality']}));
	};


	/** Forward a resizing of the stage. **/
	private function resizeHandler(evt:ViewEvent) {
		var mgn = config['margins'].split(',');
		var dat = {
			height:evt.data.height-mgn[0],
			width:evt.data.width-mgn[1],
			fullscreen:false
		};
		try { 
			var dps = skin.stage['displayState'];
		} catch (err:Error) {}
		if(dps == 'fullScreen') {
			dat.fullscreen = true;
		} else {
			if(config['controlbar'] == 'bottom') {
				dat.height -= config['controlbarsize'];
			}
			if(config['playlist'] == 'right') {
				dat.width -= config['playlistsize'];
			} else if(config['playlist'] == 'bottom') {
				dat.height -= config['playlistsize'];
			}
		}
		config['height'] = dat.height;
		config['width'] = dat.width;
		dispatchEvent(new ControllerEvent(ControllerEvent.RESIZE,dat));
	};


	/** Seek to a specific part in a mediafile. **/
	private function seekHandler(evt:ViewEvent) {
		if(config['state'] != ModelStates.IDLE && playlist[config['item']]['duration'] > 0) {
			var pos = evt.data.position;
			if(pos < 2) { 
				pos = 0;
			} else if (pos > playlist[config['item']]['duration']-2) { 
				pos = playlist[config['item']]['duration']-2;
			}
			dispatchEvent(new ControllerEvent(ControllerEvent.SEEK,{position:pos}));
		}
	};


	/** Stop all playback and buffering. **/
	private function stopHandler(evt:ViewEvent=undefined) {
		dispatchEvent(new ControllerEvent(ControllerEvent.STOP));
	};


	/** Manage playback state changes. **/
	private function stateHandler(evt:ModelEvent) {
		if(evt.data.newstate == ModelStates.COMPLETED && (config['repeat'] == 'always' ||
			(config['repeat'] == 'list' && config['shuffle'] == true && randomizer.length > 0) || 
			(config['repeat'] == 'list' && config['shuffle'] == false && config['item'] < playlist.length-1))) {
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
			dispatchEvent(new ControllerEvent(ControllerEvent.VOLUME,{percentage:vol}));
		}
	}; 


	/** Getter for the playlist. **/
	public function get playlist():Array {
		return playlister.playlist;
	};


}


}