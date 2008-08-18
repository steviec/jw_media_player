/**
* Player that crunches through all media formats Flash can read.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.player.*;
import com.jeroenwijering.plugins.*;
import com.jeroenwijering.utils.Configger;
import flash.display.MovieClip;
import flash.events.Event;


public class Player extends MovieClip {


	/** A list with all default configuration values. Change to hard-code your prefs. **/
	private var defaults:Object = {
		author:undefined,
		description:undefined,
		duration:0,
		file:undefined,
		image:undefined,
		link:undefined,
		start:0,
		title:undefined,
		type:undefined,

		backcolor:undefined,
		frontcolor:undefined,
		lightcolor:undefined,
		screencolor:undefined,

		controlbar:'bottom',
		controlbarsize:20,
		height:300,
		logo:undefined,
		playlist:'none',
		playlistsize:180,
		skin:undefined,
		width:400,

		autostart:false,
		bufferlength:0.1,
		displayclick:'play',
		item:0,
		mute:false,
		quality:true,
		repeat:'none',
		shuffle:false,
		state:'IDLE',
		stretching:'uniform',
		volume:80,

		abouttext:undefined,
		aboutlink:"http://www.jeroenwijering.com/?item=JW_FLV_Player",
		client:undefined,
		id:undefined,
		linktarget:'_blank',
		margins:'0,0,0,0',
		plugins:undefined,
		streamer:undefined,
		token:undefined,
		tracecall:undefined,
		version:'4.1.60'
	};
	/** Object that loads all configuration variables. **/
	private var configger:Configger;
	/** Object that load the skin and plugins. **/
	private var loader:SWFLoader;
	/** Reference to the Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Reference to the model of the MVC cycle. **/
	private var model:Model;
	/** Reference to the View of the MVC cycle. **/
	private var _view:View;


	/** Constructor; Loads config parameters. **/
	public function Player():void {
		visible = false;
		configger = new Configger(this);
		configger.addEventListener(Event.COMPLETE,configHandler);
		configger.load(defaults);
	};


	/** Config loading completed; now load skin. **/
	private function configHandler(evt:Event):void {
		loader = new SWFLoader(this);
		loader.addEventListener(Event.COMPLETE,skinHandler);
		loader.loadSkin(configger.config['skin']);
	};


	/** Skin loading completed, now load MVC. **/
	private function skinHandler(evt:Event):void {
		controller = new Controller(configger.config,loader.skin);
		model = new Model(configger.config,loader.skin,controller);
		_view = new View(configger.config,loader,controller,model);
		controller.start(model,_view);
		visible = true;
		addPlugins();
	};


	/** MVC inited; now add plugins. **/
	private function addPlugins() {
		if(loader.skin['captions']) { new Captions().initializePlugin(view); }
		if(loader.skin['controlbar']) { new Controlbar().initializePlugin(view); }
		if(loader.skin['display']) { new Display().initializePlugin(view); }
		if(loader.skin['playlist']) { new Playlist().initializePlugin(view); }
		loader.loadPlugins(configger.config['plugins']);
	};


	/** 
	* Reference to the view, so actionscript applications can access the API. 
	* 
	* @return	A reference to the view, which has access points for config, playlist, listeners and events.
	**/
	public function get view():View {
		return _view;
	};


}


}