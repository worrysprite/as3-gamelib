package com.worrysprite.effect
{
	import com.worrysprite.model.swf.SwfDataVo;
	/**
	 * 特效管理器，加载和缓存特效资源
	 * @author WorrySprite
	 */
	public class EffectManager
	{
		private static var effectCache:Object = new Object();
		
		public static function getSwf(url:String):SwfDataVo
		{
			return effectCache[url] as SwfDataVo;
		}
		
		public static function addCache(url:String, swf:SwfDataVo):void
		{
			effectCache[url] = swf;
		}
		
		public static function removeCache(url:String):void
		{
			delete effectCache[url];
		}
		
		public static function clearCache():void
		{
			effectCache = new Object();
		}
	}
}