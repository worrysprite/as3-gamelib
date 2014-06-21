package com.worrysprite.exception
{
	/**
	 * 继承错误
	 * @author 王润智
	 */
	public class InheritError extends Error
	{
		/**
		 * 必须覆盖方法
		 */
		public static const MUST_OVERRIDE:int = 1;
		
		public function InheritError(errID:uint)
		{
			switch(errID)
			{
				case MUST_OVERRIDE:
					super("function must be override", 20000 + errID);
					break;
			}
		}
		
	}

}