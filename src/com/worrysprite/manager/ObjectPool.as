package com.worrysprite.manager
{
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	/**
	 * 对象池
	 * @author 王润智
	 */
	public class ObjectPool
	{
		private static var pools:Dictionary = new Dictionary(true);
		private static const matrix:Matrix = new Matrix();
		
		private static function getPool(type:Class):Array
		{
			if (!pools[type])
			{
				return pools[type] = [];
			}
			return pools[type];
		}
		
		/**
		 * 产生一个对象
		 * @param	type
		 * @return
		 */
		public static function getObject(type:Class):Object
		{
			var pool:Array = getPool(type);
			if (pool.length)
			{
				return pool.pop();
			}
			else
			{
				return new type();
			}
		}
		
		/**
		 * 销毁一个对象
		 * @param	obj
		 * @param	type
		 */
		public static function disposeObject(obj:Object, type:Class = null):void
		{
			if (obj == null)
			{
				return;
			}
			if (!type)
			{
				var typeName:String = getQualifiedClassName(obj);
				type = getDefinitionByName(typeName) as Class;
			}
			var pool:Array = getPool(type);
			pool.push(obj);
			
			var displayObj:DisplayObject = obj as DisplayObject;
			if (displayObj)
			{
				displayObj.transform.matrix = matrix;
				displayObj.filters = null;
			}
		}
		
		public static function clear():void
		{
			pools = new Dictionary(true);
		}
	}
}