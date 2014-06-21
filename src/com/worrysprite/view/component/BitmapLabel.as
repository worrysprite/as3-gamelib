package com.worrysprite.view.component
{
	import flash.display.Bitmap;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	/**
	 * 位图文本标签
	 * @author 王润智
	 */
	public class BitmapLabel extends Bitmap
	{
		private var _text:String;
		private var _format:TextFormat;
		private var _filters:Array;
		private var _width:int;
		private var _multiline:Boolean;
		
		public function BitmapLabel(size:int = 40, color:uint = 0xFFFFFF, multiline:Boolean = false, width:int = 0)
		{
			super(null, "auto", true);
			_multiline = multiline;
			_width = width;
			_format = new TextFormat("_sans", size, color, false, false, false, null, null, TextFormatAlign.LEFT, 0, 0, 0, 0);
		}
		
		private function updateText():void
		{
			if (_text && _text.length)
			{
				if (_multiline && _width > 0)
				{
					bitmapData = BitmapTextPainter.paintParagraph(_text, _width, _format, _filters);
				}
				else
				{
					bitmapData = BitmapTextPainter.paintText(_text, _format, _filters);
				}
			}
			else
			{
				bitmapData = null;
			}
		}
		
		public function get text():String
		{
			return _text;
		}
		
		public function set text(value:String):void
		{
			if (_text != value)
			{
				_text = value;
				updateText();
			}
		}
		
		public function get format():TextFormat
		{
			return _format;
		}
		
		public function set format(value:TextFormat):void
		{
			if (_format != value)
			{
				_format = value;
				updateText();
			}
		}
		
		public function get color():uint
		{
			return uint(_format.color);
		}
		
		public function set color(value:uint):void
		{
			if (_format.color != value)
			{
				_format.color = value;
				updateText();
			}
		}
		
		public function get size():int
		{
			return int(_format.size);
		}
		
		public function set size(value:int):void
		{
			if (_format.size != value)
			{
				_format.size = value;
				updateText();
			}
		}
		
		override public function get filters():Array
		{
			return _filters;
		}
		
		override public function set filters(value:Array):void
		{
			if (_filters != value)
			{
				_filters = value;
				updateText();
			}
		}
		
		public function get textWidth():int
		{
			if (bitmapData)
			{
				return bitmapData.width;
			}
			return 0;
		}
		
		public function get textHeight():int
		{
			if (bitmapData)
			{
				return bitmapData.height;
			}
			return 0;
		}
		
		public function get font():String
		{
			return _format.font;
		}
		
		public function set font(value:String):void
		{
			if (_format.font != value)
			{
				_format.font = value;
				updateText();
			}
		}
	}
}