package com.worrysprite.manager
{
	import com.worrysprite.exception.SingletonError;
	import com.worrysprite.model.loader.LoaderVo;
	import com.worrysprite.model.swf.SwfDataVo;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
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
		
		private var queueLoader:LoaderVo;
		private var queueRequest:URLRequest;
		private var _loaderContext:LoaderContext;
		private var urlQueue:Vector.<String>;
		private var bytesQueue:Vector.<ByteArray>;
		private var callbackQueue:Object;
		private var callbackParamQueue:Object;
		private var queueIsLoading:Boolean;
		
		private var callbackMap:Object;
		private var callbackParamMap:Object;
		
		private var cache:Object;
		
		public function SwfLoaderManager()
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
			bytesQueue = new Vector.<ByteArray>();
			callbackQueue = new Object();
			callbackParamQueue = new Object();
			
			callbackMap = new Object();
			callbackParamMap = new Object();
			
			//初始化缓存
			cache = new Object();
			
			//初始化加载器和请求
			queueLoader = new LoaderVo();
			queueRequest = new URLRequest();
			_loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
			_loaderContext.allowCodeImport = true;
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
		 * 队列加载
		 * @param	url	加载地址
		 * @param	callback	加载完成后的回调
		 * @param	callbackParams	回调函数参数
		 */
		public function queueLoad(url:String, callback:Function, callbackParams:Array = null, bytes:ByteArray = null):void
		{
			if (url == null)
			{
				return;
			}
			if (cache[url] == undefined) //未加载
			{
				cache[url] = "loading";
				urlQueue.push(url);
				bytesQueue.push(bytes);
				callbackQueue[url] = new <Function>[callback];
				callbackParamQueue[url] = new <Array>[callbackParams];
				if (!queueIsLoading)
				{
					queueIsLoading = true;
					loadNext();
				}
			}
			else if (cache[url] == "loading" || cache[url] is LoaderVo)
			{
				//正在加载，不重复加载，只记录回调函数，等加载完成同时回调
				callbackQueue[url].push(callback);
				callbackParamQueue[url].push(callbackParams);
				return;
			}
			else if (cache[url] is SwfDataVo)//已经加载过
			{
				if (callback != null)
				{
					callback.apply(null, callbackParams);
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
		
		public function get loaderContext():LoaderContext
		{
			return _loaderContext;
		}
		
		public function loadNow(url:String, callback:Function, callbackParams:Array = null, context:LoaderContext = null):void
		{
			if (url == null)
			{
				return;
			}
			if (cache[url] == undefined)
			{
				var loader:LoaderVo = new LoaderVo();
				loader.url = url;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
				if (context == null)
				{
					context = _loaderContext;
				}
				cache[url] = loader;
				callbackMap[url] = callback;
				callbackParamMap[url] = callbackParams;
				loader.load(new URLRequest(url), context);
			}
			else if (cache[url] == "loading" || cache[url] is LoaderVo)
			{
				return;
			}
			else if (cache[url] is SwfDataVo)
			{
				callback.apply(null, callbackParams);
			}
		}
		
		public function getSwf(url:String):SwfDataVo
		{
			return cache[url] as SwfDataVo;
		}
		
		public function clearCache():void
		{
			for (var key:String in cache)
			{
				if (cache[key] is SwfDataVo)
				{
					delete cache[key];
				}
			}
			System.gc();
		}
		
		private function onLoaded(e:Event):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			var loader:LoaderVo = info.loader as LoaderVo;
			//var originURL:String = "";
			trace(loader.url, "加载成功");
			var mc:MovieClip = loader.content as MovieClip;
			if (mc)
			{
				mc.stop();
				cache[loader.url] = new SwfDataVo(mc);
				var callback:Function = callbackMap[loader.url];
				var params:Array = callbackParamMap[loader.url];
				if (callback != null)
				{
					callback.apply(null, params);
				}
			}
			//卸载资源并移除侦听，删除回调函数的引用
			loader.unload();
			info.removeEventListener(Event.COMPLETE, onLoaded);
			info.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete callbackMap[loader.url];
			delete callbackParamMap[loader.url];
		}
		
		private function onError(e:IOErrorEvent):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			trace(e.toString());
			
			//卸载资源并移除侦听，删除回调函数的引用
			info.loader.unload();
			info.removeEventListener(Event.COMPLETE, onLoaded);
			info.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			delete callbackMap[info.url];
			delete callbackParamMap[info.url];
		}
		
		private function onQueueLoaded(e:Event):void
		{
			var mc:MovieClip = queueLoader.content as MovieClip;
			if (mc)
			{
				mc.stop();
				cache[queueRequest.url] = new SwfDataVo(mc);
			}
			
			var callbackList:Vector.<Function> = callbackQueue[queueRequest.url];
			var paramsList:Vector.<Array> = callbackParamQueue[queueRequest.url];
			delete callbackQueue[queueRequest.url];
			delete callbackParamQueue[queueRequest.url];
			
			queueLoader.unload();
			loadNext();
			if (mc)
			{
				var callback:Function;
				var params:Array;
				for (var i:int = 0; i < callbackList.length; ++i)
				{
					callback = callbackList[i];
					params = paramsList[i];
					if (callback != null)
					{
						callback.apply(null, params);
					}
				}
			}
		}
		
		private function onQueueLoadError(e:IOErrorEvent):void
		{
			trace("队列加载失败，url =", queueRequest.url);
			delete cache[queueRequest.url];
			delete callbackQueue[queueRequest.url];
			delete callbackParamQueue[queueRequest.url];
			loadNext();
		}
		
		private function loadNext():void
		{
			if (urlQueue.length)
			{
				queueRequest.url = urlQueue.shift();
				var bytes:ByteArray = bytesQueue.shift();
				if (bytes)
				{
					queueLoader.loadBytes(bytes, _loaderContext);
				}
				else
				{
					queueLoader.load(queueRequest, _loaderContext);
				}
			}
			else
			{
				queueIsLoading = false;
			}
		}
	}
}