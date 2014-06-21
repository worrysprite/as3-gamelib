package com.worrysprite.effect
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	/**
	 * 技能冷却效果
	 * @author 王润智
	 */
	public class CooldownEffect extends Sprite
	{
		public static const COOLDOWN_END:String = "eventEnd"; //结束事件
		public static const COOLDOWN_START:String = "eventStart"; //开始事件
		public var color:uint = 0x000000; // 颜色
		public var alphaC:Number = 0.6; // 透明度
		public var isAnti:Boolean = false; // 是否逆时针（剩余的比过去的时间亮）
		public var isRect:Boolean = false; // 是否矩形
		public var a:Number; // 矩形半宽，椭圆的a
		public var b:Number; // 矩形半高，椭圆的b
		public var startFrom:Number = 270; // 从270度开始画
		public var delay:int = 0; // 延迟时间，负数表示已经过了多久（单位：毫秒）
		public var duration:int = 0; // CD时间，单位：毫秒
		public var isCooling:Boolean = false; // 是否正在冷却
		public var startTime:int = 0; // 开始冷却的时刻
		public var basePos:Point;
		public var rect:Rectangle;
		
		/**
		 * 技能冷却效果类
		 * @param w 宽或椭圆的a * 2
		 * @param h 高或椭圆的b * 2
		 * @param $bRect 矩形还是圆形，true为矩形，false为圆形
		 * @param $isHighLight 是否剩余的比过去的时间亮
		 */
		public function CooldownEffect(w:Number, h:Number = 0, isRect:Boolean = true, isHighLight:Boolean = false)
		{
			this.mouseEnabled = false;
			this.mouseChildren = false;
			this.isRect = isRect;
			this.isAnti = isHighLight;
			setSize(w, h);
		}
		
		public function setSize(w:Number, h:Number):void
		{
			h == 0 && (h = w);
			if (isRect)
			{
				this.a = w * Math.SQRT1_2;
				this.b = h * Math.SQRT1_2;
			}
			else
			{
				this.a = w * 0.5;
				this.b = h * 0.5;
			}
			this.basePos = new Point(w * 0.5, h * 0.5);
			rect = new Rectangle(0, 0, w, h);
			this.scrollRect = rect;
		}
		
		/**
		 * 开始冷却
		 * @param $duration 冷却周期（单位：毫秒）
		 * @param $delay 延迟时间，负数表示已经过了多久（单位：毫秒）
		 * @param $enforce 强制刷新时间
		 */
		public function start($duration:int, $delay:int = 0, $enforce:Boolean = false):void
		{
			var time:int = getTimer();
			if (!$enforce && isCooling)
			{
				if (($duration + $delay) < (duration + delay - (time - startTime)))
				{
					// 如果新的冷却时间比原来的还短，不更新
					return;
				}
				stop();
			}
			this.duration = $duration;
			this.delay = $delay;
			this.startTime = time;
			this.isCooling = true;
			this.addEventListener(Event.ENTER_FRAME, draw);
			this.dispatchEvent(new Event(COOLDOWN_START)); //派发事件
		}
		
		/**
		 * 停止冷却
		 */
		public function stop():void
		{
			isCooling = false;
			this.removeEventListener(Event.ENTER_FRAME, draw);
			this.dispatchEvent(new Event(COOLDOWN_END)); //派发事件
		}
		
		/**
		 * 清除效果，停止冷却
		 */
		public function reset():void
		{
			stop();
			clear();
		}
		
		/**
		 * 清除效果
		 */
		private function clear():void
		{
			this.graphics.clear();
		}
		
		protected function draw(e:Event):void
		{
			clear();
			var timePast:int = getTimer() - this.startTime - this.delay;
			if (timePast >= this.duration)
			{
				// 冷却结束
				stop();
				return;
			}
			else if (timePast <= 0) // 冷却还没开始
			{
				var angle:Number = 0;
			}
			else
			{
				angle = timePast * 360 / this.duration;
			}
			drawBack();
			drawAngle(angle);
		}
		
		protected function drawBack():void
		{
			this.graphics.beginFill(0xffcccc, 0);
			if (this.isRect)
			{
				this.graphics.drawRect(0, 0, rect.width, rect.height);
			}
			else
			{
				this.graphics.drawEllipse(0, 0, rect.width, rect.height);
			}
			this.graphics.endFill();
		}
		
		/**
		 * 画一个角度的图形
		 * @param angle 这个角度是顺时针算的。逆时针是360-angle
		 */
		protected function drawAngle(angle:Number):void
		{
			!isAnti && (angle = 360 - angle);
			this.drawSector(angle, isAnti);
		}
		
		/**
		 * 画椭圆扇形
		 * @param angle 角度
		 * @param anti 是否逆时针
		 */
		protected function drawSector(angle:Number, anti:Boolean = false):void
		{
			var factor:int = 1;
			anti || (factor = -1);
			this.graphics.beginFill(color, alphaC);
			this.graphics.lineStyle(0, color, 0);
			this.graphics.moveTo(basePos.x, basePos.y);
			angle = (Math.abs(angle) > 360) ? 360 : angle;
			var n:Number = Math.ceil(Math.abs(angle) / 45);
			var angleA:Number = angle / n;
			angleA = angleA * Math.PI / 180;
			var curA:Number = startFrom;
			curA = curA * Math.PI / 180;
			this.graphics.lineTo(basePos.x + a * Math.cos(curA), basePos.y + b * Math.sin(curA));
			for (var i:int = 0; i < n; ++i)
			{
				curA += factor * angleA;
				var angleMid:Number = curA - factor * angleA / 2;
				var bx:Number = a / Math.cos(angleA / 2) * Math.cos(angleMid);
				var by:Number = b / Math.cos(angleA / 2) * Math.sin(angleMid);
				var cx:Number = a * Math.cos(curA);
				var cy:Number = b * Math.sin(curA);
				this.graphics.curveTo(basePos.x + bx, basePos.y + by, basePos.x + cx, basePos.y + cy);
			}
			this.graphics.endFill();
		}
	}
}
