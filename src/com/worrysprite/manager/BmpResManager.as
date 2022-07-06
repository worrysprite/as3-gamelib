package com.worrysprite.manager
{
	import com.worrysprite.model.loader.ImageLoader;
	import com.worrysprite.model.loader.LoaderRequest;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	/**
	 * 位图资源管理
	 * @author worrysprite
	 */
	public class BmpResManager
	{
		private static const classBmpCache:Dictionary = new Dictionary();
		private static const loadingBmp:Dictionary = new Dictionary();
		private static const defBmdX:BitmapData = new BitmapData(1, 1, true, 0x0);
		
		static public function getBitmap(url:String, bmp:Bitmap, size:Point = null, callback:Function = null, params:Array = null):void
		{
			if (url == "" || !checkIsImage(url)) // 空图片，啥都不显示
			{
				bmp.bitmapData = null;
				return;
			}
			
			var cache:Bitmap = LoaderManager.getInstance().getCache(url) as Bitmap;
			if (cache)	//有缓存
			{
				setBmp(bmp, cache.bitmapData, size);
				if (callback != null)
				{
					callback.apply(null, params);
				}
				return;
			}
			
			setBmp(bmp, defBmdX, size);
			
			var vo:BitmapVo = new BitmapVo();
			vo.url = url;
			vo.bmp = bmp;
			vo.size = size;
			vo.callback = callback;
			vo.params = params;
			LoaderManager.getInstance().loadImage(url, onLoaded, [vo]);
		}
		
		private static function setBmp(bmp:Bitmap, bmd:BitmapData, size:Point = null):void
		{
			bmp.bitmapData = bmd;
			if (size && size.x != 0 && size.y != 0)
			{
				bmp.width = size.x;
				bmp.height = size.y;
			}
			bmp.smoothing = bmp.width != bmd.width || bmp.height != bmd.height;
		}
		
		private static function onLoaded(img:DisplayObject, vo:BitmapVo):void
		{
			if (!img)	//失败不回调
				return;
			
			var bmp:Bitmap;
			if (img is Bitmap)
			{
				bmp = img as Bitmap;
			}
			else if (img is Sprite)
			{
				bmp = (img as Sprite).getChildAt(0) as Bitmap;
				if (!bmp)
				{
					bmp = new Bitmap();
					bmp.bitmapData = new BitmapData(img.width, img.height, true, 0);
					bmp.bitmapData.draw(img);
				}
			}
			LoaderManager.getInstance().addCache(vo.url, bmp);
			
			if (vo.callback != null)
			{
				vo.callback.apply(null, vo.params);
			}
		}
		
		/**
		 * 检查是不是图片
		 * @param url
		 * @return
		 */
		public static function checkIsImage(url:String):Boolean
		{
			if (url)
			{
				var orgUrl:String = url.split("?")[0];
				var index:int = orgUrl.lastIndexOf(".");
				if (index != -1)
				{
					var ext:String = url.substring(index).toLowerCase();
					if (ext == ".jpg" || ext == ".png" || ext == ".swf")
					{
						return true;
					}
				}
			}
			return false;
		}
		
		static public function getBitmapByID(ClassPrefix:String, id:int):BitmapData
		{
			return getBitmapResource(ClassPrefix + id);
		}
		
		static public function getBitmapByName(ClassPrefix:String, name:String):BitmapData
		{
			return getBitmapResource(ClassPrefix + name);
		}
		
		static public function getBitmapResource(className:String):BitmapData
		{
			if (className == null)
			{
				return null;
			}
			var bmpData:BitmapData = classBmpCache[className];
			if (!bmpData)
			{
				var domain:ApplicationDomain = ApplicationDomain.currentDomain;
				if (domain.hasDefinition(className))
				{
					var ClassRef:Class = domain.getDefinition(className) as Class;
					bmpData = new ClassRef() as BitmapData;
					if (bmpData)
					{
						classBmpCache[className] = bmpData;
					}
				}
			}
			return bmpData;
		}
	}
	
	internal class BitmapVo
	{
		public var url:String;
		public var bmp:Bitmap;
		public var size:Point;
		public var callback:Function;
		public var params:Array;
	}
}
