package com.worrysprite.view.component.menu
{
	import com.worrysprite.events.ItemEvent;
	import com.worrysprite.interfaces.IItemRenderer;
	import com.worrysprite.manager.HeartbeatManager;
	import com.worrysprite.manager.StageManager;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * 菜单
	 * @author 王润智
	 */
	public class Menu extends Sprite
	{
		public static const HORIZONTAL:int = 1;
		public static const VERTICAL:int = 2;
		
		protected var _direction:int;
		protected var _space:Number = 0;
		protected var _padding:Number = 0;
		protected var itemList:Array = [];
		
		public var isOpened:Boolean = false;
		
		public function Menu()
		{
			direction = HORIZONTAL;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			addEventListener(MouseEvent.CLICK, onItemClick);
			addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
			addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
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
			var target:DisplayObject = e.target as DisplayObject;
			while (target != stage)
			{
				if (target == this)
				{
					return;
				}
				target = target.parent;
			}
			close();
		}
		
		public function close():void
		{
			isOpened = false;
		}
		
		protected function onItemClick(e:MouseEvent):void
		{
			var item:IItemRenderer = e.target as IItemRenderer;
			if (item)
			{
				item.onClick();
				dispatchEvent(new ItemEvent(ItemEvent.SELECT, item.index, item.data));
			}
		}
		
		private function onItemOver(e:MouseEvent):void
		{
			var item:IItemRenderer = e.target as IItemRenderer;
			if (item)
			{
				item.onRollOver();
			}
		}
		
		private function onItemOut(e:MouseEvent):void
		{
			var item:IItemRenderer = e.target as IItemRenderer;
			if (item)
			{
				item.onRollOut();
			}
		}
		
		public function addItem(item:IItemRenderer):void
		{
			if (item)
			{
				var disObj:DisplayObject = item as DisplayObject;
				if (disObj)
				{
					item.index = itemList.length;
					item.parentComponent = this;
					itemList.push(disObj);
					addChild(disObj);
					HeartbeatManager.addUpdateCall(updateView);
				}
			}
		}
		
		public function delItem(index:uint):void
		{
			if (index < itemList.length)
			{
				var item:DisplayObject = itemList[index];
				if (item.parent == this)
				{
					removeChild(item);
				}
				itemList.splice(index, 1);
				HeartbeatManager.addUpdateCall(updateView);
			}
		}
		
		public function get direction():int
		{
			return _direction;
		}
		
		public function set direction(value:int):void
		{
			_direction = value;
			HeartbeatManager.addUpdateCall(updateView);
		}
		
		public function updateView():void
		{
			HeartbeatManager.removeUpdateCall(updateView);
			var lastItem:DisplayObject;
			for (var i:int = 0; i < itemList.length; ++i)
			{
				var item:DisplayObject = itemList[i];
				switch (_direction)
				{
				case HORIZONTAL:
					item.x = lastItem ? lastItem.x + lastItem.width + _space : _padding;
					item.y = _padding;
					break;
				case VERTICAL:
					item.x = _padding;
					item.y = lastItem ? lastItem.y + lastItem.height + _space : _padding;
					break;
				default:
					break;
				}
				lastItem = item;
			}
		}
		
		protected function clear():void
		{
			for (var i:int = 0; i < itemList.length; ++i)
			{
				var item:DisplayObject = itemList[i];
				if (item.parent == this)
				{
					removeChild(item);
				}
			}
			itemList.length = 0;
		}
	}
}