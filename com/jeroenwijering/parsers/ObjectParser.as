/**
* Process a feeditem before adding to the feed.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class ObjectParser {


	/** All supported feeditem element defaults. **/
	protected static var ELEMENTS:Object = {
		'audio':undefined,
		'author':undefined,
		'captions':undefined,
		'description':undefined,
		'duration':0,
		'file':undefined,
		'image':undefined,
		'link':undefined,
		'title':undefined,
		'start':0,
		'type':undefined
	};
	/** Idenifier of all supported mediatypes. **/
	protected static var TYPES:Object = {
		'camera':'',
		'image':'',
		'rtmp':'',
		'sound':'',
		'video':'',
		'youtube':''
	};
	/** File extensions of all supported mediatypes. **/
	protected static var EXTENSIONS:Object = {
		'.3g2':'video',
		'.3gp':'video',
		'.aac':'video',
		'.f4b':'video',
		'.f4p':'video',
		'.f4v':'video',
		'.flv':'video',
		'.gif':'image',
		'.jpg':'image',
		'.m4a':'video',
		'.m4v':'video',
		'.mov':'video',
		'.mp3':'sound',
		'.mp4':'video',
		'.png':'image',
		'.rbs':'sound',
		'.swf':'image',
		'.vp6':'video'
	};
	/** Mimetypes of all supported mediafiles. **/
	protected static var MIMETYPES:Object = {
		'application/x-fcs':'rtmp',
		'application/x-shockwave-flash':'image',
		'audio/aac':'video',
		'audio/m4a':'video',
		'audio/mp4':'video',
		'audio/mp3':'sound',
		'audio/mpeg':'sound',
		'audio/x-3gpp':'video',
		'audio/x-m4a':'video',
		'image/gif':'image',
		'image/jpeg':'image',
		'image/png':'image',
		'video/flv':'video',
		'video/3gpp':'video',
		'video/h264':'video',
		'video/mp4':'video',
		'video/x-3gpp':'video',
		'video/x-flv':'video',
		'video/x-m4v':'video',
		'video/x-mp4':'video'
	};


	/** Translate a generic object to feeditem. **/
	public static function parse(obj:Object):Object {
		var itm = new Object();
		for(var i in ObjectParser.ELEMENTS) {
			if(obj[i] != undefined) {
				itm[i] = Strings.serialize(obj[i],ObjectParser.ELEMENTS[i]);
			}
		}
		return ObjectParser.detect(itm);
	};


	/** Detect the mediatype of a playlistitem and save to its type var. **/
	public static function detect(itm:Object):Object {
		if(itm['type']) {
			itm['type'] = itm['type'].toLowerCase();
		}
		if(itm['file'] == undefined) {
			return itm;
		} else if(ObjectParser.TYPES[itm['type']] != undefined) {
			// assume the developer knows what he does...
		} else if(ObjectParser.EXTENSIONS[itm['type']] != undefined) {
			itm['type'] = ObjectParser.EXTENSIONS[itm['type']];
		} else if(itm['file'].substr(0,4) == 'rtmp') {
			itm['type'] = 'rtmp';
		} else if(itm['file'].indexOf('youtube.com/watch') > -1 ||
			itm['file'].indexOf('youtube.com/v/') > -1) {
			itm['type'] = 'youtube';
		} else if(ObjectParser.MIMETYPES[itm['type']] != undefined) {
			itm['type'] = ObjectParser.MIMETYPES[itm['type']];
		} else {
			itm['type'] = undefined;
			for (var i in ObjectParser.EXTENSIONS) {
				if (itm['file'] && itm['file'].substr(-4).toLowerCase() == i) {
					itm['type'] = ObjectParser.EXTENSIONS[i];
					break;
				}
			}
		}
		if(!itm['duration']) { itm['duration'] = 0; }
		if(!itm['start']) { itm['start'] = 0; }
		return itm;
	};


}


}
