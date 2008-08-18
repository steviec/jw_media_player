/**
* Interface that draws synchronized closed captions over the display.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.parsers.TTParser;
import com.jeroenwijering.utils.Draw;
import flash.display.MovieClip;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFormat;


public class Captions implements PluginInterface {


	/** Reference to the MVC view. **/
	private var view:AbstractView;
	/** URL of the captions file. **/
	private var location:String;
	/** XML connect and parse object. **/
	private var loader:URLLoader;
	/** The array the captions are loaded into. **/
	private var captions:Array;
	/** The array with data for styling of the captions **/
	private var styles:Array;
	/** Displayelement to load the captions into. **/
	private var clip:MovieClip;
	/** Currently active caption. **/
	private var current:Number;


	public function Captions():void {};


	/** Initing the plugin. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		if(!view.skin['captions']) { return; }
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.META,metaHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		clip = view.skin.captions;
		clip.field.autoSize = 'center';
		clip.visible = false;
	};


	/** Check for captions with a new item. **/
	private function itemHandler(evt:ControllerEvent):void {
		current = -1;
		setCaption('');
		captions = new Array();
		var cap = view.playlist[view.config['item']]['captions'];
		if(cap && cap != location) {
			view.addModelListener(ModelEvent.TIME,timeHandler);
			try {
				location = cap;
				loader.load(new URLRequest(cap));
			} catch (err:Error) {
				view.sendEvent('ERROR','Captions: '+err.message);
			}
		}
	};


	/** Captions are loaded; now display them. **/
	private function loaderHandler(evt:Event):void {
		try {
			var dat = XML(evt.target.data);
		} catch (err:Error) {
			view.sendEvent('ERROR','These captions are not a valid XML file.');
			return;
		}
		if(dat.localName().toLowerCase() == 'tt') {
			styles = TTParser.parseStyles(dat);
			captions = TTParser.parseCaptions(dat);
		} else {
			view.sendEvent('ERROR','Captions are not a valid TimedText file.');
		}
	};


	/** Resize the captions if the display changes. **/
	private function resizeHandler(evt:ControllerEvent=undefined):void {
		clip.back.height = clip.field.height+15;
		clip.width = view.config['width'];
		clip.scaleY = clip.scaleX;
		clip.y = Math.round(view.config['height'] - clip.height);
	};


	/** Catch and display captions that are sent through metadata. **/
	private function metaHandler(evt:ModelEvent):void {
		if (evt.data.text != undefined && evt.data.trackid != undefined) {
			setCaption(evt.data.text);
		} else if(evt.data.captions != undefined) { 
			setCaption(evt.data.captions);
		}
	};


	/** Set a caption on screen. **/
	private function setCaption(txt:String):void {
		clip.visible = true;
		clip.field.htmlText = txt;
		resizeHandler();
		if(txt != '') { view.sendEvent('TRACE','caption: '+txt); }
	};


	/** Check the playback state; hide captions if not playing. **/
	private function stateHandler(evt:ModelEvent):void {
		if(view.config['caption'] == true) {
			clip.visible = true;
		} else { 
			clip.visible = false;
		}
	};


	/** Check timing of the player to sync captions.  **/
	private function timeHandler(evt:ModelEvent):void {
		var cur = -1;
		var pos = evt.data.position;
		for(var i=0; i<captions.length; i++) {
			if(captions[i]['begin'] < pos && captions[i]['end'] > pos) {
				cur = i;
				break;
			}
		}
		if(cur == -1) {
			setCaption('');
		} else if(cur != current) {
			current = cur;
			setCaption(captions[cur]['text']);
		}
	};


};


}