/**
* Parse a TimedText XML and return a rich array.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class TTParser {


	/** All supported styling elements. **/
	public static var STYLING:Object = {
		'id':0,
		'backgroundColor':'000000',
		'color':'FFFFFF',
		'displayAlign':'after',
		'fontFamily':'Arial',
		'fontSize':12,
		'fontStyle':false,
		'fontWeight':false,
		'opacity':0,
		'padding':20,
		'textAlign:':'center'
	};
	/** All supported paragraph elements. **/
	private static var ELEMENTS:Object = {
		'begin':undefined,
		'dur':undefined,
		'end':undefined,
		'style':undefined,
		'text':undefined
	};
	/** Default style ID **/
	private static var style:Number;


	/** Parse the styling head. **/
	public static function parseStyles(dat:XML):Array {
		var arr = new Array(TTParser.STYLING);
		for each (var i in dat.children()[0].children()) {
			if (i.localName() == 'styling') {
				for each (var j in i.children()) {
					var obj = TTParser.parseStyle(j);
					arr[obj.id] = obj;
				}
			}
		}
		return arr;
	};


	/** Parse a single style definition. **/
	private static function parseStyle(dat:XML):Object {
		var obj = new Object();
		for(var i in TTParser.STYLING) {
			obj[i] = TTParser.STYLING[i];
		}
		for (var j=0; j<dat.attributes().length(); j++) {
			obj[dat.attributes()[j].localName()] = dat.attributes()[j];
		}
		return obj;
	};


	/** Parse the cationing array. **/
	public static function parseCaptions(dat:XML):Array {
		var arr = new Array();
		var div = dat.children()[1].children()[0];
		if(dat.children()[1].@style > 0) {
			TTParser.style = dat.children()[1].@style;
		} else if(div.@style > 0) {
			TTParser.style = div.@style; 
		}
		for each (var i in div.children()) {
			if(i.localName() == 'p') {
				arr.push(TTParser.parseCaption(i));
			}
		}
		return arr;
	};


	/** Parse a single captions entry. **/
	private static function parseCaption(dat:XML):Object {
		var obj = {
			begin:Strings.seconds(dat.@begin),
			dur:Strings.seconds(dat.@dur),
			end:Strings.seconds(dat.@end),
			text:Strings.strip(dat.children()),
			style:dat.@style.toString()
		};
		if(obj['dur']) {
			obj['end'] = obj['begin'] + obj['dur'];
			delete obj['dur'];
		}
		if(obj['style'] == '') {
			obj['style'] = TTParser.style;
		}
		return obj;
	};


}


}