package com.worrysprite.model.image
{
	import com.worrysprite.manager.LoaderManager;
	import com.worrysprite.enum.JpegAlgorithmEnum;
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
	import org.bytearray.images.JPEGEncoder;
	/**
	 * jng文件定义
	 * @author WorrySprite
	 */
	public class JNGFile extends EventDispatcher
	{
		/**
		 * v1.0版
		 */
		public static const VERSION_1_0:uint = 0x00010000;
		/**
		 * v1.1版
		 * 在每个位图数据前新增了UTF8字符串文件名
		 */
		public static const VERSION_1_1:uint = 0x00010001;
		
		private var version:uint;
		private var jpgEncoder:JPEGEncoder;
		private var jpgEncoderOptions:JPEGEncoderOptions;
		private var _names:Vector.<String>;
		private var _bitmaps:Vector.<BitmapData>;
		private var _bytes:ByteArray;
		private var fileLoaded:int;
		private var _jpegAlgorithm:int;
		private var _quality:int;
		
		public function JNGFile(quality:int = 80, version:uint = VERSION_1_1)
		{
			this.version = version;
			_bitmaps = new Vector.<BitmapData>();
			_names = new Vector.<String>();
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeUnsignedInt(version);	//写入版本
			_bytes.writeShort(0);	//写入图片数
			_quality = quality;
			jpegAlgorithm = JpegAlgorithmEnum.ALGORITHM_ORG_BYTEARRAY_IMAGES_JPEGENCODER;
		}
		
		private function readV1_0():void
		{
			_bitmaps.length = _bytes.readUnsignedShort();
			var width:uint;
			var height:uint;
			var dataLength:uint;
			var jpgBytes:ByteArray;
			var bmp:BitmapData;
			var loader:LoaderManager = LoaderManager.getInstance();
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
				loader.loadImageBytes(jpgBytes, onLoaded, [i]);
				
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
		
		private function readV1_1():void
		{
			_bitmaps.length = _bytes.readUnsignedShort();
			_names.length = _bitmaps.length;
			var width:uint;
			var height:uint;
			var dataLength:uint;
			var jpgBytes:ByteArray;
			var bmp:BitmapData;
			var loader:LoaderManager = LoaderManager.getInstance();
			fileLoaded = 0;
			for (var i:int = 0; i < _bitmaps.length; ++i)
			{
				_names[i] = _bytes.readUTF();
				//读取宽高
				width = _bytes.readUnsignedShort();
				height = _bytes.readUnsignedShort();
				bmp = new BitmapData(width, height);
				_bitmaps[i] = bmp;
				
				//读取jpg
				dataLength = _bytes.readUnsignedInt();
				jpgBytes = new ByteArray();
				_bytes.readBytes(jpgBytes, 0, dataLength);
				loader.loadImageBytes(jpgBytes, onLoaded, [i]);
				
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
		
		private function addBitmapV1_0(bmp:BitmapData):void
		{
			//写入宽高
			_bytes.writeShort(bmp.width);
			_bytes.writeShort(bmp.height);
			//写入jpg数据
			var jpgBytes:ByteArray;
			if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_ORG_BYTEARRAY_IMAGES_JPEGENCODER)
			{
				jpgBytes = jpgEncoder.encode(bmp);
			}
			else if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_BITMAPDATA_ENCODE)
			{
				jpgBytes = bmp.encode(bmp.rect, jpgEncoderOptions);
			}
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
		
		private function addBitmapV1_1(bmp:BitmapData, fileName:String):void
		{
			if (fileName)
			{
				_bytes.writeUTF(fileName);
			}
			else
			{
				_bytes.writeUTF("");
			}
			//写入宽高
			_bytes.writeShort(bmp.width);
			_bytes.writeShort(bmp.height);
			//写入jpg数据
			var jpgBytes:ByteArray;
			if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_ORG_BYTEARRAY_IMAGES_JPEGENCODER)
			{
				jpgBytes = jpgEncoder.encode(bmp);
			}
			else if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_BITMAPDATA_ENCODE)
			{
				jpgBytes = bmp.encode(bmp.rect, jpgEncoderOptions);
			}
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
		
		public function addBitmap(bmp:BitmapData, fileName:String = null):void
		{
			if (bmp)
			{
				if (version == VERSION_1_0)
				{
					addBitmapV1_0(bmp);
				}
				else if (version == VERSION_1_1)
				{
					addBitmapV1_1(bmp, fileName);
				}
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
			else if (version == VERSION_1_1)
			{
				readV1_1();
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
		
		public function get names():Vector.<String>
		{
			return _names.slice();
		}
		
		public function get bmpCount():int
		{
			return _bitmaps.length;
		}
		
		public function get jpegAlgorithm():int
		{
			return _jpegAlgorithm;
		}
		
		public function set jpegAlgorithm(value:int):void
		{
			_jpegAlgorithm = value;
			if (_jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_ORG_BYTEARRAY_IMAGES_JPEGENCODER)
			{
				jpgEncoder = new JPEGEncoder(_quality);
				jpgEncoderOptions = null;
			}
			else if (_jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_BITMAPDATA_ENCODE)
			{
				jpgEncoderOptions = new JPEGEncoderOptions(_quality);
				jpgEncoder = null;
			}
		}
	}

}