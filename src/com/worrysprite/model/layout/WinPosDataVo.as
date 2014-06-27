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
		public var layoutType:int = 0;
		/**
		 * 距离基础定位点的横向偏移
		 * @default
		 */
		public var hOffset:int = 0;
		/**
		 * 距离基础定位点的纵向偏移
		 * @default
		 */
		public var vOffset:int = 0;
		/**
		 * 是否打开过
		 * @default
		 */
		public var hasOpened:Boolean = false;
		
		public function WinPosDataVo(win:DisplayObject = null, layoutType:int = 0, hOffset:int = 0, vOffset:int = 0)
		{
			this.win = win;
			this.layoutType = layoutType;
			this.hOffset = hOffset;
			this.vOffset = vOffset;
		}
	}
}