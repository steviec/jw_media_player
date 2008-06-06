/**
* Placeholder class for a playlistbutton.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.*;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.URLRequest;
import flash.text.TextField;



public class PlaylistButton extends MovieClip {


	/** Playlist index of this button. **/
	private var index:Number;
	/** Reference to the view (to access config & playlist). **/
	private var view:View;
	/** Loader for loading the thumbnail. **/
	private var loader:Loader;
	/** Maximum width of the button. **/
	private var buttonsize:Number;


	/** Constructor; saves vars. **/
	public function PlaylistButton(idx:Number=undefined,wid:Number=undefined,vie:View=undefined) {
		super();
		index = idx;
		buttonsize = back.width;
		view = vie;
		if(view) {
			resize(wid);
			setElements(); 
		}
	};


	/** Setup button elements **/
	private function setElements() {
		this.y = this.height*index;
		if(title && view.playlist[index]['title']) {
			title.tf.text = Strings.fit(view.playlist[index]['title'],title.tf);
		}
		if(description && view.playlist[index]['description']) {
			var dsc = Strings.strip(view.playlist[index]['description']);
			description.tf.text = Strings.fit(dsc,description.tf);
		}
		if(view.playlist[index]['duration'] > 0) {
			duration.tf.text = Strings.digits(view.playlist[index]['duration']);
		} else { 
			duration.visible = false;
		}
		if(view.playlist[index]['image']) {
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
			loader.load(new URLRequest(view.playlist[index]['image']));
		}
		buttonMode = true;
		mouseChildren =false;
		addEventListener(MouseEvent.CLICK,clickHandler);
		resize(buttonsize);
	};


	/** Loading of image completed; resume loading **/
	private function loaderHandler(evt:Event) {
		var itm = addChild(loader);
		Stretcher.stretch(itm,image.width,image.height,Stretcher.FILL);
		itm.mask = image;
	}


	/** Handle a click on the button. **/
	private function clickHandler(evt:MouseEvent) {
		view.sendEvent('item',index);
	};


	/** Resize the button if the stage changes **/
	public function resize(wid:Number) { 
		var dif = wid - buttonsize;
		buttonsize = wid;
		back.width = buttonsize;
		duration.x = buttonsize - duration.width;
		title.tf.width += dif;
		description.tf.width += dif;
	};


};


}