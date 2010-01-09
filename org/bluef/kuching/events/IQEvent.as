package org.bluef.kuching.events {
	import flash.events.Event;
	import org.bluef.kuching.packets.IQPacket;
	
	public class IQEvent extends Event {
		public static var RECEIVED:String = "IQ_Received";
		private var _data:IQPacket;
		
		public function IQEvent(s:IQPacket) {
			//trace("IQEvent :",s.content.toXMLString());
			super(RECEIVED, true, false);
			_data = s;
		}
		
		public function get data():IQPacket {
			return _data;
		}
		
		public function set data( s:IQPacket ):void {
			_data = s;
		}
	}
}