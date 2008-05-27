/**
* Display a searchbar and direct the search externally.
**/
package com.jeroenwijering.views {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;
import com.jeroenwijering.views.PlaylistButton;
import com.jeroenwijering.utils.Draw;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
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
	private var buttonsize:Number;
	/** Proportion between clip and mask. **/
	private var proportion:Number;
	/** Interval ID for scrolling **/
	private var scrollInterval:Number;


	public function PlaylistView(vie:View) {
		view = vie;
		clip = view.skin['playlist'];
		clip.visible = false;
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,playlistHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		var btn = clip.scrollClip.getChildByName('button');
		buttonsize = btn.height;
		clip.scrollClip.removeChild(btn);
		clip.scrollClip.mask = clip.scrollMask;
		clip.scrollBar.buttonMode = true;
		clip.scrollBar.mouseChildren = false;
		clip.scrollBar.addEventListener(MouseEvent.MOUSE_DOWN,startHandler);
		view.skin.addEventListener(MouseEvent.MOUSE_UP,stopHandler);
	};


	/** Setup all buttons in the playlist **/
	private function buildList(clr:Boolean) {
		var wid = clip.back.width;
		var hei = clip.back.height;
		proportion = view.playlist.length*buttonsize/hei;
		if (proportion > 1) {
			wid -=20;
			buildScroller();
		} else {
			clip.scrollBar.visible = false;
		}
		clip.scrollMask.height = hei;
		clip.scrollMask.width = wid;
		if(clr) {
			clip.scrollClip.y = 0;
			Draw.clear(clip.scrollClip);
			buttons = new Array();
		}
		for(var i=0; i<view.playlist.length; i++) {
			if(clr) { 
				var btn = new PlaylistButton(i,wid,view);
				clip.scrollClip.addChild(btn);
				buttons.push(btn);
			} else { 
				buttons[i].resize(wid);
				if(proportion > 1) { 
					scrollCheck();
				}
			}
		}
	};


	/** Setup the scrollbar component **/
	private function buildScroller() {
		var scr = clip.scrollBar;
		scr.visible = true;
		scr.x = clip.back.width - scr.width;
		var dif = clip.back.height - scr.height;
		scr.back.height += dif;
		scr.rail.height += dif;
		scr.icon.height = Math.round(scr.rail.height/proportion);
	};


	/** Switch the currently active item */
	private function itemHandler(evt:ControllerEvent) {
		// code for highlighting a certain button.
	};


	/** New playlist loaded: rebuild the playclip. **/
	private function playlistHandler(evt:ControllerEvent) {
		buildList(true);
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent) {
		if(view.config['playlist'] == 'right') {
			clip.visible = true;
			clip.x = evt.data.width;
			clip.y = 0;
			clip.back.width = view.config['playlistsize'];
			clip.back.height = evt.data.height;
		} else if (view.config['playlist'] == 'below') {
			clip.visible = true;
			clip.x = 0;
			clip.y = evt.data.height;
			if (view.config['controlbar'] == 'below') {
				clip.y += view.config['controlbarsize'];
			}
			clip.back.height = view.config['playlistsize'];
			clip.back.width = evt.data.width;
		} else if (view.config['playlist'] == 'above') {
			clip.visible = true;
			var wid = evt.data.width-2*view.config['controlbarsize'];
			var hei = evt.data.height-2*view.config['controlbarsize'];
			if(evt.data.width > 640) { wid = 600; }
			if(view.config['controlbar'] == 'above') { hei -= 2*view.config['controlbarsize']; }
			clip.x = Math.round(evt.data.width/2 - wid/2);
			clip.y = view.config['controlbarsize'];
			clip.back.height = hei;
			clip.back.width = wid;
		} else { 
			clip.visible = false;
		}
		buildList(false);
	};


	/** Make sure the playlist is not out of range. **/
	private function scrollCheck() {
		var scr = clip.scrollBar;
		if(clip.scrollClip.y > 0) {
			clip.scrollClip.y = 0;
			scr.icon.y = scr.rail.y;
		} else if (clip.scrollClip.y < clip.scrollMask.height-clip.scrollClip.height) {
			scr.icon.y = scr.rail.y+scr.rail.height-scr.icon.height;
			clip.scrollClip.y = clip.scrollMask.height-clip.scrollClip.height;
		}
	};


	/** Scrolling handler. **/
	private function scrollHandler() {
		var scr = clip.scrollBar;
		var yps = scr.mouseY;
		var ips = yps - scr.icon.height/2;
		var cps = clip.scrollMask.y+clip.scrollMask.height/2-proportion*yps;
		scr.icon.y = Math.round(ips - (ips-scr.icon.y)/1.5);
		clip.scrollClip.y = Math.round((cps - (cps-clip.scrollClip.y)/1.5));
		scrollCheck();
	};


	/** Start scrolling the playlist. **/
	private function startHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
		scrollHandler();
		scrollInterval = setInterval(scrollHandler,50);
	};


	/** Stop scrolling the playlist. **/
	private function stopHandler(evt:MouseEvent) {
		clearInterval(scrollInterval);
	};




};


}