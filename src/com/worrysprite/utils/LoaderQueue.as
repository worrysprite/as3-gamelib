package com.worrysprite.utils
{
	import com.worrysprite.manager.LoaderManager;
	import com.worrysprite.model.loader.LoaderRequest;
	import com.worrysprite.model.loader.ImageLoader;
	import com.worrysprite.model.loader.DataLoader;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	/**
	 * 加载队列
	 * @author WorrySprite
	 */
	public class LoaderQueue
	{
		//并发数
		private var concurrency:uint;
		private var _maxConcurrency:uint = 10;
		/**
		 * <p>加载选项</p>
		 * Loader options
		 */
		public var loaderContext:LoaderContext;
		
		//正在加载中的url => [LoaderRequest]
		private var dict:Dictionary;
		//加载队列
		private var queue:Vector.<LoaderRequest>;
		//正在加载的请求，仅并发数=1时确保正确
		private var _loading:LoaderRequest;
		
		public function LoaderQueue()
		{
			dict = new Dictionary();
			queue = new Vector.<LoaderRequest>();
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
		 * @param	needCache	<p>添加缓存</p>
		 * Add loaded data into cache.
		 */
		public function load(url:String, format:String, callback:Function, callbackParams:Array = null, needCache:Boolean = false):void
		{
			//无效URL、没有回调且不添加缓存的加载没有意义
			if (!url || (callback == null && !needCache))
			{
				return;
			}
			
			var data:Object = LoaderManager.getInstance().getCache(url);
			if (data)	//有缓存
			{
				if (callback != null)
				{
					if (callbackParams == null)
					{
						callback(data);
					}
					else
					{
						callbackParams.unshift(data);
						callback.apply(null, callbackParams);
					}
				}
				return;
			}
			
			var request:LoaderRequest = dict[url] as LoaderRequest;
			var callbacks:Array;
			if (!request)
			{
				request = new LoaderRequest();
				request.url = url;
				request.format = format;
				request.onLoaded = onLoaded;
				request.onError = onError;
				request.params = [];
				dict[url] = request;
			}
			request.cache ||= needCache;
			
			callbacks = request.params as Array;
			callbacks.push({"callback": callback, "params": callbackParams});
			if (callbacks.length == 1)
			{
				queue.push(request);
				if (concurrency < _maxConcurrency)
				{
					++concurrency;
					loadNext();
				}
			}
		}
		
		public function loadImg(url:String, callback:Function, callbackParams:Array = null, needCache:Boolean = false):void
		{
			load(url, "image", callback, callbackParams);
		}
		
		public function get maxConcurrency():uint
		{
			return _maxConcurrency;
		}
		
		public function set maxConcurrency(value:uint):void
		{
			if (value)
			{
				_maxConcurrency = value;
			}
			else
			{
				_maxConcurrency = 1;
			}
		}
		
		/**
		 * <p>加载队列长度</p>
		 * Current length of the loading queue.
		 */
		public function get queueLength():int
		{
			return queue.length;
		}
		
		/**
		 * <p>队列正在处理的URL</p>
		 * Current URL of the queue processing
		 */
		public function get processingURL():String
		{
			return _loading ? _loading.url : "";
		}
		
		private function loadNext():void
		{
			if (queue.length)
			{
				_loading = queue.shift();
				if (_loading.format == "image")
				{
					var imgLoader:ImageLoader = new ImageLoader();
					imgLoader.request = _loading;
					imgLoader.startLoad(loaderContext);
				}
				else
				{
					var dataLoader:DataLoader = new DataLoader();
					dataLoader.request = _loading;
					dataLoader.startLoad();
				}
			}
			else
			{
				--concurrency;
			}
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
				LoaderManager.getInstance().addCache(request.url, data);
			}
			
			delete dict[request.url];
			//先开始下一个加载
			loadNext();
			
			//最后才循环回调，避免报错导致队列中断
			loopCallback(request, data);
		}
		
		private function onError(obj:Object):void
		{
			var request:LoaderRequest = obj.request;
			trace("队列加载失败，url=", request.url);
			loadNext();
			
			delete dict[request.url];
			//加载失败依然回调
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