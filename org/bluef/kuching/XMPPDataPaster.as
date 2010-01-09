package org.bluef.kuching {
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import org.bluef.kuching.events.DataEvent;
	import org.bluef.kuching.events.ChannelStateEvent;
	import org.bluef.kuching.events.ChannelEvent;
	import org.bluef.kuching.XMPPChannel;
	
	public final class XMPPDataPaster extends EventDispatcher {
		public static const DISCONNECT:String = "disconnect";
		public static const CONNECT:String = "connect";
		private var _channel = XMPPChannel;
		
		private var _buffer:String;
		private var _xmlPattern:RegExp = /^<([A-Za-z0-9\:\/\"]+)[^>]*?((>.*?<\/\1>)|(\/>))/i;
		private var _o:Array;
		private var _l:uint = 0;
		
		public function XMPPDataPaster(host:String, port:uint) {
			_o = [];
			_buffer = '';
			
			_channel = new XMPPChannel(host, port);
			_channel.addEventListener(ChannelStateEvent.CONNECT, onConnect);
			_channel.addEventListener(ChannelStateEvent.DISCONNECT, onDisconnect);
			//activate onData method when new data is available
			_channel.addEventListener(ChannelEvent.DATA, onData);
			
		}
		
		private function onConnect(e:ChannelStateEvent):void {
			trace("DATA-PASTER: CHANNEL CONECTED");
			dispatchEvent(e);
		}
		
		private function onDisconnect(e:ChannelStateEvent):void {
			dispatchEvent(new ChannelStateEvent(e.type));
		}
		
		private function onData(e:ChannelEvent):void {
			_buffer = _buffer + e.data;
			paste(_buffer);
		}
		
		public function paste(s:String):void {
			_buffer = '';
			_o = _xmlPattern.exec(s);
			while (_o != null) {				
				//trace("got it index:", _o.index, _l);
				alertDataPaste(_o[0]);
				_l = _o[0].length;
				s = s.substring(_o.index + _l);
				_o = _xmlPattern.exec(s);
			}
			alertDataTail(s);
		}
		
		private function alertDataPaste(s:String):void {
			//trace("alertData>>",s,"\n\n");
			var e:DataEvent = new DataEvent(DataEvent.DATA, s);
			dispatchEvent(e);
		}
		
		private function alertDataTail(s:String):void {
			_buffer = s + _buffer;
		}
		
		public function confirmConnect(domain:String):void {
			_channel.sendData("<stream:stream to='" + domain + "' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>")
		};
		
		public function sendData(s:String):void {
			_channel.sendData(s);
		}
		
		public function connect():void {
			_channel.connect();
		}
		
		public function disconnect():void {
			_channel.sendData("</stream:stream>");
			_channel.disconnect();
		}
	}
}