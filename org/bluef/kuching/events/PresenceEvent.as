package org.bluef.kuching.events {
	import flash.events.Event;
	import org.bluef.kuching.packets.PresencePacket;
	
	public class PresenceEvent extends Event {
		public static var RECEIVED:String = "Presence_Received";
		private var _data:PresencePacket;
		
		public function PresenceEvent(s:PresencePacket) {
			super(PresenceEvent.RECEIVED, true, false);
			_data = s;
		}
		
		public function get data():PresencePacket {
			return _data;
		}
		
		public function set data(s:PresencePacket):void {
			_data = s;
		}
	}
}