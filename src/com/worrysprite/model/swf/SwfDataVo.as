package com.worrysprite.model.swf
{
	import com.worrysprite.enum.UnitActionEnum;
	import com.worrysprite.enum.UnitDirectionEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	/**
	 * 储存使用工具生成的swf数据
	 * @author 王润智
	 */
	public class SwfDataVo
	{
		public static const MAX_WIDTH:int = 512;
		public static const HALF_WIDTH:int = MAX_WIDTH / 2;
		
		private var bitmapList:Array;
		
		private var _swf:Sprite;
		private var _actionType:int;	//类型，普通=0，动作=其他
		
		public function SwfDataVo(swf:Sprite, type:int = 0)
		{
			_swf = swf;
			_actionType = type;
			analyseSwf();
		}
		
		private function analyseSwf():void
		{
			if (!_swf)
			{
				trace("无效的动作包");
				return;
			}
			
			bitmapList = [];
			var action:int;
			var bap:BitAndPos;
			var bmp:Bitmap;
			var frameCount:int;
			var i:int;
			if (_actionType == 0)	//作为普通特效解析
			{
				for (i = 0; i < _swf.numChildren; ++i)
				{
					bmp = _swf.getChildAt(i) as Bitmap;
					if (bmp)
					{
						bap = new BitAndPos();
						bap.bmpData = bmp.bitmapData;
						bap.x = bmp.x;
						bap.y = bmp.y;
						bitmapList[i] = bap;
					}
				}
			}
			else	//作为动作解析
			{
				for (i = 1; i <= UnitActionEnum.MAX_ACTION; ++i)	//遍历每种动作
				{
					bitmapList[i] = [];
					frameCount = UnitActionEnum.getFrameCount(i);
					
					bitmapList[i][UnitDirectionEnum.LEFT] = [];
					bitmapList[i][UnitDirectionEnum.RIGHT] = [];
					for (var k:int = 0; k < frameCount; ++k)	//遍历每一帧
					{
						bmp = _swf.removeChildAt(0) as Bitmap;
						if (!bmp)
						{
							continue;
						}
						//读取右方向
						bap = new BitAndPos();
						bap.bmpData = bmp.bitmapData;
						bap.x = bmp.x;
						bap.y = bmp.y;
						bitmapList[i][UnitDirectionEnum.RIGHT][k] = bap;
						
						//镜像左方向
						bap = new BitAndPos();
						bap.bmpData = getMirror(bmp.bitmapData);
						bap.x = MAX_WIDTH - bmp.width - bmp.x;
						bap.y = bmp.y;
						bitmapList[i][UnitDirectionEnum.LEFT][k] = bap;
					}
				}
			}
		}
		
		private function getMirror(bmd:BitmapData):BitmapData
		{
			var result:BitmapData = new BitmapData(bmd.width, bmd.height, bmd.transparent, 0);
			var matrix:Matrix = new Matrix(-1, 0, 0, 1, bmd.width, 0);
			result.draw(bmd, matrix);
			return result;
		}
		
		public function getBitAndPos(action:int, direction:int, frameIndex:int):BitAndPos
		{
			if (bitmapList)
			{
				if (_actionType == 0)
				{
					return bitmapList[frameIndex];
				}
				else if (bitmapList[action])
				{
					var frames:Array = bitmapList[action][direction];
					if (frames)
					{
						return frames[frameIndex % frames.length];
					}
				}
			}
			return null;
		}
		
		public function get totalFrames():int
		{
			return _swf.numChildren;
		}
		
		public function get unitType():int
		{
			return _actionType;
		}
		
		public function get swf():Sprite
		{
			return _swf;
		}
	}
}