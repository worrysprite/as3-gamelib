package com.worrysprite.manager
{
	import com.worrysprite.model.layout.WinPosDataVo;
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	/**
	 * 窗口定位管理器
	 * @author worrysprite
	 */
	public class WinPosManager
	{
		public static const V_FREE:int = 0x00;
		public static const V_TOP:int = 0x01;
		public static const V_CENTER:int = 0x02;
		public static const V_BOTTOM:int = 0x04;
		public static const H_FREE:int = 0x00;
		public static const H_LEFT:int = 0x10;
		public static const H_CENTER:int = 0x20;
		public static const H_RIGHT:int = 0x40;
		private static const V_MASK:int = 0x0F;
		private static const H_MASK:int = 0xF0;
		private static var datas:Dictionary = new Dictionary(true);
		
		/**
		 * 注册一个窗口（显示对象）
		 * @param win 显示对象
		 * @param type 类型 在屏幕中心这样写：WinPosManager.V_CENTER | WinPosManager.H_CENTER
		 * @param hPixels
		 * @param vPixels
		 */
		public static function registerWin(win:DisplayObject, type:int = 0, hPixels:int = 0, vPixels:int = 0):void
		{
			var posData:WinPosDataVo = new WinPosDataVo(win, type, hPixels, vPixels);
			datas[win] = posData;
			if (win.stage)
			{
				setPos(posData);
			}
			else
			{
				win.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			}
		}

		public static function unregisterWin(win:DisplayObject):void
		{
			delete datas[win];
		}
		
		/**
		 * 直接设置窗口位置, 相对舞台
		 * @param win
		 * @param type
		 * @param hPixels
		 * @param vPixels
		 */
		public static function setWinPos(win:DisplayObject, type:int = 0, hPixels:int = 0, vPixels:int = 0):void
		{
			var posData:WinPosDataVo = new WinPosDataVo(win, type, hPixels, vPixels);
			setPos(posData);
		}
		
		public static function updatePos(win:DisplayObject):void
		{
			var posData:WinPosDataVo = datas[win] as WinPosDataVo;
			if (posData)
			{
				setPos(posData);
			}
		}
		
		private static function addedToStageHandler(e:Event):void
		{
			var win:DisplayObject = e.currentTarget as DisplayObject;
			if (win)
			{
				var posData:WinPosDataVo = datas[win] as WinPosDataVo;
				if (posData)
				{
					setPos(posData);
				}
			}
		}

		private static function setPos(posData:WinPosDataVo):void
		{
			var stage:Stage = posData.win.stage;
			if (stage == null)
			{
				return;
			}
			var type:int = posData.type;
			var pos:Point = new Point(posData.win.x, posData.win.y); // 坐标点
			var rect:Rectangle;
			if (posData.win.width == 0 || posData.win.height == 0)
			{
				var p:Point = posData.win.localToGlobal(new Point());
				rect = new Rectangle(p.x, p.y, 0, 0);
			}
			else
			{
				rect = posData.win.getRect(posData.win.parent); // 用于定位的矩形
			}
			var deltaPos:Point = pos.subtract(rect.topLeft); // 自身的偏移
			if ((WinPosManager.H_CENTER & type) == WinPosManager.H_CENTER)
			{
				rect.x = (stage.stageWidth - rect.width) * 0.5;
			}
			else if ((WinPosManager.H_LEFT & type) == WinPosManager.H_LEFT)
			{
				rect.x = 0;
			}
			else if ((WinPosManager.H_RIGHT & type) == WinPosManager.H_RIGHT)
			{
				rect.x = stage.stageWidth - rect.width;
			}
			if ((WinPosManager.V_CENTER & type) == WinPosManager.V_CENTER)
			{
				rect.y = (stage.stageHeight - rect.height) * 0.5;
			}
			else if ((WinPosManager.V_TOP & type) == WinPosManager.V_TOP)
			{
				rect.y = 0;
			}
			else if ((WinPosManager.V_BOTTOM & type) == WinPosManager.V_BOTTOM)
			{
				rect.y = stage.stageHeight - rect.height;
			}
			if ((type & WinPosManager.H_MASK) != 0)
			{
				posData.win.x = rect.x + deltaPos.x + posData.hPixels;
			}
			if ((type & WinPosManager.V_MASK) != 0)
			{
				posData.win.y = rect.y + deltaPos.y + posData.vPixels;
				if (posData.win.y < 0)
				{
					posData.win.y = 0;
				}
			}
		}

		private static function resizeHandler(e:Event):void
		{
			for each (var posData:WinPosDataVo in datas)
			{
				if (posData.win.stage != null) // 在舞台上的才调整位置
				{
					setPos(posData);
				}
			}
		}
	}
}
