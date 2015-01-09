package com.worrysprite.model.image
{
	import com.worrysprite.manager.SwfLoaderManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.JPEGEncoderOptions;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataOutput;
	/**
	 * jng文件定义
	 * @author WorrySprite
	 */
	public class JNGFile extends EventDispatcher
	{
		private static const VERSION_1_0:uint = 0x00010000;	//v1.0
		
		private var version:uint;
		private var jpgEncoder:JPEGEncoderOptions;
		private var _bitmaps:Vector.<BitmapData>;
		private var _bytes:ByteArray;
		private var fileLoaded:int;
		
		public function JNGFile(quality:int = 80)
		{
			version = VERSION_1_0;
			jpgEncoder = new JPEGEncoderOptions(quality);
			_bitmaps = new Vector.<BitmapData>();
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeUnsignedInt(version);	//写入版本
			_bytes.writeShort(0);	//写入图片数
		}
		
		private function readV1_0():void
		{
			_bitmaps.length = _bytes.readUnsignedShort();
			var width:uint;
			var height:uint;
			var dataLength:uint;
			var jpgBytes:ByteArray;
			var bmp:BitmapData;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			fileLoaded = 0;
			for (var i:int = 0; i < _bitmaps.length; ++i)
			{
				//读取宽高
				width = _bytes.readUnsignedShort();
				height = _bytes.readUnsignedShort();
				bmp = new BitmapData(width, height);
				_bitmaps[i] = bmp;
				
				//读取jpg
				dataLength = _bytes.readUnsignedInt();
				jpgBytes = new ByteArray();
				_bytes.readBytes(jpgBytes, 0, dataLength);
				loader.loadBytes(jpgBytes, onLoaded, [i]);
				
				//读取alpha
				for (var j:int = 0; j < height; ++j)
				{
					for (var k:int = 0; k < width; ++k)
					{
						bmp.setPixel32(k, j, _bytes.readByte() << 24);
					}
				}
			}
		}
		
		private function onLoaded(jpgImg:Bitmap, index:int):void
		{
			var bmpData:BitmapData = jpgImg.bitmapData;
			var destBmp:BitmapData = _bitmaps[index];
			var rect:Rectangle = bmpData.rect;
			var destPoint:Point = new Point();
			destBmp.lock();
			destBmp.copyChannel(bmpData, rect, destPoint, BitmapDataChannel.RED, BitmapDataChannel.RED);
			destBmp.copyChannel(bmpData, rect, destPoint, BitmapDataChannel.BLUE, BitmapDataChannel.BLUE);
			destBmp.copyChannel(bmpData, rect, destPoint, BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);
			destBmp.unlock();
			
			if (++fileLoaded == _bitmaps.length)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		public function addBitmap(bmp:BitmapData):void
		{
			if (bmp)
			{
				//写入宽高
				_bytes.writeShort(bmp.width);
				_bytes.writeShort(bmp.height);
				//写入jpg数据
				var jpgBytes:ByteArray = bmp.encode(bmp.rect, jpgEncoder);
				_bytes.writeUnsignedInt(jpgBytes.length);
				_bytes.writeBytes(jpgBytes);
				//写入alpha数据
				var vec:Vector.<uint> = bmp.getVector(bmp.rect);
				var len:int = vec.length;
				for (var i:int = 0; i < len; ++i)
				{
					_bytes.writeByte(vec[i] >> 24);
				}
				
				//修改位图数量
				_bytes.position = 4;
				_bytes.writeShort(_bitmaps.push(bmp));
				_bytes.position = _bytes.length;
			}
		}
		
		public function writeToFile(file:IDataOutput):void
		{
			var content:ByteArray = bytes;
			content.compress();
			file.writeBytes(content);
		}
		
		public function readFromFile(file:ByteArray):void
		{
			file.uncompress();
			readFromBytes(file);
		}
		
		public function readFromBytes(byteArray:ByteArray):void
		{
			_bytes.clear();
			_bytes.writeBytes(byteArray);
			_bytes.position = 0;
			version = _bytes.readUnsignedInt();
			_bitmaps.length = 0;
			if (version == VERSION_1_0)
			{
				readV1_0();
			}
		}
		
		public function get bytes():ByteArray
		{
			var clone:ByteArray = new ByteArray();
			clone.endian = Endian.LITTLE_ENDIAN;
			clone.writeBytes(_bytes);
			return clone;
		}
		
		public function get bitmaps():Vector.<BitmapData>
		{
			return _bitmaps.slice();
		}
	}

}