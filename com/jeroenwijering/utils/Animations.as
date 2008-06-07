/**
* A couple of commonly used animation functions.
**/
package com.jeroenwijering.utils {


import flash.display.MovieClip;
import flash.events.Event;


public class Animations {


	/** Fade speed variable. **/
	private static var speed:Number = 0.2;
	/** Fade final value variable. **/
	private static var end:Number = 1;


	/**
	* Fade function for MovieClip.
	*
	* @param tgt	The Movieclip to fade out.
	* @param end	The final alpha value.
	* @param spd	The amount of alpha change per frame.
	**/
	public static function fade(tgt:MovieClip,end:Number,spd:Number=undefined) {
		if(arguments.length > 2) { 
			Animations.speed = spd; 
		}
		if(arguments.length > 1) { 
			Animations.end = end; 
		}
		if(tgt.alpha > Animations.end) {
			Animations.speed = -Math.abs(Animations.speed);
		} else {
			Animations.speed = Math.abs(Animations.speed);
		}
		tgt.visible = true;
		tgt.addEventListener(Event.ENTER_FRAME,fadeHandler);
	};


	/** The fade enterframe function. **/
	private static function fadeHandler(evt:Event) {
		var tgt = MovieClip(evt.target);
		if((tgt.alpha >= Animations.end && Animations.speed > 0) ||
			(tgt.alpha <= Animations.end && Animations.speed < 0)) {
			tgt.removeEventListener(Event.ENTER_FRAME,fadeHandler);
			tgt.alpha = Animations.end;
			if(Animations.end == 0) { 
				tgt.visible = false; 
			}
		} else {
			tgt.alpha += Animations.speed;
		}
	};


	/**
	* Smoothly move a Movielip to a certain position.
	*
	* @param tgt	The Movielip to move.
	* @param xps	The x destination.
	* @param yps	The y destination.
	* @param spd	The movement speed (1 - 2).
	**/
	public static function ease(tgt:MovieClip,xps:Number,yps:Number,spd:Number) {
		/*
		arguments.length < 4 ? spd = 2: null;
		tgt.onEnterFrame = function() {
			this._x = xps-(xps-this._x)/(1+1/spd);
			this._y = yps-(yps-this._y)/(1+1/spd);
			if (this._x>xps-1 && this._x<xps+1 && this._y>yps-1 && this._y<yps+1) {
				this._x = Math.round(xps);
				this._y = Math.round(yps);
				delete this.onEnterFrame;
			}
		};
		*/
	};


	/**
	* Typewrite text into a textfield.
	*
	* @param tgt	Movieclip that has a 'field' TextField.
	* @param txt	The textstring to write; uses current content if omitted.
	* @param spd	The speed of typing (1 - 2).
	**/
	public static function write(tgt:MovieClip,txt:String,spd:Number) {
		/*
		if (arguments.length < 2) {
			tgt.str = tgt.tf.text;
			tgt.hstr = tgt.tf.htmlText;
		} else {
			tgt.str = tgt.hstr = txt; 
		}
		if (arguments.length < 3) { spd = 1.5; }
		tgt.tf.text = "";
		tgt.i = 0;
		tgt.onEnterFrame = function() {
			var dif = Math.floor((this.str.length-this.tf.text.length)/spd);
			this.tf.text = this.str.substr(0,this.str.length-dif);
			if(this.tf.text == this.str) {
				this.tf.htmlText = this.hstr;
				delete this.onEnterFrame;
			}
			this.i++;
		};
		*/
	};


}


}