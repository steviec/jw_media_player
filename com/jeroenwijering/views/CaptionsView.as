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
		view.addControllerListener(ControllerEvent.CAPTION,captionHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.META,metaHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		captions = new Array();
		clip = new MovieClip();
		view.skin.addChild(clip);
	};


	/** Register changes to the on/off of captions. **/
	private function captionHandler(evt:ControllerEvent) {
		clip.visible = evt.data.state;
	};


	/** Draw a caption in specific formatting on stage. **/
	private function drawCaption(nbr:Number) {
		Draw.clear(clip);
		if(nbr > -1) {
			var stl = styles[captions[nbr]['style']];
			var tfd = new TextField();
			tfd.width = view.config['width'];
			tfd.wordWrap = true;
			tfd.autoSize = 'left';
			tfd.multiline = true;
			tfd.selectable = false;
			clip.addChild(tfd);
			tfd.defaultTextFormat = new TextFormat(stl['fontFamily'],stl['fontSize'],'0x'+stl['color'].substr(-6),
				stl['fontWeight'],stl['fontStyle'],null,null,null,stl['textAlign'], stl['padding'], stl['padding'],null,null);
			tfd.text = captions[nbr]['text'];
			if(stl['displayAlign'] == 'center') {
				tfd.y = view.config['height']/2 - tfd.height/2;
			} else if (stl['displayAlign'] == 'after') { 
				tfd.y = view.config['height'] - tfd.height - stl['padding'];
			} else { 
				tfd.y = stl['padding'];
			}
			if(stl['opacity'] > 0) {
				var rct = Draw.rect(clip,'0x'+stl['backgroundColor'].substr(-6),
					view.config['width'],tfd.height+2*stl['padding'],0,tfd.y-stl['padding'],stl['opacity']);
				clip.swapChildrenAt(0,1);
			} else {
				var flt = new GlowFilter(Number('0x'+stl['backgroundColor'].substr(-6)),100,2,2,10); 
				clip.filters = new Array(flt);
			}
		}
	};


	/** Catch security and io errors. **/
	private function errorHandler(evt:ErrorEvent) {
		view.sendEvent('ERROR',evt.text);
	};


	/** Check for captions with a new item. **/
	private function itemHandler(evt:ControllerEvent) {
		var cap = view.playlist[evt.data.index]['captions'];
		if(cap && cap != location) {
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
			view.sendEvent('ERROR','This playlist is not a valid TimedText file.');
		}
	};


	/** Resize the captions if the display changes. **/
	private function resizeHandler(evt:ControllerEvent) {
	};


	/** Catch and display captions that are sent through metadata. **/
	private function metaHandler(evt:ModelEvent) {
	};


	/** Check timing of the player to sync captions.  **/
	private function timeHandler(evt:ModelEvent) {
		var cur = -1;
		var pos = evt.data.position;
		if (captions.length == 0) { return; }
		for(var i=0; i<captions.length; i++) {
			if((captions[i]['begin'] < pos && captions[i]['end'] && captions[i]['end'] > pos) ||
				(captions[i]['begin'] < pos  && !captions[i]['end'] && captions[i+1] && captions[i+1]['begin'] > pos)) {
				cur = i;
				break;
			}
		}
		if(cur != current) {
			current = cur;
			drawCaption(cur);
		}
	};


	/** Check the playback state; hide captions if not playing. **/
	private function stateHandler(evt:ModelEvent) {
		if(evt.data.newState !== ModelStates.PLAYING || evt.data.newState == ModelStates.BUFFERING) { 
			clip.visible = true;
		} else { 
			clip.visible = false;
		}
	};


};


}