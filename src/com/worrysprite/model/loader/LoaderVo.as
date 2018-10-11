package com.worrysprite.model.loader
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.system.LoaderContext;
	import flash.display.Loader;
	import flash.net.URLRequest;
	/**
	 * 加载器
	 * @author 王润智
	 */
	public class LoaderVo extends Loader
	{
		private var _url:String;
		private var _isLoading:Boolean;
		
		public function LoaderVo()
		{
			contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadEnd);
			contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadEnd);
		}
		
		public function get url():String
		{
			return _url;
		}
		
		public function get isLoading():Boolean 
		{
			return _isLoading;
		}
		
		override public function load(request:URLRequest, context:LoaderContext = null):void
		{
			_url = request.url;
			_isLoading = true;
			super.load(request, context);
		}
		
		private function onLoadEnd(evt:Event):void 
		{
			_isLoading = false;
		}
	}
}