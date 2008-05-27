/**
* Static typed list of all possible model states, fired with the 'state' event.
**/
package com.jeroenwijering.events {


public class ModelStates {


	/** Nothing has happened yet. **/
	public static var IDLE:String = "IDLE";
	/** Buffering; will start to play when the buffer is full. **/
	public static var BUFFERING:String = "BUFFERING";
	/** Playing back the mediafile. **/
	public static var PLAYING:String = "PLAYING";
	/** Playback is paused. **/
	public static var PAUSED:String = "PAUSED";
	/** End of mediafile has been reached. **/
	public static var COMPLETED:String = "COMPLETED";


}


}