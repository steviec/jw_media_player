/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.views.*;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.MovieClip;
import flash.events.*;
import flash.system.Capabilities;
import flash.net.URLRequest;


public class View extends AbstractView {


	/** Object with all configuration parameters **/
	private var _config:Object;
	/** Clip with all graphical elements **/
	private var _skin:MovieClip;
	/** Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Model of the MVC cycle. **/
	private var model:Model;
	/** A list with all the active views. **/
	private var views:Array;
	/**  A list with all the active plugins. **/
	private var plugins:Array;
	/** Base directory for the plugins. **/
	private var DIRECTORY:String = 'http://www.jeroenwijering.com/upload/';


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ctr:Controller,mdl:Model) {
		_config = cfg;
		_skin = skn;
		_config['controlbarheight'] = _skin['controlbar'].height;
		controller = ctr;
		model = mdl;
		loadViews();
		if(_config['plugins']) {
			plugins = new Array();
			loadPlugins();
		}
	};


	/** Add a plugin to the list when loaded. **/
	private function loadHandler(evt:Event) {
		var ldi = LoaderInfo(evt.target);
		plugins.push(ldi.content);
		ldi.content.initialize(this);
	}


	/** Load all attached plugins. **/
	private function loadPlugins() { 
		var arr = _config['plugins'].split(',');
		for(var i in arr) {
			var ldr = new Loader();
			_skin.addChild(ldr);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,loadHandler);
			ldr.load(new URLRequest(DIRECTORY+arr[i]+'.swf'));
		}
	};


	/** Add all default views. **/
	private function loadViews() {
		views = new Array();
		views.push(new CaptionsView(this));
		views.push(new DisplayView(this));
		views.push(new ExternalView(this));
		views.push(new KeyboardView(this));
		views.push(new RightclickView(this));
		if(_skin.controlbar) {
			if(config['controlbar'] == 'none') { 
				_skin.controlbar.visible = false;
			} else { 
				views.push(new ControlbarView(this));
			}
		}
		if(_skin.playlist) {
			if(config['playlist'] == 'none') {
				_skin.playlist.visible = false;
			} else { 
				views.push(new PlaylistView(this));
			}
		}
	};


	/**  Getters for the config parameters, skinning parameters and playlist. **/
	override public function get config():Object { return _config; };
	override public function get playlist():Array { return controller.playlist; };
	override public function get skin():MovieClip { return _skin; };


	/**  Subscribers to the controller and model. **/
	override public function addControllerListener(typ:String,fcn:Function) {
		controller.addEventListener(typ.toUpperCase(),fcn);
	};
	override public function addModelListener(typ:String,fcn:Function) {
		model.addEventListener(typ.toUpperCase(),fcn);
	};
	override public function addViewListener(typ:String,fcn:Function) {
		this.addEventListener(typ.toUpperCase(),fcn);
	};


	/**  Dispatch events. **/
	override public function sendEvent(typ:String,prm:Object=undefined) {
		typ = typ.toUpperCase();
		var dat = new Object();
		switch(typ) {
			case 'ERROR':
				dat['message'] = prm;
				break;
			case 'LINK':
				dat['index'] = prm;
				break;
			case 'LOAD':
				dat['object'] = prm;
				break;
			case 'ITEM':
				dat['index'] = prm;
				break;
			case 'SEEK':
				dat['position'] = prm;
				break;
			case 'VOLUME':
				dat['percentage'] = prm;
				break;
			default:
				if(prm) { dat['state'] = prm; }
				break;
		}
		dispatchEvent(new ViewEvent(typ,dat));
	};


}


}