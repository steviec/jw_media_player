/**
* A couple of commonly used string operations.
**/
package com.jeroenwijering.utils {


import flash.text.TextField;


public class Strings {


	/** Strip tags and trim a string; convert <br> breaks to \n. **/
	public static function strip(str:String):String {
		var tmp = str.split("\n");
		str = tmp.join("");
		tmp = str.split("\r");
		str = tmp.join("");
		var idx = str.indexOf("<");
		while(idx != -1) {
			var end = str.indexOf(">",idx+1);
			end == -1 ? end = str.length-1: null;
			if(str.substr(idx,3) == '<br') { 
				str = str.substr(0,idx)+"\n"+str.substr(end+1,str.length);
			} else { 
				str = str.substr(0,idx)+" "+str.substr(end+1,str.length);
			}
			idx = str.indexOf("<",idx);
		}
		return str;
	};


	/** Convert number to MIN:SS string. **/
	public static function digits(nbr:Number):String {
		var min = Math.floor(nbr/60);
		var sec = Math.floor(nbr%60);
		var str = Strings.zero(min)+':'+Strings.zero(sec);
		return str;
	};


	/** Add a leading zero to a number. **/
	public static function zero(nbr:Number):String {
		if(nbr < 10) { 
			return '0'+nbr;
		} else {
			return ''+nbr;
		}
	};


	/**
	* Convert a string to seconds, with these formats supported:
	* 00:03:00.1 / 03:00.1 / 180.1s / 3.2m / 3.2h
	**/
	public static function seconds(str:String):Number {
		var arr = str.split(':');
		var sec = 0;
		if (str.substr(-1) == 's') {
			sec = Number(str.substr(0,str.length-1));
		} else if (str.substr(-1) == 'm') {
			sec = Number(str.substr(0,str.length-1))*60;
		} else if(str.substr(-1) == 'h') {
			sec = Number(str.substr(0,str.length-1))*3600;
		} else if(arr.length > 1) {
			sec = Number(arr[arr.length-1]);
			sec += Number(arr[arr.length-2])*60;
			if(arr.length == 3) {
				sec += Number(arr[arr.length-3])*3600;
			}
		} else {
			sec = Number(str);
		}
		return sec;
	};


	/** 
	* Compare a string agains it's destination and return datatyped 
	*
	* @param val	String value to check.
	* @param cpm	Destination string, number or boolean.
	* 
	* @return		The checked value in the correct primitive tpe.
	**/
	public static function serialize(val:String, cmp:Object):Object {
		switch(typeof(cmp)) {
			case 'boolean':
				if (val == 'true') {
					return true;
				} else {
					return false;
				}
			case 'number':
				return Number(val);
			default:
				return Strings.decode(val);
		}
	};


	/** URLDecode a string and remove possible asfunction reference. **/
	public static function decode(str:String):String {
		var idx = str.indexOf('asfunction');
		if(idx == -1) {
			return decodeURI(str);
		} else {
			return decodeURI(str.substr(0,idx)+str.substr(idx+10));
		}
	
	};


}


}