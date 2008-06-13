/**
* Abstract superclass for the View. Defines methods accessible to plugins.
**/
package com.jeroenwijering.events {


import flash.events.EventDispatcher;
import flash.display.MovieClip;


public class AbstractView extends EventDispatcher {


	/** Constructor. **/
	public function AbstractView() { };


	/**  Getters for the config, playlist and skin. **/
	public function get config():Object { return new Object(); };
	public function get playlist():Array { return new Array(); };
	public function get skin():MovieClip { return new MovieClip(); };


	/**  Subscribers to the controller and model. **/
	public function addControllerListener(typ:String,fcn:Function) {};
	public function addModelListener(typ:String,fcn:Function) {};
	public function addViewListener(typ:String,fcn:Function) {};


	/**  Dispatch events. **/
	public function sendEvent(typ:String,prm:Object=undefined) { };


}


}