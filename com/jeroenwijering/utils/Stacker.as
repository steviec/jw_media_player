/**
* Parses children of a MovieClip and docks them to the left & right.
**/


package com.jeroenwijering.utils {


import flash.display.MovieClip;


public class Stacker {


	/** Reference to the clip to stack. **/
	public var clip:MovieClip;
	/** SWF skin loader reference **/
	private var stack:Array;
	/** Original width of the clip. **/
	private var _width:Number;
	/** Latest width of the clip. **/
	private var latest:Number;


	/**
	* Constructor.
	*
	* @param skn	The MovieClip to manage stacking of.
	**/
	public function Stacker(clp:MovieClip) {
		clip = clp;
		analyze();
	};


	/** Analyze the MovieClip and save its children.  **/
	private function analyze() {
		_width = clip.width;
		stack = new Array();
		for(var i=0; i<clip.numChildren; i++) {
			var clp = clip.getChildAt(i);
			stack.push({c:clp,x:clp.x,n:clp.name,w:clp.width});
		}
		stack.sortOn(['x','n'],[Array.NUMERIC,Array.CASEINSENSITIVE]);
	};


	/** Check if an child overlaps with others. **/
	private function overlaps(idx:Number):Boolean {
		var min = stack[idx].x;
		var max = stack[idx].x+stack[idx].w;
		for (var i in stack) {
			if(i!=idx && stack[i].c.visible==true && stack[i].w < _width &&
				stack[i].x < max && stack[i].x+stack[i].w > min) {
				//trace(stack[idx].n+'overlaps with'+stack[i].n);
				//trace(stack[i].x+'-'+max+' / '+(stack[i].x+stack[i].w)+'-'+min);
				return true;
			}
		}
		return false;
	};


	/** 
	* Rearrange the contents of the clip. 
	*
	* @param wid	The target width of the clip.
	**/
	public function rearrange(wid:Number=undefined) { 
		if(wid) { latest = wid; }
		var rdf = latest-width;
		var ldf = 0;
		// first run through the entire stack, closing the gaps.
		for(var i=0; i<stack.length; i++) {
			if(stack[i].x > width/2) {
				stack[i].c.x = stack[i].x + rdf;
				if(stack[i].c.visible == false && overlaps(i) == false) {
					rdf -= stack[i+1].x - stack[i].x;
				}
			} else {
				stack[i].c.x = stack[i].x-ldf;
				if(stack[i].c.visible == false && overlaps(i) == false) {
					ldf += stack[i].w + stack[i].x;
					if(stack[i-1].n != 'back') {
						ldf -=  stack[i-1].x + stack[i-1].w;
					}
				}
			}
			if(stack[i].w > width/3) {
				stack[i].c.width = stack[i].w+rdf+ldf;
			}
		}
		// if gaps were closed, move all rightside stuff to fill the width.
		var dif = latest-width-rdf;
		if(dif>0) {
			for(var j=0; j<stack.length; j++) {
				if(stack[j].x > width/2) {
					stack[j].c.x += dif;
				}
				if(stack[j].w>width/4 && stack[j].n!='back') {
					stack[j].c.width += dif;
				}
			}
		}
	};


	/** Getter for the original width of the MC. **/
	public function get width():Number { 
		return _width;
	};


}


}