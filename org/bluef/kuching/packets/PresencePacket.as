package org.bluef.kuching.packets {
	import org.bluef.kuching.packets.AbstractPacket;
	import org.bluef.kuching.utils.JID;
	
	public class PresencePacket extends AbstractPacket {
		/**
    	 * The entity is connected to the network.
    	 */
    	public static const TYPE_AVAILABLE:String = "available";
    	/**
    	 * Signals that the entity is no longer available for communication.
    	 */
    	public static const TYPE_UNAVAILABLE:String = "unavailable";
    	/**
    	 * A request for an entity's current presence; SHOULD be generated only by a server on behalf of a user.
    	 */
    	public static const TYPE_PROBE:String = "probe";
    	/**
    	 * The sender wishes to subscribe to the recipient's presence.
    	 */
    	public static const TYPE_SUBSCRIBE:String = "subscribe";
    	/**
    	 * The sender is unsubscribing from another entity's presence.
    	 */
    	public static const TYPE_UNSUBSCRIBE:String = "unsubscribe";
    	/**
    	 * The sender has allowed the recipient to receive their presence.
    	 */
    	public static const TYPE_SUBSCRIBED:String = "subscribed";
    	/**
    	 * The subscription request has been denied or a previously-granted subscription has been cancelled.
    	 */
    	public static const TYPE_UNSUBSCRIBED:String = "unsubscribed";
    	/**
    	 * An error has occurred regarding processing or delivery of a previously-sent presence stanza.
    	 */
    	public static const TYPE_ERROR:String = "error";
    	
    	/**
    	 * The entity or resource is temporarily away.
    	 */
    	public static const SHOW_AWAY:String = "away";
    	/**
    	 * The entity or resource is actively interested in chatting.
    	 */
    	public static const SHOW_CHAT:String = "chat";
    	/**
    	 * The entity or resource is busy (dnd = "Do Not Disturb").
    	 */
    	public static const SHOW_DND:String = "dnd";
    	/**
    	 * The entity or resource is away for an extended period (xa = "eXtended Away"). For example, 
    	 * status may be "will be back from vacation in a week."
    	 */
    	public static const SHOW_XA:String = "xa";
    	
		private var _show:String;
		private var _status:String;
		private var _type:String;
		private var _priority:uint;
		
		public function PresencePacket(type:String = ''):void {
			init();
			_type = type;
			super("presence");
		}
		
		private function init():void {
			_show = '';
			_status = '';
			_priority = 8;
			_type = '';
		};
		
		public function set show(pshow:String):void {
			_show = pshow;
		}
		
		public function get show():String{
			return _show ;
		}
		
		public function set status(pstatus:String):void {
			_status = pstatus;
		}
		
		public function get status():String{
			return _status ;
		}
		
		public function set type(ptype:String):void {
			_type = ptype;
		}
		
		public function get type():String{
			return _type ;
		}
		
		public function set priority(ppriority:uint):void {
			_priority = ppriority;
		}
		
		public function get priority():uint {
			return _priority ;
		}
		
		public function toXMLString():String {
			_xmlsanza.show = _show;
			_xmlsanza.status = _status;
			_xmlsanza.priority = _priority;
			
			if (_type != '') {
				_xmlsanza.@type = _type;
			}
			
			if (_to != null) {
				_xmlsanza.@to = JID(_to).toString();
			}
			
			
			return _xmlsanza.toXMLString();
		}
		
		public function loadXML(pxmlsanza:XML):void {
			_to = new JID(pxmlsanza.@to);
			_from = new JID(pxmlsanza.@from);
			_status = pxmlsanza.status;
			_show = pxmlsanza.show;
			_priority = pxmlsanza.priority;
			_type = pxmlsanza.@type;
		}
		
		public function clone():PresencePacket {
			var p:PresencePacket = new PresencePacket();
			p.to = _to.clone();
			p.from = _from.clone();
			p.type = _type;
			p.priority = _priority;
			p.status = _status;
			p.show = _show;
			return p;
		}
	}
}