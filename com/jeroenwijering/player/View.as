/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.player {


import flash.display.MovieClip;
import flash.events.EventDispatcher;
import flash.external.ExternalInterface;
import flash.system.Capabilities;
import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.views.*;


public class View extends EventDispatcher {


	/** Object with all configuration parameters **/
	private var _config:Object;
	/** Clip with all graphical elements **/
	private var _skin:MovieClip;
	/** Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Model of the MVC cycle. **/
	private var model:Model;
	/** A list with all the currently active views. **/
	private var views:Array;


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ctr:Controller,mdl:Model) {
		_config = cfg;
		_skin = skn;
		controller = ctr;
		model = mdl;
		addViews();
	};


	/** Add all child views. **/
	private function addViews() {
		views = new Array();
		views.push(new CaptionsView(this));
		views.push(new DisplayView(this));
		views.push(new KeyboardView(this));
		views.push(new RightclickView(this));
		if(_skin['controlbar']) {
			views.push(new ControlbarView(this));
		}
		if(_skin['playlist']) {
			views.push(new PlaylistView(this));
		}
		if(ExternalInterface.available || Capabilities.playerType == 'External') {
			views.push(new ExternalView(this));
		}
	};


	/**  Getters for the config parameters, skinning parameters and playlist. **/
	public function get config():Object { return _config; };
	public function get playlist():Array { return controller.playlist; };
	public function get skin():MovieClip { return _skin; };


	/**  Subscribers to the controller and model. **/
	public function addControllerListener(typ:String,fcn:Function) {
		controller.addEventListener(typ.toUpperCase(),fcn);
	};
	public function addModelListener(typ:String,fcn:Function) {
		model.addEventListener(typ.toUpperCase(),fcn);
	};
	public function addViewListener(typ:String,fcn:Function) {
		this.addEventListener(typ.toUpperCase(),fcn);
	};


	/**  Dispatch events. **/
	public function sendEvent(typ:String,prm:Object=undefined) {
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