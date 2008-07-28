/**
* Loads application configuration data (from xml, cookies and flashvars).
**/
package com.jeroenwijering.utils {


import com.jeroenwijering.utils.Strings;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.display.Sprite;
import flash.net.SharedObject;
import flash.net.URLRequest;
import flash.net.URLLoader;


public class Configger extends EventDispatcher {


	/** Reference to a display object to get flashvars from. **/
	private var reference:Sprite;
	/** Reference to the config object. **/
	public var config:Object;
	/** XML loading object reference **/
	private var loader:URLLoader;


	/** Constructor; nothing fancy. **/
	public function Configger(ref:Sprite) {
		reference = ref;
	};


	/** 
	* Start the loading process. 
	* 
	* @param def	The config object to overwrite new data in.
	**/
	public function load(def:Object) {
		config = def;
		var xml = reference.root.loaderInfo.parameters['config'];
		if(xml) {
			loadXML(Strings.decode(xml));
		} else {
			loadFlashvars();
		}
	};


	/** Load configuration data from external XML file. **/
	private function loadXML(url:String) {
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,xmlHandler);
		try {
			loader.load(new URLRequest(url));
		} catch (err:Error) { throw err; }
	};


	/** Parse the XML list **/
	private function xmlHandler(evt:Event) {
		var dat = XML(evt.currentTarget.data);
		var obj = new Object();
		for each (var prp in dat.children()) {
			obj[prp.name()] = prp.text();
		}
		compareWrite(obj)
		loadFlashvars();
	};


	/** Set config variables or load them from flashvars. **/
	private function loadFlashvars() {
		compareWrite(reference.root.loaderInfo.parameters);
		dispatchEvent(new Event(Event.COMPLETE));
	};


	/** Compare and save new items in config, preserving datatype. **/
	private function compareWrite(obj:Object) {
		for(var cfv in obj) {
			var lfv = cfv.toLowerCase();
			if(config[lfv] != undefined) {
				config[lfv] = Strings.serialize(obj[lfv],config[cfv]);
			} else { 
				config[lfv] = obj[lfv];
			}
		}
	};


}


}