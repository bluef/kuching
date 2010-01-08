package org.bluef.kuching.events {
	import flash.events.Event;
	public class DataEvent extends Event {
		public static const STREAM:String = "data_stream";
		public static const DATA:String = "data_pasted";
		private var _data:String;
		public function DataEvent(t:String,s:String){
			super(t,true,false);
			//data = new XML();
			//data = s.copy();
			_data = s;
		}
		
		public function set data(s:String):void{
			//_data = s.copy();
			_data = s;
		}
		
		public function get data():String{
			//return _data.copy();
			return _data;
		}
	}
}