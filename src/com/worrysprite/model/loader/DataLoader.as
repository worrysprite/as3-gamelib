package com.worrysprite.model.loader
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	/**
	 * 加载器
	 * @author 王润智
	 */
	public class DataLoader extends URLLoader
	{
		public var request:LoaderRequest;
		private var isLoading:Boolean = false;
		
		public function DataLoader()
		{
			
		}
		
		public function get format():String
		{
			return request.format;
		}
		
		public function get url():String
		{
			return request.url;
		}
		
		public function startLoad():void 
		{
			if (!isLoading && request)
			{
				isLoading = true;
				
				addEventListener(Event.COMPLETE, onLoadEnd);
				addEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
				
				dataFormat = request.format;
				super.load(new URLRequest(url));
			}
		}
		
		override public function load(request:URLRequest):void
		{
			throw new Error("call startLoad instead.");
		}
		
		private function onLoadEnd(evt:Event):void 
		{
			isLoading = false;
			removeEventListener(Event.COMPLETE, onLoadEnd);
			removeEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
			if (evt.type == Event.COMPLETE)
			{
				request.onLoaded && request.onLoaded(this);
			}
			else if (evt.type == IOErrorEvent.IO_ERROR)
			{
				request.onError && request.onError(this);
			}
		}
	}
}