/**
* Object that catches calls invoked by NetStream / NetConnection.
**/
package com.jeroenwijering.utils {


public class NetClient {


	/** Function to callback all events to **/
	private var callback:Object;


	/** Constructor. **/
	public function NetClient(cbk:Object) {
		callback = cbk;
	};


	/** Forward calls to callback **/
	private function forward(dat:Object) {
		callback.onData(dat);
	};


	/** Handler for captionate events. **/
	public function onBWDone() {
		var dat = {type:'bwdone'};
		forward(dat);
	};


	/** Handler for captionate events. **/
	public function onCaption(cps:String,spk:Number) {
		var dat = {type:'caption',captions:cps,speaker:spk};
		forward(dat);
	};


	/** Handler for captionate events. **/
	public function onCaptionInfo(obj:Object) {
		var dat = {type:'captioninfo'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Handler for captionate events. **/
	public function onCuePoint(obj:Object) {
		var dat = {type:'cuepoint'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Some Limelight crap. **/
	public function onFCSubscribe(obj:Object) {
		var dat = {type:'fcsubscribe'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


	/** Get image data from netstream. **/
	public function onImageData(obj:Object) {
		var dat = {type:'imagedata'};
		forward(obj);
	};


	/** Handler for LaasstSecond call. **/
	public function onLastSecond(obj:Object) {
		var dat = {type:'lastsecond'};
		forward(dat);
	};


	/** Get metadata information from netstream class. **/
	public function onMetaData(obj:Object) {
		var dat = {type:'metadata'};
		for(var i in obj) { dat[i] = obj[i]; }
		if(dat.videocodecid && !dat.width) {
			dat.width = 320;
			dat.height = 240;
		}
		forward(dat);
	};


	/** Receive NetStream playback codes. **/
	public function onPlayStatus(dat:Object) {
		if(dat.code == "NetStream.Play.Complete") {
			var dat = {type:'complete'};
			forward(dat);
		}
	};


	/** RTMP Sample callback. **/
	public function RtmpSampleAccess(obj:Object) {
		var dat = {type:'rtmpsampleaccess'};
		forward(dat);
	};


	/** Get textdata from netstream. **/
	public function onTextData(obj:Object) {
		var dat = {type:'textdata'};
		for(var i in obj) { dat[i] = obj[i]; }
		forward(dat);
	};


};


}