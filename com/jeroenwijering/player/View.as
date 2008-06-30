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
import flash.system.*;
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
	/**  A list with all the active plugins. **/
	private var plugins:Array;
	/** Base directory for the plugins. **/
	private var directory:String = 'http://plugins.longtailvideo.com/';


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ctr:Controller,mdl:Model) {
		Security.allowDomain('*');
		_config = cfg;
		_config['client'] = 'FLASH '+Capabilities.version;
		_skin = skn;
		_skin.stage.scaleMode = "noScale";
		_skin.stage.align = "TL";
		_skin.stage.addEventListener(Event.RESIZE,resizeHandler);
		_config['controlbarsize'] = _skin['controlbar'].height;
		controller = ctr;
		model = mdl;
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
			ldr.contentLoaderInfo.addEventListener(Event.INIT,loadHandler);
			if(skin.loaderInfo.url.indexOf('http://') == 0) {
            	var ctx = new LoaderContext(true,ApplicationDomain.currentDomain,SecurityDomain.currentDomain);
				ldr.load(new URLRequest(directory+arr[i]+'.swf'),ctx);
			} else {
				ldr.load(new URLRequest(arr[i]+'.swf'));
			}
		}
	};


	/** Forward a resizing of the stage. **/
	private function resizeHandler(evt:Event=undefined) {
		var dat = {
			height:_skin.stage.stageHeight,
			width:_skin.stage.stageWidth
		};
		dispatchEvent(new ViewEvent(ViewEvent.RESIZE,dat));
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
				if (prm > -1) {
					dat['index'] = prm;
				}
				break;
			case 'LOAD':
				dat['object'] = prm;
				break;
			case 'ITEM':
				if (prm > -1) {
					dat['index'] = prm;
				}
				break;
			case 'SEEK':
				dat['position'] = prm;
				break;
			case 'VOLUME':
				dat['percentage'] = prm;
				break;
			default:
				if(prm) {
					if(prm == true || prm == 'true') {
						dat['state'] = true;
					} else { 
						dat['state'] = false;
					}
				}
				break;
		}
		dispatchEvent(new ViewEvent(typ,dat));
	};


}


}