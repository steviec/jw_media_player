/**
* Parse an XSPF feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;
import com.jeroenwijering.parsers.ObjectParser;


public class XSPFParser extends ObjectParser {


	/** Parse an XSPF playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr = new Array();
		var itm = new Object();
		for each (var i in dat.children()) {
			if (i.localName().toLowerCase() == 'tracklist') {
				for each (var j in i.children()) {
					itm = XSPFParser.parseItem(j);
					if(itm['type'] != undefined) {
						arr.push(itm);
					}
				}
			}
		}
		return arr;
	};


	/** Translate XSPF item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm =  new Object();
		for each (var i in obj.children()) {
			if(!i.localName()) { break; }
			switch(i.localName().toLowerCase()) {
				case 'location':
					itm['file'] = i.text().toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'annotation':
					itm['description'] = i.text().toString();
					break;
				case 'info':
					itm['link'] = i.text().toString();
					break;
				case 'image':
					itm['image'] = i.text().toString();
					break;
				case 'creator':
					itm['author'] = i.text().toString();
					break;
				case 'duration':
					itm['duration'] = Strings.seconds(i.text());
					break;
				case 'meta':
					itm[i.@rel] = i.text().toString();
					break;
			}
		}
		return ObjectParser.detect(itm);
	};


}


}