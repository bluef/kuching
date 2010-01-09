package org.bluef.kuching.utils {	
	public class JID {
		private var _jidString:String;
    	private var _node:String;
    	private var _domain:String;
    	private var _resource:String;
    	
    	public function JID(jid:String) {
    		init(jid);
    	}
    	
    	private function init(jid:String):void {
    		_jidString = jid;
    		var a:Array = jid.split("@");
    		
    		if (a.length > 1) {
    			node = a[0];
    			
    			a = String(a[1]).split("/");
    		} else {
    			a = jid.split("/");
    		}
    		
    		domain = a[0];
    		
    		if (a.length > 1) {
    			resource = a[1];
    		}
    	};
    	
    	public function clone():JID {
    		return new JID(_jidString);
    	}
    	
    	public function set domain(value:String):void {
    		if (_domain !== value) {
    			_domain = value;
    		}
		}
		
        public function get domain():String {
        	return _domain;
    	}
    	
        public function set resource(value:String):void {
			if (_resource !== value) {
				_resource = value;
			}
        	
        }
        
        public function get resource():String { return _resource; }
    	
        public function set node(value:String):void{
        	if (_node !== value) {
				_node = value;
			}
        	
        }
        
        public function get node():String { return _node; }
    	
    	public function get bareId():String {
    		var n:String = (_node) ? _node : "";
    		var d:String = (_domain) ? _domain : "";
    		var at:String = (_node && _domain) ? "@" : "";
    		return n + at + d;
    	}
    	
    	public function get bareJid():JID {
    		return new JID(bareId);
    	}
    	
        public function toString():String {
    		var jid:String = '';
    		if (node != "" && node != null) {
                jid = node + "@";
    		}
    		
            jid += domain;
            return jid;
    	}
        
        public function valueOf():String {
            var jid:String = '';
    		if (node != "" && node != null) {
                jid = node + "@";
    		}
            jid += domain;
    		if (resource != "" && resource != null) {
                jid += "/" + resource;
    		}
            return jid;
        }
	}
}