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
		 * remote log url
		 */
		public static var traceURL:String;
		/**
		 * 远程trace时发送的方法，URLRequestMethod中的常量
		 * remote trace method, use constant in URLRequestMethod
		 */
		public static var traceMethod:String = URLRequestMethod.GET;
		/**
		 * 返回值回调函数，需要有一个参数
		 * call back function to receive returned value, must have one param
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
		 * send message to remote server
		 * @param	...rest	像trace()一样的参数
		 * use it like trace()
		 */
		public static function traceRemote(...rest):void
		{
			if (!traceURL)
			{
				return;
			}
			var str:String = "";
			for (var i:int = 0; i < rest.length; ++i)
			{
				str += rest[i] + " ";
			}
			var request:URLRequest = new URLRequest(traceURL);
			request.method = traceMethod;
			request.contentType = "text/plain";
			request.data = str;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onTraceComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onTraceError);
			loader.load(request);
		}
		
		/**
		 * 发送键值对到远程服务器
		 * send key value map to remote server
		 * @param	webParams	网页参数，像key1=value1&key2=value2&key3=value3
		 * web params such as key1=value1&key2=value2&key3=value3
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
			request.data = new URLVariables(webParams);
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onTraceComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onTraceError);
			loader.load(request);
		}
	}
}