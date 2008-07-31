/**
* Event types fired by the View.
**/
package com.jeroenwijering.events {


import flash.events.Event;


public class ViewEvent extends Event {


	/** Identifiers for the accepted event types. **/
	public static var FULLSCREEN:String = "FULLSCREEN";
	public static var ITEM:String = "ITEM";
	public static var LINK:String = "LINK";
	public static var LOAD:String = "LOAD";
	public static var META:String = "META";
	public static var MUTE:String = "MUTE";
	public static var NEXT:String = "NEXT";
	public static var PLAY:String = "PLAY";
	public static var PREV:String = "PREV";
	public static var QUALITY:String = "QUALITY";
	public static var RESIZE:String = "RESIZE";
	public static var SEEK:String = "SEEK";
	public static var STOP:String = "STOP";
	public static var VOLUME:String = "VOLUME";
	/** The data associated with the event. **/
	private var _data:Object;


	/**
	* Constructor; sets the event type and inserts the new value.
	*
	* @param typ	The type of event.
	* @param dat	An object with all associated data.
	**/
	public function ViewEvent(typ:String,dat:Object=undefined,bbl:Boolean=false,ccb:Boolean=false) {
		super(typ, bbl, ccb);
		_data = dat;
	};


	/** Returns the associated data. **/
	public function get data():Object {
		return _data;
	};


}


}