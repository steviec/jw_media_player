/**
* Interface that draws synchronized closed captions over the display.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.parsers.TTParser;
import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.Draw;
import flash.display.MovieClip;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFormat;


public class CaptionsView {


	/** Reference to the MVC view. **/
	private var view:View;
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


	public function CaptionsView(vie:View) {
		view = vie;
		if(!view.skin['captions']) { return; }
		view.addControllerListener(ControllerEvent.ERROR,errorHandler);
		view.addControllerListener(ControllerEvent.CAPTION,captionHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.ERROR,errorHandler);
		view.addModelListener(ModelEvent.META,metaHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addViewListener(ViewEvent.ERROR,errorHandler);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		clip = view.skin.captions;
		clip.field.autoSize = 'center';
		if(view.config['caption'] == false) {
			clip.visible = false;
		}
	};


	/** Register changes to the on/off of captions. **/
	private function captionHandler(evt:ControllerEvent) {
		clip.visible = evt.data.state;
	};


	/** Catch security and io errors. **/
	private function errorHandler(evt:Object) {
		setCaption(evt.data.message);
	};


	/** Check for captions with a new item. **/
	private function itemHandler(evt:ControllerEvent) {
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
	private function loaderHandler(evt:Event) {
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
	private function resizeHandler(evt:ControllerEvent=undefined) {
		clip.back.height = clip.field.height+15;
		clip.width = view.config['width'];
		clip.scaleY = clip.scaleX;
		clip.y = Math.round(view.config['height'] - clip.height);
	};


	/** Catch and display captions that are sent through metadata. **/
	private function metaHandler(evt:ModelEvent) {
		if (evt.data.text != undefined && evt.data.trackid != undefined) {
			setCaption(evt.data.text);
		} else if(evt.data.captions != undefined) { 
			setCaption(evt.data.captions);
		}
	};


	/** Set a caption on screen. **/
	private function setCaption(txt:String) {
		clip.field.htmlText = txt;
		resizeHandler();
	};


	/** Check the playback state; hide captions if not playing. **/
	private function stateHandler(evt:ModelEvent) {
		if(view.config['caption'] == true) {
			clip.visible = true;
		} else { 
			clip.visible = false;
		}
	};


	/** Check timing of the player to sync captions.  **/
	private function timeHandler(evt:ModelEvent) {
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