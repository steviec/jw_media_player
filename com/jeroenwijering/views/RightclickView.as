/**
* Interface for the rightclick menu.
**/
package com.jeroenwijering.views {


import flash.events.ContextMenuEvent;
import flash.net.navigateToURL;
import flash.net.URLRequest;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import com.jeroenwijering.player.View;


public class RightclickView {


	/** Reference to the MVC view. **/
	private var view:View;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;


	/** Contructor; sets up rightclick menu. **/
	public function RightclickView(vie:View) {
		view = vie;
		context = new ContextMenu();
		context.hideBuiltInItems();
		view.skin.contextMenu = context;
		addItem('Toggle Playback Quality',qualityHandler);
		addItem('Toggle Captions Display',captionHandler);
		if(view.config['fullscreen'] == true && view.skin.stage['displayState']!=null) {
			addItem('Toggle Fullscreen Mode',fullscreenHandler);
		}
		if(view.config['abouttext']) {
			addItem(view.config['abouttext'],aboutHandler);
		} else {
			addItem('About '+view.config['player']+'...',aboutHandler);
		}
	};


	/** Add a custom menu item. **/
	private function addItem(txt:String,hdl:Function) {
		var itm = new ContextMenuItem(txt);
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,hdl);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Toggle the fullscreen mode. **/
	private function fullscreenHandler(evt:ContextMenuEvent) {
		view.sendEvent('fullscreen');
	};


	/** Toggle the smoothing mode. **/
	private function qualityHandler(evt:ContextMenuEvent) {
		view.sendEvent('quality');
	};


	/** Toggle the fullscreen mode. **/
	private function captionHandler(evt:ContextMenuEvent) {
		view.sendEvent('caption');
	};


	/** jump to the about page. **/
	private function aboutHandler(evt:ContextMenuEvent) {
		navigateToURL(new URLRequest(view.config['aboutlink']),'_blank');
	};


};


}