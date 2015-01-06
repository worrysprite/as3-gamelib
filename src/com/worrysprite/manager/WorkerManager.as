package com.worrysprite.manager
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	/**
	 * 并发管理器
	 * @author WorrySprite
	 */
	public class WorkerManager
	{
		public static const listener:EventDispatcher = new EventDispatcher();
		
		private static const MAX_WORKERS:int = 5;
		private static var workers:Vector.<Worker>;
		
		private static var commandChannels:Vector.<MessageChannel>;
		private static var stateChannels:Vector.<MessageChannel>;
		private static var isBusy:Vector.<Boolean>;
		private static var lastFlag:int;
		
		public static function init(main:Sprite, numWorkers:int, onComplete:Function):void
		{
			if (!Worker.isSupported || !main || onComplete == null)
			{
				return;
			}
			var currentWorker:Worker = Worker.current;
			if (currentWorker.isPrimordial)
			{
				if (numWorkers > MAX_WORKERS)
				{
					numWorkers = MAX_WORKERS;
				}
				workers = new Vector.<Worker>(numWorkers);
				commandChannels = new Vector.<MessageChannel>(numWorkers);
				stateChannels = new Vector.<MessageChannel>(numWorkers);
				isBusy = new Vector.<Boolean>(numWorkers);
				var bytes:ByteArray = main.loaderInfo.bytes;
				var worker:Worker;
				var channel:MessageChannel;
				for (var i:int = 0; i < numWorkers; ++i)
				{
					worker = WorkerDomain.current.createWorker(bytes);
					workers[i] = worker;
					
					channel = currentWorker.createMessageChannel(worker);
					worker.setSharedProperty("commandChannel", channel);
					commandChannels[i] = channel;
					
					channel = worker.createMessageChannel(currentWorker);
					worker.setSharedProperty("stateChannel", channel);
					channel.addEventListener(Event.CHANNEL_MESSAGE, onStateChannelMessage);
					stateChannels[i] = channel;
					
					//worker.addEventListener(Event.WORKER_STATE, onWorkerState);
					worker.start();
				}
			}
			else
			{
				channel = Worker.current.getSharedProperty("commandChannel") as MessageChannel;
				channel.addEventListener(Event.CHANNEL_MESSAGE, onCommand);
			}
		}
		
		static public function workAtBackground(func:Function, params:Array = null):void
		{
			++lastFlag;
			for (var i:int = 0; i < isBusy.length; ++i)
			{
				if (!isBusy[i])
				{
					commandChannels[i].send([func, params, lastFlag]);
					return;
				}
			}
			commandChannels[int(Math.random() * isBusy.length)].send([func, params, lastFlag]);
		}
		
		static public function dispatchToMainThread(msg:Object):void
		{
			if (!Worker.current.isPrimordial)
			{
				var index:int = workers.indexOf(Worker.current);
				stateChannels[index].send(msg);
			}
		}
		
		//static private function onWorkerState(e:Event):void
		//{
			//var worker:Worker = e.currentTarget as Worker;
			//if (worker.state == WorkerState.RUNNING)
			//{
				//
			//}
		//}
		
		static private function onStateChannelMessage(e:Event):void
		{
			//var channel:MessageChannel = e.currentTarget as MessageChannel;
			//while (channel.messageAvailable)
			//{
				//
				//
				//listener.dispatchEvent(new ThreadEvent(ThreadEvent.THREAD_MESSAGE));
			//}
		}
		
		static private function onCommand(e:Event):void
		{
			//var channel:MessageChannel = e.currentTarget as MessageChannel;
			//while (channel.messageAvailable)
			//{
				//var arr:Array = channel.receive() as Array;
				//var func:Function = arr[0];
				//var params:Array = arr[1];
				//var flag:int = arr[2];
				//func.apply(params);
			//}
		}
	}
}