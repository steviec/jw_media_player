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
	private function overlaps() { 
		// working on this...
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
		for(var i=0; i<stack.length; i++) {
			if(stack[i].x > stack[0].w/2) { 
				stack[i].c.x = stack[i].x + rdf;
			} else {
				stack[i].c.x = stack[i].x+ldf;
			}
			if(stack[i].w > width/3) {
				stack[i].c.width = stack[i].w+rdf+ldf;
			}
		}
	};


	/** Getter for the original width of the MC. **/
	public function get width():Number { 
		return _width;
	};


}


}