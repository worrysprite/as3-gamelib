package com.worrysprite.model.image
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * 动作VO
	 * Action value object
	 * @author WorrySprite
	 */
	public class ActionVo
	{
		/**
		 * 从0开始的索引
		 * Index starts from 0.
		 */
		public var index:int;
		/**
		 * 图片文件夹，播放时作为动作名
		 * Image directory, use as action name when playing.
		 */
		public var directory:String;
		/**
		 * 帧间隔(毫秒)
		 * Frame interval(millisecond)
		 */
		public var interval:uint;
		/**
		 * 序列图片
		 * Sequence bitmaps.
		 */
		public var bitmaps:Vector.<BitmapData>;
		/**
		 * 偏移X
		 * Offset x of every frame
		 */
		public var offsetXs:Vector.<int>;
		/**
		 * 偏移Y
		 * Offset y of every frame
		 */
		public var offsetYs:Vector.<int>;
		
		public function ActionVo()
		{
			
		}
	}
}