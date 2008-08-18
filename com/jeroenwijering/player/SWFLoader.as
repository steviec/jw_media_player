/**
* Loads external SWF skins and plugins.
**/


package com.jeroenwijering.player {


import com.jeroenwijering.utils.Draw;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.*;
import flash.net.URLRequest;
import flash.system.*;


public class SWFLoader extends EventDispatcher {


	/** Reference to the player itself. **/
	private var player:MovieClip;
	/** Reference to the stage graphics. **/
	public var skin:MovieClip;
	/** SWF loader reference **/
	private var loader:Loader;
	/** Base directory for the plugins. **/
	private var basedir:String = 'http://plugins.longtailvideo.com/';


	/**
	* Constructor.
	*
	* @param ply	The player instance.
	**/
	public function SWFLoader(ply:MovieClip):void {
		player = ply;
	};


	/** 
	* Load a list of SWF plugins.
	*
	* @prm pgi	A commaseparated list with plugins.
	**/
	public function loadPlugins(pgi:String=null):void {
		if(pgi) {
			var arr = pgi.split(',');
			for(var i in arr) { loadSWF(arr[i],false); }
		}
	}; 


	/**
	* Start the loading process.
	*
	* @param cfg	Object that contains all configuration parameters.
	**/
	public function loadSkin(skn:String=null):void {
		if(skn) {
			loadSWF(skn,true);
		} else {
			skin = player['player'];
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** Load a particular SWF file. **/
	public function loadSWF(str:String,skn:Boolean):void {
		if(str.substr(-4) != '.swf') { str += '.swf'; }
		var ldr = new Loader();
		if(skn) {
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,skinError);
			ldr.contentLoaderInfo.addEventListener(Event.INIT,skinHandler);
		} else {
			skin.addChild(ldr);
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,pluginError);
			ldr.contentLoaderInfo.addEventListener(Event.INIT,pluginHandler);
		}
		if(player.loaderInfo.url.indexOf('http') == 0) {
			var ctx = new LoaderContext(true,ApplicationDomain.currentDomain,SecurityDomain.currentDomain);
			if(skn) { 
				ldr.load(new URLRequest(str),ctx);
			} else { 
				ldr.load(new URLRequest(basedir+str),ctx);
			}
		} else {
			ldr.load(new URLRequest(str));
		}
	};


	/** SWF loading failed. **/
	private function pluginError(evt:IOErrorEvent):void {
		player.view.sendEvent('trace',' plugin: '+evt.toString());
	};


	/** Plugin loading completed; add to stage and populate. **/
	private function pluginHandler(evt:Event):void {
		var plg = evt.target.content;
		try { 
			plg.initializePlugin(player.view);
		} catch(err:Error) { 
			player.view.sendEvent('trace',' plugin: '+err.message);
		}
	};


	/** SWF loading failed; use default skin. **/
	private function skinError(evt:IOErrorEvent=null):void {
		skin = player['player'];
		dispatchEvent(new Event(Event.COMPLETE));
	};


	/** Skin loading completed; add to stage and populate. **/
	private function skinHandler(evt:Event):void {
		var clp = evt.target.content;
		if(clp['player']) {
			skin = MovieClip(clp['player']);
			Draw.clear(player);
			player.addChild(skin);
			dispatchEvent(new Event(Event.COMPLETE));
		} else {
			skinError();
		}
	};

}


}