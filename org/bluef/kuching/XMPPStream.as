/*
   XMPPStream.as
   kuching
   
   Created by bluef on 2010-01-08.
   Copyright 2010 bluef. All rights reserved.
*/

package org.bluef.kuching {
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	import org.bluef.kuching.events.*;
	import org.bluef.kuching.utils.*;
	import org.bluef.kuching.packets.*;
	import org.bluef.kuching.XMPPAuth;
	import org.bluef.kuching.XMPPDataPaster;
	
	public final class XMPPStream extends EventDispatcher{
		private static const CHAT_NS:Namespace = new Namespace("http://jabber.org/protocol/chatstates");
		
		private var _user:JID;
		private var _pw:String;
		
		private var _auth:XMPPAuth;
		private var _dp:XMPPDataPaster;
		
		private var _authed:Boolean;
		private var _binded:Boolean;
		private var _rostered:Boolean;
		private var _sessioned:Boolean;
		
		//singleton mode
		public function XMPPStream(user:JID, pw:String, server:String, port:uint = 5222) {			
			init(user, pw, server, port);
		}
		
		//init the XMPPStream with username and password provided by Env
		private function init(user:JID, pw:String, server:String, port:uint = 5222):void {
			_authed = false;
			_binded = false;
			_rostered = false;
			_sessioned = false;
			
			_dp = new XMPPDataPaster(server, port);
			
			_user = user.clone();			
			_auth = new XMPPAuth(_user, pw, _dp);
			
			configureListeners();
		}
		
		//public method to connect to host
		public function connect():void {
			_dp.connect();
		}
		
		//disconnect from host after send a end-xmlstream sanza
		public function disconnect():void {
			_dp.disconnect();
		}
		
		//configure event listener of all the sub modules
		private function configureListeners():void {
			_dp.addEventListener(DataEvent.DATA, onData);
			_dp.addEventListener(ChannelStateEvent.CONNECT, onChannelState);
			_dp.addEventListener(ChannelStateEvent.DISCONNECT, onChannelState);
			//handle auth result
			_auth.addEventListener(XMPPAuth.AUTH_SUCCESS, onAuthSuc);
			_auth.addEventListener(XMPPAuth.AUTH_FAILURE, onAuthFail);
		}
		
		//start a new stream by sending begin-xmlstream sanza
		private function onChannelState(e:Event):void {
			_dp.confirmConnect(_user.domain);
			dispatchEvent(new Event(e.type, true));
		}
		
		private function onData(ee:DataEvent):void {
			var s:XML;
			try {
				s = new XML(ee.data);
				if (!_authed) {
				//start auth
				//trace("going to auth");
					_auth.auth(s);
				} else {
				//trace("authed");
					if (_binded) {
						if (!_sessioned) {
							setSession();
						} else {
							if (_rostered) {
								filterPacket(s);
							} else {
								setOnline("");
								getRoster();
							}
						}
					} else {
						bindResource();
					}
				}
			} catch(e) {
				trace("[ERROR]>>", e);
				trace("[ERROR-SANZA]>>", ee.data);
			}
			//trace("e.data =",e.data.toXMLString());
			/*if (e.data.elements("*")[0].name().uri === "urn:ietf:params:xml:ns:xmpp-bind"){
				_binded = true;
			}
			if (e.data.elements("*")[0].name().uri === "jabber:iq:roster"){
				_rostered = true;
			}
			*/
			
		}
		
		//set auth state
		private function onAuthSuc(e:Event):void {
			_authed = true;
			dispatchEvent(new XMPPEvent(XMPPEvent.AUTH_SUCCESS));
			
			bindResource();
		}
		
		private function onAuthFail(e:Event):void {
			_authed = false;
			dispatchEvent(new XMPPEvent(XMPPEvent.AUTH_FAILURE));
		}
		
		public function sendData(sanza:String):void {
			dispatchEvent(new XMPPEvent(XMPPEvent.RAW, sanza));
			
			_dp.sendData(sanza);
		};
		
		//create packet by checking the localname of the sanza 
		private function filterPacket(xmlsanza:XML):void {
			//dispatch the raw data of incoming sanza
			dispatchEvent(new XMPPEvent(XMPPEvent.RAW, XML(xmlsanza).toXMLString()));
			
			switch (XML(xmlsanza).name().localName) {
				case "message":
					pasteMsgSanza(XML(xmlsanza));
					break;
					
				case "presence":
					pastePresenceSanza(XML(xmlsanza));
					break;
					
				case "iq":
					pasteIQSanza(XML(xmlsanza));
					break;
					
				case "error":
					pasteErrorSanza(XML(xmlsanza));
					break;
			}
			
		}
		
		private function pasteMsgSanza(xmlsanza:XML):void {
			if (!XML(xmlsanza).hasOwnProperty('@type')) {
				pasteChatSanza(xmlsanza);
			} else {
				switch (XML(xmlsanza).@type) {
					case 'chat':
						pasteChatSanza(XML(xmlsanza));
						break;
						
					case 'normal' :
						pasteChatSanza(XML(xmlsanza));
						break;
						
					case 'error':
						pasteErrorSanza(XML(xmlsanza));
						break;
						
					case 'groupchat':
						break;
						
					case 'headline':
						pasteChatSanza(XML(xmlsanza));
						break;
						
					default :
						pasteChatSanza(XML(xmlsanza));
						break;
				}
			}			
		};
		
		private function pasteChatSanza(xmlsanza:XML):void {
			if (XML(xmlsanza).hasOwnProperty("body") && XML(xmlsanza).child("body").toXMLString() != '') {
				var packet:MessagePacket = new MessagePacket();
				packet.loadXML(XML(xmlsanza));
				var e:MessageEvent = new MessageEvent(packet);
				dispatchEvent(e);
			} else {
				if (XML(xmlsanza).CHAT_NS::composing.toXMLString() != '') {
				//trace(xmlsanza.@from.toString());
					var tte:TypingEvent = new TypingEvent(new JID(XML(xmlsanza).@from.toString()), TypingEvent.TYPING);
					dispatchEvent(tte);
				} else if (XML(xmlsanza).CHAT_NS::paused.toXMLString() != '') {
					var tpe:TypingEvent = new TypingEvent(new JID(XML(xmlsanza).@from.toString()), TypingEvent.PAUSED);
					dispatchEvent(tpe);
				}
			}
		};
		
		private function pastePresenceSanza(xmlsanza:XML):void {
			var packet:PresencePacket = new PresencePacket();
			if (xmlsanza.hasOwnProperty('@type')) {
				packet.type = XML(xmlsanza.@type);
			}
			
			packet.loadXML(XML(xmlsanza));
			var pe:PresenceEvent = new PresenceEvent(packet);
			dispatchEvent(pe);
		};
		
		private function pasteIQSanza(xmlsanza:XML):void {
			var ipacket:IQPacket = new IQPacket();
			ipacket.loadXML(XML(xmlsanza));
			var ie:IQEvent = new IQEvent(ipacket);
			dispatchEvent(ie);
		};
		
		private function pasteErrorSanza(xml:XML):void {
			var errMsg:String = '';
			switch (XML(xml).elements("*")[0].name().localName) {
				case XMPPErrors.BAD_NAMESPACE_PREFIX :
					errMsg = "The entity has sent a namespace prefix that is unsupported, or has sent no namespace prefix on an element that requires such a prefix";
					break;
					
				case XMPPErrors.CONFLICT :
					errMsg = "The server is closing the active stream for this entity because a new stream has been initiated that conflicts with the existing stream";
					break;
					
				case XMPPErrors.CONNECTION_TIMEOUT :
					errMsg = "The entity has not generated any traffic over the stream for some period of time (configurable according to a local service policy).";
					break;
					
				case XMPPErrors.HOST_GONE :
					errMsg = "The value of the 'to' attribute provided by the initiating entity in the stream header corresponds to a hostname that is no longer hosted by the server. ";
					break;
					
				case XMPPErrors.HOST_UNKNOWN :
					errMsg = "the value of the 'to' attribute provided by the initiating entity in the stream header does not correspond to a hostname that is hosted by the server. ";
					break;
					
				case XMPPErrors.IMPROPER_ADDRESSING :
					errMsg = "a stanza sent between two servers lacks a 'to' or 'from' attribute (or the attribute has no value). ";
					break;
					
				case XMPPErrors.INTERNAL_SERVER_ERROR :
					errMsg = "the server has experienced a misconfiguration or an otherwise-undefined internal error that prevents it from servicing the stream. ";
					break;
					
				case XMPPErrors.INVALID_FROM :
					errMsg = "the JID or hostname provided in a 'from' address does not match an authorized JID or validated domain negotiated between servers via SASL or dialback, or between a client and a server via authentication and resource binding. ";
					break;
					
				case XMPPErrors.INVALID_ID :
					errMsg = "the stream ID or dialback ID is invalid or does not match an ID previously provided. ";
					break;
					
				case XMPPErrors.INVALID_NAMESPACE :
					errMsg = "the streams namespace name is something other than 'http://etherx.jabber.org/streams' or the dialback namespace name is something other than 'jabber:server:dialback'";
					break;
					
				case XMPPErrors.INVALID_XML :
					errMsg = "the entity has sent invalid XML over the stream to a server that performs validation";
					break;
					
				case XMPPErrors.NOT_AUTHORIZED :
					errMsg = "the entity has attempted to send data before the stream has been authenticated, or otherwise is not authorized to perform an action related to stream negotiation; the receiving entity MUST NOT process the offending stanza before sending the stream error. ";
					break;
					
				case XMPPErrors.POLICY_VIOLATION :
					errMsg = "the entity has violated some local service policy; the server MAY choose to specify the policy in the <text/> element or an application-specific condition element. ";
					break;
					
				case XMPPErrors.REMOTE_CONNECTION_FAILED :
					errMsg = "the server is unable to properly connect to a remote entity that is required for authentication or authorization. ";
					break;
					
				case XMPPErrors.RESOURCE_CONSTRAINT :
					errMsg = "the server lacks the system resources necessary to service the stream. ";
					break;
					
				case XMPPErrors.RESTRICTED_XML :
					errMsg = "the entity has attempted to send restricted XML features such as a comment, processing instruction, DTD, entity reference, or unescaped character";
					break;
					
				case XMPPErrors.SEE_OTHER_HOST :
					errMsg = "the server will not provide service to the initiating entity but is redirecting traffic to another host; the server SHOULD specify the alternate hostname or IP address (which MUST be a valid domain identifier) as the XML character data of the <see-other-host/> element.";
					break;
					
				case XMPPErrors.SYSTEM_SHUTDOWN :
					errMsg = "the server is being shut down and all active streams are being closed. ";
					break;
					
				case XMPPErrors.UNDEFINED_CONDITION :
					errMsg = "the error condition is not one of those defined by the other conditions in this list; this error condition SHOULD be used only in conjunction with an application-specific condition.";
					break;
					
				case XMPPErrors.UNSUPPORTED_ENCODING :
					errMsg = "the initiating entity has encoded the stream in an encoding that is not supported by the server";
					break;
					
				case XMPPErrors.UNSUPPORTED_STANZA_TYPE :
					errMsg = "the initiating entity has sent a first-level child of the stream that is not supported by the server. ";
					break;
					
				case XMPPErrors.UNSUPPORTED_VERSION :
					errMsg = "the value of the 'version' attribute provided by the initiating entity in the stream header specifies a version of XMPP that is not supported by the server; the server MAY specify the version(s) it supports in the <text/> element";
					break;
					
				case XMPPErrors.XML_NOT_WELL_FORMED :
					errMsg = "the initiating entity has sent XML that is not well-formed as defined by XML";
					break;
			}
			
			dispatchEvent(new XMPPEvent(XMPPEvent.ERROR, errMsg)); //XMPPEvent.ERROR, errMsg
		
		};
		
		//public method for creating a new msg packet
		public function newMessage(pto:JID,pbody:String):void {
			var packet:MessagePacket = new MessagePacket();
			packet.to = pto;
			packet.from = _user;
			packet.body = pbody;
			packet.type = MessagePacket.TYPE_CHAT;
			sendData(packet.toXMLString());
		}
		
		//base method to set current state
		public function newPresence(pshow:String,pstatus:String,ptype:String,pto:JID = null,ppriority:int=8):void {
			var packet:PresencePacket = new PresencePacket();
			packet.to = pto;
			packet.from = _user;
			packet.show = pshow;
			packet.status = pstatus;
			packet.type = ptype;
			packet.priority = ppriority;
			sendData(packet.toXMLString());
		}
		
		//base method to create a new IQ packet
		public function newIQ(ptype:String,paction:String,pto:JID):void {
			var packet:IQPacket = new IQPacket();
			packet.to = pto;
			packet.from = _user;
			packet.ptype = ptype;
			sendData(packet.toXMLString());
		}
		
		//bind the resource after auth
		private function bindResource():void {
			var packet:IQPacket = new IQPacket();
			packet.to = new JID(_user.domain);
			packet.ptype = IQPacket.TYPE_SET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = IQPacket.BIND_RESOURCE;
			packet.addXMLChild("", "bind", '', xmlns);
			packet.addXMLChild("bind", "resource", _user.resource);
			
			sendData(packet.toXMLString());
			_binded = true;
		}
		
		//set session
		private function setSession():void {
			var p:IQPacket = new IQPacket();
			p.ptype = IQPacket.TYPE_SET;
			p.to = new JID(_user.domain);
			var xn:Object = new Object();
			xn.tag = "xmlns";
			xn.value = "urn:ietf:params:xml:ns:xmpp-session";
			p.addXMLChild("", "session", "", xn);
			sendData(p.toXMLString());
			_sessioned = true;
		}
		
		//get roster
		public function getRoster():void {
			var packet:IQPacket = new IQPacket();
			packet.to = new JID(_user.domain);
			packet.ptype = IQPacket.TYPE_GET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = IQPacket.QUERY_ROSTER;
			packet.addXMLChild("","query",'',xmlns);
			sendData(packet.toXMLString());
			_rostered = true;
			
			sendData("<presence type='probe' from='" + JID(_user).node + "@" + _user.domain + "/" + _user.resource + "' to='" + _user.domain + "'/>");
		}
		
		public function tellBroatcast():void {
			var packet:IQPacket = new IQPacket();
			packet.to = new JID(_user.domain);
			packet.ptype = IQPacket.TYPE_GET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = "http://jabber.org/protocol/disco#info";
			packet.addXMLChild("", "query", '', xmlns);
			sendData(packet.toXMLString());
		}
		
		public function setOnline(pstatus:String):void {
			var packet:PresencePacket = new PresencePacket();
			packet.status = pstatus;
			packet.priority = 10;
			sendData(packet.toXMLString());
		}
		
		public function setAway(pstatus:String):void {
			var packet:PresencePacket = new PresencePacket();
			packet.show = PresencePacket.SHOW_AWAY;
			packet.status = pstatus;
			packet.priority = 10;
			sendData(packet.toXMLString());
		}
		
		public function setXa(pstatus:String):void {
			var packet:PresencePacket = new PresencePacket();
			packet.show = PresencePacket.SHOW_XA;
			packet.status = pstatus;
			packet.priority = 10;
			sendData(packet.toXMLString());
		}
		
		public function setBusy(pstatus:String):void {
			var packet:PresencePacket = new PresencePacket();
			packet.show = PresencePacket.SHOW_DND;
			packet.status = pstatus;
			packet.priority = 10;
			sendData(packet.toXMLString());
		}
		
		public function setOffline():void {
			var packet:PresencePacket = new PresencePacket(PresencePacket.TYPE_UNAVAILABLE);
			packet.priority = 10;
			sendData(packet.toXMLString());
			
			disconnect();
		}
		
		public function subscribe(s:JID, name:String = '', group:String = ''):void {
			addRoster(JID(s), JID(s).node, group);
			
			var packet:PresencePacket = new PresencePacket(PresencePacket.TYPE_SUBSCRIBE);
			packet.to = JID(s).clone();
			sendData(packet.toXMLString());
		};
		
		public function unsubscribe(s:JID):void {
			var packet:PresencePacket = new PresencePacket(PresencePacket.TYPE_UNSUBSCRIBE);
			packet.to = JID(s).clone();
			sendData(packet.toXMLString());
			
			deleteRoster(s);
		};
		
		public function handleSubReq(approve:Boolean, s:JID, name:String = '', group:String = ''):void {
			var type:String = PresencePacket.TYPE_SUBSCRIBED;
			if (!approve) {
				type = PresencePacket.TYPE_UNSUBSCRIBED;
			}
			var packet:PresencePacket = new PresencePacket(type);
			packet.to = JID(s).clone();
			sendData(packet.toXMLString());
			
			if (name == '') {
				name = JID(s).node;
			}
			
			if (approve) {
				subscribe(JID(s), name, group);
			}
		};
		
		
		public function sysHandleSubReq(approve:Boolean, s:JID, name:String = '', group:String = ''):void {
			var type:String = PresencePacket.TYPE_SUBSCRIBE;
			if (!approve) {
				type = PresencePacket.TYPE_UNSUBSCRIBE;
			}
			var packet:PresencePacket = new PresencePacket(type);
			packet.to = JID(s).clone();
			sendData(packet.toXMLString());
			
			if (name == '') {
				name = JID(s).node;
			}
		};
		
		
		public function addRoster(jid:JID, name:String = '', group:String = ''):void {
			var packet:IQPacket = new IQPacket();
			packet.ptype = IQPacket.TYPE_SET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = IQPacket.QUERY_ROSTER;
			packet.addXMLChild("", "query", '', xmlns);
			packet.addXMLChild("query", "item", '', {tag:"jid", value:JID(jid).toString()}, {tag:"name", value:(name == '' ? JID(jid).node : name)});
			if (group != '') {
				packet.addXMLChild("query", "group", group)
			}
			
			sendData(packet.toXMLString());
		};
		
		public function updateRoster(jid:JID, name:String = '', group:String = '', subscription:String = 'both'):void {
			var packet:IQPacket = new IQPacket();
			packet.ptype = IQPacket.TYPE_SET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = IQPacket.QUERY_ROSTER;
			packet.addXMLChild("", "query", '', xmlns);
			packet.addXMLChild("query", "item", '', {tag:"jid", value:JID(jid).toString()}, {tag:"name", value:(name == '' ? JID(jid).node : name)}, {tag:"subscription", value:subscription});
			if (group != '') {
				packet.addXMLChild("query", "group", group)
			}
			
			sendData(packet.toXMLString());
		};
		
		public function deleteRoster(jid:JID):void {
			var packet:IQPacket = new IQPacket();
			packet.ptype = IQPacket.TYPE_SET;
			var xmlns:Object = new Object();
			xmlns.tag = "xmlns";
			xmlns.value = IQPacket.QUERY_ROSTER;
			packet.addXMLChild("", "query", '', xmlns);
			packet.addXMLChild("query", "item", '', {tag:"jid", value:JID(jid).toString()}, {tag:"subscription", value:"remove"});
			
			sendData(packet.toXMLString());
		};
		
		public function typingTo(s:JID):void {
			sendData("<message from='" + _user.valueOf() + "' to='" + s.valueOf() + "' type='chat'><composing xmlns='http://jabber.org/protocol/chatstates'/></message>");
		}
	}
}