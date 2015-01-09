package com.worrysprite.utils
{
	import flash.filesystem.File;
	
	/**
	 * 文件助手
	 * @author WorrySprite
	 */
	public class FileUtils
	{
		public function FileUtils()
		{
			
		}
		
		public static function checkDirValid(pathOrURL:String, dir:File = null):Boolean
		{
			if (!dir)
			{
				dir = new File();
			}
			try
			{
				dir.nativePath = pathOrURL;
				if (!dir.exists || !dir.isDirectory)
				{
					dir.url = pathOrURL;
					if (!dir.exists || !dir.isDirectory)
					{
						return false;
					}
				}
			}
			catch (err:Error)
			{
				return false;
			}
			return true;
		}
		
		public static function checkFileValid(pathOrURL:String, extensions:Array = null, file:File = null):Boolean
		{
			if (!file)
			{
				file = new File();
			}
			try
			{
				file.nativePath = pathOrURL;
				if (!file.exists || (extensions && extensions.indexOf(getLowerCaseExt(file)) == -1))
				{
					file.url = pathOrURL;
					if (!file.exists || (extensions && extensions.indexOf(getLowerCaseExt(file)) == -1))
					{
						return false;
					}
				}
			}
			catch (err:Error)
			{
				return false;
			}
			return true;
		}
		
		public static function splitPathAndName(pathOrURL:String):Array
		{
			var index1:int = pathOrURL.lastIndexOf("/");
			var index2:int = pathOrURL.lastIndexOf("\\");
			var index:int = index1 > index2 ? index1 : index2;
			return [pathOrURL.substr(0, index), pathOrURL.substr(index + 1)];
		}
		
		public static function splitNameAndExt(fileName:String):Array
		{
			var index:int = fileName.lastIndexOf(".");
			if (index > 0)
			{
				return [fileName.substr(0, index), fileName.substr(index + 1)];
			}
			else
			{
				return [fileName, ""];
			}
		}
		
		public static function isImage(file:File):Boolean
		{
			return isPNG(file) || isJPEG(file);
		}
		
		public static function isPNG(file:File):Boolean
		{
			var ext:String = getLowerCaseExt(file);
			return ext == "png";
		}
		
		public static function isJPEG(file:File):Boolean
		{
			var ext:String = getLowerCaseExt(file);
			return ext == "jpg" || ext == "jpeg";
		}
		
		public static function getLowerCaseExt(file:File):String
		{
			if (file && !file.isDirectory)
			{
				var ext:String = file.extension;
				if (ext)
				{
					return ext.toLowerCase();
				}
			}
			return "";
		}
	}

}