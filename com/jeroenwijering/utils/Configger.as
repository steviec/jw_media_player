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
import flash.system.Capabilities;


public class Configger extends EventDispatcher {


	/** Reference to a display object to get flashvars from. **/
	private var reference:Sprite;
	/** Reference to the config object. **/
	public var config:Object;
	/** XML loading object reference **/
	private var loader:URLLoader;
	/** Cookie object. **/
	private static var cookie:SharedObject;


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
		config['client'] = 'FLASH '+Capabilities.version;
		var xml = reference.root.loaderInfo.parameters['config'];
		if(xml) {
			loadXML(Strings.decode(xml));
		} else {
			loadCookies();
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
		loadCookies();
	};


	/** Load configuration data from flashcookie. **/
	private function loadCookies() {
		Configger.cookie = SharedObject.getLocal('com.jeroenwijering','/');
		compareWrite(Configger.cookie.data);
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


	/**
	* Save config parameter to cookie.
	*
	* @param prm	The parameter name.
	* @param val	The parameter value.
	**/
	public static function saveCookie(prm:String,val:Object) {
		Configger.cookie.data[prm] = val;
		Configger.cookie.flush();
	};


}


}