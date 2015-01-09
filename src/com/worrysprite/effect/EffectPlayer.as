package com.worrysprite.effect
{
	import com.worrysprite.manager.BinaryLoaderManager;
	import com.worrysprite.manager.HeartbeatManager;
	import com.worrysprite.manager.StageManager;
	import com.worrysprite.model.image.ActionVo;
	import com.worrysprite.model.image.AEPFile;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	/**
	 * 特效播放器
	 * @author WorrySprite
	 */
	public class EffectPlayer extends Bitmap
	{
		private static const changeByte:int = 100;
		
		/**
		 * 播放完成回调<br/>
		 * callback when finished playing
		 */
		public var onComplete:Function;
		/**
		 * 播放完成回调参数<br/>
		 * callback params when finished playing
		 */
		public var onCompleteParams:Array;
		/**
		 * 特效加载完成回调<br/>
		 * callback when effect is loaded
		 */
		public var onEffectLoaded:Function;
		/**
		 * 特效加载完成回调参数<br/>
		 * callback params when effect is loaded
		 */
		public var onEffectLoadedParams:Array;
		/**
		 * 帧回调函数
		 */
		public var onEnterFrame:Function;
		/**
		 * 帧回调函数参数
		 */
		public var onEnterFrameParams:Array;
		
		/**
		 * 帧回调函数列表，帧索引从0开始<br/>
		 * frame callback list, frame index starts from 0
		 */
		protected var frameScripts:Array;
		/**
		 * 帧回调参数列表，帧索引从0开始<br/>
		 * frame callback params list, frame index starts from 0
		 */
		protected var frameScriptParams:Array;
		/**
		 * 特效序列帧数据<br/>
		 * effect sequence frames
		 */
		protected var effectData:ActionVo;
		/**
		 * 与特效相关联的动作文件<br/>
		 * related aep file
		 */
		protected var aepFile:AEPFile;
		
		protected var _effectURL:String;
		protected var _isMirror:Boolean;
		protected var _mirrorX:int;
		protected var _autoRemoveOnComplete:Boolean;
		
		protected var _currentLoop:int;
		protected var _totalLoop:int;
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
			_totalLoop = loopTimes;
			init();
		}
		
		protected function init():void
		{
			_frameRate = StageManager.globalStage.frameRate;
			
			addEventListener(Event.ADDED_TO_STAGE, updateStatus);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		protected function loadEffect():void
		{
			effectData = null;
			bitmapData = null;
			if (_effectURL)
			{
				var index:int = _effectURL.lastIndexOf(".");
				if (index >= 0)
				{
					if (_effectURL.toLowerCase().substr(index + 1) == "aep")
					{
						aepFile = EffectManager.getEffectFile(_effectURL);
						if (aepFile)
						{
							onFileLoaded();
						}
						else
						{
							BinaryLoaderManager.getInstance().loadNow(_effectURL, URLLoaderDataFormat.BINARY, onFileLoaded);
						}
						return;
					}
				}
			}
			stop();
		}
		
		protected function onFileLoaded(fileData:ByteArray = null):void
		{
			if (fileData)
			{
				aepFile = AEPFile.createFromBytes(fileData);
			}
			if (aepFile && aepFile.actionList.length)
			{
				effectData = aepFile.actionList[0];
				if (effectData)
				{
					_totalFrames = effectData.bitmaps.length;
					frameRate = 1000 / effectData.interval;
					updateStatus();
					if (isRevers)
					{
						currentFrame = _totalFrames;
					}
					else
					{
						currentFrame = frameIndex + 1;
					}
					if (onEffectLoaded != null)
					{
						onEffectLoaded.apply(null, onEffectLoadedParams);
					}
				}
				EffectManager.addCache(_effectURL, aepFile);
			}
		}
		
		protected function updateStatus(e:Event = null):void
		{
			if (isPlaying && stage && effectData && _frameRate != 0)
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
			if (onEnterFrame != null)
			{
				onEnterFrame.apply(null, onEnterFrameParams);
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
			if (isRevers)
			{
				if (--frameIndex <= 0)
				{
					frameIndex = _totalFrames - 1;
					if (++_currentLoop >= _totalLoop)	//循环播放结束
					{
						onLoop();
					}
					else
					{
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
					frameIndex = 0;
					if (++_currentLoop >= _totalLoop)
					{
						onLoop();
					}
					else
					{
						if (_loopDelay > 0)
						{
							stop();
							HeartbeatManager.addTimeCall(_loopDelay, play, 0);
						}
					}
				}
			}
		}
		
		protected function update():void
		{
			if (effectData)
			{
				bitmapData = effectData.bitmaps[frameIndex];
				if (_isMirror)
				{
					super.x = _offsetX + _mirrorX - effectData.offsetXs[frameIndex];
					super.y = _offsetY + effectData.offsetYs[frameIndex];
				}
				else
				{
					super.x = _offsetX + effectData.offsetXs[frameIndex] * scaleX;
					super.y = _offsetY + effectData.offsetYs[frameIndex] * scaleY;
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
		 * 特效文件，AEP格式
		 * effect file, *.aep
		 */
		public function get effectURL():String
		{
			return _effectURL;
		}
		
		public function set effectURL(value:String):void
		{
			if (_effectURL != value)
			{
				_effectURL = value;
				loadEffect();
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
		 * 总循环播放次数
		 */
		public function get totalLoop():int
		{
			return _totalLoop;
		}
		
		public function set totalLoop(value:int):void
		{
			_totalLoop = value;
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