package com.worrysprite.enum
{
	/**
	 * 异常枚举
	 * @author WorrySprite
	 */
	public final class ExceptionEnum
	{
		
		public function ExceptionEnum()
		{
			
		}
		private static const ERR_MSG:Object = new Object();
		/**
		 * 单例类不能多实例化
		 */
		public static const SINGLETON_ERROR:int = 10001;
		ERR_MSG[SINGLETON_ERROR] = "singleton can not construct more instance, use getInstance() instead";
		/**
		 * 函数必须被覆盖
		 */
		public static const FUNCTION_MUST_BE_OVERRIDE:int = 10002;
		ERR_MSG[FUNCTION_MUST_BE_OVERRIDE] = "this function must be override by subclass";
		/**
		 * 静态类不能被实例化
		 */
		public static const STATIC_CLASS_CAN_NOT_CONSTRUCT:int = 10003;
		ERR_MSG[STATIC_CLASS_CAN_NOT_CONSTRUCT] = "static class can not construct, use static members instead";
		
		public static function getExceptionMsg(exception:int):String
		{
			return ERR_MSG[exception];
		}
	}
}