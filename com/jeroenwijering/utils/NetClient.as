/**
* Object that catches calls invoked by NetStream / NetConnection.
**/
package com.jeroenwijering.utils {


public class NetClient {


	/** Function to callback all events to **/
	private var callback:Object;


	/** Constructor. **/
	public function NetClient(cbk:Object):void {
		callback = cbk;
	};


	/** Forward calls to callback **/
	private function forward(dat:Object):void {
		callback.onData(dat);
	};


	/** Checking the available bandwidth. **/
	public function onBWCheck(... rest):Number {
		return 0;
	};


	/** Receiving the bandwidth check result. **/
	public function onBWDone(... rest):void {
		if (rest.length > 0) {
			var dat = {type:'bandwidth',bandwidth:rest[0]};
			forward(dat);
		}
	};


	/** Handler for captionate events. **/
	public function onCaption(cps:String,spk:Number):void {
		var dat = {type:'caption',captions:cps,speaker:spk};
		forward(dat);
	};


	/** Handler for captionate events. **/
	public function onCaptionInfo(obj:Object):void {
		var dat = {type:'captioninfo'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Handler for captionate events. **/
	public function onCuePoint(obj:Object):void {
		var dat = {type:'cuepoint'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Some Limelight crap. **/
	public function onFCSubscribe(obj:Object):void {
		var dat = {type:'fcsubscribe'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Get image data from netstream. **/
	public function onImageData(obj:Object):void {
		var dat = {type:'imagedata'};
		forward(obj);
	};


	/** Handler for LaasstSecond call. **/
	public function onLastSecond(obj:Object):void {
		var dat = {type:'lastsecond'};
		forward(dat);
	};


	/** Get metadata information from netstream class. **/
	public function onMetaData(obj:Object):void {
		var dat = {type:'metadata'};
		for(var i in obj) { dat[i] = obj[i]; }
		if((dat.videocodecid || dat.videodatarate) && !dat.width) {
			dat.width = 320;
			dat.height = 240;
		}
		forward(dat);
	};


	/** Receive NetStream playback codes. **/
	public function onPlayStatus(dat:Object):void {
		if(dat.code == "NetStream.Play.Complete") {
			var dat = {type:'complete'};
			forward(dat);
		}
	};


	/** RTMP Sample callback. **/
	public function RtmpSampleAccess(obj:Object):void {
		var dat = {type:'rtmpsampleaccess'};
		forward(dat);
	};


	/** Get textdata from netstream. **/
	public function onTextData(obj:Object):void {
		var dat = {type:'textdata'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


};


}