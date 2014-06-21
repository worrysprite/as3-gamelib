package com.worrysprite.enum
{
	/**
	 * 单位动作
	 * @author 王润智
	 */
	public class UnitActionEnum
	{
		private static const FRAME_COUNT_TABLE:Array = [];
		/**
		 * 攻击
		 */
		public static const ATTACK:int = 1;
		FRAME_COUNT_TABLE[ATTACK] = 8;
		/**
		 * 移动
		 */
		public static const RUN:int = 2;
		FRAME_COUNT_TABLE[RUN] = 8;
		/**
		 * 死亡
		 */
		public static const DIE:int = 3;
		FRAME_COUNT_TABLE[DIE] = 1;
		/**
		 * 动作总数
		 */
		public static const MAX_ACTION:int = 3;
		
		/**
		 * 获取帧数
		 * @param	type	单位类型
		 * @param	action	动作
		 * @return	该单位该动作的帧数
		 */
		public static function getFrameCount(action:int):int
		{
			return FRAME_COUNT_TABLE[action];
		}
	}
}