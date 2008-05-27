/**
* Parse an RSS feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.MediaParser;
import com.jeroenwijering.parsers.ObjectParser;
import com.jeroenwijering.utils.Strings;


public class RSSParser extends ObjectParser {


	/** Parse an RSS playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr = new Array();
		var itm = new Object();
		for each (var i in dat.children()) {
			if (i.localName() == 'channel') {
				for each (var j in i.children()) {
					if(j.name() == 'item') {
						itm = RSSParser.parseItem(j);
					}
					if(itm['type'] != undefined) {
						arr.push(itm);
					}
				}
			}
		}
		return arr;
	};


	/** Translate RSS item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm =  new Object();
		for each (var i in obj.children()) {
			switch(i.localName()) {
				case 'duration':
					itm['duration'] = Strings.seconds(i.text());
					break;
				case 'enclosure':
					itm['file'] = i.@url.toString();
					itm['type'] = i.@type.toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'description':
					itm['description'] = i.text().toString();
					break;
				case 'summary':
					itm['description'] = i.text().toString();
					break;
				case 'link':
					itm['link'] = i.text().toString();
					break;
				case 'author':
					itm['author'] = i.text().toString();
					break;
				case 'group':
					itm = MediaParser.parseGroup(i,itm);
					break;
			}
		}
		itm = MediaParser.parseGroup(obj,itm);
		return ObjectParser.detect(itm);
	};


}


}