/**
* Interface for the rightclick menu.
**/
package com.jeroenwijering.views {


import flash.events.ContextMenuEvent;
import flash.net.navigateToURL;
import flash.net.URLRequest;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import com.jeroenwijering.events.*;
import com.jeroenwijering.player.View;


public class RightclickView {


	/** Reference to the MVC view. **/
	private var view:View;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;
	/** Quality menuitem **/
	private var quality:ContextMenuItem;
	/** Fullscreen menuitem **/
	private var fullscreen:ContextMenuItem;
	/** About **/
	private var about:ContextMenuItem;


	/** Contructor; sets up rightclick menu. **/
	public function RightclickView(vie:View) {
		view = vie;
		view.addControllerListener(ControllerEvent.QUALITY,qualityHandler);
		context = new ContextMenu();
		context.hideBuiltInItems();
		view.skin.contextMenu = context;
		if(view.config['quality'] == false) {
			quality = new ContextMenuItem('Switch to high quality');
		} else { 
			quality = new ContextMenuItem('Switch to low quality');
		}
		addItem(quality,qualitySetter);
		try { 
			var dps = view.skin.stage['displayState'];
		} catch (err:Error) {}
		if(view.config['fullscreen'] == true && dps != null) {
			view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
			fullscreen = new ContextMenuItem('Switch to fullscreen');
			addItem(fullscreen,fullscreenHandler);
		}
		if(view.config['abouttext']) {
			about = new ContextMenuItem(view.config['abouttext']+'...');
		} else {
			about = new ContextMenuItem('About JW Player '+view.config['version']+'...');
		}
		addItem(about,aboutHandler);
	};


	/** jump to the about page. **/
	private function aboutHandler(evt:ContextMenuEvent) {
		navigateToURL(new URLRequest(view.config['aboutlink']),'_blank');
	};


	/** Add a custom menu item. **/
	private function addItem(itm:ContextMenuItem,hdl:Function) {
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,hdl);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Toggle the fullscreen mode. **/
	private function fullscreenHandler(evt:ContextMenuEvent) {
		view.sendEvent('fullscreen');
	};


	/** Toggle the smoothing mode. **/
	private function qualityHandler(evt:ControllerEvent) {
		if(evt.data.state == true) { 
			quality.caption = "Switch to low quality";
		} else {
			quality.caption = "Switch to high quality";
		}
	};


	/** Toggle the smoothing mode. **/
	private function qualitySetter(evt:ContextMenuEvent) {
		view.sendEvent('quality');
	};


	/** Set the fullscreen menubutton. **/
	private function resizeHandler(evt:ControllerEvent) {
		if(evt.data.fullscreen == false) { 
			fullscreen.caption = "Switch to fullscreen";
		} else {
			fullscreen.caption = "Return to normal screen";
		}
	};


};


}