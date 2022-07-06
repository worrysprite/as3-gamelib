package com.worrysprite.manager
{
	import com.worrysprite.enum.ExceptionEnum;
	import com.worrysprite.model.loader.DataLoader;
	import com.worrysprite.model.loader.ImageLoader;
	import com.worrysprite.model.loader.LoaderRequest;
	import flash.system.LoaderContext;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	/**
	 * <p>加载管理器，内置队列加载和独立加载</p>
	 * Loader manager
	 * @author WorrySprite
	 */
	public final class LoaderManager
	{
		private static var _instance:LoaderManager;
		private var cache:Dictionary;			//缓存
		
		/**
		 * <p>加载选项</p>
		 * Loader options
		 */
		public var loaderContext:LoaderContext;
		
		/**
		 * <p>加载管理器</p>
		 * Loader manager
		 */
		public function LoaderManager()
		{
			if (_instance != null)
			{
				throw new Error(ExceptionEnum.getExceptionMsg(ExceptionEnum.SINGLETON_ERROR), ExceptionEnum.SINGLETON_ERROR);
			}
			_instance = this;
			//初始化缓存
			cache = new Dictionary();
		}
		
		/**
		 * <p>获取唯一实例</p>
		 * Get the single instance
		 */
		public static function getInstance():LoaderManager
		{
			if (_instance == null)
			{
				_instance = new LoaderManager();
			}
			return _instance;
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
		 * @param	needCache	<p>添加缓存</p>
		 * Add loaded data into cache.
		 */
		public function loadNow(url:String, format:String, callback:Function, callbackParams:Array = null, needCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !needCache))
			{
				return;
			}
			
			var obj:Object = cache[url];
			if (!obj || obj is LoaderRequest)
			{
				var request:LoaderRequest = obj as LoaderRequest;
				if (!request)
				{
					request = new LoaderRequest();
					request.url = url;
					request.format = format;
					request.onLoaded = onLoaded;
					request.onError = onError;
					request.params = [];
					cache[url] = request;
				}
				request.cache ||= needCache;
				var callbacks:Array = request.params as Array;
				callbacks.push({"callback": callback, "params": callbackParams});
				if (callbacks.length == 1)
				{
					if (request.format == "image")
					{
						var imgLoader:ImageLoader = new ImageLoader();
						imgLoader.request = request;
						imgLoader.startLoad(loaderContext);
					}
					else
					{
						var dataLoader:DataLoader = new DataLoader();
						dataLoader.request = request;
						dataLoader.startLoad();
					}
				}
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
		
		public function loadImage(url:String, callback:Function, callbackParams:Array = null, needCache:Boolean = false):void
		{
			loadNow(url, "image", callback, callbackParams, needCache);
		}
		
		public function loadImageBytes(bytes:ByteArray, callback:Function, callbackParams:Array = null):void
		{
			var request:LoaderRequest = new LoaderRequest();
			request.onLoaded = onLoaded;
			request.onError = onError;
			request.format = "image";
			request.params = [{"callback": callback, "params": callbackParams}];
			
			var imgLoader:ImageLoader = new ImageLoader();
			imgLoader.request = request;
			imgLoader.loadBytes(bytes, loaderContext);
		}
		
		/**
		 * <p>从缓存获取数据</p>
		 * Get data from cache.
		 * @param	url	<p>缓存时的URL</p>
		 * The URL of caching.
		 */
		public function getCache(url:String):Object
		{
			return cache[url];
		}
		
		public function addCache(url:String, data:Object):void
		{
			cache[url] = data;
		}
		
		/**
		 * <p>清空缓存</p>
		 * Clear all cached datas
		 */
		public function clearCache():void
		{
			for (var key:String in cache)
			{
				if (cache[key] is DataLoader)
				{
					continue;
				}
				delete cache[key];
			}
			System.gc();
		}
		
		private function onLoaded(obj:Object):void
		{
			var request:LoaderRequest = obj.request;
			var data:Object;
			if (obj.format == "image")
			{
				var imgLoader:ImageLoader = obj as ImageLoader;
				data = imgLoader.content;
			}
			else
			{
				var loader:DataLoader = obj as DataLoader;
				data = loader.data;
			}
			
			if (request.cache)
			{
				addCache(request.url, data);
			}
			else
			{
				delete cache[request.url];
			}
			loopCallback(request, data);
		}
		
		private function onError(obj:Object):void
		{
			var request:LoaderRequest = obj.request;
			trace("加载失败，url=", request.url);
			
			delete cache[request.url];
			//加载失败也回调
			loopCallback(request, null);
		}
		
		private function loopCallback(request:LoaderRequest, data:Object):void
		{
			var callbacks:Array = request.params as Array;
			for (var i:int = 0; i < callbacks.length; ++i)
			{
				var cb:Function = callbacks[i].callback;
				if (cb == null)
					continue;
				
				var params:Array = callbacks[i].params;
				if (params)
				{
					params.unshift(data);
					cb.apply(null, params);
				}
				else
				{
					cb(data);
				}
			}
		}
	}
}