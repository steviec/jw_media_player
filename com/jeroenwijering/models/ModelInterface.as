/**
* Wrapper for playback of progressively downloaded video.
**/
package com.jeroenwijering.models {


import flash.display.DisplayObject;


public interface ModelInterface {

	/** Load a file into the model. **/
	function load();
	/** Playback resume directive. **/
	function play();
	/** Playback pause directive. **/
	function pause();
	/** Playback seeking directive. **/
	function seek(pos:Number);
	/** Stop the item altogether. **/
	function stop();
	/** Set or toggle the playback quality. **/
	function quality(stt:Boolean);
	/** Change the volume. **/
	function volume(vol:Number);


};


}