package com.worrysprite.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class ItemEvent extends Event
	{
		public static const SELECT:String = "select";
		
		public var index:int;
		public var data:Object;
		
		public function ItemEvent(type:String, index:int, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.index = index;
			this.data = data;
		}
		
		public override function clone():Event
		{
			return new ItemEvent(type, index, data, bubbles, cancelable);
		}
		
		public override function toString():String
		{
			return formatToString("ItemEvent", "type", "index", "bubbles", "cancelable", "eventPhase");
		}
		
	}
	
}