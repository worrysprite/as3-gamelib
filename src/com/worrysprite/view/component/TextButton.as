package com.worrysprite.view.component
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class TextButton extends TextField
	{
		public function TextButton()
		{
			autoSize = TextFieldAutoSize.LEFT;
			border = true;
			selectable = false;
			var format:TextFormat = new TextFormat();
			format.size = 14;
			format.leftMargin = format.letterSpacing = 5;
			//format.letterSpacing = 5;
			defaultTextFormat = format;
		}
		
	}

}