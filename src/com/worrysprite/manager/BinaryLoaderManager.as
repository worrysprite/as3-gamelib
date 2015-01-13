package com.worrysprite.manager
{
	import com.worrysprite.enum.ExceptionEnum;
	import com.worrysprite.model.loader.URLLoaderVo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.System;
	/**
	 * <p>二进制数据加载管理</p>
	 * Binary loader manager
	 * @author WorrySprite
	 */
	public final class BinaryLoaderManager
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
		
		/**
		 * <p>二进制数据加载管理</p>
		 * Binary loader manager
		 */
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
		
		/**
		 * <p>获取唯一实例</p>
		 * Get the single instance
		 */
		public static function getInstance():BinaryLoaderManager
		{
			if (_instance == null)
			{
				_instance = new BinaryLoaderManager();
			}
			return _instance;
		}
		
		/**
		 * <p>将url添加到队列加载。如果目标url已经在队列中，或者正在独立加载，则保存回调函数，等待加载完成后一起回调。</p>
		 * Add the url into queue to load. If target url is already in the queue or loading stand alone, the callback function will be saved and invoke together after loaded.
		 * @param	url	<p>加载地址</p>
		 * The url to be load
		 * @param	format	<p>数据格式，<code>URLLoaderDataFormat</code>里的值</p>
		 * Data format, values in <code>URLLoaderDataFormat</code>
		 * @param	callback	<p>加载完成后的回调，不能为null，至少带一个Object类型的参数</p>
		 * The callback on loaded, must be not null, the first parameter must be <code>Object</code>.
		 * @param	callbackParams	<p>回调函数参数</p>
		 * Parameters of the callback.
		 * @param	addCache	<p>添加缓存</p>
		 * Add loaded data into cache.
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
		 * <p>立刻开启一个独立的加载。如果目标url已经在队列中，将从队列中移除该url的加载请求，并开启新的独立加载（如果format与队列加载时的不一致，将使用本次传递的值），原队列中的回调函数会在该独立加载完成时同时调用。如果目标url正在独立加载，则保存回调函数，等待加载完成后一起回调。</p>
		 * Starts a stand alone loader immediately. If target url is already in the queue, the request url in the queue will be removed and starts a new stand alone loader(if the format parameter in queue is different from this invoke, it will use the value passed by this invoke.), the callbacks in the queue will be invoked together after the stand alone loader loaded. If target url is already loading stand alone, the callback function will be saved and invoked together after loaded.
		 * @param	url	<p>加载地址</p>
		 * The url to be load
		 * @param	format	<p>数据格式，<code>URLLoaderDataFormat</code>里的值</p>
		 * Data format, values in <code>URLLoaderDataFormat</code>
		 * @param	callback	<p>加载完成后的回调，不能为null，至少带一个Object类型的参数</p>
		 * The callback on loaded, must be not null, the first parameter must be <code>Object</code>.
		 * @param	callbackParams	<p>回调函数参数</p>
		 * Parameters of the callback.
		 * @param	addCache	<p>添加缓存</p>
		 * Add loaded data into cache.
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
		
		/**
		 * <p>从缓存获取数据</p>
		 * Get data from cache.
		 * @param	url	<p>缓存时的URL</p>
		 * The URL of caching.
		 */
		public function getDataFromCache(url:String):Object
		{
			return cache[url];
		}
		
		/**
		 * <p>清空缓存</p>
		 * Clear all cached datas
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