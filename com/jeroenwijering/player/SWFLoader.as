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
	/** Amount of plugins still to load. **/
	private var amount:Number;


	/**
	* Constructor.
	*
	* @param ply	The player instance.
	**/
	public function SWFLoader(ply:MovieClip) {
		player = ply;
		amount = 0;
	};


	/** 
	* Load a list of SWF plugins.
	*
	* @prm pgi		A commaseparated list with plugins. 
	**/
	public function loadPlugins(pgi:String=null) {
		if(pgi) { 
			var arr = pgi.split(',');
			amount = arr.length;
			for(var i in arr) { loadSWF(arr[i],false); }
		} else { 
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}; 


	/**
	* Start the loading process.
	*
	* @param cfg	Object that contains all configuration parameters.
	**/
	public function loadSkin(skn:String=null) {
		if(skn) {
			loadSWF(skn,true);
		} else {
			skin = player['player'];
			dispatchEvent(new Event(Event.INIT));
		}
	};


	/** Load a particular SWF file. **/
	public function loadSWF(str:String,skn:Boolean) {
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
		if(player.loaderInfo.url.indexOf('http://') == 0) {
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


	/** SWF loading failed; use default skin. **/
	private function pluginError(evt:IOErrorEvent) {
		amount--;
		if (amount == 0) {
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** Plugin loading completed; add to stage and populate. **/
	private function pluginHandler(evt:Event) {
		var clp = evt.target.content;
		player.addPlugin(clp);
		amount--;
		if (amount == 0) {
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** SWF loading failed; use default skin. **/
	private function skinError(evt:IOErrorEvent=null) {
		skin = player['player'];
		dispatchEvent(new Event(Event.INIT));
	};


	/** Skin loading completed; add to stage and populate. **/
	private function skinHandler(evt:Event) {
		var clp = evt.target.content;
		if(clp['player']) {
			skin = MovieClip(clp['player']);
			Draw.clear(player);
			player.addChild(skin);
			dispatchEvent(new Event(Event.INIT));
		} else {
			skinError();
		}
	};

}


}