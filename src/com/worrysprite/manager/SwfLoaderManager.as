package com.worrysprite.manager
{
	import com.worrysprite.enum.ExceptionEnum;
	import com.worrysprite.model.loader.LoaderVo;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.System;
	import flash.utils.ByteArray;
	/**
	 * SWF加载管理器
	 * @author 王润智
	 */
	public class SwfLoaderManager
	{
		private static var _instance:SwfLoaderManager;
		
		private static const IS_QUEUE_LOADING:String = "is_queue_loading";
		
		private var queueLoader:LoaderVo;
		private var queueRequest:URLRequest;
		private var urlQueue:Vector.<String>;
		private var callbackQueue:Object;
		private var callbackParamQueue:Object;
		private var queueIsLoading:Boolean;
		
		private var callbackMap:Object;
		private var callbackParamMap:Object;
		
		private var cache:Object;
		private var needCache:Object;
		
		private var bytesLoaderInfos:Vector.<LoaderInfo>;
		private var bytesCallback:Vector.<Function>;
		private var bytesCallbackParams:Vector.<Array>;
		
		public var loaderContext:LoaderContext;
		
		public function SwfLoaderManager()
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
			callbackQueue = new Object();
			callbackParamQueue = new Object();
			
			callbackMap = new Object();
			callbackParamMap = new Object();
			
			//初始化缓存
			cache = new Object();
			needCache = new Object();
			
			bytesLoaderInfos = new Vector.<LoaderInfo>();
			bytesCallback = new Vector.<Function>();
			bytesCallbackParams = new Vector.<Array>();
			
			//初始化加载器和请求
			queueLoader = new LoaderVo();
			queueRequest = new URLRequest();
			queueLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onQueueLoaded);
			queueLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onQueueLoadError);
		}
		
		public static function getInstance():SwfLoaderManager
		{
			if (_instance == null)
			{
				_instance = new SwfLoaderManager();
			}
			return _instance;
		}
		
		/**
		 * 队列加载，可以指定全局loaderContext供整个队列使用
		 * @param	url	加载地址
		 * @param	callback	加载完成后的回调
		 * @param	callbackParams	回调函数参数
		 * @param	addCache	添加缓存
		 */
		public function queueLoad(url:String, callback:Function, callbackParams:Array = null, addCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !addCache))
			{
				return;
			}
			if (cache[url] is DisplayObject)	//有缓存
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
			else if (cache[url] == undefined) //未加载
			{
				cache[url] = IS_QUEUE_LOADING;
				urlQueue.push(url);
				callbackQueue[url] = new <Function>[callback];
				callbackParamQueue[url] = new <Array>[callbackParams];
				needCache[url] = addCache;
				if (!queueIsLoading)
				{
					queueIsLoading = true;
					loadNext();
				}
			}
			else if (cache[url] == IS_QUEUE_LOADING)
			{
				//正在队列加载，不重复加载，只记录回调函数，等加载完成同时回调
				callbackQueue[url].push(callback);
				callbackParamQueue[url].push(callbackParams);
				needCache[url] ||= addCache;
			}
			else if (cache[url] is LoaderVo)
			{
				//正在单独加载，记录回调函数，等加载完成后同时回调
				callbackMap[url].push(callback);
				callbackParamMap[url].push(callbackParams);
				needCache[url] ||= addCache;
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
		 * 立刻开启一个并发加载
		 * @param	url	加载地址
		 * @param	callback	回调函数
		 * @param	callbackParams	回调函数参数
		 * @param	context	加载选项，若未设置则使用全局loaderContext
		 * @param	addCache	添加缓存
		 */
		public function loadNow(url:String, callback:Function, callbackParams:Array = null, context:LoaderContext = null, addCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !addCache))
			{
				return;
			}
			if (cache[url] is DisplayObject)	//有缓存
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
			else if (cache[url] == undefined)
			{
				var loader:LoaderVo = new LoaderVo();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
				if (context == null)
				{
					context = loaderContext;
				}
				cache[url] = loader;
				callbackMap[url] = new <Function>[callback];
				callbackParamMap[url] = new <Array>[callbackParams];
				needCache[url] = addCache;
				loader.load(new URLRequest(url), context);
			}
			else if (cache[url] == IS_QUEUE_LOADING)
			{
				//正在队列加载，从队列中移除开启新的并发加载
				var index:int = urlQueue.indexOf(url);
				urlQueue.splice(index, 1);
				
				//取出队列里的回调列表
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
					loadNow(url, callbackList[i], callbackParamList[i], context, addCache);
				}
			}
			else if(cache[url] is LoaderVo)
			{
				//正在单独加载，记录回调函数，等加载完成后同时回调
				callbackMap[url].push(callback);
				callbackParamMap[url].push(callbackParams);
				needCache[url] ||= addCache;
			}
		}
		
		public function getDisplayObject(url:String):DisplayObject
		{
			return cache[url] as DisplayObject;
		}
		
		public function clearCache():void
		{
			for (var key:String in cache)
			{
				if (cache[key] is DisplayObject)
				{
					delete cache[key];
				}
			}
			System.gc();
		}
		
		public function loadBytes(bytes:ByteArray, callback:Function, callbackParams:Array = null, context:LoaderContext = null):void
		{
			if (!bytes || callback == null)
			{
				return;
			}
			
			var loader:LoaderVo = new LoaderVo();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBytesLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onBytesLoadError);
			if (context == null)
			{
				context = loaderContext;
			}
			bytesLoaderInfos.push(loader.contentLoaderInfo);
			bytesCallback.push(callback);
			bytesCallbackParams.push(callbackParams);
			loader.loadBytes(bytes, context);
		}
		
		private function onLoaded(e:Event):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			info.removeEventListener(Event.COMPLETE, onLoaded);
			info.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			
			var loader:LoaderVo = info.loader as LoaderVo;
			var url:String = loader.url;
			trace("加载成功", url);
			var displayObj:DisplayObject = loader.content;
			if (needCache[url])
			{
				cache[url] = displayObj;
			}
			else
			{
				delete cache[url];
			}
			delete needCache[url];
			var mc:MovieClip = displayObj as MovieClip;
			if (mc)
			{
				mc.stop();
			}
			var callbackList:Vector.<Function> = callbackMap[url];
			var paramsList:Vector.<Array> = callbackParamMap[url];
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.unload();
			delete callbackMap[url];
			delete callbackParamMap[url];
			//循环回调
			loopCallback(callbackList, paramsList, displayObj);
		}
		
		private function onError(e:IOErrorEvent):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			info.removeEventListener(Event.COMPLETE, onLoaded);
			info.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			
			var loader:LoaderVo = info.loader as LoaderVo;
			var url:String = loader.url;
			trace("加载失败", url);
			delete cache[url];
			delete needCache[url];
			
			//卸载资源并移除侦听，删除回调函数的引用
			loader.unload();
			delete callbackMap[url];
			delete callbackParamMap[url];
		}
		
		private function onQueueLoaded(e:Event):void
		{
			var displayObj:DisplayObject = queueLoader.content;
			var url:String = queueRequest.url;
			if (needCache[url])
			{
				cache[url] = displayObj;
			}
			else
			{
				delete cache[url];
			}
			delete needCache[url];
			var mc:MovieClip = displayObj as MovieClip;
			if (mc)
			{
				mc.stop();
			}
			
			var callbackList:Vector.<Function> = callbackQueue[queueRequest.url];
			var paramsList:Vector.<Array> = callbackParamQueue[queueRequest.url];
			delete callbackQueue[queueRequest.url];
			delete callbackParamQueue[queueRequest.url];
			
			queueLoader.unload();
			loadNext();
			
			loopCallback(callbackList, paramsList, displayObj);
		}
		
		private function onQueueLoadError(e:IOErrorEvent):void
		{
			var url:String = queueRequest.url;
			trace("队列加载失败，url =", queueRequest.url);
			delete cache[url];
			delete needCache[url];
			delete callbackQueue[url];
			delete callbackParamQueue[url];
			loadNext();
		}
		
		private function onBytesLoaded(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.currentTarget as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, onBytesLoaded);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onBytesLoadError);
			var index:int = bytesLoaderInfos.indexOf(loaderInfo);
			if (index >= 0)
			{
				var callback:Function = bytesCallback.splice(index, 1)[0];
				var callbackParams:Array = bytesCallbackParams.splice(index, 1)[0];
				bytesLoaderInfos.splice(index, 1);
				if (callbackParams)
				{
					callbackParams.unshift(loaderInfo.content);
					callback.apply(null, callbackParams);
				}
				else
				{
					callback(loaderInfo.content);
				}
			}
		}
		
		private function onBytesLoadError(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.currentTarget as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, onBytesLoaded);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onBytesLoadError);
			var index:int = bytesLoaderInfos.indexOf(loaderInfo);
			if (index >= 0)
			{
				bytesCallback.splice(index, 1);
				bytesCallbackParams.splice(index, 1);
				bytesLoaderInfos.splice(index, 1);
			}
		}
		
		private function loopCallback(callbackList:Vector.<Function>, paramsList:Vector.<Array>, data:DisplayObject):void
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
				queueRequest.url = urlQueue.shift();
				queueLoader.load(queueRequest, loaderContext);
			}
			else
			{
				queueRequest.url = null;
				queueIsLoading = false;
			}
		}
	}
}