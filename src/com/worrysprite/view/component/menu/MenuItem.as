package com.worrysprite.view.component.menu
{
	import com.worrysprite.interfaces.IItemRenderer;
	import com.worrysprite.view.component.TextButton;
	import flash.display.DisplayObject;
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class MenuItem extends TextButton implements IItemRenderer
	{
		private var _data:Object;
		private var _index:int;
		private var _parentComponent:DisplayObject;
		private var _subMenu:PopupMenu;
		
		public function MenuItem(data:Object = null)
		{
			this.data = data;
		}
		
		private function popup(parentMenu:Menu):void
		{
			if (_subMenu && parentMenu)
			{
				switch(parentMenu.direction)
				{
				case Menu.HORIZONTAL:
					_subMenu.popup(x, y + height, parentMenu);
					break;
				case Menu.VERTICAL:
					_subMenu.popup(x + width, y, parentMenu);
					break;
				}
				parentMenu.isOpened = true;
			}
		}
		
		public function onRollOver():void
		{
			background = true;
			backgroundColor = 0;
			textColor = 0xFFFFFF;
			var menu:Menu = _parentComponent as Menu;
			if (menu && menu.isOpened)
			{
				popup(menu);
			}
		}
		
		public function onRollOut():void
		{
			background = false;
			backgroundColor = 0xFFFFFF;
			textColor = 0;
			if (_subMenu)
			{
				_subMenu.close();
			}
		}
		
		public function onClick():void
		{
			var menu:Menu = _parentComponent as Menu;
			if (menu)
			{
				if (menu.isOpened)
				{
					if (_subMenu)
					{
						_subMenu.close();
					}
					menu.isOpened = false;
				}
				else
				{
					popup(menu);
				}
			}
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function set data(value:Object):void
		{
			_data = value;
			if (_data is String)
			{
				text = _data as String;
			}
		}
		
		public function get index():int
		{
			return _index;
		}
		
		public function set index(value:int):void
		{
			_index = value;
		}
		
		public function get parentComponent():DisplayObject
		{
			return _parentComponent;
		}
		
		public function set parentComponent(value:DisplayObject):void
		{
			_parentComponent = value;
		}
		
		public function get subMenu():PopupMenu
		{
			return _subMenu;
		}
		
		public function set subMenu(value:PopupMenu):void
		{
			_subMenu = value;
		}
	}

}