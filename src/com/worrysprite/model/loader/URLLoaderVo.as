package com.worrysprite.model.loader
{
	import flash.net.URLLoader;
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
		
		public function set url(value:String):void
		{
			_url = value;
		}
	}
}