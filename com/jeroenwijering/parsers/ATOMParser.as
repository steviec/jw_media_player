/**
* Parse an ATOM feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.MediaParser;
import com.jeroenwijering.parsers.ObjectParser;
import com.jeroenwijering.utils.Strings;


public class ATOMParser extends ObjectParser {


	/** Parse an RSS playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr = new Array();
		var itm = new Object();
		for each (var i in dat.children()) {
			if (i.localName() == 'entry') {
				itm = ATOMParser.parseItem(i);
			}
			if(itm['type'] != undefined) {
				arr.push(itm);
			}
		}
		return arr;
	};


	/** Translate ATOM item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm =  new Object();
		for each (var i in obj.children()) {
			switch(i.localName()) {
				case 'author':
					itm['author'] = i.children()[0].text().toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'summary':
					itm['description'] = i.text().toString();
					break;
				case 'link':
					if(i.@rel == 'alternate') {
						itm['link'] = i.@href;
					}
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