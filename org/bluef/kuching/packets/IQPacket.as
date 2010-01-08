package org.bluef.kuching.packets {
	import org.bluef.kuching.packets.AbstractPacket;
	import grassland.core.utils.JID;
	
	public class IQPacket extends AbstractPacket {
		
		public static const TYPE_GET:String = "get";
		public static const TYPE_SET:String = "set";
		public static const TYPE_RESULT:String = "result";
		public static const TYPE_ERROR:String = "error";
		
		public static const QUERY_ROSTER:String = "jabber:iq:roster";
		public static const BIND_RESOURCE:String = "urn:ietf:params:xml:ns:xmpp-bind";
		
		private var _type:String;
		private var _content:XMLList;
		
		public function IQPacket(){
			init();
			super("iq");
		}
		
		private function init():void {
			_type = '';
		};
		
		public function get content():XMLList{
			return _content;
		}
		
		public function set ptype(s:String):void{
			_type = s;
		}
		
		public function get ptype():String{
			return _type;
		}
		
		public function toXMLString():String{
			_xmlsanza.@type = _type;
			_xmlsanza.@id = generateID();
			if (_content != null) {
				_xmlsanza.appendChild(_content);
			}
			
			return _xmlsanza.toXMLString();
		}
		
		public function loadXML(pxmlsanza:XML):void{
			_to = new JID(pxmlsanza.@to);
			_from = new JID(pxmlsanza.@from);
			_type = pxmlsanza.@type;
			_content = pxmlsanza.elements("*").copy();
		}
		
	}
}