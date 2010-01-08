package org.bluef.kuching {
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import com.adobe.crypto.MD5;
	import org.bluef.kuching.XMPPDataPaster;
	import org.bluef.kuching.utils.Base64;
	import org.bluef.kuching.utils.RandomString;
	
	public class XMPPAuth extends EventDispatcher {
		public static const AUTH_SUCCESS:String = "xmpp_auth_success";
		public static const AUTH_FAILURE:String = "xmpp_auth_failure";
		
		private var _authSent:Boolean;
		private var _dp:XMPPDataPaster;
		
		private var _username:String;
		private var _password:String;
		
		//constructor.take over channel to complete auth course
		public function XMPPAuth(usr:String, pw:String, dp:XMPPDataPaster):void {
			_username = usr;
			_password = pw;
			
			_dp = dp;
			
			//auth request sanza
			_authSent = false;
		}
		
		//public method to auth
		public function auth(xmlsanza:XML):void {
			
			//check if the auth request sanza sent
			if(!_authSent){
				trace("auth:begin authing");
				if (xmlsanza.name().localName == "features" || xmlsanza.name().localName == "stream") {
					//anounce using digest-md5 method to authenticate
					var returnxml:XML = <auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='DIGEST-MD5'/>;
					_authSent = true;
					_dp.sendData(returnxml.toXMLString());
				}
			}else{
				//trace("2");
				//trace("xmlsanza.name().localName =",xmlsanza.name().localName);
				//filter data to complete the flow
				switch (xmlsanza.name().localName) {
					//while a challenge received
					case "challenge":
						challengeMD5(xmlsanza);
						break;
					case "success":
						authSuccess(xmlsanza);
						break;
					case "failure":
						authFailure(xmlsanza);
						break;
					case "stream":
						onStream(xmlsanza);
						break;
				}
			}
		}
		
		//hexdigest implementation with ByteArray
		private function hex2digest(md5:String):ByteArray {
			var raw_bytes:String;
			var char_hex:String;
			var ba:ByteArray = new ByteArray();
			for (var i:int = 0;i < 32; i += 2) {
				char_hex = md5.substr(i, 2);
				ba.writeByte(int("0x" + char_hex));
			}
			return ba;
		}
		
		//caculate the response of the challenge
		private function challengeMD5(xmlsanza:XML):void {
			var chadata:String = xmlsanza.toString();
			var dedata:String = Base64.decode(chadata);
			var arr:Array = dedata.split(",");
			
			//get realm from challenge
			var realmP:RegExp = /realm="(.+)"$/;
			var realmO:Object = realmP.exec(arr[0]);
			var realmS:String = realmO[1];
			
			//get nonce from challenge
			var nonceP:RegExp = /nonce="(.+)"$/;
			var nonceO:Object = nonceP.exec(arr[1]);
			var nonceS:String = nonceO[1];
			
			//generate random conce for response
			var cnonce:String = RandomString.generateRandomString(64);
			var user_pw_hash:String = MD5.hash(_username + ":" + realmS + ":" + _password);
			//only with the help of ByteArray will ha1 get the correct value
			var ba:ByteArray = hex2digest(user_pw_hash);
			ba.writeUTFBytes(":" + nonceS + ":" + cnonce);
			//use hashBinary to hash a ByteArray
			var ha1:String = MD5.hashBinary(ba);
			var ha2:String = MD5.hash("AUTHENTICATE:xmpp/" + _dp.domain);
			var response:String = MD5.hash(ha1 + ":" + nonceS + ":00000001:" + cnonce + ":auth:" + ha2);
			var responseBody:String = Base64.encode('username="' + _username + '",realm="' + _dp.domain + '",nonce="'+ nonceS + '",cnonce="' + cnonce + '",nc=00000001,qop=auth,digest-uri="xmpp/' + _dp.domain + '",charset=utf-8,response='+response);
			var resultxml:XML = <response xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/>;
			resultxml.appendChild(responseBody);
			_dp.sendData(resultxml.toXMLString());
		}
		
		//begin a new stream after challenge is accept
		private function authSuccess(xmlsanza:XML):void {
			var resultxml:String =  "<stream:stream to='dormforce.net' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' xml:lang='en'>";
			_dp.sendData(resultxml);
		}
		
		//dispatch a AHTU_FAILURE on auth fail
		private function authFailure(xmlsanza:XML):void {
			dispatchEvent(new Event(AUTH_FAILURE));
		}
		
		//dispatch a AUTH_SUCCESS when a stream sanza received,which indicating the auth flow is complete
		private function onStream(xmlsanza:XML):void {
			dispatchEvent(new Event(AUTH_SUCCESS));
		}
	}
}