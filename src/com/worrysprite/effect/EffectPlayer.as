package com.worrysprite.effect
{
	import com.worrysprite.manager.HeartbeatManager;
	import com.worrysprite.manager.StageManager;
	import com.worrysprite.manager.SwfLoaderManager;
	import com.worrysprite.model.swf.BitAndPos;
	import com.worrysprite.model.swf.SwfDataVo;
	import flash.display.Bitmap;
	import flash.events.Event;
	/**
	 * 特效播放
	 * @author WorrySprite
	 */
	public class EffectPlayer extends Bitmap
	{
		private static const changeByte:int = 100;
		
		public var onComplete:Function;
		public var onCompleteParams:Array;
		public var onSwfLoaded:Function;
		public var onSwfLoadedParams:Array;
		protected var frameScripts:Array;
		protected var frameScriptParams:Array;
		
		protected var swfData:SwfDataVo;
		protected var _effectFile:String;
		protected var _isMirror:Boolean;
		protected var _mirrorX:int;
		protected var _autoRemoveOnComplete:Boolean;
		
		protected var _currentLoop:int;
		protected var _maxLoop:int;
		protected var frameIndex:int;
		protected var _totalFrames:int;
		protected var _frameRate:Number;
		protected var _loopDelay:Number;
		
		protected var _offsetX:Number = 0;
		protected var _offsetY:Number = 0;
		
		protected var isPlaying:Boolean;
		protected var isRendering:Boolean;
		protected var isRevers:Boolean;
		
		/**
		 * 位图特效播放器
		 * @param	loopTimes	播放次数
		 */
		public function EffectPlayer(loopTimes:int = int.MAX_VALUE)
		{
			_maxLoop = loopTimes;
			init();
		}
		
		protected function init():void
		{
			_frameRate = StageManager.globalStage.frameRate;
			
			addEventListener(Event.ADDED_TO_STAGE, updateStatus);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		protected function loadFile():void
		{
			swfData = null;
			bitmapData = null;
			if (_effectFile && _effectFile.lastIndexOf(".swf") >= 0)
			{
				swfData = SwfLoaderManager.getInstance().getSwf(_effectFile);
				if (swfData)
				{
					_totalFrames = swfData.totalFrames;
					updateStatus();
					if (isRevers)
					{
						currentFrame = _totalFrames;
					}
					else
					{
						currentFrame = frameIndex + 1;
					}
					if (onSwfLoaded != null)
					{
						onSwfLoaded.apply(null, onSwfLoadedParams);
					}
				}
				else
				{
					SwfLoaderManager.getInstance().queueLoad(_effectFile, onFileLoaded);
				}
			}
			else
			{
				stop();
			}
		}
		
		protected function onFileLoaded():void
		{
			swfData = SwfLoaderManager.getInstance().getSwf(_effectFile);
			_totalFrames = swfData.totalFrames;
			updateStatus();
			if (isRevers)
			{
				currentFrame = _totalFrames;
			}
			else
			{
				currentFrame = frameIndex + 1;
			}
			if (onSwfLoaded != null)
			{
				onSwfLoaded.apply(null, onSwfLoadedParams);
			}
		}
		
		protected function updateStatus(e:Event = null):void
		{
			if (isPlaying && stage && swfData && _frameRate != 0)
			{
				if (!isRendering)
				{
					HeartbeatManager.addTimeCall(1000 / _frameRate, onRender);
					isRendering = true;
				}
			}
			else
			{
				if (isRendering)
				{
					HeartbeatManager.removeTimeCall(onRender);
					isRendering = false;
				}
			}
		}
		
		protected function onRemoved(e:Event):void
		{
			if (isRendering)
			{
				HeartbeatManager.removeTimeCall(onRender);
				isRendering = false;
			}
		}
		
		protected function onRender():void
		{
			update();
			if (isRevers)
			{
				if (--frameIndex <= 0)
				{
					if (++_currentLoop == _maxLoop)	//循环播放结束
					{
						onLoop();
					}
					else
					{
						frameIndex = _totalFrames - 1;
						if (_loopDelay > 0)
						{
							stop();
							HeartbeatManager.addTimeCall(_loopDelay, play, 0);
						}
					}
				}
			}
			else
			{
				if (++frameIndex >= _totalFrames)
				{
					if (++_currentLoop == _maxLoop)
					{
						onLoop();
					}
					else
					{
						frameIndex = 0;
						if (_loopDelay > 0)
						{
							stop();
							HeartbeatManager.addTimeCall(_loopDelay, play, 0);
						}
					}
				}
			}
			if (frameScripts)
			{
				var script:Function = frameScripts[frameIndex];
				var params:Array = frameScriptParams[frameIndex];
				if (script != null)
				{
					script.apply(null, params);
				}
			}
		}
		
		protected function update():void
		{
			if (swfData)
			{
				var bap:BitAndPos = swfData.getBitAndPos(0, 0, frameIndex);
				if (bap)
				{
					bitmapData = bap.bmpData;
					if (_isMirror)
					{
						super.x = _offsetX + _mirrorX - bap.x;
						super.y = _offsetY + bap.y;
					}
					else
					{
						super.x = _offsetX + bap.x * scaleX;
						super.y = _offsetY + bap.y * scaleY;
					}
				}
			}
			else
			{
				bitmapData = null;
			}
		}
		
		protected function onLoop():void
		{
			_currentLoop = 0;
			stop();
			if (_autoRemoveOnComplete && parent)
			{
				parent.removeChild(this);
			}
			if (onComplete != null)
			{
				onComplete.apply(null, onCompleteParams);
			}
		}
		
		public function play(reset:Boolean = false):void
		{
			isRevers = false;
			isPlaying = true;
			updateStatus();
			if (reset)
			{
				currentFrame = 1;
			}
		}
		
		public function stop():void
		{
			isPlaying = false;
			updateStatus();
		}
		
		public function playRevers(reset:Boolean = false):void
		{
			isPlaying = true;
			isRevers = true;
			if (reset)
			{
				currentFrame = _totalFrames;
			}
			updateStatus();
		}
		
		/**
		 * 给某帧增加回调，进入帧之前（渲染之前）回调
		 * @param	...rest	参数顺序为帧索引1，回调函数1，回调参数1，帧索引2，回调函数2，回调参数2
		 */
		public function addFrameScript(...rest):void
		{
			if (frameScripts == null)
			{
				frameScripts = [];
				frameScriptParams = [];
			}
			var frame:int;
			var script:Function;
			var params:Array;
			for (var i:int = 0; i < rest.length; i += 3)
			{
				frame = rest[i];
				script = rest[i + 1];
				params = rest[i + 2];
				frameScripts[frame] = script;
				frameScriptParams[frame] = params;
			}
		}
		
		/**
		 * 移除帧回调
		 * @param	frame	移除某帧上的回调，-1表示移除所有
		 */
		public function removeFrameScript(frame:int):void
		{
			if (frameScripts && frameScriptParams)
			{
				if (frame < 0)
				{
					frameScripts.length = 0;
					frameScriptParams.length = 0;
				}
				else
				{
					frameScripts[frame] = null;
					frameScriptParams[frame] = null;
				}
			}
		}
		
		/**
		 * 特效文件
		 */
		public function get effectFile():String
		{
			return _effectFile;
		}
		
		public function set effectFile(value:String):void
		{
			if (_effectFile != value)
			{
				_effectFile = value;
				loadFile();
			}
		}
		
		/**
		 * 总帧数（只读）
		 */
		public function get totalFrames():int
		{
			return _totalFrames;
		}
		
		/**
		 * 当前帧
		 */
		public function get currentFrame():int
		{
			return frameIndex + 1;
		}
		
		public function set currentFrame(value:int):void
		{
			frameIndex = value - 1;
			if (_totalFrames <= 0)
			{
				return;
			}
			if (frameIndex < 0)
			{
				frameIndex = 0;
			}
			else if (frameIndex >= _totalFrames)
			{
				frameIndex = _totalFrames - 1;
			}
			update();
		}
		
		/**
		 * 帧率
		 */
		public function get frameRate():Number
		{
			return _frameRate;
		}
		
		public function set frameRate(value:Number):void
		{
			var stageFrameRate:int = StageManager.globalStage.frameRate;
			if (value > stageFrameRate)
			{
				value = stageFrameRate;
			}
			if (_frameRate != value)
			{
				_frameRate = value;
				if (isRendering)
				{
					HeartbeatManager.removeTimeCall(onRender);
					isRendering = false;
					updateStatus();
				}
			}
		}
		
		/**
		 * 最大循环次数
		 */
		public function get maxLoop():int
		{
			return _maxLoop;
		}
		
		public function set maxLoop(value:int):void
		{
			_maxLoop = value;
		}
		
		/**
		 * 当前循环次数（只读）
		 */
		public function get currentLoop():int
		{
			return _currentLoop;
		}
		
		/**
		 * 偏移量X
		 */
		override public function get x():Number
		{
			return _offsetX;
		}
		
		override public function set x(value:Number):void
		{
			_offsetX = value;
			update();
		}
		
		/**
		 * 偏移量Y
		 */
		override public function get y():Number
		{
			return _offsetY;
		}
		
		override public function set y(value:Number):void
		{
			_offsetY = value;
			update();
		}
		
		/**
		 * 是否镜像
		 */
		public function get isMirror():Boolean
		{
			return _isMirror;
		}
		
		public function set isMirror(value:Boolean):void
		{
			_isMirror = value;
			if (_isMirror)
			{
				if (scaleX > 0)
				{
					scaleX *= -1;
				}
			}
			else
			{
				if (scaleX < 0)
				{
					scaleX *= -1;
				}
			}
			update();
		}
		
		/**
		 * 左右镜像对齐点
		 */
		public function get mirrorX():int
		{
			return _mirrorX >> 1;
		}
		
		public function set mirrorX(value:int):void
		{
			_mirrorX = value << 1;
			update();
		}
		
		/**
		 * 每次循环之间的间隔时间，单位毫秒
		 */
		public function get loopDelay():int
		{
			return _loopDelay;
		}
		
		public function set loopDelay(value:int):void
		{
			_loopDelay = value;
		}
		
		/**
		 * 播放完毕后自动移除
		 */
		public function get autoRemoveOnComplete():Boolean
		{
			return _autoRemoveOnComplete;
		}
		
		public function set autoRemoveOnComplete(value:Boolean):void
		{
			_autoRemoveOnComplete = value;
		}
	}
}