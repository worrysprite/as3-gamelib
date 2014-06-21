package com.worrysprite.manager
{
	import com.worrysprite.exception.SingletonError;
	import com.worrysprite.model.loader.URLLoaderVo;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	/**
	 * 二进制数据加载管理
	 * @author 王润智
	 */
	public class BinaryLoaderManager
	{
		private static var _instance:BinaryLoaderManager;
		
		private var queueLoader:URLLoaderVo;
		private var queueRequest:URLRequest;
		private var urlQueue:Vector.<String>;
		private var formatQueue:Vector.<String>;
		private var callbackQueue:Object;
		private var callbackParamQueue:Object;
		private var queueIsLoading:Boolean;
		
		private var callbackMap:Object;
		private var callbackParamMap:Object;
		
		private var cache:Object;
		
		public function BinaryLoaderManager()
		{
			if (_instance != null)
			{
				throw new SingletonError(SingletonError.INSTANCE_DUPLICATE);
			}
			_instance = this;
			init();
		}
		
		private function init():void
		{
			//初始化队列
			urlQueue = new Vector.<String>();
			formatQueue = new Vector.<String>();
			callbackQueue = new Object();
			callbackParamQueue = new Object();
			
			callbackMap = new Object();
			callbackParamMap = new Object();
			
			//初始化缓存
			cache = new Object();
			
			//初始化加载器和请求
			queueLoader = new URLLoaderVo();
			queueRequest = new URLRequest();
			queueLoader.addEventListener(Event.COMPLETE, onQueueLoaded);
			queueLoader.addEventListener(IOErrorEvent.IO_ERROR, onQueueLoadError);
		}
		
		public static function getInstance():BinaryLoaderManager
		{
			if (_instance == null)
			{
				_instance = new BinaryLoaderManager();
			}
			return _instance;
		}
		
		/**
		 * 队列加载
		 * @param	url	加载地址
		 * @param	callback	加载完成后的回调
		 * @param	callbackParams	回调函数参数
		 */
		public function queueLoad(url:String, format:String, callback:Function, callbackParams:Array = null):void
		{
			if (url == null)
			{
				return;
			}
			if (cache[url] == undefined) //未加载
			{
				cache[url] = "loading";
				urlQueue.push(url);
				formatQueue.push(format);
				callbackQueue[url] = new <Function>[callback];
				callbackParamQueue[url] = new <Array>[callbackParams];
				if (!queueIsLoading)
				{
					queueIsLoading = true;
					loadNext();
				}
			}
			else if (cache[url] == "loading" || cache[url] is URLLoaderVo)
			{
				//正在加载，不重复加载，只记录回调函数，等加载完成同时回调
				callbackQueue[url].push(callback);
				callbackParamQueue[url].push(callbackParams);
				return;
			}
		}
		
		/**
		 * 加载队列长度
		 */
		public function get queueLength():int
		{
			return urlQueue.length;
		}
		
		public function loadNow(url:String, format:String, callback:Function, callbackParams:Array = null):void
		{
			if (url == null)
			{
				return;
			}
			if (cache[url] == undefined)
			{
				var loader:URLLoaderVo = new URLLoaderVo();
				loader.dataFormat = format;
				loader.addEventListener(Event.COMPLETE, onLoaded);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				cache[url] = loader;
				callbackMap[url] = callback;
				callbackParamMap[url] = callbackParams;
				loader.load(new URLRequest(url));
			}
			else if (cache[url] == "loading" || cache[url] is Loader)
			{
				return;
			}
		}
		
		private function onLoaded(e:Event):void
		{
			var loader:URLLoaderVo = e.currentTarget as URLLoaderVo;
			var callback:Function = callbackMap[loader.url];
			var params:Array = callbackParamMap[loader.url];
			if (callback != null)
			{
				if (params == null)
				{
					params = [];
				}
				params.unshift(loader.data);
				
				callback.apply(null, params);
			}
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.removeEventListener(Event.COMPLETE, onLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete cache[loader.url];
			delete callbackMap[loader.url];
			delete callbackParamMap[loader.url];
		}
		
		private function onError(e:IOErrorEvent):void
		{
			var loader:URLLoaderVo = e.currentTarget as URLLoaderVo;
			trace(e.toString());
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.removeEventListener(Event.COMPLETE, onLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete cache[loader.url];
			delete callbackMap[loader.url];
			delete callbackParamMap[loader.url];
		}
		
		private function onQueueLoaded(e:Event):void
		{
			var url:String = queueRequest.url;
			delete cache[url];
			
			var callbackList:Vector.<Function> = callbackQueue[url];
			var paramsList:Vector.<Array> = callbackParamQueue[url];
			delete callbackQueue[url];
			delete callbackParamQueue[url];
			
			loadNext();
			
			var callback:Function;
			var params:Array;
			for (var i:int = 0; i < callbackList.length; ++i)
			{
				callback = callbackList[i];
				params = paramsList[i];
				if (callback != null)
				{
					if (params == null)
					{
						params = [];
					}
					params.unshift(queueLoader.data);
					callback.apply(null, params);
				}
			}
		}
		
		private function onQueueLoadError(e:IOErrorEvent):void
		{
			var url:String = queueRequest.url;
			delete cache[url];
			
			var callbackList:Vector.<Function> = callbackQueue[url];
			var paramsList:Vector.<Array> = callbackParamQueue[url];
			delete callbackQueue[url];
			delete callbackParamQueue[url];
			
			trace("队列加载失败，url =", queueRequest.url);
			loadNext();
			
			var callback:Function;
			var params:Array;
			for (var i:int = 0; i < callbackList.length; ++i)
			{
				callback = callbackList[i];
				params = paramsList[i];
				if (callback != null)
				{
					if (params == null)
					{
						params = [];
					}
					params.unshift(null);
					callback.apply(null, params);
				}
			}
		}
		
		private function loadNext():void
		{
			if (urlQueue.length)
			{
				queueLoader.dataFormat = formatQueue.shift();
				queueRequest.url = urlQueue.shift();
				queueLoader.load(queueRequest);
			}
			else
			{
				queueIsLoading = false;
			}
		}
	}
}