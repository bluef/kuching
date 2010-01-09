package org.bluef.kuching.packets {
	import org.bluef.kuching.packets.AbstractPacket;
	import org.bluef.kuching.utils.JID;
	
	public class MessagePacket extends AbstractPacket {
		public static const TYPE_NORMAL:String = "normal";
        public static const TYPE_CHAT:String = "chat";
        public static const TYPE_GROUPCHAT:String = "groupchat";
        public static const TYPE_HEADLINE:String = "headline";
        public static const TYPE_ERROR:String = "error";
        private static const ACTIVE_XML:XML = <active xmlns="http://jabber.org/protocol/chatstates"></active>;
        
		private var _body:String;
		private var _type:String;
        
        public function MessagePacket() {
        	init();
        	
        	super("message");
        }
        
        private function init():void {
        	_body = '';
        	_type = '';
        };
        
        public function get body():String {
			return _body;
		}
		
		public function set body(pbody:String):void {
			_body = pbody;
		}
		
		public function set type(s:String):void {
			_type = s;
		}
        
		public function get type():String {
			return _type;
		}
		
        public function toXMLString():String {
        	_xmlsanza.@to = _to;
        	_xmlsanza.@from = _from;
        	_xmlsanza.@type = _type;
			_xmlsanza.body = _body;
			_xmlsanza.appendChild(ACTIVE_XML);
			
			return _xmlsanza.toXMLString();
        }
        
        public function loadXML(pxmlsanza:XML):void {
        	var ns:Namespace = pxmlsanza.namespace();
        	_to = new JID(pxmlsanza.@to);
			_from = new JID(pxmlsanza.@from);
			_type = pxmlsanza.@type;
			_body = pxmlsanza.ns::body;
        }
		
		public function clone():MessagePacket {
			var p:MessagePacket = new MessagePacket();
			p.to = _to.clone();
			p.from = _from.clone();
			p.type = _type;
			p.body = _body;
			return p;
		}
	}
}