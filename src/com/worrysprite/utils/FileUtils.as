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
				if (!file.exists || (extensions && extensions.indexOf(file.extension) == -1))
				{
					file.url = pathOrURL;
					if (!file.exists || (extensions && extensions.indexOf(file.extension) == -1))
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
	}

}