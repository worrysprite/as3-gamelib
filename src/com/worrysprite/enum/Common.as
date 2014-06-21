package com.worrysprite.enum
{
	import flash.filters.ColorMatrixFilter;
	/**
	 * 通用常量
	 * @author WorrySprite
	 */
	public class Common
	{
		/**
		 * 灰色滤镜
		 */
		static public const GRAY_FILTER:ColorMatrixFilter = new ColorMatrixFilter([0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0, 0, 0, 1, 0]);
		
		static public const DEFAULT_FONT:String = "_sans";
	}

}