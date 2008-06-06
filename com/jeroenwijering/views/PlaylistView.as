﻿/**
* Display a searchbar and direct the search externally.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import com.jeroenwijering.utils.*;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.setInterval;
import flash.utils.clearInterval;


public class PlaylistView {


	/** Reference to the view. **/
	private var view:View;
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


	public function PlaylistView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,playlistHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		clip = view.skin['playlist'];
		buttonheight = clip.list.button.height;
		clip.list.button.visible = false;
		clip.list.mask = clip.masker;
		clip.slider.buttonMode = true;
		clip.slider.mouseChildren = false;
		clip.list.addEventListener(MouseEvent.CLICK,clickHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_UP,stopHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_DOWN,startHandler);
		clip.visible = false;
		trace(clip);
	};


	/** Setup all buttons in the playlist **/
	private function buildList(clr:Boolean) {
		var wid = clip.back.width;
		var hei = clip.back.height;
		proportion = view.playlist.length*buttonheight/hei;
		if (proportion > 1) {
			wid -=20;
			buildSlider();
		} else {
			clip.slider.visible = false;
		}
		clip.masker.height = hei;
		clip.masker.width = wid;
		if(clr) {
			clip.list.y = 0;
			Draw.clear(clip.list);
			buttons = new Array();
			clip.visible= true;
		} else { 
			if(proportion > 1) { scrollCheck(); }
		}
		for(var i=0; i<view.playlist.length; i++) {
			if(clr) {
				var btn = Draw.clone(clip.list.button);
				clip.list.addChild(btn);
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
		var idx = evt.data.index;
		if(!isNaN(active)) {
			buttons[active].c.gotoAndStop('out');
		}
		buttons[idx].c.gotoAndStop('active');
		active = idx;
	};


	/** Loading of image completed; resume loading **/
	private function loaderHandler(evt:Event) {
		var ldr = Loader(evt.target.loader);
		Stretcher.stretch(ldr,ldr.mask.width,ldr.mask.height,Stretcher.FILL);
	};


	/** Handle a button rollover. **/
	private function overHandler(evt:MouseEvent) {
		var idx = Number(evt.target.name);
		buttons[idx].c.gotoAndStop('over');
	};


	/** Handle a button rollover. **/
	private function outHandler(evt:MouseEvent) {
		var idx = Number(evt.target.name);
		if(idx == active) {
			buttons[idx].c.gotoAndStop('active');
		} else { 
			buttons[idx].c.gotoAndStop('out');
		}
	};


	/** New playlist loaded: rebuild the playclip. **/
	private function playlistHandler(evt:ControllerEvent) {
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
		} else if (view.config['playlist'] == 'bottom') {
			clip.x = 0;
			clip.y = evt.data.height;
			if (view.config['controlbar'] == 'bottom') {
				clip.y += view.config['controlbarsize'];
			}
			clip.back.height = view.config['playlistsize'];
			clip.back.width = evt.data.width;
		} else if (view.config['playlist'] == 'over') {
			clip.x = clip.y = 0;
			clip.back.height = evt.data.height;
			clip.back.width = evt.data.width;
		}
		buildList(false);
	};


	/** Make sure the playlist is not out of range. **/
	private function scrollCheck() {
		var scr = clip.slider;
		if(clip.list.y > 0) {
			clip.list.y = 0;
			scr.icon.y = scr.rail.y;
		} else if (clip.list.y < clip.masker.height-clip.list.height) {
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
		scr.icon.y = Math.round(ips - (ips-scr.icon.y)/1.5);
		clip.list.y = Math.round((cps - (cps-clip.list.y)/1.5));
		scrollCheck();
	};


	/** Setup button elements **/
	private function setContents(idx:Number) {
		for (var itm in view.playlist[idx]) {
			if(!buttons[idx].c[itm]) {
				continue;
			} else if(itm == 'image') {
				var ldr = new Loader();
				buttons[idx].c.addChild(ldr);
				ldr.x = buttons[idx].c.image.x;
				ldr.y = buttons[idx].c.image.y;
				ldr.mask = buttons[idx].c.image;
				ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
				ldr.load(new URLRequest(view.playlist[idx]['image']));
			} else if(itm == 'duration') {
				if(view.playlist[idx][itm] > 0) {
					buttons[idx].c[itm].field.text = Strings.digits(view.playlist[idx][itm]);
				}
			} else {
				buttons[idx].c[itm].field.text = view.playlist[idx][itm];
			}
		}
		if(!view.playlist[idx]['image'] && buttons[idx].c['image']) {
			buttons[idx].c['image'].visible = false;
		}
	};


	/** Start scrolling the playlist. **/
	private function startHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
		scrollHandler();
		scrollInterval = setInterval(scrollHandler,50);
	};

	/** Process state changes **/
	private function stateHandler(evt:ModelEvent) {
		if(view.config['playlist'] == 'over') {
			if(evt.data.newstate == ModelStates.PLAYING || evt.data.newstate == ModelStates.BUFFERING) {
				clip.visible = false;
			} else {
				clip.visible = true;
			}
		}
	};


	/** Stop scrolling the playlist. **/
	private function stopHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
	};


};


}