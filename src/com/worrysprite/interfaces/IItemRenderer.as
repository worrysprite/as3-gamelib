package com.worrysprite.interfaces
{
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public interface IItemRenderer
	{
		function get data():Object;
		
		function set data(value:Object):void;
		
		function get index():int;
		
		function set index(value:int):void;
		
		function get parentComponent():DisplayObject;
		
		function set parentComponent(value:DisplayObject):void;
		
		function onRollOver():void;
		
		function onRollOut():void;
		
		function onClick():void;
	}
	
}