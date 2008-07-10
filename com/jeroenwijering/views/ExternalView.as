/**
* Interface for javascript interaction and IDE tracing.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import flash.external.ExternalInterface;
import flash.system.Capabilities;
import flash.utils.setTimeout;


public class ExternalView {


	/** Reference to the MVC view. **/
	private var view:View;
	/** List with all subscribers. **/
	private var listeners:Array;


	public function ExternalView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.CAPTION,setController);
		view.addControllerListener(ControllerEvent.ERROR,setController);
		view.addControllerListener(ControllerEvent.ITEM,setController);
		view.addControllerListener(ControllerEvent.MUTE,setController);
		view.addControllerListener(ControllerEvent.PLAY,setController);
		view.addControllerListener(ControllerEvent.PLAYLIST,setController);
		view.addControllerListener(ControllerEvent.QUALITY,setController);
		view.addControllerListener(ControllerEvent.RESIZE,setController);
		view.addControllerListener(ControllerEvent.SEEK,setController);
		view.addControllerListener(ControllerEvent.STOP,setController);
		view.addControllerListener(ControllerEvent.VOLUME,setController);
		view.addModelListener(ModelEvent.BUFFER,setModel);
		view.addModelListener(ModelEvent.ERROR,setModel);
		view.addModelListener(ModelEvent.LOADED,setModel);
		view.addModelListener(ModelEvent.META,setModel);
		view.addModelListener(ModelEvent.STATE,setModel);
		view.addModelListener(ModelEvent.TIME,setModel);
		view.addViewListener(ViewEvent.CAPTION,setView);
		view.addViewListener(ViewEvent.ERROR,setView);
		view.addViewListener(ViewEvent.FULLSCREEN,setView);
		view.addViewListener(ViewEvent.ITEM,setView);
		view.addViewListener(ViewEvent.LINK,setView);
		view.addViewListener(ViewEvent.LOAD,setView);
		view.addViewListener(ViewEvent.MUTE,setView);
		view.addViewListener(ViewEvent.NEXT,setView);
		view.addViewListener(ViewEvent.PLAY,setView);
		view.addViewListener(ViewEvent.PREV,setView);
		view.addViewListener(ViewEvent.QUALITY,setView);
		view.addViewListener(ViewEvent.RESIZE,setView);
		view.addViewListener(ViewEvent.SEEK,setView);
		view.addViewListener(ViewEvent.STOP,setView);
		view.addViewListener(ViewEvent.VOLUME,setView);
		if(ExternalInterface.available && view.skin.loaderInfo.url.indexOf('http://') == 0) {
			listeners = new Array();
			try {
				ExternalInterface.addCallback("getConfig", getConfig);
				ExternalInterface.addCallback("getPlaylist", getPlaylist);
				ExternalInterface.addCallback("addControllerListener", addControllerListener);
				ExternalInterface.addCallback("addModelListener", addModelListener);
				ExternalInterface.addCallback("addViewListener", addViewListener);
				ExternalInterface.addCallback("sendEvent", view.sendEvent);
			} catch (err:Error) {}
			setTimeout(playerReady,50);
		}
	};


	/** Manage subscriptions of events. **/
	public function addControllerListener(typ:String,fcn:Object):Boolean {
		listeners.push({target:'CONTROLLER',type:typ.toUpperCase(),callee:String(fcn)});
		return true;
	};
	public function addModelListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'MODEL',type:typ.toUpperCase(),callee:String(fcn)});
		return true;
	};
	public function addViewListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'VIEW',type:typ.toUpperCase(),callee:String(fcn)});
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
		} else if(view.config['tracecall']) { 
			ExternalInterface.call(view.config['tracecall'],tgt+': '+typ+' '+prm);
		}
		if(!dat) { dat = new Object(); }
	 	dat.id = ExternalInterface.objectID;
		dat.client = view.config['client'];
		dat.version = view.config['version'];
		for each (var itm in listeners) {
			if(itm['target'] == tgt && itm['type'] == typ) {
				ExternalInterface.call(itm['callee'],dat);
			}
		}
	};


	/** Return the config and playlist objects to javascript. **/
	public function getConfig():Object { 
		return view.config; 
	};
	public function getPlaylist():Array {
		return view.playlist;
	};


	/** Send a call to javascript that the player is ready. **/
	private function playerReady() {
		var dat = {
			id:ExternalInterface.objectID,
			client:view.config['client'],
			version:view.config['version']
		};
		try {
			ExternalInterface.call("playerReady",dat);
		} catch (err:Error) {}
	};


	/** Forward events to tracer and subscribers. **/
	private function setController(evt:ControllerEvent) {
		forward('CONTROLLER',evt.type,evt.data);
	};
	private function setModel(evt:ModelEvent) {
		forward('MODEL',evt.type,evt.data);
	};
	private function setView(evt:ViewEvent) {
		forward('VIEW',evt.type,evt.data);
	};


};


}