/**
* Show a YouTube searchbar that loads the results into the player.
**/
package com.longtailvideo.yousearch {


import com.jeroenwijering.events.*;
import flash.display.MovieClip;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;


public class YouSearch extends MovieClip implements PluginInterface {


	/** Reference to the View of the player. **/
	private var view:AbstractView;
	/** Reference to the graphics. **/
	private var clip:MovieClip;
	/** Prefix for the search request. **/
	private var prefix = "http://gdata.youtube.com/feeds/api/videos?vq=";
	/** initialize call for backward compatibility. **/
	public var initialize:Function = initializePlugin;


	/** Constructor; nothing going on. **/
	public function YouSearch() {
		clip = this;
		clip.search.addEventListener(MouseEvent.CLICK,clickHandler);
		clip.query.addEventListener(FocusEvent.FOCUS_IN,focusHandler);
		clip.query.addEventListener(KeyboardEvent.KEY_DOWN,keyHandler);
		clip.search.buttonMode = true;
		clip.search.mouseChildren = false;
	};


	/** The initialize call is invoked by the player View. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		resizeHandler();
	};


	/** Start the search. **/
	private function clickHandler(evt:MouseEvent=null) {
		var que = encodeURI(clip.query.text);
		if(que.length > 3) { 
			view.sendEvent('LOAD',prefix+que);
		}
		clip.query.text = '';
	};


	/** Clear the field on focus. **/
	private function focusHandler(evt:FocusEvent) {
		if(clip.query.text == '...') { 
			clip.query.text = '';
		}
	};


	/** Start the search on enter. **/
	private function keyHandler(evt:KeyboardEvent) {
		if(evt.charCode == 13) { 
			clickHandler();
		}
	};


	/** Handle a resize. **/
	private function resizeHandler(evt:ControllerEvent=undefined) {
		clip.x = view.config['width']/2-140;
		clip.y = view.config['height']/2-20;
	};


	/** Close on video completed. **/
	private function stateHandler(evt:ModelEvent) { 
		switch(evt.data.newstate) {
			case ModelStates.BUFFERING:
			case ModelStates.PLAYING:
				clip.visible = false;
				break;
			default:
				clip.stage.focus = clip.query;
				clip.visible = true;
				break;
		}
	};


}


}