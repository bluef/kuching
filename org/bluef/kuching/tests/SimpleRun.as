/*
   SimpleRun.as
   kuching
   
   To try this test you need to adjust some variables to fit your setting, 
   including the jid, password, server address, domain and resource.
   
   Created by bluef on 2010-01-09.
   Copyright 2010 bluef. All rights reserved.
*/

package org.bluef.kuching.tests {
	import flash.display.Sprite;
	
	import org.bluef.kuching.events.XMPPEvent;
	import org.bluef.kuching.XMPPStream;
	
	import org.bluef.kuching.utils.JID;
	
	public class SimpleRun extends Sprite {
		private var _xmpp:XMPPStream;
		
		public function SimpleRun():void {
			_xmpp = new XMPPStream(new JID("test@test.com/HOME"), "password", "server");
			_xmpp.addEventListener(XMPPEvent.RAW, onXMPPData);
			_xmpp.connect();
		};
		
		private function onXMPPData(e:XMPPEvent):void {
			debugtext.appendText(String(e.data) + "\n\n");
			debugtext.verticalScrollPosition = debugtext.maxVerticalScrollPosition;
		};
	}
}