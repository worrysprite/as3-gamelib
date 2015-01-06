package com.worrysprite.manager
{
	import com.worrysprite.enum.ExceptionEnum;
	import com.worrysprite.model.loader.URLLoaderVo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.System;
	/**
	 * 二进制数据加载管理
	 * @author 王润智
	 */
	public class BinaryLoaderManager
	{
		private static var _instance:BinaryLoaderManager;
		
		private static const IS_QUEUE_LOADING:String = "is_queue_loading";
		
		private var queueLoader:URLLoaderVo;	//队列加载器，重复利用
		private var queueRequest:URLRequest;	//队列请求，重复利用
		
		private var urlQueue:Vector.<String>;	//队列URL
		private var formatQueue:Vector.<String>;//队列格式
		
		private var callbackQueue:Object;		//队列回调函数
		private var callbackParamQueue:Object;	//队列回调参数
		private var queueIsLoading:Boolean;		//队列状态
		
		private var callbackMap:Object;			//并发加载回调函数
		private var callbackParamMap:Object;	//并发加载回调参数
		
		private var cache:Object;				//缓存
		private var needCache:Object;			//记录是否需要缓存
		
		public function BinaryLoaderManager()
		{
			if (_instance != null)
			{
				throw new Error(ExceptionEnum.getExceptionMsg(ExceptionEnum.SINGLETON_ERROR), ExceptionEnum.SINGLETON_ERROR);
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
			needCache = new Object();
			
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
		 * 队列加载，如果加载目标已经并发加载中，则只会将回调添加到并发加载中
		 * @param	url	加载地址
		 * @param	format	加载格式，URLLoaderDataFormat里的值
		 * @param	callback	回调函数，至少带一个Object类型的参数
		 * @param	callbackParams	回调函数参数
		 * @param	addCache	加入缓存，对于加载同一个URL多次调用，只要有一个调用使用加入缓存则会加入缓存
		 */
		public function queueLoad(url:String, format:String, callback:Function, callbackParams:Array = null, addCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !addCache))
			{
				return;
			}
			if (cache[url] == undefined) //未加载
			{
				cache[url] = IS_QUEUE_LOADING;
				urlQueue.push(url);
				formatQueue.push(format);
				needCache[url] = addCache;
				
				callbackQueue[url] = new <Function>[callback];
				callbackParamQueue[url] = new <Array>[callbackParams];
				if (!queueIsLoading)
				{
					queueIsLoading = true;
					loadNext();
				}
			}
			else if (cache[url] == IS_QUEUE_LOADING)
			{
				//正在队列中，不重复加载，只记录回调函数，等加载完成同时回调
				callbackQueue[url].push(callback);
				callbackParamQueue[url].push(callbackParams);
				needCache[url] ||= addCache;
			}
			else if (cache[url] is URLLoaderVo)
			{
				//正在单独加载中，不重复加载，记录回调函数，等加载完成同时回调
				callbackMap[url].push(callback);
				callbackParamMap[url].push(callbackParams);
				needCache[url] ||= addCache;
			}
			else	//有缓存
			{
				if (callback != null)
				{
					if (callbackParams == null)
					{
						callback(cache[url]);
					}
					else
					{
						callbackParams.unshift(cache[url]);
						callback.apply(null, callbackParams);
					}
				}
			}
		}
		
		/**
		 * 加载队列长度
		 */
		public function get queueLength():int
		{
			return urlQueue.length;
		}
		
		/**
		 * 队列正在处理的URL
		 */
		public function get processingURL():String
		{
			return queueRequest.url;
		}
		
		/**
		 * 立刻开启一个并发加载，如果URL在加载队列中则从队列中移除，如果format与队列加载中不一致，将使用本次调用的值
		 * @param	url	加载地址
		 * @param	format	加载格式，URLLoaderDataFormat里的值
		 * @param	callback	回调函数，至少带一个Object类型的参数
		 * @param	callbackParams	回调参数
		 * @param	addCache	加入缓存，对于加载同一个URL多次调用，只要有一个调用使用加入缓存则会加入缓存
		 */
		public function loadNow(url:String, format:String, callback:Function, callbackParams:Array = null, addCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !addCache))
			{
				return;
			}
			if (cache[url] == undefined)
			{
				//开启新的加载
				var loader:URLLoaderVo = new URLLoaderVo();
				loader.dataFormat = format;
				loader.addEventListener(Event.COMPLETE, onLoaded);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				cache[url] = loader;
				needCache[url] = addCache;
				
				callbackMap[url] = new <Function>[callback];
				callbackParamMap[url] = new <Array>[callbackParams];
				loader.load(new URLRequest(url));
			}
			else if (cache[url] == IS_QUEUE_LOADING)
			{
				//正在队列加载中，将队列中的加载记录移除，立即开启一个新的加载
				var index:int = urlQueue.indexOf(url);
				urlQueue.splice(index, 1);
				formatQueue.splice(index, 1);
				
				//取出队列中的回调列表
				var callbackList:Vector.<Function> = callbackQueue[url];
				callbackList.push(callback);
				var callbackParamList:Vector.<Array> = callbackParamQueue[url];
				callbackParamList.push(callbackParams);
				//移除队列中的记录
				delete cache[url];
				delete callbackQueue[url];
				delete callbackParamQueue[url];
				for (var i:int = 0; i < callbackList.length; ++i)
				{
					loadNow(url, format, callbackList[i], callbackParamList[i], addCache);
				}
			}
			else if (cache[url] is URLLoaderVo)
			{
				//正在单独加载中，只记录回调函数，等加载完成同时回调
				callbackMap[url].push(callback);
				callbackParamMap[url].push(callbackParams);
				needCache[url] ||= addCache;
			}
			else	//有缓存
			{
				if (callback != null)
				{
					if (callbackParams == null)
					{
						callback(cache[url]);
					}
					else
					{
						callbackParams.unshift(cache[url]);
						callback.apply(null, callbackParams);
					}
				}
			}
		}
		
		public function getDataFromCache(url:String):Object
		{
			return cache[url];
		}
		
		/**
		 * 清空缓存
		 */
		public function clearCache():void
		{
			for (var key:String in cache)
			{
				if (cache[key] == IS_QUEUE_LOADING || cache[key] is URLLoaderVo)
				{
					continue;
				}
				delete cache[key];
			}
			System.gc();
		}
		
		private function onLoaded(e:Event):void
		{
			var loader:URLLoaderVo = e.currentTarget as URLLoaderVo;
			var url:String = loader.url;
			var data:Object = loader.data;
			if (needCache[url])
			{
				cache[url] = data;
			}
			else
			{
				delete cache[url];
			}
			
			//取得回调列表
			var callbackList:Vector.<Function> = callbackMap[url];
			var paramsList:Vector.<Array> = callbackParamMap[url];
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.removeEventListener(Event.COMPLETE, onLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete needCache[url];
			delete callbackMap[url];
			delete callbackParamMap[url];
			
			//循环回调
			loopCallback(callbackList, paramsList, data);
		}
		
		private function onError(e:IOErrorEvent):void
		{
			var loader:URLLoaderVo = e.currentTarget as URLLoaderVo;
			var url:String = loader.url;
			trace("加载失败，url=", url);
			delete cache[url];
			delete needCache[url];
			
			//取得回调列表
			//var callbackList:Vector.<Function> = callbackMap[url];
			//var paramsList:Vector.<Array> = callbackParamMap[url];
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.removeEventListener(Event.COMPLETE, onLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete callbackMap[url];
			delete callbackParamMap[url];
			
			//加载失败也回调
			//loopCallback(callbackList, paramsList, null);
		}
		
		private function onQueueLoaded(e:Event):void
		{
			var url:String = queueRequest.url;
			var data:Object = queueLoader.data;
			if (needCache[url])
			{
				cache[url] = data;
			}
			else
			{
				delete cache[url];
			}
			delete needCache[url];
			//取出回调列表
			var callbackList:Vector.<Function> = callbackQueue[url];
			var paramsList:Vector.<Array> = callbackParamQueue[url];
			delete callbackQueue[url];
			delete callbackParamQueue[url];
			//先开始下一个加载
			loadNext();
			//循环回调
			loopCallback(callbackList, paramsList, data);
		}
		
		private function onQueueLoadError(e:IOErrorEvent):void
		{
			var url:String = queueRequest.url;
			delete cache[url];
			delete needCache[url];
			
			//var callbackList:Vector.<Function> = callbackQueue[url];
			//var paramsList:Vector.<Array> = callbackParamQueue[url];
			delete callbackQueue[url];
			delete callbackParamQueue[url];
			
			trace("队列加载失败，url=", url);
			loadNext();
			//加载失败依然回调
			//loopCallback(callbackList, paramsList, null);
		}
		
		private function loopCallback(callbackList:Vector.<Function>, paramsList:Vector.<Array>, data:Object):void
		{
			var callback:Function;
			var params:Array;
			for (var i:int = 0; i < callbackList.length; ++i)
			{
				callback = callbackList[i];
				if (callback != null)
				{
					params = paramsList[i];
					if (params == null)
					{
						callback(data);
					}
					else
					{
						params.unshift(data);
						callback.apply(null, params);
					}
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
				queueRequest.url = null;
				queueIsLoading = false;
			}
		}
	}
}