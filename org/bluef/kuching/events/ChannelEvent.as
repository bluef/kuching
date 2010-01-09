package org.bluef.kuching.events {
	import flash.events.Event;
	
	public class ChannelEvent extends Event {
		public static const DATA:String = "DataReceived";
		private var _data:String;
		
		public function ChannelEvent(s:String) {
			super(DATA, true, false);
			_data = s;
			//trace("data set = ",_data.toXMLString());
		}
		
		public function get data():String {
			return _data;
		}
		
		public function set data(s:String):void {
			_data = s;
			//trace("data set = ",_data.toXMLString());
		}
	}
}