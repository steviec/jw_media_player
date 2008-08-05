/**
* Display a searchbar and direct the search externally.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.setInterval;
import flash.utils.clearInterval;


public class Playlist implements PluginInterface {


	/** Reference to the view. **/
	private var view:AbstractView;
	/** Reference to the playlist MC. **/
	private var clip:MovieClip;
	/** Array with all button instances **/
	private var buttons:Array;
	/** Height of a button (to calculate scrolling) **/
	private var buttonheight:Number;
	/** Currently active button. **/
	private var active:Number;
	/** Proportion between clip and mask. **/
	private var proportion:Number;
	/** Interval ID for scrolling **/
	private var scrollInterval:Number;
	/** Image dimensions. **/
	private var image:Array;
	/** Color object for backcolor. **/
	private var back:ColorTransform;
	/** Color object for frontcolor. **/
	private var front:ColorTransform;
	/** Color object for lightcolor. **/
	private var light:ColorTransform;


	public function Playlist() {};


	/** Initialize the communication with the player. **/
	public function initialize(vie:AbstractView) {
		view = vie;
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,playlistHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		clip = view.skin['playlist'];
		buttonheight = clip.list.button.height;
		clip.list.button.visible = false;
		clip.list.mask = clip.masker;
		clip.list.addEventListener(MouseEvent.CLICK,clickHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		clip.slider.buttonMode = true;
		clip.slider.mouseChildren = false;
		clip.slider.addEventListener(MouseEvent.MOUSE_DOWN,sdownHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_OVER,soverHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_OUT,soutHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_WHEEL,wheelHandler);
		clip.visible = false;
		buttons = new Array();
		try { 
			image = new Array(clip.list.button.image.width,clip.list.button.image.height);
		} catch (err:Error) {}
		setColors();
	};


	/** Setup all buttons in the playlist **/
	private function buildList(clr:Boolean) {
		if(!view.playlist) { return; }
		var wid = clip.back.width;
		var hei = clip.back.height;
		proportion = view.playlist.length*buttonheight/hei;
		if (proportion > 1.01) {
			wid -=clip.slider.width;
			buildSlider();
		} else {
			clip.slider.visible = false;
		}
		clip.masker.height = hei;
		clip.masker.width = wid;
		if(clr) {
			clip.list.y = 0;
			for(var j=0; j<buttons.length; j++) {
				clip.list.removeChild(buttons[j].c);
			}
			buttons = new Array();
			clip.visible= true;
		} else { 
			if(proportion > 1) { scrollCheck(); }
		}
		for(var i=0; i<view.playlist.length; i++) {
			if(clr) {
				var btn = Draw.clone(clip.list.button,true);
				var stc = new Stacker(btn);
				btn.y = i*buttonheight;
				btn.buttonMode = true;
				btn.mouseChildren =false;
				btn.name = i;
				buttons.push({c:btn,s:stc});
				setContents(i);
			}
			buttons[i].s.rearrange(wid);
		}
	};


	/** Setup the scrollbar component **/
	private function buildSlider() {
		var scr = clip.slider;
		scr.visible = true;
		scr.x = clip.back.width-scr.width;
		var dif = clip.back.height-scr.height;
		scr.back.height += dif;
		scr.rail.height += dif;
		scr.icon.height = Math.round(scr.rail.height/proportion);
	};


	/** Handle a click on a button. **/
	private function clickHandler(evt:MouseEvent) {
		view.sendEvent('item',Number(evt.target.name));
	};


	/** Switch the currently active item */
	private function itemHandler(evt:ControllerEvent) {
		var idx = view.config['item'];
		if(buttons[idx]) {
			if(buttons[idx].c['back']) {
				buttons[idx].c['back'].visible = true;
				if(!isNaN(active)) {
					buttons[active].c['back'].visible = false;
				}
			} else {
				buttons[idx].c.gotoAndPlay('active');
				if(!isNaN(active)) {
					buttons[active].c.gotoAndPlay('out');
				}
			}
		}
		active = idx;
	};


	/** Loading of image completed; resume loading **/
	private function loaderHandler(evt:Event) {
		var ldr = Loader(evt.target.loader);
		Stretcher.stretch(ldr,image[0],image[1],Stretcher.EXACTFIT);
	};


	/** Handle a button rollover. **/
	private function overHandler(evt:MouseEvent) {
		var idx = Number(evt.target.name);
		if(light) { 
			for (var itm in view.playlist[idx]) {
				if(buttons[idx].c[itm]) { 
					buttons[idx].c[itm].textColor = light.color;
				}
			}
		} else { 
			buttons[idx].c.gotoAndPlay('over');
		}
	};


	/** Handle a button rollover. **/
	private function outHandler(evt:MouseEvent) {
		var idx = Number(evt.target.name);
		if(front) {
			for (var itm in view.playlist[idx]) {
				if(buttons[idx].c[itm]) { 
					buttons[idx].c[itm].textColor = front.color;
				}
			}
		} else if(idx == active) {
			buttons[idx].c.gotoAndPlay('active');
		} else { 
			buttons[idx].c.gotoAndPlay('out');
		}
	};


	/** New playlist loaded: rebuild the playclip. **/
	private function playlistHandler(evt:ControllerEvent) {
		active = undefined;
		if(view.config['playlist'] != 'none') {
			buildList(true);
		}
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		if(view.config['playlist'] == 'right') {
			clip.x = evt.data.width;
			clip.y = 0;
			clip.back.width = view.config['playlistsize'];
			clip.back.height = evt.data.height;
			buildList(false);
		} else if (view.config['playlist'] == 'bottom') {
			clip.x = 0;
			clip.y = evt.data.height;
			if (view.config['controlbar'] == 'bottom') {
				clip.y += view.config['controlbarsize'];
			}
			clip.back.height = view.config['playlistsize'];
			clip.back.width = evt.data.width;
			buildList(false);
		} else if (view.config['playlist'] == 'over') {
			clip.x = clip.y = 0;
			clip.back.width = evt.data.width;
			clip.back.height = evt.data.height;
			buildList(false);
		} else {
			clip.visible = false;
		}
	};


	/** Make sure the playlist is not out of range. **/
	private function scrollCheck() {
		var scr = clip.slider;
		if(clip.list.y > 0 || scr.icon.y < scr.rail.y) {
			clip.list.y = 0;
			scr.icon.y = scr.rail.y;
		} else if (clip.list.y < clip.masker.height-clip.list.height ||
			scr.icon.y > scr.rail.y+scr.rail.height-scr.icon.height) {
			scr.icon.y = scr.rail.y+scr.rail.height-scr.icon.height;
			clip.list.y = clip.masker.height-clip.list.height;
		}
	};


	/** Scrolling handler. **/
	private function scrollHandler() {
		var scr = clip.slider;
		var yps = scr.mouseY;
		var ips = yps - scr.icon.height/2;
		var cps = clip.masker.y+clip.masker.height/2-proportion*yps;
		scr.icon.y = Math.round(ips-(ips-scr.icon.y)/1.5);
		clip.list.y = Math.round((cps - (cps-clip.list.y)/1.5));
		scrollCheck();
	};


	/** Init the colors. **/
	private function setColors() {
		if(view.config['backcolor']) { 
			back = new ColorTransform();
			back.color = uint('0x'+view.config['backcolor'].substr(-6));
			clip.back.transform.colorTransform = back;
		}
		if(view.config['frontcolor']) {
			front = new ColorTransform();
			front.color = uint('0x'+view.config['frontcolor'].substr(-6));
			try { 
				clip.slider.icon.transform.colorTransform = front;
				clip.slider.rail.transform.colorTransform = front;
			} catch (err:Error) {}
		}
		if(view.config['lightcolor']) {
			light = new ColorTransform();
			light.color = uint('0x'+view.config['lightcolor'].substr(-6));
		}
	};


	/** Setup button elements **/
	private function setContents(idx:Number) {
		for (var itm in view.playlist[idx]) {
			if(!buttons[idx].c[itm]) {
				continue;
			} else if(itm == 'image') {
				var img = buttons[idx].c.image;
				var msk = Draw.rect(buttons[idx].c,'0xFF0000',img.width,img.height,img.x,img.y);
				var ldr = new Loader();
				img.mask = msk;
				img.addChild(ldr);
				ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
				ldr.load(new URLRequest(view.playlist[idx]['image']));
			} else if(itm == 'duration') {
				if(view.playlist[idx][itm] > 0) {
					buttons[idx].c[itm].text = Strings.digits(view.playlist[idx][itm]);
					if(front) { 
						buttons[idx].c[itm].textColor = front.color;
					}
				}
			} else {
				buttons[idx].c[itm].htmlText = view.playlist[idx][itm];
				if(front) { 
					buttons[idx].c[itm].textColor = front.color;
				}
			}
		}
		if(buttons[idx].c['back']) {
			if(light) {
				buttons[idx].c['back'].transform.colorTransform = light;
			}
			buttons[idx].c['back'].visible = false;
		}
		if(!view.playlist[idx]['image'] && buttons[idx].c['image']) {
			buttons[idx].c['image'].visible = false;
		}
	};


	/** Start scrolling the playlist on mousedown. **/
	private function sdownHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
    	clip.stage.addEventListener(MouseEvent.MOUSE_UP,supHandler);
		scrollHandler();
		scrollInterval = setInterval(scrollHandler,50);
	};


	/** Revert the highlight on mouseout. **/
	private function soutHandler(evt:MouseEvent) {
		if(front) {
			clip.slider.icon.transform.colorTransform = front;
		} else { 
			clip.slider.icon.gotoAndPlay('out');
		}
	};


	/** Highlight the icon on rollover. **/
	private function soverHandler(evt:MouseEvent) {
		if(light) {
			clip.slider.icon.transform.colorTransform = light;
		} else { 
			clip.slider.icon.gotoAndPlay('over');
		}
	};


	/** Stop scrolling the playlist on mouseout. **/
	private function supHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
    	clip.stage.removeEventListener(MouseEvent.MOUSE_UP,supHandler);
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent) {
		if(view.config['playlist'] == 'over') {
			if(evt.data.newstate == ModelStates.PLAYING || 
				evt.data.newstate == ModelStates.BUFFERING) {
				Animations.fade(clip,0);
			} else {
				Animations.fade(clip,1);
			}
		}
	};


	/** Process mousewheel usage. **/
	private function wheelHandler(evt:MouseEvent) {};


};


}