/**
* Interface for controlling the player through keyboard.
**/
package com.jeroenwijering.views {


import flash.events.KeyboardEvent;
import com.jeroenwijering.events.ControllerEvent;
import com.jeroenwijering.player.View;


public class KeyboardView {


	/** Reference to the MVC view. **/
	private var view:View


	/** Constructor; register to keyboard events. **/
	public function KeyboardView(vie:View) {
		view = vie;
		view.skin.addEventListener(KeyboardEvent.KEY_DOWN,keyHandler);
	};


	/** Process keyboard events. **/
	private function keyHandler(evt:KeyboardEvent) {
		switch(evt.keyCode) {
			case 37:
				view.sendEvent('prev');
				break;
			case 38:
				view.sendEvent('volume',view.config['volume']+10);
				break;
			case 39:
				view.sendEvent('next');
				break;
			case 40:
				view.sendEvent('volume',view.config['volume']-10);
				break;
			case 80:
				view.sendEvent('play');
				break;
			case 67:
				view.sendEvent('caption');
				break;
			case 70:
				view.sendEvent('fullscreen');
				break;
			case 76:
				view.sendEvent('link');
				break;
			case 77:
				view.sendEvent('mute');
				break;
		}
	};


};


}