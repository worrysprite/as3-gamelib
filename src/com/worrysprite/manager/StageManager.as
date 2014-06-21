package com.worrysprite.manager
{
	import flash.display.Stage;
	/**
	 * 舞台视图管理器
	 * @author 王润智
	 */
	public class StageManager
	{
		private static var _globalStage:Stage;
		
		public static function init(stage:Stage):void
		{
			_globalStage = stage;
			HeartbeatManager.init(stage);
		}
		
		public static function get globalStage():Stage
		{
			return _globalStage;
		}
	}
}