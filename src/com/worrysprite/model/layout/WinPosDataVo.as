package com.worrysprite.model.layout
{
	import flash.display.DisplayObject;

	/**
	 * 窗口定位数据
	 * @author worrysprite
	 */
	public class WinPosDataVo
	{
		/**
		 * 窗口-显示对象
		 * @default
		 */
		public var win:DisplayObject;
		/**
		 * 定位类型 WinPosManager定义的常量
		 * @default 自由定位
		 */
		public var type:int = 0;
		/**
		 * 距离基础定位点的横向偏移
		 * @default
		 */
		public var hPixels:int = 0;
		/**
		 * 距离基础定位点的纵向偏移
		 * @default
		 */
		public var vPixels:int = 0;
		/**
		 * 是否打开过
		 * @default
		 */
		public var hasOpen:Boolean = false;
		
		public function WinPosDataVo(win:DisplayObject = null, type:int = 0, hPixels:int = 0, vPixels:int = 0)
		{
			this.win = win;
			this.type = type;
			this.hPixels = hPixels;
			this.vPixels = vPixels;
		}
	}
}