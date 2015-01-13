package com.worrysprite.utils
{
	import com.worrysprite.enum.ExceptionEnum;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	/**
	 * 调试工具
	 * @author WorrySprite
	 */
	public final class Debug
	{
		public function Debug()
		{
			throw new Error(ExceptionEnum.getExceptionMsg(ExceptionEnum.STATIC_CLASS_CAN_NOT_CONSTRUCT), ExceptionEnum.STATIC_CLASS_CAN_NOT_CONSTRUCT);
		}
		
		/**
		 * 远程日志地址
		 * <p>Remote log url</p>
		 */
		public static var traceURL:String;
		/**
		 * 远程trace时发送的方法，URLRequestMethod中的常量，默认值GET
		 * <p>Remote trace method, use constant in URLRequestMethod, default is GET</p>
		 */
		public static var traceMethod:String = URLRequestMethod.GET;
		/**
		 * 返回值回调函数，需要有一个参数
		 * <p>Callback function to receive returned value, must have one param</p>
		 */
		public static var resultFunc:Function;
		
		static private function onTraceComplete(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onTraceComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onTraceError);
			if (resultFunc != null)
			{
				resultFunc(loader.data);
			}
		}
		
		static private function onTraceError(e:IOErrorEvent):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onTraceComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onTraceError);
		}
		
		/**
		 * 发送信息到远程服务器
		 * Send message to remote server
		 * @param	...rest	像trace()一样的参数
		 * Use it like trace()
		 */
		public static function traceRemote(...rest):void
		{
			if (!traceURL)
			{
				return;
			}
			var request:URLRequest = new URLRequest(traceURL);
			request.method = traceMethod;
			request.contentType = "text/plain";
			request.data = encodeURI(rest.join(" "));
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onTraceComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onTraceError);
			loader.load(request);
		}
		
		/**
		 * 发送键值对到远程服务器
		 * <p>Send key value map to remote server</p>
		 * @param	webParams	网页参数，像key1=value1&amp;key2=value2&amp;key3=value3
		 * <p>Web params such as key1=value1&amp;key2=value2&amp;key3=value3</p>
		 */
		public static function traceKeyValue(webParams:String):void
		{
			if (!traceURL)
			{
				return;
			}
			var request:URLRequest = new URLRequest(traceURL);
			request.method = traceMethod;
			request.contentType = "application/x-www-form-urlencoded";
			request.data = new URLVariables(encodeURI(webParams));
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onTraceComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onTraceError);
			loader.load(request);
		}
	}
}