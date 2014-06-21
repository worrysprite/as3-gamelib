package com.worrysprite.view.component
{
	import flash.display.BitmapData;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	/**
	 * 位图渲染文字
	 * @author 王润智
	 */
	public class BitmapTextPainter
	{
		public static var font:String = "_sans";
		
		private static var _painter:TextField;
		
		public function BitmapTextPainter()
		{
			
		}
		
		public static function paintText(txt:String, format:TextFormat = null, filters:Array = null):BitmapData
		{
			if (txt == null || txt == "")
			{
				return null;
			}
			painter.multiline = false;
			_painter.autoSize = TextFieldAutoSize.LEFT;
			_painter.wordWrap = false;
			if (format)
			{
				_painter.defaultTextFormat = format;
			}
			else
			{
				_painter.defaultTextFormat = new TextFormat(font, 40, 0xFFFFFF, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0);
			}
			_painter.filters = filters;
			_painter.htmlText = txt;
			var bmpData:BitmapData = new BitmapData(_painter.width, _painter.height, true, 0);
			bmpData.draw(_painter);
			return bmpData;
		}
		
		public static function paintParagraph(txt:String, width:int, format:TextFormat = null, filters:Array = null):BitmapData
		{
			if (txt == null || txt == "")
			{
				return null;
			}
			painter.multiline = true;
			_painter.wordWrap = true;
			_painter.width = width;
			_painter.autoSize = TextFieldAutoSize.LEFT;
			if (format)
			{
				_painter.defaultTextFormat = format;
			}
			else
			{
				_painter.defaultTextFormat = new TextFormat(font, 40, 0xFFFFFF, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0);
			}
			_painter.filters = filters;
			_painter.htmlText = txt;
			var bmpData:BitmapData = new BitmapData(width, _painter.height, true, 0);
			bmpData.draw(_painter);
			return bmpData;
		}
		
		public static function getTextWidth(text:String, size:int = 40):Number
		{
			painter.autoSize = TextFieldAutoSize.LEFT;
			var format:TextFormat = _painter.defaultTextFormat;
			format.size = size;
			_painter.defaultTextFormat = format;
			_painter.multiline = false;
			_painter.wordWrap = false;
			_painter.text = text;
			return _painter.textWidth;
		}
		
		static public function get painter():TextField
		{
			if (_painter == null)
			{
				_painter = new TextField();
				_painter.selectable = false;
			}
			return _painter;
		}
	}
}