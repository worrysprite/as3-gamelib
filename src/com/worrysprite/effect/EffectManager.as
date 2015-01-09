package com.worrysprite.effect
{
	import com.worrysprite.model.image.AEPFile;
	/**
	 * 特效管理器，加载和缓存特效资源
	 * @author WorrySprite
	 */
	public class EffectManager
	{
		private static var effectCache:Object = new Object();
		
		public static function getEffectFile(url:String):AEPFile
		{
			return effectCache[url] as AEPFile;
		}
		
		public static function addCache(url:String, effectFile:AEPFile):void
		{
			effectCache[url] = effectFile;
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