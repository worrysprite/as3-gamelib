package com.worrysprite.model.loader
{
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
		
		public function LoaderVo()
		{
			
		}
		
		public function get url():String
		{
			return _url;
		}
		
		override public function load(request:URLRequest, context:LoaderContext = null):void
		{
			_url = request.url;
			super.load(request, context);
		}
	}
}