package com.worrysprite.effect
{
	import com.worrysprite.model.image.AEPFile;
	/**
	 * 特效缓存管理
	 * <p>Effect cache manager</p>
	 * @author WorrySprite
	 */
	public class EffectCache
	{
		private static var effectCache:Object = new Object();
		
		/**
		 * 获取特效文件
		 * <p>Get effect file data</p>
		 * @param	url	缓存时的URL
		 * <p>The url of cache.</p>
		 * @return
		 */
		public static function getEffectFile(url:String):AEPFile
		{
			return effectCache[url] as AEPFile;
		}
		
		/**
		 * 添加特效文件到缓存
		 * <p>Add effect file to cache</p>
		 * @param	url	缓存URL
		 * <p>The url of cache.</p>
		 * @param	effectFile	特效文件数据
		 * <p>The effect file data</p>
		 */
		public static function addCache(url:String, effectFile:AEPFile):void
		{
			effectCache[url] = effectFile;
		}
		
		/**
		 * 删除缓存
		 * <p>Remove the cache of url</p>
		 * @param	url	缓存时的URL
		 * <p>The url of cache.</p>
		 */
		public static function removeCache(url:String):void
		{
			delete effectCache[url];
		}
		
		/**
		 * 清空缓存
		 * <p>Clear all cache</p>
		 */
		public static function clearCache():void
		{
			effectCache = new Object();
		}
	}
}