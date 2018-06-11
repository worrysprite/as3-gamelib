package com.worrysprite.view.component.menu
{
	import com.worrysprite.manager.StageManager;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * 弹出式菜单
	 * @author WorrySprite
	 */
	public class PopupMenu extends Menu
	{
		
		public function PopupMenu()
		{
			direction = VERTICAL;
		}
		
		override protected function onItemClick(e:MouseEvent):void
		{
			super.onItemClick(e);
			close();
			e.stopImmediatePropagation();
		}
		
		public function popup(x:Number, y:Number, parent:DisplayObjectContainer = null):void
		{
			this.x = x;
			this.y = y;
			if (!parent)
			{
				parent = StageManager.globalStage;
			}
			parent.addChild(this);
		}
		
		override public function close():void
		{
			if (parent)
			{
				parent.removeChild(this);
			}
		}
	}
}