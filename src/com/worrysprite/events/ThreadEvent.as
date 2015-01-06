package com.worrysprite.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class ThreadEvent extends Event
	{
		public static const THREAD_MESSAGE:String = "thread_message";
		
		private var _data:Object;
		
		public function ThreadEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_data = data;
		}
		
		public override function clone():Event
		{
			return new ThreadEvent(type, _data, bubbles, cancelable);
		}
		
		public override function toString():String
		{
			return formatToString("ThreadEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
		public function get data():Object
		{
			return _data;
		}
	}
}