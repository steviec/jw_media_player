/**
* Loads external SWF skin and calculates dimensions.
**/


package com.jeroenwijering.utils {


import com.jeroenwijering.utils.Draw;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.*;
import flash.net.URLRequest;
import flash.system.*;


public class Skinner extends EventDispatcher {


	/** Reference to the stage graphics. **/
	public var skin:MovieClip;
	/** SWF skin loader reference **/
	private var loader:Loader;
	/** Reference to the player itself. **/
	private var player:MovieClip;
	/** Reference to the config object. **/
	private var config:Object;


	/**
	* Constructor.
	*
	* @param skn	The player instance.
	**/
	public function Skinner(ply:MovieClip) {
		player = ply;
	};


	/**
	* Start the loading process.
	*
	* @param cfg	Object that contains all configuration parameters.
	**/
	public function load(cfg:Object=undefined) {
		config = cfg;
		if(config['skin']) {
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT,loaderHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
			if(player.loaderInfo.url.indexOf('http://') == 0) {
				var ctx = new LoaderContext(true,ApplicationDomain.currentDomain,SecurityDomain.currentDomain);
				loader.load(new URLRequest(config['skin']),ctx);
			} else { 
				loader.load(new URLRequest(config['skin']));
			}
		} else {
			skin = player['player'];
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** SWF loading failed; use default skin. **/
	private function errorHandler(evt:IOErrorEvent=undefined) {
			skin = player['player'];
		dispatchEvent(new Event(Event.COMPLETE));
	};


	/** SWF loading completed; add to stage and populate. **/
	private function loaderHandler(evt:Event) {
		if(loader.content['player']) {
			skin = MovieClip(loader.content['player']);
		} else {
			skin = MovieClip(loader.content);
		}
		Draw.clear(player);
		player.addChild(skin);
		dispatchEvent(new Event(Event.COMPLETE));
	};


}


}