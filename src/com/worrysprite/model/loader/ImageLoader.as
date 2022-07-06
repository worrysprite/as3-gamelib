package com.worrysprite.model.loader
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.system.LoaderContext;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	/**
	 * 加载器
	 * @author worrysprite
	 */
	public class ImageLoader extends Loader
	{
		public var request:LoaderRequest;
		private var isLoading:Boolean = false;
		
		public function ImageLoader()
		{
			request = new LoaderRequest();
		}
		
		public function get format():String
		{
			return "image";
		}
		
		public function get url():String
		{
			return request.url;
		}
		
		public function startLoad(context:LoaderContext = null):void 
		{
			if (!isLoading && request)
			{
				contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadEnd);
				contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
				
				super.load(new URLRequest(url), context);
			}
		}
		
		override public function load(request:URLRequest, context:LoaderContext = null):void
		{
			throw new Error("call startLoad instead.");
		}
		
		override public function loadBytes(bytes:ByteArray, context:LoaderContext = null):void
		{
			if (!isLoading && request)
			{
				contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadEnd);
				contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
				
				super.loadBytes(bytes, context);
			}
		}
		
		private function onLoadEnd(evt:Event):void 
		{
			isLoading = false;
			contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadEnd);
			contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
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