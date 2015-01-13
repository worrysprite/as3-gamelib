package com.worrysprite.utils
{
	import com.worrysprite.enum.ExceptionEnum;
	import flash.filesystem.File;
	
	/**
	 * 文件助手，需要支持File类的AIR运行时，请使用静态方法而不要实例化该类
	 * @author WorrySprite
	 * @playerversion	AIR 1.0
	 */
	public final class FileUtils
	{
		public function FileUtils()
		{
			throw new Error(ExceptionEnum.getExceptionMsg(ExceptionEnum.STATIC_CLASS_CAN_NOT_CONSTRUCT), ExceptionEnum.STATIC_CLASS_CAN_NOT_CONSTRUCT);
		}
		
		/**
		 * <p>检查文件夹是否有效（存在且是文件夹）</p>
		 * check a directory is valid or not
		 * @param	pathOrURL	<p>路径或URL</p>
		 * path or url
		 * @param	dir	<p>一个File对象，将用pathOrURL填充</p>
		 * a File object will filled by pathOrURL
		 * @return	<p>true有效，false无效</p>
		 * true is valid, false is invalid
		 * @playerversion	AIR 1.0
		 */
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
		
		/**
		 * <p>检查文件是否有效（存在且后缀名符合）</p>
		 * check a file is valid or not(exist and matches extensions)
		 * @param	pathOrURL	<p>路径或URL</p>
		 * path or url
		 * @param	extensions	<p>后缀名/扩展名数组，不包含句点，如["jpg", "png"]</p>
		 * extensions array, not contains dot. example: ["jpg", "png"]
		 * @param	file	<p>一个File对象，将用pathOrURL填充</p>
		 * a File object will filled by pathOrURL
		 * @return	<p>true有效，false无效</p>
		 * true is valid, false is invalid
		 */
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
		
		/**
		 * <p>分割路径和文件名</p>
		 * split path and file name
		 * @param	pathOrURL	<p>路径或URL</p>
		 * path or url
		 * @return	<p>一个含有两个字符串的数组，第一项是路径，第二项是文件名</p>
		 * an array contains two strings, the first is path and the second is file name.
		 */
		public static function splitPathAndName(pathOrURL:String):Array
		{
			var index1:int = pathOrURL.lastIndexOf("/");
			var index2:int = pathOrURL.lastIndexOf("\\");
			var index:int = index1 > index2 ? index1 : index2;
			return [pathOrURL.substr(0, index), pathOrURL.substr(index + 1)];
		}
		
		/**
		 * <p>分割文件名和后缀名（不包含句点）</p>
		 * split file name and extension(not contains dot)
		 * @param	fileName	<p>完整的文件名</p>
		 * full file name
		 * @return	<p>一个含有两个字符串的数组，第一项是文件名，第二项是后缀/扩展名</p>
		 * an array contains two strings, the first is file name and the second is extension.(not contains dot)
		 */
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
		
		/**
		 * <p>判断一个文件是否是图像文件（扩展名为jpg、jpeg和png的）</p>
		 * judge a file is image or not
		 * @param	file	<p>要判断的文件</p>
		 * the file to be judged
		 * @return
		 */
		public static function isImage(file:File):Boolean
		{
			return isPNG(file) || isJPEG(file);
		}
		
		/**
		 * <p>判断一个文件是否是png文件</p>
		 * Judge a file is png or not
		 * @param	file	<p>要判断的文件</p>
		 * The file to be judged
		 * @return
		 */
		public static function isPNG(file:File):Boolean
		{
			var ext:String = getLowerCaseExt(file);
			return ext == "png";
		}
		
		/**
		 * <p>判断一个文件是否是jpg或jpeg文件</p>
		 * Judge a file is jpg or jpeg or not
		 * @param	file	<p>要判断的文件</p>
		 * The file to be judged
		 * @return
		 */
		public static function isJPEG(file:File):Boolean
		{
			var ext:String = getLowerCaseExt(file);
			return ext == "jpg" || ext == "jpeg";
		}
		
		/**
		 * <p>获取文件的小写扩展名</p>
		 * Get lower case of a file extension
		 * @param	file	<p>要获取的文件</p>
		 * The file to be get extension
		 * @return	<p>文件的小写扩展名，如果是文件夹或没有扩展名则返回空字符串</p>
		 * The lower case of the file extension. Return empty string if the file is directory or has no extension.
		 */
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