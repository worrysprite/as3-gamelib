package com.worrysprite.utils
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	/**
	 * 客户端静态配置数据
	 * @author 王润智
	 */
	public class StaticConfig
	{
		private var configData:Object;
		
		/**
		 * 通过配置名获取配置数据
		 * @param	configName	配置名
		 * @return	配置数据，任意类型
		 */
		public function getConfigByName(configName:String):Object
		{
			return configData[configName];
		}
		
		public function StaticConfig()
		{
			
		}
		
		/**
		 * 由文本文件创建
		 * @param	byte	文本文件的二进制字节
		 * @return	解析好的配置
		 */
		public static function createFromByte(byte:ByteArray):StaticConfig
		{
			var config:StaticConfig = new StaticConfig();
			var str:String = byte.readUTFBytes(byte.length);
			config.readConfig(str);
			return config;
		}
		
		/**
		 * 由字符串创建
		 * @param	str	XML字符串
		 * @return	解析好的配置
		 */
		public static function createFromString(str:String):StaticConfig
		{
			var config:StaticConfig = new StaticConfig();
			config.readConfig(str);
			return config;
		}
		
		public function readConfig(str:String):void
		{
			configData = new Object();
			var xml:XML = XML(str);
			for each(var data:XML in xml.config)
			{
				configData[data.@name] = parseData(data);
			}
		}
		
		/**
		 * 将一条XML数据解析成一个AS3数据对象
		 * @param	data	包含有class属性的一个XML
		 * @return	根据data的class解析出来数据的值
		 */
		private static function parseData(data:XML):*
		{
			var className:String = data.@type;
			switch(className)
			{
				case "int":
					return int(data.@value);
					
				case "uint":
					return uint(data.@value);
					
				case "Boolean":
					return Boolean(data.@value);
					
				case "Number":
					return Number(data.@value);
					
				case "String":
					return String(data.@value);
					
				case "Array":
					return parseArray(data.element);
					
				default:
					return parseObject(className, data.field);
			}
			return null;
		}
		
		private static function parseArray(dataList:XMLList):Array
		{
			var result:Array = [];
			for each(var element:XML in dataList)
			{
				if (element.@index)
				{
					result[int(element.@index)] = parseData(element);
				}
				else
				{
					result.push(parseData(element));
				}
			}
			return result;
		}
		
		static private function parseObject(className:String, fields:XMLList):Object
		{
			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
			if (!domain.hasDefinition(className))
			{
				trace("找不到类型定义：", className);
				return null;
			}
			var ClassRef:Class = domain.getDefinition(className) as Class;
			var result:Object = new ClassRef();
			for each(var field:XML in fields)
			{
				result[String(field.@name)] = parseData(field);
			}
			return result;
		}
	}
}