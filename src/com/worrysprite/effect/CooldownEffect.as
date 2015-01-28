package com.worrysprite.effect
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.getTimer;

	/**
	 * 冷却效果，矩形或圆形的转圈效果
	 * <p>Cooldown effect(round or rect)</p>
	 * @author WorrySprite
	 */
	public class CooldownEffect extends Shape
	{
		/**
		 * CD结束事件
		 * <p>Cooldown end event</p>
		 */
		public static const COOLDOWN_END:String = "cooldown_end";
		/**
		 * CD开始事件
		 * <p>Cooldown start event</p>
		 */
		public static const COOLDOWN_START:String = "cooldown_start";
		/**
		 * 颜色
		 */
		public var color:uint = 0x000000;
		/**
		 * 是否顺时针旋转
		 */
		public var isClockwise:Boolean = true;
		/**
		 * 由填充到抹除
		 */
		public var isFillToErase:Boolean = true;
		/**
		 * 透明度
		 */
		protected var _alpha:Number = 0.6;
		/**
		 * 宽
		 */
		protected var _width:Number = 0;
		/**
		 * 高
		 */
		protected var _height:Number = 0;
		/**
		 * 是否为矩形
		 */
		protected var isRect:Boolean = true; // 是否矩形
		protected var halfWidth:Number;
		protected var halfHeight:Number;
		protected var crossAngle:Number;
		private static const HALF_PI:Number = Math.PI * 0.5;
		
		protected var startFrom:Number = 270; // 从270度开始画
		private var elapsedTime:int = 0; //已经过的时间
		private var totalTime:int = 0; // CD时间，单位：毫秒
		private var startTime:int = 0; // 开始冷却的时刻
		private var centerX:Number = 0;
		private var centerY:Number = 0;
		
		/**
		 * 冷却效果，矩形或圆形的转圈效果
		 * <p>Cooldown effect(round or rect)</p>
		 * @param w 宽或椭圆的a * 2
		 * @param h 高或椭圆的b * 2
		 * @param $bRect 矩形还是圆形，true为矩形，false为圆形
		 * @param $isHighLight 是否剩余的比过去的时间亮
		 */
		public function CooldownEffect(w:Number, h:Number = 0, rect:Boolean = true, clockwise:Boolean = true, fillToErase:Boolean = true)
		{
			isRect = rect;
			isClockwise = clockwise;
			isFillToErase = fillToErase;
			setSize(w, h);
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		protected function onAdded(e:Event):void
		{
			if (elapsedTime < totalTime)
			{
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		protected function onRemoved(e:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		protected function onEnterFrame(e:Event):void
		{
			graphics.clear();
			elapsedTime = getTimer() - startTime;
			if (elapsedTime >= totalTime)
			{
				stop();	//cool down complete
			}
			else
			{
				draw(elapsedTime / totalTime * 360);
			}
			//removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		protected function draw(angle:Number):void
		{
			graphics.beginFill(color, _alpha);
			if (isRect)
			{
				drawRect(angle);
			}
			else
			{
				drawEllipse(angle);
			}
			graphics.endFill();
		}
		
		protected function drawRect(angle:Number):void
		{
			if (!isClockwise)
			{
				angle = 360 - angle;
			}
			var drawClockwise:Boolean = isFillToErase != isClockwise;
			angle = angle * Math.PI / 180;
			graphics.moveTo(centerX, centerY);
			var start:Number = startFrom * Math.PI / 180;
			var currentAngle:Number = start;	//当前绘制角度
			var targetAngle:Number = start + angle;	//要绘制的目标角度
			//trace("target", targetAngle * 180 / Math.PI);
			//先绘制到起始角度，得到下一个转角处角度
			//Draw to start angle first, and get the angle of the next corner.
			var nextAngle:Number = drawToAngle(currentAngle, drawClockwise);
			//转化返回的角度让while比较有效（start到targetAngle）
			//Convert the angle into valid range.(from start to targetAngle)
			if (nextAngle < start)
			{
				nextAngle += 2 * Math.PI;
			}
			//trace("next", nextAngle * 180 / Math.PI);
			while ((drawClockwise && nextAngle < targetAngle) ||
					(!drawClockwise && nextAngle > targetAngle))
			{
				currentAngle = nextAngle;
				nextAngle = drawToAngle(currentAngle, drawClockwise);
				//转化返回的角度让while比较有效（start到targetAngle）
				//Convert the angle into valid range.(from start to targetAngle)
				if (nextAngle < start)
				{
					nextAngle += 2 * Math.PI;
				}
				if ((drawClockwise && currentAngle > nextAngle) ||
					(!drawClockwise && currentAngle < nextAngle))
				{
					break;
				}
				//trace("next", nextAngle * 180 / Math.PI);
			}
			//最后绘制到目标角度
			//At last, draw to the target angle
			drawToAngle(targetAngle, drawClockwise);
			graphics.lineTo(centerX, centerY);
		}
		
		protected function correctAngle(angle:Number):Number
		{
			while (angle < crossAngle)
			{
				angle += 2 * Math.PI;
			}
			while (angle >= 2 * Math.PI + crossAngle)
			{
				angle -= 2 * Math.PI;
			}
			return angle;
		}
		
		/**
		 * 绘制到矩形的一个角度
		 * <p>Draw to an angle of rectangle</p>
		 * @param	angle	要绘制到的角度
		 * <p>The angle want to draw to.</p>
		 * @param	clockwise	是否顺时针绘制，决定返回值是当前绘制角度的哪一侧
		 * <p>Draw by clockwise or not, this will decide the return value is at which side of current angle.</p>
		 * @return	返回下一个转角处的角度
		 * <p>Return the angle of the next corner.</p>
		 */
		protected function drawToAngle(angle:Number, clockwise:Boolean):Number
		{
			angle = correctAngle(angle);	//修正角度
			//trace("drawTo", angle * 180 / Math.PI);
			var smallNum:Number = 0.00001;
			if (crossAngle <= angle && angle < Math.PI - crossAngle)	//底部
			{
				graphics.lineTo(halfWidth + halfHeight / Math.tan(angle), _height);
				if (clockwise)
				{
					return Math.PI - crossAngle + smallNum;
				}
				else
				{
					return crossAngle - smallNum;
				}
			}
			else if (Math.PI - crossAngle <= angle && angle < Math.PI + crossAngle)	//左部
			{
				graphics.lineTo(0, halfHeight - Math.tan(angle) * halfWidth);
				if (clockwise)
				{
					return Math.PI + crossAngle + smallNum;
				}
				else
				{
					return Math.PI - crossAngle - smallNum;
				}
			}
			else if (Math.PI + crossAngle <= angle && angle < 2 * Math.PI - crossAngle)	//顶部
			{
				graphics.lineTo(halfWidth - halfHeight / Math.tan(angle), 0);
				if (clockwise)
				{
					return 2 * Math.PI - crossAngle + smallNum;
				}
				else
				{
					return Math.PI + crossAngle - smallNum;
				}
			}
			else if (2 * Math.PI - crossAngle <= angle && angle < 2 * Math.PI + crossAngle)	//右部
			{
				graphics.lineTo(_width, halfHeight + Math.tan(angle) * halfWidth);
				if (clockwise)
				{
					return 2 * Math.PI + crossAngle + smallNum;
				}
				else
				{
					return 2 * Math.PI - crossAngle - smallNum;
				}
			}
			//防止外部死循环
			//Avoid dead loop outside the function
			return int.MAX_VALUE;
		}
		
		/**
		 * 绘制椭圆
		 * @param	angle
		 */
		protected function drawEllipse(angle:Number):void
		{
			var factor:int = isFillToErase != isClockwise ? 1 : -1;
			if (isFillToErase)
			{
				angle = 360 - angle;
			}
			graphics.moveTo(centerX, centerY);	//中心
			var n:int = Math.ceil(angle / 45);
			var angleSector:Number = angle / n;
			angleSector = angleSector * Math.PI / 180;
			var currentAngle:Number = startFrom * Math.PI / 180;
			graphics.lineTo(centerX + halfWidth * Math.cos(currentAngle), centerY + halfHeight * Math.sin(currentAngle));
			for (var i:int = 0; i < n; ++i)
			{
				currentAngle += factor * angleSector;
				var angleMid:Number = currentAngle - factor * angleSector / 2;
				var bx:Number = halfWidth / Math.cos(angleSector / 2) * Math.cos(angleMid);
				var by:Number = halfHeight / Math.cos(angleSector / 2) * Math.sin(angleMid);
				var cx:Number = halfWidth * Math.cos(currentAngle);
				var cy:Number = halfHeight * Math.sin(currentAngle);
				graphics.curveTo(centerX + bx, centerY + by, centerX + cx, centerY + cy);
			}
		}
		
		/**
		 * 开始冷却
		 * <p>Start cool down</p>
		 * @param total	冷却总时间（单位：毫秒）
		 * <p>Total cool down time in millisecond.</p>
		 * @param elapsed	已经过了的时间（单位：毫秒）
		 * <p>Elapsed time of total cool down time</p>
		 * @param enforce 强制刷新时间
		 */
		public function start(total:int, elapsed:int = 0):void
		{
			if (elapsed >= total || total <= 0 || elapsed < 0)
			{
				trace("invalid cooldown params");
				return;
			}
			totalTime = total;
			elapsedTime = elapsed;
			startTime = getTimer() - elapsed;	//开始时间倒退到elapsed之前
			dispatchEvent(new Event(COOLDOWN_START));
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		/**
		 * 停止冷却
		 */
		public function stop():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			dispatchEvent(new Event(COOLDOWN_END)); //派发事件
		}
		
		/**
		 * 清除效果，停止冷却
		 */
		public function reset():void
		{
			stop();
			graphics.clear();
		}
		
		public function setSize(w:Number, h:Number):void
		{
			_width = w;
			_height = h;
			halfWidth = centerX = w * 0.5;
			halfHeight = centerY = h * 0.5;
			crossAngle = Math.atan2(_height, _width);
		}
		
		/**
		 * 透明度，默认0.6
		 * <p>Alpha, default is 0.6</p>
		 */
		override public function get alpha():Number
		{
			return _alpha;
		}
		
		override public function set alpha(value:Number):void
		{
			_alpha = value;
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		override public function set width(value:Number):void
		{
			if (value > 0)
			{
				setSize(value, _height);
			}
		}
		
		override public function get height():Number
		{
			return _height;
		}
		
		override public function set height(value:Number):void
		{
			if (value > 0)
			{
				setSize(value, _height);
			}
		}
	}
}
