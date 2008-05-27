/**
* Loads external SWF skin and calculates dimensions.
**/


package com.jeroenwijering.utils {


import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.*;
import flash.net.URLRequest;


public class Skinner extends EventDispatcher {


	/** Reference to the stage graphics **/
	public var skin:MovieClip;
	/** SWF skin loader reference **/
	private var loader:Loader;


	/**
	* Constructor.
	*
	* @param skn	The MovieClip that contains the display, playlist and controlbar.
	**/
	public function Skinner(skn:MovieClip) {
		skin = skn;
	};


	/**
	* Start the loading process.
	*
	* @param cfg	Object that contains all docking parameters.
	**/
	public function load(url:String=undefined) {
		if(url) {
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
			try {
				loader.load(new URLRequest(url));
			} catch (err:Error) { 
				dispatchEvent(new Event(Event.COMPLETE));
			}
		} else {
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** SWF loading failed; use default skin. **/
	private function errorHandler(evt:IOErrorEvent) {
		dispatchEvent(new Event(Event.COMPLETE));
	};


	/** SWF loading completed; add to stage and populate. **/
	private function loaderHandler(evt:Event) {
		var cnt = MovieClip(loader.content);
		while(cnt.numChildren > 0) {
			var ncd = cnt.getChildAt(0);
			var ocd = skin.getChildByName(ncd.name);
			skin.removeChild(ocd);
			skin.addChild(ncd);
		}
		dispatchEvent(new Event(Event.COMPLETE));
	};


}


}