package org.bluef.kuching {
	import flash.net.Socket;
	import flash.utils.Timer;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	
	import org.bluef.kuching.events.ChannelStateEvent;
	import org.bluef.kuching.events.ChannelEvent;
	
	internal class XMPPChannel extends EventDispatcher{
		private var _socket:Socket;
		private var _host:String;
		private var _port:uint;
		private var _timer:Timer;
		private var _rawXML:String;
		private var _pattern:RegExp;
		private var _o:Array;
		private var _expireTag:uint;
		
		public function XMPPChannel(host:String, port:uint):void {
			init(host, port);
		}
		
		private function init(host:String, port:uint):void {
			_host = host;
			_port = port;
			
			_expireTag = 0;
			
			_socket = new Socket();
			_timer = new Timer(120000);
			
			_socket.addEventListener(Event.CONNECT, onConnect);
			_socket.addEventListener(Event.CLOSE, onDisconnect);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onRead);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		private function onTimer(e:TimerEvent):void {
			trace("send empty packet");
			sendData("  ");
		}
		
		public function connect():void {
			trace("XMPPChannel: CONNECT", _host, _port)
			_socket.connect(_host, _port);
		}
		
		//send data
		public function sendData(s:String):void {
			trace("SENT>>", s, "\n");
			//_timer.reset();
			_socket.writeUTFBytes(s);
			_socket.flush();
		}
		
		private function onConnect(e:Event):void {
			//trace("channel conected");
			_timer.start();
			dispatchEvent(new ChannelStateEvent(ChannelStateEvent.CONNECT));
		}
		
		private function onDisconnect(e:Event):void {
			dispatchEvent(new ChannelStateEvent(ChannelStateEvent.DISCONNECT));
		}
		
		public function disconnect():void {
			_socket.close();
		}
		
		//when new data is available
		private function onRead(e:ProgressEvent):void {
			_rawXML = _socket.readUTFBytes(_socket.bytesAvailable);
			trace("[RECEIVED]>>", _rawXML, "\n");
			
			_pattern = /\<stream:(.*?)\>/;
			_rawXML = _rawXML.replace(_pattern, '<stream:$1 xmlns:stream="http://etherx.jabber.org/streams">');
			
			if (_expireTag < 2) {
				_pattern = /^(.*?)\<stream:stream/i;
				_o = _pattern.exec(_rawXML);
				if (_o != null) {
					_rawXML = _rawXML.replace(_pattern, "<stream:stream")
					_rawXML = _rawXML.concat("</stream:stream>");
					++_expireTag;
				}
			} else {
				_pattern = /\<\/stream.*?\>/;
				_o = _pattern.exec(_rawXML);
				if (_o != null) {
					dispatchEvent(new ChannelStateEvent(ChannelStateEvent.DISCONNECT));
				}
			}
			
			_pattern = /(\n|\r)+/g;
			_rawXML = _rawXML.replace(_pattern, "<br/>");
			
			//_pattern = /(^\s+\<)/g;
			//_rawXML = _rawXML.replace(_pattern, "");
			
			dispatchData(_rawXML);
		}
		
		private function dispatchData(s:String):void {
			var e:ChannelEvent = new ChannelEvent(s);
			e.data = s;
			dispatchEvent(e);
		}
		
		private function onIOError(e:IOErrorEvent):void {
			trace(e);
			dispatchEvent(new ChannelStateEvent(ChannelStateEvent.DISCONNECT));
		}
		
		private function onSecurityError(e:IOErrorEvent):void {
			trace(e);
		}
		
		public function disConnect():void {
			_socket.close();
		}
		
		public function get host():String {
			return _host;
		};
	}
}