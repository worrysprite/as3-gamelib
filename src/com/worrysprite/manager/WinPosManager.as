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
	 * 窗口定位管理器，用于全局舞台坐标定位
	 * windows/panel position manager, locate by global stage coordinate
	 * @author worrysprite
	 */
	public final class WinPosManager
	{
		/**
		 * 垂直自由
		 * vertical free
		 */
		public static const V_FREE:int = 0x00;
		/**
		 * 垂直顶部
		 * vertical top
		 */
		public static const V_TOP:int = 0x01;
		/**
		 * 垂直居中
		 * vertical center
		 */
		public static const V_CENTER:int = 0x02;
		/**
		 * 垂直底部
		 * vertical bottom
		 */
		public static const V_BOTTOM:int = 0x04;
		/**
		 * 水平自由
		 * horizontal free
		 */
		public static const H_FREE:int = 0x00;
		/**
		 * 水平左部
		 * horizontal left
		 */
		public static const H_LEFT:int = 0x10;
		/**
		 * 水平居中
		 * horizontal center
		 */
		public static const H_CENTER:int = 0x20;
		/**
		 * 水平右部
		 * horizontal right
		 */
		public static const H_RIGHT:int = 0x40;
		
		private static const V_MASK:int = 0x0F;
		private static const H_MASK:int = 0xF0;
		private static var datas:Dictionary = new Dictionary(true);
		
		public static function init(stage:Stage):void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		
		/**
		 * 注册一个窗口布局（任意显示对象，窗口或面板或按钮控件）
		 * register a window layout(it can be any display object, windows or panels or button components)
		 * @param win 需要布局的显示对象
		 * the display object you want to layout
		 * @param layoutType 布局类型，在舞台中心这样写：WinPosManager.V_CENTER | WinPosManager.H_CENTER
		 * layout type, use <code>WinPosManager.V_CENTER | WinPosManager.H_CENTER</code> for center of the stage.
		 * @param hOffset 水平偏移量
		 * horizontal offset
		 * @param vOffset 垂直偏移量
		 * vertical offset
		 */
		public static function registerWin(win:DisplayObject, layoutType:int = 0, hOffset:int = 0, vOffset:int = 0):void
		{
			var posData:WinPosDataVo = new WinPosDataVo(win, layoutType, hOffset, vOffset);
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
		
		/**
		 * 取消注册一个窗口布局
		 * unregister a window layout
		 * @param	win	已经注册过的窗口
		 * the window already registered
		 */
		public static function unregisterWin(win:DisplayObject):void
		{
			delete datas[win];
		}
		
		/**
		 * 直接设置窗口布局
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
		
		/**
		 * 强制更新窗口布局
		 * @param	win
		 */
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
			var type:int = posData.layoutType;
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
				posData.win.x = rect.x + deltaPos.x + posData.hOffset;
			}
			if ((type & WinPosManager.V_MASK) != 0)
			{
				posData.win.y = rect.y + deltaPos.y + posData.vOffset;
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
