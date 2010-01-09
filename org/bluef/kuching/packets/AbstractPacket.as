package org.bluef.kuching.packets {
	import org.bluef.kuching.utils.JID;
	
	public class AbstractPacket {
		public static const XMLNS:String = "jabber:client";
		protected static var _id:uint = 0;
		protected var _xmlsanza:XML;
		protected var _to:JID;
		protected var _from:JID;
		
		public function AbstractPacket(ptype:String) {
			switch (ptype) {
				case "iq":
					_xmlsanza = <iq />;
					_xmlsanza.@id = generateID();
					break;
					
				case "message":
					_xmlsanza = <message />;
					break;
					
				case "presence":
					_xmlsanza = <presence />;
					break;
					
				default :
					throw new Error("Unexpected sanza type" + ptype);
					break;
			}
			_xmlsanza.@xmlns = XMLNS;
		}
		
		public function set to(pto:JID):void {
			_to = pto.clone();
		}
		
		public function set from(pfrom:JID):void {
			_from = pfrom.clone();
		}
		
		public function get to():JID {
			return _to.clone();
		}
		
		public function get from():JID {
			return _from.clone();
		}
		
		protected function generateID():String {
			++_id;
			return String(_id);
		}
		
		//add a child to _xmlsanza,args is objects with two property:tag and value
		public function addXMLChild(source:String, pname:String, pvalue:String, ... args):void{
			var i:uint;
			var ll:int = args.length;
			if (source == '') {
				_xmlsanza.appendChild(<{pname}/>);
				if (pvalue !== '') {
					_xmlsanza.child(pname).appendChild(pvalue);
				}
				for (i = 0; i < ll; ++i) {
					_xmlsanza.child(pname).@[args[i].tag] = args[i].value;
				}
			} else {
				_xmlsanza.descendants(source).appendChild(<{pname}/>);
				if (pvalue !== '') {
					_xmlsanza.descendants(source).child(pname).appendChild(pvalue);
				}
				for (i = 0; i< ll; ++i) {
					_xmlsanza.descendants(source).child(pname).@[args[i].tag] = args[i].value;
				}
			}
		}
	}
}