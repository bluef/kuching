package org.bluef.kuching.events {
	import flash.events.Event;
	
	public class XMPPEvent extends Event {
		public static const AUTH_SUCCESS:String = "xmpp_auth_success";
		public static const AUTH_FAILURE:String = "xmpp_auth_failure";
		
		public static const RAW:String = "xmpp_raw_data";
		public static const ERROR:String = "xmpp_error_data";
		
		private var _data:Object;
		
		public function XMPPEvent(t:String, s:Object = null) {
			super(t, true, false);
			_data = s;
		}
		
		public function set data(value:Object):void {
			_data = value;
		}
		
		public function get data():Object {
			return _data;
		}
	}
}