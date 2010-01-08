package org.bluef.kuching.events{
	import flash.events.Event;
	
	public class ChannelStateEvent extends Event {
		public static const CONNECT:String = "Connect";
		public static const DISCONNECT:String = "Disconnect";
		private var _data:XML;
		
		public function ChannelStateEvent(type:String){
			super(type, true, false);
		}
	}
}