package com.worrysprite.model.loader
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	/**
	 * 加载器
	 * @author 王润智
	 */
	public class URLLoaderVo extends URLLoader
	{
		private var _url:String;
		
		public function URLLoaderVo()
		{
			
		}
		
		public function get url():String
		{
			return _url;
		}
		
		override public function load(request:URLRequest):void
		{
			_url = request.url;
			super.load(request);
		}
	}
}