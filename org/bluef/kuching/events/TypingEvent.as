package org.bluef.kuching.events {
	import flash.events.Event;
	import grassland.core.utils.JID;
	public class TypingEvent extends Event {
		public static const TYPING:String = "typing";
		public static const PAUSED:String = "paused";
		private var _jid:JID;
		public function TypingEvent(user:JID,ptype:String){
			_jid = user.clone();
			super(ptype,true,false);
		}
		
		public function get jid():JID{
			return _jid.clone();
		}
	}
}