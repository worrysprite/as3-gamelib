package com.worrysprite.model.loader 
{
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class LoaderRequest
	{
		public var url:String;
		public var format:String;	//内容格式
		public var cache:Boolean;	//是否缓存
		
		public var onLoaded:Function;	//成功回调
		public var onError:Function;	//错误回调
		
		public var params:Object;	//透传参数
		
		public function LoaderRequest() 
		{
			
		}
	}
}