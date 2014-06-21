package com.worrysprite.exception
{
	/**
	 * 单例异常类
	 * @author 王润智
	 */
	public class SingletonError extends Error
	{
		/**
		 * 单例类重复实例化
		 */
		public static const INSTANCE_DUPLICATE:int = 1;
		
		public function SingletonError(errID:uint)
		{
			switch(errID)
			{
				case INSTANCE_DUPLICATE:
					super("singleton duplicate instance", 10000 + errID);
					break;
			}
		}
	}
}