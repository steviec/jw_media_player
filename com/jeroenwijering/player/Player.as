/**
* Player that crunches through all media formats Flash can read.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.Configger;
import com.jeroenwijering.utils.Skinner;
import flash.display.MovieClip;
import flash.events.Event;


public class Player extends MovieClip {


	/** A list with all default configuration values. **/
	private var defaults:Object = {
		author:undefined,
		captions:undefined,
		description:undefined,
		duration:0,
		file:undefined,
		image:undefined,
		link:undefined,
		start:0,
		title:undefined,
		type:undefined,

		controlbar:'bottom',
		logo:undefined,
		playlist:'none',
		playlistsize:180,
		skin:undefined,

		autostart:false,
		bufferlength:1,
		caption:true,
		displayclick:'play',
		fullscreen:false,
		item:0,
		mute:false,
		quality:true,
		repeat:false,
		shuffle:false,
		stretching:'uniform',
		volume:80,

		abouttext:"About JW Player 4.0...",
		aboutlink:"http://www.jeroenwijering.com/?page=about",
		linktarget:'_self',
		streamscript:undefined,
		tracecall:undefined,

		client:undefined,
		controlbarheight:20,
		height:300,
		plugins:undefined,
		state:'IDLE',
		version:'4.0 r21',
		width:400
	};
	/** Object that loads all configuration variables. **/
	private var configger:Configger;
	/** Object that load the skin and inits the layout. **/
	private var skinner:Skinner;
	/** Reference to the Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Reference to the model of the MVC cycle. **/
	private var model:Model;
	/** Reference to the View of the MVC cycle. **/
	private var _view:View;


	/** Constructor; Loads config parameters. **/
	public function Player() {
		this.visible = false;
		configger = new Configger(this);
		configger.addEventListener(Event.COMPLETE,configHandler);
		configger.load(defaults);
	};


	/** Config loading completed; now load skin. **/
	private function configHandler(evt:Event) {
		skinner = new Skinner(this);
		skinner.addEventListener(Event.COMPLETE,skinHandler);
		skinner.load(configger.config);
	};


	/** Skin loading completed, now load MVC and plugins. **/
	private function skinHandler(evt:Event) {
		this.visible = true;
		controller = new Controller(configger.config,skinner.skin);
		model = new Model(configger.config,skinner.skin,controller);
		_view = new View(configger.config,skinner.skin,controller,model);
		controller.start(model,_view);
	};


	/** reference to the view, so plugins and listeners can interface. **/
	public function get view():View {
		return _view;
	};


}


}