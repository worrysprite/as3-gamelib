package com.worrysprite.manager
{
	import com.worrysprite.model.loader.LoaderVo;
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
	 * 游戏资源
	 * @author 王润智
	 */
	public class ResourceManager
	{
		private static const classBmpCache:Object = new Object();
		private static const bmdCache:Object = new Object();	//位图缓存
		private static const urlCache:Dictionary = new Dictionary(true); // bmp作为key，对应url
		private static const bmps:Object = new Object(); // 储存bmp的引用
		private static const sizes:Object = new Object(); // 储存size的引用
		private static const funs:Object = new Object(); // 存储callback的引用
		private static const defBmdX:BitmapData = new BitmapData(1, 1, true, 0x0);
		
		static public function getBitmap(url:String, bmp:Bitmap, size:Point = null, callback:Function = null):void
		{
			deleteBitmap(bmp); // 删除曾经的引用
			if (url == "" || !checkIsImage(url)) // 空图片，啥都不显示
			{
				bmp.bitmapData = null;
				return;
			}
			var bmdResult:BitmapData = bmdCache[url] as BitmapData;
			if (bmdResult) // 有缓存
			{
				setBmp(bmp, bmdResult, size);
				if (callback != null)
				{
					callback();
				}
			}
			else
			{
				urlCache[bmp] = url;
				if (bmps[url] == null)
				{
					bmps[url] = new Vector.<Bitmap>();
				}
				bmps[url].push(bmp);
				if (sizes[url] == null)
				{
					sizes[url] = new Vector.<Point>();
				}
				sizes[url].push(size);
				if (funs[url] == null)
				{
					funs[url] = new Vector.<Function>();
				}
				funs[url].push(callback);
				if (bmdCache[url] == null) // Loader不存在才加载，不然会自动处理
				{
					var loader:LoaderVo = new LoaderVo();
					loader.url = url;
					bmdCache[url] = loader;
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
					loader.load(new URLRequest(url), SwfLoaderManager.getInstance().loaderContext);
				}
				setBmp(bmp, defBmdX, size);
			}
		}
		
		static private function deleteBitmap(bmp:Bitmap):void
		{
			var url:String = urlCache[bmp];
			if (url)
			{
				delete urlCache[bmp];
				var ary:Vector.<Bitmap> = bmps[url] as Vector.<Bitmap>;
				if (ary)
				{
					var index:int = ary.indexOf(bmp);
					if (index != -1)
					{
						ary.splice(index, 1);
						sizes[url].splice(index, 1);
						funs[url].splice(index, 1);
					}
				}
			}
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
		
		private static function completeHandler(e:Event):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			var loader:LoaderVo = info.loader as LoaderVo;
			info.removeEventListener(Event.COMPLETE, completeHandler);
			info.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			var url:String = loader.url;
			var obj:Bitmap;
			if (loader.content is Bitmap)
			{
				obj = loader.content as Bitmap;
			}
			else
			{
				var child:DisplayObject = (loader.content as Sprite).getChildAt(0);
				if (child is Bitmap)
				{
					obj = child as Bitmap;
				}
				else
				{
					obj = new Bitmap();
					obj.bitmapData = new BitmapData(child.width, child.height, true, 0);
					obj.bitmapData.draw(child);
				}
			}
			var bmd:BitmapData = obj.bitmapData;
			bmdCache[url] = bmd;
			var tmpBmps:Vector.<Bitmap> = bmps[url] as Vector.<Bitmap>;
			var tmpSizes:Vector.<Point> = sizes[url] as Vector.<Point>;
			var tmpFuns:Vector.<Function> = funs[url] as Vector.<Function>;
			for (var i:int = 0; i < tmpBmps.length; ++i)
			{
				delete urlCache[tmpBmps[i]];
				setBmp(tmpBmps[i], bmd, tmpSizes[i]);
				if (tmpFuns[i])
				{
					tmpFuns[i]();
				}
			}
			delete sizes[url];
			delete bmps[url];
			delete funs[url];
		}
		
		private static function errorHandler(e:Event):void
		{
			var info:LoaderInfo = e.currentTarget as LoaderInfo;
			info.removeEventListener(Event.COMPLETE, completeHandler);
			info.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
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
		
		static public function getResourceByID(ClassPrefix:String, id:int):BitmapData
		{
			return getBitmapResource(ClassPrefix + id);
		}
		
		static public function getResourceByName(ClassPrefix:String, name:String):BitmapData
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
}