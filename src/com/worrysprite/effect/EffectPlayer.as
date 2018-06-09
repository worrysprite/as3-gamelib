package com.worrysprite.effect
{
	import com.worrysprite.manager.LoaderManager;
	import com.worrysprite.manager.HeartbeatManager;
	import com.worrysprite.manager.StageManager;
	import com.worrysprite.model.image.ActionVo;
	import com.worrysprite.model.image.AEPFile;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	/**
	 * <p>位图序列帧播放器，必须先使用<code>StageManager.init(stage)</code>初始化舞台后才能正常播放。注意：为了提高效率，该播放器继承自Bitmap，并且移出显示列表时会停止渲染。</p>
	 * <p>含有以下特征：
	 * <li>设置特效文件URL将自动加载特效文件</li>
	 * <li>可指定循环播放次数</li>
	 * <li>可指定每次循环之间间隔时间</li>
	 * <li>播放完毕自动移出舞台</li>
	 * <li>反向播放</li>
	 * <li>随时改变播放帧率</li>
	 * <li>支持左右镜像</li>
	 * <li>支持每帧回调</li>
	 * <li>支持特定帧回调</li>
	 * <li>支持加载完成回调</li>
	 * <li>支持播放完成回调</li>
	 * </p>
	 * <p>Bitmap sequence frame player, before playing correct, you must init stage using <code>StageManager.init(stage). Notice: for efficiency, this class inherits from Bitmap and will stop rendering when removed from stage.</code></p>
	 * <p>Features:
	 * <li>Auto load effect file when setting effectURL.</li>
	 * <li>Specify loop times.</li>
	 * <li>Specify loop interval.</li>
	 * <li>Auto remove from stage when playing complete.</li>
	 * <li>Reverse playing.</li>
	 * <li>Change playing frame rate at any time.</li>
	 * <li>Support horizontal mirror.</li>
	 * <li>Support enterframe callback.</li>
	 * <li>Support callback on specified frame.</li>
	 * <li>Support callback on effect loaded.</li>
	 * <li>Support callback on playing complete.</li>
	 * </p>
	 * @author WorrySprite
	 */
	public class EffectPlayer extends Bitmap
	{
		private static const changeByte:int = 100;
		
		/**
		 * <p>播放完成回调</p>
		 * Callback when finished playing
		 */
		public var onComplete:Function;
		/**
		 * <p>播放完成回调参数</p>
		 * Callback params when finished playing
		 */
		public var onCompleteParams:Array;
		/**
		 * <p>特效加载完成回调</p>
		 * Callback when effect is loaded
		 */
		public var onEffectLoaded:Function;
		/**
		 * <p>特效加载完成回调参数</p>
		 * Callback params when effect is loaded
		 */
		public var onEffectLoadedParams:Array;
		/**
		 * <p>帧回调函数</p>
		 * Callback on every frame
		 */
		public var onEnterFrame:Function;
		/**
		 * <p>帧回调函数参数</p>
		 * Callback params on every frame
		 */
		public var onEnterFrameParams:Array;
		/**
		 * <p>帧回调函数列表，帧索引从0开始</p>
		 * Frame callback list, frame index starts from 0
		 */
		protected var frameScripts:Array;
		/**
		 * <p>帧回调参数列表，帧索引从0开始</p>
		 * Frame callback params list, frame index starts from 0
		 */
		protected var frameScriptParams:Array;
		/**
		 * <p>特效序列帧数据</p>
		 * Effect sequence frames
		 */
		protected var effectData:ActionVo;
		/**
		 * <p>与特效相关联的动作文件</p>
		 * Related aep file
		 */
		protected var aepFile:AEPFile;
		/**
		 * <p>特效文件URL</p>
		 * Effect aep file url
		 */
		protected var _effectURL:String;
		/**
		 * <p>是否水平镜像</p>
		 * Is horizontal mirror or not
		 */
		protected var _isMirror:Boolean;
		/**
		 * <p>水平镜像对齐点</p>
		 * Horizontal mirror align x
		 */
		protected var _mirrorX:int;
		/**
		 * <p>播放完成自动移除</p>
		 * Auto remove from parent on complete
		 */
		protected var _autoRemoveOnComplete:Boolean;
		/**
		 * <p>当前循环次数</p>
		 * Current loop times
		 */
		protected var _currentLoop:int;
		/**
		 * <p>总循环（播放）次数，包含第1次播放</p>
		 * Total loop(play) times, include the first time.
		 */
		protected var _totalLoop:int;
		/**
		 * <p>帧索引，从0开始</p>
		 * Frame index starts from 0
		 */
		protected var frameIndex:int;
		/**
		 * <p>总帧数</p>
		 * Total frames
		 */
		protected var _totalFrames:int;
		/**
		 * <p>帧率，每秒帧数</p>
		 * Frame rate, frame count in a second.
		 */
		protected var _frameRate:Number;
		/**
		 * <p>循环延迟，每次循环间隔的时间，单位毫秒</p>
		 * Loop delay, interval between every loop in millisecond.
		 */
		protected var _loopDelay:Number;
		/**
		 * <p>基点X坐标</p>
		 * X position of base point
		 */
		protected var _x:Number = 0;
		/**
		 * <p>基点Y坐标</p>
		 * Y position of base point
		 */
		protected var _y:Number = 0;
		/**
		 * <p>是否在播放</p>
		 * Is playing or not
		 */
		protected var isPlaying:Boolean;
		/**
		 * <p>是否在渲染</p>
		 * Is rendering or not
		 */
		protected var isRendering:Boolean;
		/**
		 * <p>是否反向播放</p>
		 * Is reverse playing or not
		 */
		protected var isRevers:Boolean;
		
		/**
		 * <p>位图序列帧播放器，必须先使用<code>StageManager.init(stage)</code>初始化舞台后才能正常播放。注意：为了提高效率，该播放器继承自Bitmap，并且移出显示列表时会停止渲染。</p>
		 * Bitmap sequence frame player, before playing correct, you must init stage using <code>StageManager.init(stage). Notice: for efficiency, this class inherits from Bitmap and will stop rendering when removed from stage.</code>
		 * @param	loopTimes	<p>循环（播放）次数，包含第一次，默认<code>int.MAX_VALUE</code></p>
		 * Loop(play) times, include the first time, default is <code>int.MAX_VALUE</code>.
		 */
		public function EffectPlayer(loopTimes:int = int.MAX_VALUE)
		{
			_totalLoop = loopTimes;
			init();
		}
		
		/**
		 * <p>初始化</p>
		 * Initialization
		 */
		protected function init():void
		{
			_frameRate = StageManager.globalStage.frameRate;
			
			addEventListener(Event.ADDED_TO_STAGE, updateStatus);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		/**
		 * <p>加载特效文件</p>
		 * Load effect file
		 */
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
						aepFile = EffectCache.getEffectFile(_effectURL);
						if (aepFile)
						{
							onFileLoaded();
						}
						else
						{
							LoaderManager.getInstance().loadNow(_effectURL, URLLoaderDataFormat.BINARY, onFileLoaded);
						}
						return;
					}
				}
			}
			stop();
		}
		
		/**
		 * <p>特效文件加载完成回调</p>
		 * Callback on effect loaded
		 * @param	fileData	<p>特效文件数据</p>
		 * Effect file datas
		 */
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
				EffectCache.addCache(_effectURL, aepFile);
			}
		}
		
		/**
		 * <p>更新状态</p>
		 * Update playing or rendering status
		 */
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
		
		/**
		 * <p>移出舞台时的回调</p>
		 * Callback on removed from stage
		 */
		protected function onRemoved(e:Event):void
		{
			if (isRendering)
			{
				HeartbeatManager.removeTimeCall(onRender);
				isRendering = false;
			}
		}
		
		/**
		 * <p>定时渲染回调</p>
		 * Callback on render
		 */
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
						onLoopEnd();
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
						onLoopEnd();
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
		
		/**
		 * <p>更新bitmapData和坐标</p>
		 * Update bitmapData and position
		 */
		protected function update():void
		{
			if (effectData)
			{
				bitmapData = effectData.bitmaps[frameIndex];
				if (_isMirror)
				{
					super.x = _x + _mirrorX - effectData.offsetXs[frameIndex];
					super.y = _y + effectData.offsetYs[frameIndex];
				}
				else
				{
					super.x = _x + effectData.offsetXs[frameIndex] * scaleX;
					super.y = _y + effectData.offsetYs[frameIndex] * scaleY;
				}
			}
			else
			{
				bitmapData = null;
			}
		}
		
		/**
		 * <p>循环播放结束</p>
		 * Loop playing end
		 */
		protected function onLoopEnd():void
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
		
		/**
		 * <p>开始播放</p>
		 * Start playing
		 * @param	reset	<p>是否重置当前帧为第一帧，默认false</p>
		 * Reset current frame to the first frame, default is false.
		 */
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
		
		/**
		 * <p>停止播放</p>
		 * Stop playing
		 */
		public function stop():void
		{
			isPlaying = false;
			updateStatus();
		}
		
		/**
		 * <p>反向播放</p>
		 * Start playing reverse
		 * @param	reset	<p>是否重置当前帧为最后一帧，默认false</p>
		 * Reset current frame to the last frame, default is false.
		 */
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
		 * <p>给某些帧增加回调，该回调触发在onEnterFrame之后</p>
		 * Add callbacks on specified frames, these callbacks will invoked after onEnterFrame.
		 * @param	...rest	<p>参数顺序为帧索引1，回调函数1，回调参数1，帧索引2，回调函数2，回调参数2。注意：帧索引从0开始表示第一帧</p>
		 * Parameters sequence is frame index1, callback1, callback params1, frame index2, callback2, callback params2. Notice: frame index starts from 0.
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
		 * <p>移除帧回调</p>
		 * Remove callback on specified frame.
		 * @param	frame	<p>要移除回调函数的帧索引，-1表示移除所有</p>
		 * The frame index of the callback you want to remove, pass -1 to remove all.
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
				else if (frame < frameScripts.length)
				{
					frameScripts[frame] = null;
					frameScriptParams[frame] = null;
				}
			}
		}
		
		/**
		 * <p>特效文件URL，AEP格式，设置后自动加载该文件</p>
		 * Effect file URL, aep format. Auto load the file after setting this property.
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
		 * <p>总帧数（只读）</p>
		 * Total frames(read only)
		 */
		public function get totalFrames():int
		{
			return _totalFrames;
		}
		
		/**
		 * <p>当前帧数，从1开始</p>
		 * Current frame count, starts from 1.
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
		 * <p>播放帧率，不可大于舞台帧率</p>
		 * Playing frame rate, can not larger than stage.frameRate.
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
		 * <p>总循环（播放）次数，包含第一次</p>
		 * Total loop(play) times, include the first time.
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
		 * <p>当前循环（播放完）次数（只读）</p>
		 * Current loop(played) times.(read only)
		 */
		public function get currentLoop():int
		{
			return _currentLoop;
		}
		
		/**
		 * <p>基点的x坐标</p>
		 * X position of base point
		 */
		override public function get x():Number
		{
			return _x;
		}
		
		override public function set x(value:Number):void
		{
			_x = value;
			update();
		}
		
		/**
		 * <p>基点的Y坐标</p>
		 * Y position of base point
		 */
		override public function get y():Number
		{
			return _y;
		}
		
		override public function set y(value:Number):void
		{
			_y = value;
			update();
		}
		
		/**
		 * <p>是否水平镜像</p>
		 * Is horizontal mirror or not
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
		 * <p>水平镜像对齐点</p>
		 * Horizontal mirror align x
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
		 * <p>循环延迟，每次循环间隔的时间，单位毫秒</p>
		 * Loop delay, interval between every loop in millisecond.
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
		 * <p>播放完成自动移除</p>
		 * Auto remove from parent on complete
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