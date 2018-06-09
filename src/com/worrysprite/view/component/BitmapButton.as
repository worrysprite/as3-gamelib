package com.worrysprite.view.component
{
	import com.worrysprite.effect.CooldownEffect;
	import com.worrysprite.enum.Common;
	import com.worrysprite.manager.BmpResManager;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * 标准按钮
	 * @author 王润智
	 */
	public class BitmapButton extends Sprite
	{
		protected var _upStatus:String;
		protected var _overStatus:String;
		protected var _downStatus:String;
		protected var _disableStatus:String;
		protected var currentStatus:String;
		
		protected var background:Bitmap;
		protected var _textfield:BitmapLabel;
		protected var cdEffect:CooldownEffect;
		
		protected var centerPoint:Point;
		protected var _cooldownTime:uint;
		protected var _selected:Boolean = false;
		protected var _enabled:Boolean = true;
		protected var _downScaleRate:Number = 0.9;
		
		public function BitmapButton(up:String)
		{
			_upStatus = up;
			initView();
		}
		
		protected function initView():void
		{
			//初始化使用普通状态
			currentStatus = _upStatus;
			background = new Bitmap(BmpResManager.getBitmapResource(_upStatus));
			centerPoint = new Point(background.width * 0.5, background.height * 0.5);
			addChild(background);
			
			mouseChildren = false;
			buttonMode = true;
			
			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHandler);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandler);
		}
		
		private function onRollOver(e:MouseEvent):void
		{
			if (e.buttonDown)
			{
				changeStatus(_downStatus);
			}
			else
			{
				changeStatus(_overStatus);
			}
		}
		
		private function onRollOut(e:MouseEvent):void
		{
			if (mouseEnabled)
			{
				changeStatus(_upStatus);
			}
		}
		
		private function onMouseDownHandler(e:MouseEvent = null):void
		{
			changeStatus(_downStatus);
		}
		
		private function onMouseUpHandler(e:MouseEvent = null):void
		{
			if (mouseEnabled)
			{
				changeStatus(_upStatus);
			}
		}
		
		private function changeStatus(status:String):void
		{
			if (currentStatus != status)
			{
				currentStatus = status;
				background.bitmapData = BmpResManager.getBitmapResource(status);
				background.x = centerPoint.x - background.width * 0.5;
				background.y = centerPoint.y - background.height * 0.5;
			}
			if (_textfield)
			{
				if (status == _upStatus)
				{
					_textfield.scaleX = _textfield.scaleY = 1;
					_textfield.x = centerPoint.x - _textfield.textWidth * 0.5;
					_textfield.y = centerPoint.y - _textfield.textHeight * 0.5;
				}
				else if (status == _downStatus)
				{
					_textfield.scaleX = _textfield.scaleY = _downScaleRate;
					_textfield.x = centerPoint.x - _textfield.textWidth * 0.5 * _downScaleRate;
					_textfield.y = centerPoint.y - _textfield.textHeight * 0.5 * _downScaleRate;
				}
			}
		}
		
		private function onClick(e:MouseEvent):void
		{
			cdEffect.start(_cooldownTime);
			mouseEnabled = false;
		}
		
		private function initCooldownEffect():void
		{
			if (cdEffect == null)
			{
				cdEffect = new CooldownEffect(width, height);
				addChild(cdEffect);
				cdEffect.addEventListener(CooldownEffect.COOLDOWN_END, onCDEnd);
			}
		}
		
		private function onCDEnd(e:Event):void
		{
			mouseEnabled = true;
		}
		
		private function updateStatus():void
		{
			mouseEnabled = !_selected && _enabled;
			if (_enabled)
			{
				filters = null;
				if (_selected)
				{
					changeStatus(_downStatus);
				}
				else
				{
					changeStatus(_upStatus);
				}
			}
			else
			{
				if (_selected)
				{
					changeStatus(_downStatus);
				}
				else
				{
					changeStatus(_upStatus);
				}
				if (_disableStatus != null)
				{
					changeStatus(_disableStatus);
				}
				else
				{
					filters = [Common.GRAY_FILTER];
				}
			}
		}
		
		public function get cooldownTime():uint
		{
			return _cooldownTime;
		}
		
		public function set cooldownTime(value:uint):void
		{
			if (_cooldownTime == value)
			{
				return;
			}
			_cooldownTime = value;
			if (_cooldownTime > 0)
			{
				initCooldownEffect();
				addEventListener(MouseEvent.CLICK, onClick);
			}
			else
			{
				if (cdEffect)
				{
					if (cdEffect.parent)
					{
						removeChild(cdEffect);
					}
					cdEffect.removeEventListener(CooldownEffect.COOLDOWN_END, onCDEnd);
					cdEffect = null;
				}
				removeEventListener(MouseEvent.CLICK, onClick);
			}
		}
		
		/**
		 * 标签文字
		 */
		public function get label():String
		{
			if (_textfield)
			{
				return _textfield.text;
			}
			return null;
		}
		
		public function set label(value:String):void
		{
			if (value)
			{
				if (_textfield == null)
				{
					_textfield = new BitmapLabel();
					addChild(_textfield);
				}
				_textfield.text = value;
				changeStatus(currentStatus);
			}
			else
			{
				if (_textfield)
				{
					_textfield.text = null;
				}
			}
		}
		
		/* DELEGATE com.ztstudio.utils.BitmapLabel */
		public function get textFilters():Array
		{
			if (_textfield)
			{
				return _textfield.filters;
			}
			return null;
		}
		
		public function set textFilters(value:Array):void
		{
			if (value)
			{
				if (_textfield == null)
				{
					_textfield = new BitmapLabel();
					addChild(_textfield);
				}
				_textfield.filters = value;
			}
		}
		
		public function get textSize():int
		{
			if (_textfield)
			{
				return _textfield.size;
			}
			return 0;
		}
		
		public function set textSize(value:int):void
		{
			if (value > 0)
			{
				if (_textfield == null)
				{
					_textfield = new BitmapLabel();
					addChild(_textfield);
				}
				_textfield.size = value;
				changeStatus(currentStatus);
			}
		}
		
		/**
		 * 选中状态
		 */
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function set selected(value:Boolean):void
		{
			if (_selected != value)
			{
				_selected = value;
				updateStatus();
			}
		}
		
		/**
		 * 启用状态
		 */
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			if (_enabled != value)
			{
				_enabled = value;
				updateStatus();
			}
		}
		
		public function get upStatus():String
		{
			return _upStatus;
		}
		
		public function set upStatus(value:String):void
		{
			_upStatus = value;
		}
		
		public function get overStatus():String
		{
			return _overStatus;
		}
		
		public function set overStatus(value:String):void
		{
			_overStatus = value;
		}
		
		public function get downStatus():String
		{
			return _downStatus;
		}
		
		public function set downStatus(value:String):void
		{
			_downStatus = value;
		}
		
		public function get disableStatus():String
		{
			return _disableStatus;
		}
		
		public function set disableStatus(value:String):void
		{
			_disableStatus = value;
		}
		
		public function get downScaleRate():Number
		{
			return _downScaleRate;
		}
		
		public function set downScaleRate(value:Number):void
		{
			_downScaleRate = value;
		}
		
		public function startCooldown(time:uint):void
		{
			initCooldownEffect();
			cdEffect.start(time);
			mouseEnabled = false;
		}
	}
}