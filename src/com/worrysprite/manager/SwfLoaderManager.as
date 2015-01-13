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
	 * <p>图像加载管理器，使用<code>Loader</code>加载swf、jpg和png等作为显示对象使用</p>
	 * Image loader manager, use <code>Loader</code> to load swf, jpg and png as <code>DisplayObject</code>.
	 * @author WorrySprite
	 */
	public final class SwfLoaderManager
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
		/**
		 * <p>加载选项</p>
		 * Loader options
		 */
		public var loaderContext:LoaderContext;
		/**
		 * <p>图像加载管理器，使用<code>Loader</code>加载swf、jpg和png等作为显示对象使用</p>
		 * Image loader manager, use <code>Loader</code> to load swf, jpg and png as <code>DisplayObject</code>.
		 */
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
		
		/**
		 * <p>获取唯一实例</p>
		 * Get the single instance
		 */
		public static function getInstance():SwfLoaderManager
		{
			if (_instance == null)
			{
				_instance = new SwfLoaderManager();
			}
			return _instance;
		}
		
		/**
		 * <p>将url添加到队列加载，可以指定loaderContext供整个队列使用。如果目标url已经在队列中，或者正在独立加载，则保存回调函数，等待加载完成后一起回调。</p>
		 * Add the url into queue to load, use loaderContext for the whole queue. If target url is already in the queue or loading stand alone, the callback function will be saved and invoked together after loaded.
		 * @param	url	<p>加载地址</p>
		 * The url to be load
		 * @param	callback	<p>加载完成后的回调，不能为null，第一个参数必须是<code>DisplayObject</code>类型</p>。
		 * The callback on loaded, must be not null, the first parameter must be <code>DisplayObject</code>.
		 * @param	callbackParams	<p>回调函数参数</p>
		 * Parameters of the callback.
		 * @param	addCache	<p>添加缓存</p>
		 * Add loaded data into cache.
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
		 * <p>加载队列长度</p>
		 * Current length of the loading queue.
		 */
		public function get queueLength():int
		{
			return urlQueue.length;
		}
		
		/**
		 * <p>队列正在处理的URL</p>
		 * Current URL of the queue processing
		 */
		public function get processingURL():String
		{
			return queueRequest.url;
		}
		
		/**
		 * <p>立刻开启一个独立的加载。如果目标url已经在队列中，将从队列中移除该url的加载请求，并开启新的独立加载，原队列中的回调函数会在该独立加载完成时同时调用。如果目标url正在独立加载，则保存回调函数，等待加载完成后一起回调。</p>
		 * Starts a stand alone loader immediately. If target url is already in the queue, the request url in the queue will be removed and starts a new stand alone loader, the callbacks in the queue will be invoked together after the stand alone loader loaded. If target url is already loading stand alone, the callback function will be saved and invoked together after loaded.
		 * @param	url	<p>加载地址</p>
		 * The url to be load
		 * @param	callback	<p>加载完成后的回调，不能为null，第一个参数必须是<code>DisplayObject</code>类型</p>。
		 * The callback on loaded, must be not null, the first parameter must be <code>DisplayObject</code>.
		 * @param	callbackParams	<p>回调函数参数</p>
		 * Parameters of the callback.
		 * @param	context	<p>加载选项，若未设置则使用全局loaderContext</p>
		 * Loader options, use loaderContext if not set.
		 * @param	addCache	<p>添加缓存</p>
		 * Add loaded data into cache.
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
				//正在队列加载，从队列中移除开启新的独立加载
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
		
		/**
		 * <p>从缓存获取显示对象</p>
		 * Get <code>DisplayObject</code> from cache.
		 * @param	url	<p>缓存时的URL</p>
		 * The URL of caching.
		 */
		public function getDisplayObject(url:String):DisplayObject
		{
			return cache[url] as DisplayObject;
		}
		
		/**
		 * <p>清空缓存</p>
		 * Clear all cached DisplayObjects
		 */
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
		
		/**
		 * <p>从二进制字节数组加载</p>
		 * Load from binary bytes.
		 * @param	bytes	<p>要加载的字节数组</p>
		 * The binary bytes want to load.
		 * @param	callback	<p>加载完成后的回调，第一个参数必须是<code>DisplayObject</code>类型</p>。
		 * The callback on loaded, the first parameter must be <code>DisplayObject</code>.
		 * @param	callbackParams	<p>回调函数参数</p>
		 * Parameters of the callback.
		 * @param	context	<p>加载选项，若未设置则使用全局loaderContext</p>
		 * Loader options, use loaderContext if not set.
		 */
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