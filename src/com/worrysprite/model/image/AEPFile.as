package com.worrysprite.model.image
{
	import com.worrysprite.manager.SwfLoaderManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataOutput;
	/**
	 * aep文件定义
	 * @author WorrySprite
	 */
	public class AEPFile extends EventDispatcher
	{
		public static const TYPE_ACTION:int = 1;
		public static const TYPE_EFFECT:int = 2;
		
		private static const VERSION_1_0:uint = 0x00010000;
		private static const pngEncoder:PNGEncoderOptions = new PNGEncoderOptions();
		
		private static var lengthPosition:int;
		
		private var _version:int;
		private var _type:int;
		private var _bytes:ByteArray;
		private var _actionList:Vector.<ActionVo>;
		private var _quality:int;
		private var jngList:Vector.<JNGFile>;
		private var fileLoaded:int;
		private var fileTotal:int;
		
		/**
		 * AEP文件格式，储存动作或特效序列帧
		 * @param	type
		 * @param	quality
		 */
		public function AEPFile(type:int = TYPE_EFFECT, quality:int = 80)
		{
			if ((type != TYPE_ACTION && type != TYPE_EFFECT) || quality > 101 || quality <= 0)
			{
				throw new ArgumentError();
			}
			_type = type;
			_quality = quality;
			_version = VERSION_1_0;
			
			//写入文件头
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeUnsignedInt(_version);
			_bytes.writeByte(_type);
			_bytes.writeByte(_quality);
			lengthPosition = _bytes.position;
			_bytes.writeShort(0);	//写入动作数量，初始为0
			
			_actionList = new Vector.<ActionVo>();
			if (quality <= 100)
			{
				jngList = new Vector.<JNGFile>();
			}
		}
		
		public static function createFromBytes(fileData:ByteArray):AEPFile
		{
			var file:AEPFile = new AEPFile();
			file.readFromFile(fileData);
			return file;
		}
		
		private function readV1_0():void
		{
			_type = _bytes.readByte();
			_quality = _bytes.readByte();
			_actionList.length = _bytes.readShort();
			if (_quality <= 100)
			{
				jngList = new Vector.<JNGFile>(_actionList.length);
			}
			else
			{
				jngList = null;
			}
			fileLoaded = 0;
			fileTotal = 0;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < _actionList.length; ++i)
			{
				var action:ActionVo = new ActionVo();
				action.index = i;
				action.directory = _bytes.readUTF();
				action.interval = _bytes.readUnsignedInt();
				var bmpCount:int = _bytes.readUnsignedShort();
				action.offsetXs = new Vector.<int>(bmpCount);
				action.offsetYs = new Vector.<int>(bmpCount);
				//先读取坐标
				for (var j:int = 0; j < bmpCount; ++j)
				{
					action.offsetXs[j] = _bytes.readInt();
					action.offsetYs[j] = _bytes.readInt();
				}
				//再读取图片
				if (jngList)
				{
					var jngLength:int = _bytes.readUnsignedInt();
					var jngBytes:ByteArray = new ByteArray();
					jngBytes.endian = Endian.LITTLE_ENDIAN;
					_bytes.readBytes(jngBytes, 0, jngLength);
					
					var jng:JNGFile = new JNGFile(_quality);
					jng.readFromBytes(jngBytes);
					action.bitmaps = jng.bitmaps.slice();
				}
				else
				{
					fileTotal += bmpCount;
					action.bitmaps = new Vector.<BitmapData>(bmpCount);
					for (var k:int = 0; k < bmpCount; ++k)
					{
						var pngLength:int = _bytes.readUnsignedInt();
						var pngBytes:ByteArray = new ByteArray();
						_bytes.readBytes(pngBytes, 0, pngLength);
						loader.loadBytes(pngBytes, onLoaded, [action.bitmaps, k]);
					}
					trace("file total changed", fileTotal);
				}
				_actionList[i] = action;
			}
		}
		
		private function onLoaded(pngImage:Bitmap, list:Vector.<BitmapData>, index:int):void
		{
			trace("on loaded", fileLoaded);
			list[index] = pngImage.bitmapData;
			if (++fileLoaded == fileTotal)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function addBitmap(bmp:BitmapData):void
		{
			if (bmp)
			{
				//写入宽高
				//_bytes.writeShort(bmp.width);
				//_bytes.writeShort(bmp.height);
				//写入png数据
				var pngBytes:ByteArray = bmp.encode(bmp.rect, pngEncoder);
				_bytes.writeUnsignedInt(pngBytes.length);
				_bytes.writeBytes(pngBytes);
			}
		}
		
		public function addAction(action:ActionVo):void
		{
			if (!action || !action.bitmaps)
			{
				return;
			}
			action.index = _actionList.length;
			//修改动作数量
			_bytes.position = lengthPosition;
			_bytes.writeShort(_actionList.push(action));
			_bytes.position = _bytes.length;
			
			//写入动作信息
			_bytes.writeUTF(action.directory);
			_bytes.writeUnsignedInt(action.interval);
			//写入PNG图片数量
			var bmpCount:int = action.bitmaps.length;
			_bytes.writeShort(bmpCount);
			
			var jng:JNGFile;
			if (_quality <= 100)	//压缩为jng
			{
				jng = new JNGFile(_quality);	//每个动作对应一个jng文件
				jngList.push(jng);
			}
			//写入偏移量列表
			for (var j:int = 0; j < bmpCount; ++j)
			{
				_bytes.writeInt(action.offsetXs[j]);
				_bytes.writeInt(action.offsetYs[j]);
			}
			//写入图片列表
			for (var i:int = 0; i < bmpCount; ++i)
			{
				if (jng)
				{
					jng.addBitmap(action.bitmaps[i]);
				}
				else
				{
					addBitmap(action.bitmaps[i]);
				}
			}
			if (jng)
			{
				var jngData:ByteArray = jng.bytes;
				_bytes.writeUnsignedInt(jngData.length);
				_bytes.writeBytes(jngData);
			}
		}
		
		public function writeToFile(file:IDataOutput):void
		{
			var content:ByteArray = bytes;
			content.compress();
			file.writeBytes(content);
		}
		
		public function readFromFile(fileData:ByteArray):void
		{
			fileData.uncompress();
			_bytes.clear();
			_bytes.writeBytes(fileData);
			_bytes.position = 0;
			_version = _bytes.readUnsignedInt();
			if (_version == VERSION_1_0)
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
		
		public function get type():int
		{
			return _type;
		}
		
		public function get actionList():Vector.<ActionVo>
		{
			return _actionList;
		}
		
		/**
		 * 品质，1~100为jpg品质，101为无损
		 */
		public function get quality():int
		{
			return _quality;
		}
		
		/**
		 * 文件版本
		 */
		public function get version():int
		{
			return _version;
		}
	}
}