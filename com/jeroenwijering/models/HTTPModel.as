﻿/**
* Wrapper for playback of progressively downloaded video.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import flash.events.*;
import flash.display.DisplayObject;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.net.*;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class HTTPModel implements ModelInterface {


	/** reference to the model. **/
	private var model:Model;
	/** Video object to be instantiated. **/
	private var video:Video;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Sound control object. **/
	private var transform:SoundTransform;
	/** Interval ID for the time. **/
	private var timeinterval:Number;
	/** Interval ID for the loading. **/
	private var loadinterval:Number;
	/** Object with keyframe times and positions. **/
	private var keyframes:Object;
	/** Offset byteposition to start streaming. **/
	private var offset:Number;
	/** Offset timeposition for lighttpd streaming. **/
	private var timeoffset:Number;
	/** switch for h264 streaming **/
	private var h264:Boolean;
	/** Byteposition to which the file has been loaded. **/
	private var loaded:Number;


	/** Constructor; sets up the connection and display. **/
	public function HTTPModel(mod:Model) {
		model = mod;
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		connection.connect(null);
		stream = new NetStream(connection);
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = this;
		video = new Video(320,240);
		video.attachNetStream(stream);
		transform = new SoundTransform();
		stream.soundTransform = transform;
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		quality(model.config['quality']);
		offset = timeoffset = 0;
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent) {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Return a keyframe byteoffset or timeoffset. **/
	private function getOffset(pos:Number,tme:Boolean=false):Number {
		var off = 0;
		if(keyframes === null) {
			errorHandler(new ErrorEvent(ErrorEvent.ERROR,false,false,"This file has no seekpoints metadata."));
			return 0;
		}
		for (var i=0; i< keyframes.times.length; i++) {
			if(keyframes.times[i] <= pos && keyframes.times[i+1] >= pos) {
				if(tme == true) {
					off = keyframes.times[i];
				} else { 
					off = keyframes.filepositions[i];
				}
				break;
			}
		}
		return off;
	};


	/** Load content. **/
	public function load() {
		stream.close();
		var url = model.playlist[model.config['item']]['file'];
		if(model.config["streamscript"] == "lighttpd") {
			if(h264) {
				url +='?start='+timeoffset;
			} else {
				url += '?start='+offset;
			}
		} else {
			url = model.config["streamscript"]+"?file="+url+'&start='+offset;
		}
		url += '&width='+model.config['width'];
		url += '&client='+encodeURI(model.config['client']);
		stream.play(url);
		clearInterval(loadinterval);
		clearInterval(timeinterval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		loadinterval = setInterval(loadHandler,100);
		timeinterval = setInterval(timeHandler,100);
	};


	/** Interval for the loading progress **/
	private function loadHandler() {
		loaded = stream.bytesLoaded;
		var ttl = stream.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:loaded,total:ttl+offset,offset:offset});
		if(loaded >= ttl && loaded > 0) {
			clearInterval(loadinterval);
		}
	};


	/** Get textdata from netstream. **/
	public function onImageData(info:Object) {
		var dat = new Object();
		for(var i in info) { 
			dat[i] = info[i];
		}
		model.sendEvent(ModelEvent.META,dat);
	};


	/** Get metadata information from netstream class. **/
	public function onMetaData(info:Object) {
		if(h264) { return; }
		video.width = info.width;
		video.height = info.height;
		model.mediaHandler(video);
		if(info.seekpoints) {
			h264 = true;
			keyframes = new Object();
			keyframes.times = new Array();
			keyframes.filepositions = new Array();
			for (var j in info.seekpoints) {
				keyframes.times.push(Number(info.seekpoints[j]['time']));
				keyframes.filepositions.push(Number(info.seekpoints[j]['offset']));
			}
		} else if(info.keyframes) {
			keyframes = info.keyframes;
		}
		var dat = new Object();
		for(var i in info) {
			dat[i] = info[i];
		}
		delete dat.seekpoints;
		dat.keyframes = '';
		for(var k=0; k<keyframes.times.length; k++) {
			dat['keyframes'] += ','+keyframes.times[k]+':'+keyframes.filepositions[k];
		}
		model.sendEvent(ModelEvent.META,dat);
		if(model.playlist[model.config['item']]['start'] > 0) {
			seek(model.playlist[model.config['item']]['start']);
		}
	};


	/** Get textdata from netstream. **/
	public function onTextData(info:Object) {
		var dat = new Object();
		for(var i in info) { 
			dat[i] = info[i];
		}
		model.sendEvent(ModelEvent.META,dat);
	};


	/** Pause playback. **/
	public function pause() {
		clearInterval(timeinterval);
		stream.pause();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Resume playing. **/
	public function play() {
		stream.resume();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		timeinterval = setInterval(timeHandler,100);
	};


	/** Change the smoothing mode. **/
	public function seek(pos:Number) {
		clearInterval(timeinterval);
		var off = getOffset(pos);
		if(off < offset || off > offset+loaded) {
			offset = off;
			timeoffset = getOffset(pos,true);
			load();
		} else {
			if(h264) {
				stream.seek(pos-timeoffset);
			} else { 
				stream.seek(pos)
			}
			play();
		}
	};


	/** Change the smoothing mode. **/
	public function quality(qua:Boolean) {
		if(qua == true) { 
			video.smoothing = true;
			video.deblocking = 4;
		} else { 
			video.smoothing = false;
			video.deblocking = 1;
		}
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent) {
		if(evt.info.code == "NetStream.Play.Stop") {
			if(model.state == ModelStates.COMPLETED) {
				stream.close();
			} else { 
				clearInterval(timeinterval);
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
			}
		} else if(evt.info.code == "NetStream.Play.StreamNotFound") {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:"Video stream not found: " + 
				model.playlist[model.config['item']]['file']});
		}
		model.sendEvent(ModelEvent.META,{info:evt.info.code});
	};


	/** Destroy the HTTP stream. **/
	public function stop() {
		clearInterval(loadinterval);
		clearInterval(timeinterval);
		stream.close();
		offset = timeoffset = 0;
	};


	/** Interval for the position progress **/
	private function timeHandler() {
		var bfr = Math.round(stream.bufferLength/stream.bufferTime*100);
		var pos = Math.round(stream.time*10)/10;
		if (h264) { pos += timeoffset; }
		var dur = model.playlist[model.config['item']]['duration'];
		if(bfr < 100 && pos < Math.abs(dur-stream.bufferTime-1)) {
			model.sendEvent(ModelEvent.BUFFER,{percentage:bfr});
			if(model.state != ModelStates.BUFFERING) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			}
		} else if (model.state == ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(dur > 0) {
			model.sendEvent(ModelEvent.TIME,{position:pos,duration:dur});
		}
	};


	/** Set the volume level. **/
	public function volume(vol:Number) {
		transform.volume = vol/100;
		stream.soundTransform = transform;
	};


};


}