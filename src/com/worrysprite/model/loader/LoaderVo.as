package com.worrysprite.model.loader
{
	import flash.display.Loader;
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
		
		public function set url(value:String):void
		{
			_url = value;
		}
	}
}