package com.worrysprite.model.timer
{
	import flash.utils.getTimer;
	/**
	 * 计时器vo
	 * @author 王润智
	 */
	public class TimerVo
	{
		public var lastTime:int;
		
		public var delay:int;
		
		public var repeat:int;
		
		public var callback:Function;
		
		public var params:Array;
		
		public function TimerVo(delay:int = 1000, callback:Function = null, repeat:int = int.MAX_VALUE, params:Array = null)
		{
			lastTime = getTimer();
			this.delay = delay;
			this.callback = callback;
			this.repeat = repeat;
			this.params = params;
		}
	}
}