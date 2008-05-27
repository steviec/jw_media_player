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


public class VideoModel implements ModelInterface {


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


	/** Constructor; sets up the connection and display. **/
	public function VideoModel(mod:Model) {
		model = mod;
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.objectEncoding = ObjectEncoding.AMF0;
		connection.connect(null);
		stream = new NetStream(connection);
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = this;
		video = new Video(320,240);
		video.attachNetStream(stream);
		transform = new SoundTransform();
		stream.soundTransform = transform;
		quality(model.config['quality']);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		model.sendEvent(ModelEvent.TIME,{
			position:model.playlist[model.config['item']]['start'],
			duration:model.playlist[model.config['item']]['duration']
		});
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent) {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Load content. **/
	public function load() {
		stream.play(model.playlist[model.config['item']]['file']);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		loadinterval = setInterval(loadHandler,100);
		timeinterval = setInterval(timeHandler,100);
	};


	/** Interval for the loading progress **/
	private function loadHandler() { 
		var ldd = stream.bytesLoaded;
		var ttl = stream.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl});
		if(ldd == ttl && ldd > 0) {
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
		video.width = info.width;
		video.height = info.height;
		model.mediaHandler(video);
		var dat = new Object();
		for(var i in info) { 
			dat[i] = info[i];
		}
		model.sendEvent(ModelEvent.META,dat);
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
		stream.seek(pos);
		play();
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
			clearInterval(timeinterval);
			model.sendEvent(ModelEvent.TIME,{
				position:model.playlist[model.config['item']]['start'],
				duration:model.playlist[model.config['item']]['duration']
			});
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		} else if (evt.info.code == "NetStream.Play.StreamNotFound") {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:'Video not found: '+model.playlist[model.config['item']]['file']});
		}
		model.sendEvent(ModelEvent.META,{info:evt.info.code});
	};


	/** Destroy the videocamera. **/
	public function stop() {
		clearInterval(loadinterval);
		clearInterval(timeinterval);
		stream.pause();
		video.attachNetStream(null);
		video.clear();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/** Interval for the position progress **/
	private function timeHandler() {
		var bfr = Math.round(stream.bufferLength/stream.bufferTime*100);
		var pos = Math.round(stream.time*10)/10;
		var dur = model.playlist[model.config['item']]['duration'];
		if(bfr < 100 && pos < dur-stream.bufferTime-1) {
			model.sendEvent(ModelEvent.BUFFER,{percentage:bfr});
			if(model.state != ModelStates.BUFFERING) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			}
		} else if (model.state == ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if( dur > 0) {
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