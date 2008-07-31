/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import flash.display.MovieClip;
import flash.events.*;
import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.*;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import flash.utils.setTimeout;


public class View extends AbstractView {


	/** Object with all configuration parameters **/
	private var _config:Object;
	/** Clip with all graphical elements **/
	private var _skin:MovieClip;
	/** Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Model of the MVC cycle. **/
	private var model:Model;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;
	/** Quality menuitem **/
	private var listeners:Array;


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ctr:Controller,mdl:Model) {
		_config = cfg;
		_config['client'] = 'FLASH '+Capabilities.version;
		_skin = skn;
		_skin.stage.scaleMode = "noScale";
		_skin.stage.align = "TL";
		_skin.stage.addEventListener(Event.RESIZE,resizeSetter);
		_config['controlbarsize'] = _skin['controlbar'].height;
		controller = ctr;
		model = mdl;
		menuSet();
		if(ExternalInterface.available && skin.loaderInfo.url.indexOf('http://') == 0) {
			listeners = new Array();
			setListening();
			try {
				if(ExternalInterface.objectID) { 
					_config['id'] = ExternalInterface.objectID;
				}
				ExternalInterface.addCallback("getConfig", getConfig);
				ExternalInterface.addCallback("getPlaylist", getPlaylist);
				ExternalInterface.addCallback("addControllerListener", addJSControllerListener);
				ExternalInterface.addCallback("addModelListener", addJSModelListener);
				ExternalInterface.addCallback("addViewListener", addJSViewListener);
				ExternalInterface.addCallback("sendEvent", sendEvent);
			} catch (err:Error) {}
			setTimeout(playerReady,50);
		} else if (Capabilities.playerType == 'External') {
			setListening();
		}
	};


	/**  Getters for the config parameters, skinning parameters and playlist. **/
	override public function get config():Object { return _config; };
	private function getConfig():Object { return _config; };
	override public function get playlist():Array { return controller.playlist; };
	private function getPlaylist():Array { return controller.playlist; };
	override public function get skin():MovieClip { return _skin; };


	/** jump to the about page. **/
	private function aboutSetter(evt:ContextMenuEvent) {
		navigateToURL(new URLRequest(config['aboutlink']),'_blank');
	};


	/**  Subscribers to the controller and model. **/
	override public function addControllerListener(typ:String,fcn:Function) {
		controller.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSControllerListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'CONTROLLER',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addModelListener(typ:String,fcn:Function) {
		model.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSModelListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'MODEL',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addViewListener(typ:String,fcn:Function) {
		this.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSViewListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'VIEW',type:typ.toUpperCase(),callee:fcn});
		return true;
	};


	/** Send event to listeners and tracers. **/
	private function forward(tgt:String,typ:String,dat:Object) {
		var prm = '';
		for (var i in dat) { prm += i+':'+dat[i]+','; }
		if(prm.length > 0) {
			prm = '('+prm.substr(0,prm.length-1)+')';
		}
		if(Capabilities.playerType == 'External') {
			trace(tgt+': '+typ+' '+prm);
		} else if(config['tracecall']) { 
			ExternalInterface.call(config['tracecall'],tgt+': '+typ+' '+prm);
		}
		if(!dat) { dat = new Object(); }
	 	dat.id = ExternalInterface.objectID;
		dat.client = config['client'];
		dat.version = config['version'];
		for each (var itm in listeners) {
			if(itm['target'] == tgt && itm['type'] == typ) {
				ExternalInterface.call(itm['callee'],dat);
			}
		}
	};


	/** Toggle the fullscreen mode. **/
	private function fullscreenSetter(evt:ContextMenuEvent) { sendEvent('fullscreen'); };


	/** Add a custom menu item. **/
	private function menuAdd(itm:ContextMenuItem,hdl:Function) {
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,hdl);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Set the rightclick menu. **/
	private function menuSet() {
		context = new ContextMenu();
		context.hideBuiltInItems();
		skin.contextMenu = context;
		addControllerListener(ControllerEvent.QUALITY,qualityHandler);
		var qua = new ContextMenuItem('Switch to low quality');
		if(config['quality'] == false) {
			qua = new ContextMenuItem('Switch to high quality');
		}
		menuAdd(qua,qualitySetter);
		try {
			if(skin.stage['displayState']) {
				addControllerListener(ControllerEvent.RESIZE,resizeHandler);
				var fsm = new ContextMenuItem('Switch to fullscreen');
				menuAdd(fsm,fullscreenSetter);
			}
		} catch (err:Error) {}
		var abt = new ContextMenuItem('About JW Player '+config['version']+'...');
		if(config['abouttext']) {
			abt = new ContextMenuItem(config['abouttext']+'...');
		}
		menuAdd(abt,aboutSetter);
	};


	/** Send a call to javascript that the player is ready. **/
	private function playerReady() {
		var dat = {
			id:config['id'],
			client:config['client'],
			version:config['version']
		};
		try {
			ExternalInterface.call("playerReady",dat);
		} catch (err:Error) {}
	};


	/** Toggle the smoothing mode. **/
	private function qualityHandler(evt:ControllerEvent) {
		if(evt.data.state == true) {
			context.customItems[0].caption = "Switch to low quality";
		} else {
			context.customItems[0].caption = "Switch to high quality";
		}
	};


	/** Toggle the smoothing mode. **/
	private function qualitySetter(evt:ContextMenuEvent) { sendEvent('quality'); };


	/** Set the fullscreen menubutton. **/
	private function resizeHandler(evt:ControllerEvent) {
		if(evt.data.fullscreen == false) { 
			context.customItems[1].caption = "Switch to fullscreen";
		} else {
			context.customItems[1].caption = "Return to normal screen";
		}
	};


	/** Forward a resizing of the stage. **/
	private function resizeSetter(evt:Event=undefined) {
		var dat = {
			height:_skin.stage.stageHeight,
			width:_skin.stage.stageWidth
		};
		dispatchEvent(new ViewEvent(ViewEvent.RESIZE,dat));
	};


	/**  Dispatch events. **/
	override public function sendEvent(typ:String,prm:Object=undefined) {
		typ = typ.toUpperCase();
		var dat = new Object();
		switch(typ) {
			case 'META':
				dat['message'] = prm;
				break;
			case 'LINK':
				if (prm != null) {
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
				if(prm!=null) {
					if(prm == true || prm == 'true') {
						dat['state'] = true;
					} else if(prm == false || prm == 'false') {
						dat['state'] = false;
					}
				}
				break;
		}
		dispatchEvent(new ViewEvent(typ,dat));
	};


	/** Forward events to tracer and subscribers. **/
	private function setController(evt:ControllerEvent) { forward('CONTROLLER',evt.type,evt.data); };
	private function setModel(evt:ModelEvent) { forward('MODEL',evt.type,evt.data); };
	private function setView(evt:ViewEvent) { forward('VIEW',evt.type,evt.data); };


	/** Setup listeners to all events for tracing / javascript. **/
	private function setListening() {
		addControllerListener(ControllerEvent.ERROR,setController);
		addControllerListener(ControllerEvent.ITEM,setController);
		addControllerListener(ControllerEvent.MUTE,setController);
		addControllerListener(ControllerEvent.PLAY,setController);
		addControllerListener(ControllerEvent.PLAYLIST,setController);
		addControllerListener(ControllerEvent.QUALITY,setController);
		addControllerListener(ControllerEvent.RESIZE,setController);
		addControllerListener(ControllerEvent.SEEK,setController);
		addControllerListener(ControllerEvent.STOP,setController);
		addControllerListener(ControllerEvent.VOLUME,setController);
		addModelListener(ModelEvent.BUFFER,setModel);
		addModelListener(ModelEvent.ERROR,setModel);
		addModelListener(ModelEvent.LOADED,setModel);
		addModelListener(ModelEvent.META,setModel);
		addModelListener(ModelEvent.STATE,setModel);
		addModelListener(ModelEvent.TIME,setModel);
		addViewListener(ViewEvent.FULLSCREEN,setView);
		addViewListener(ViewEvent.ITEM,setView);
		addViewListener(ViewEvent.LINK,setView);
		addViewListener(ViewEvent.LOAD,setView);
		addViewListener(ViewEvent.MUTE,setView);
		addViewListener(ViewEvent.META,setView);
		addViewListener(ViewEvent.NEXT,setView);
		addViewListener(ViewEvent.PLAY,setView);
		addViewListener(ViewEvent.PREV,setView);
		addViewListener(ViewEvent.QUALITY,setView);
		addViewListener(ViewEvent.RESIZE,setView);
		addViewListener(ViewEvent.SEEK,setView);
		addViewListener(ViewEvent.STOP,setView);
		addViewListener(ViewEvent.VOLUME,setView);
	};


}


}