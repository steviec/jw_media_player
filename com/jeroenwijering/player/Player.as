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
		margins:'0,0',
		plugins:undefined,
		streamer:undefined,
		token:undefined,
		tracecall:undefined,
		version:'4.1.59'
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
	/** A list with all the active plugins. **/
	private var plugins:Array;


	/** Constructor; Loads config parameters. **/
	public function Player():void {
		visible = false;
		plugins = new Array();
		configger = new Configger(this);
		configger.addEventListener(Event.COMPLETE,configHandler);
		configger.load(defaults);
	};


	/** Config loading completed; now load skin. **/
	private function configHandler(evt:Event):void {
		loader = new SWFLoader(this);
		loader.addEventListener(Event.INIT,skinHandler);
		loader.addEventListener(Event.COMPLETE,pluginHandler);
		loader.loadSkin(configger.config['skin']);
	};


	/** Skin loading completed, now load MVC and plugins. **/
	private function skinHandler(evt:Event):void {
		controller = new Controller(configger.config,loader.skin);
		model = new Model(configger.config,loader.skin,controller);
		_view = new View(configger.config,loader.skin,controller,model);
		if(loader.skin['captions']) { addPlugin(new Captions()); }
		if(loader.skin['controlbar']) { addPlugin(new Controlbar()); }
		if(loader.skin['display']) { addPlugin(new Display()); }
		if(loader.skin['playlist']) { addPlugin(new Playlist()); }
		loader.loadPlugins(configger.config['plugins']);
	};


	/** 
	* Add a certain plugin to the list.
	*
	* @prm plg		Any object that implements the PluginInterface.
	**/
	public function addPlugin(plg:Object):void {
		plugins.push(plg);
	};


	/** Plugin loading completed; let's start! **/
	private function pluginHandler(evt:Event=null):void {
		for(var i=0; i<plugins.length; i++) { plugins[i].initializePlugin(_view); }
		controller.start(model,_view);
		visible = true;
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