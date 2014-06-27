package com.worrysprite.view.component
{
	import com.worrysprite.enum.ExceptionEnum;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * 菜单
	 * @author 王润智
	 */
	public class Menu extends Sprite
	{
		protected var background:DisplayObject;
		protected var space:int;
		protected var padding:int;
		protected var itemList:Array = [];
		
		public function Menu()
		{
			addEventListener(MouseEvent.MOUSE_DOWN, onItemClick);
			
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		protected function onAdded(e:Event):void
		{
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		
		protected function onRemoved(e:Event):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		
		protected function onStageMouseDown(e:MouseEvent):void
		{
			parent.removeChild(this);
		}
		
		protected function addItem(item:int):void
		{
			var menuItem:BitmapButton = createItem(item);
			if (menuItem)
			{
				menuItem.x = padding;
				menuItem.y = padding + space * itemList.length;
				menuItem.name = item.toString();
				addChild(menuItem);
				itemList.push(menuItem);
				updateSize();
			}
		}
		
		protected function clear():void
		{
			for (var i:int = 0; i < itemList.length; ++i)
			{
				removeChild(itemList[i]);
			}
			itemList.length = 0;
		}
		
		protected function createItem(item:int):BitmapButton
		{
			throw new Error(ExceptionEnum.getExceptionMsg(ExceptionEnum.FUNCTION_MUST_BE_OVERRIDE), ExceptionEnum.FUNCTION_MUST_BE_OVERRIDE);
			return null;
		}
		
		protected function updateSize():void
		{
			
		}
		
		protected function onItemClick(e:MouseEvent):void
		{
			var item:BitmapButton = e.target as BitmapButton;
			if (item)
			{
				doFunc(int(item.name));
			}
		}
		
		protected function doFunc(item:int):void
		{
			
		}
	}
}