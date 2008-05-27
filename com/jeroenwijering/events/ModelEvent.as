/**
* Event types fired by the Model.
**/
package com.jeroenwijering.events {


import flash.events.Event;


public class ModelEvent extends Event {


	/** Identifier for buffer change event. **/
	public static var BUFFER:String = "BUFFER";
	public static var ERROR:String = "ERROR";
	public static var LOADED:String = "LOADED";
	public static var META:String = "META";
	public static var STATE:String = "STATE";
	public static var TIME:String = "TIME";
	/** The data associated with the event. **/
	private var _data:Object;


	/**
	* Constructor; sets the event type and inserts the new value.
	*
	* @param typ	The type of event.
	* @param dat	An object with all associated data.
	**/
	public function ModelEvent(typ:String,dat:Object=undefined,bbl:Boolean=false,ccb:Boolean=false) {
		super(typ,bbl,ccb);
		_data = dat;
	};


	/** Returns the associated data. **/
	public function get data():Object {
		return _data;
	};


}


}