package com.worrysprite.manager
{
	import com.worrysprite.model.timer.TimerVo;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	/**
	 * 心跳管理
	 * @author 王润智
	 */
	public class HeartbeatManager
	{
		private static var frameTime:int;
		private static var lastTime:int;
		private static var processTimer:TimerVo;
		private static var stopTimer:Boolean;
		
		private static const allTimers:Dictionary = new Dictionary();
		private static const frameCalls:Dictionary = new Dictionary();
		private static var updateCalls:Dictionary = new Dictionary();
		
		public static function init(stage:Stage):void
		{
			if (stage)
			{
				lastTime = getTimer();
				stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				frameTime = 1000 / stage.frameRate;
			}
		}
		
		static private function onEnterFrame(e:Event):void
		{
			var now:int = getTimer();
			var call:*;
			while (lastTime + frameTime <= now)
			{
				for (call in frameCalls)
				{
					call.apply(null, frameCalls[call]);
				}
				for (call in updateCalls)
				{
					call.apply(null, updateCalls[call]);
				}
				updateCalls = new Dictionary();
				lastTime += frameTime;
			}
			for (call in allTimers)
			{
				processTimer = allTimers[call];
				while (processTimer.lastTime + processTimer.delay <= now)
				{
					if (stopTimer)	//在执行回调的过程中被removeTimeCall了
					{
						stopTimer = false;
						break;
					}
					processTimer.callback.apply(null, processTimer.params);
					if (--processTimer.repeat < 0)	//重复次数完成
					{
						delete allTimers[call];
						break;
					}
					processTimer.lastTime += processTimer.delay;
				}
			}
			processTimer = null;
		}
		
		/**
		 * 增加帧回调
		 * @param	call
		 * @param	params
		 */
		static public function addFrameCall(call:Function, params:Array = null):void
		{
			frameCalls[call] = params;
		}
		
		/**
		 * 移除帧回调
		 * @param	call
		 */
		static public function removeFrameCall(call:Function):void
		{
			delete frameCalls[call];
		}
		
		/**
		 * 增加一个计时回调
		 * @param	time	间隔毫秒数
		 * @param	call	回调函数
		 * @param	repeat	重复次数
		 * @param	params	回调参数
		 */
		static public function addTimeCall(time:int, call:Function, repeat:int = int.MAX_VALUE, params:Array = null):void
		{
			allTimers[call] = new TimerVo(time, call, repeat, params);
		}
		
		/**
		 * 移除一个计时回调
		 * @param	call
		 */
		static public function removeTimeCall(call:Function):void
		{
			if (processTimer && allTimers[call] == processTimer)
			{
				stopTimer = true;
			}
			delete allTimers[call];
		}
		
		/**
		 * 添加下一帧的回调，通常用于对象多个属性修改时暂不重新计算，而只是标记属性改变，等到下一帧才应用属性来刷新数据或显示
		 * @param	call	回调函数
		 * @param	params	回调参数
		 */
		static public function addUpdateCall(call:Function, params:Array = null):void
		{
			updateCalls[call] = params;
		}
		
		static public function removeUpdateCall(call:Function):void
		{
			delete updateCalls[call];
		}
	}
}