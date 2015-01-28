package com.worrysprite.effect
{
	import com.worrysprite.model.image.ActionVo;
	import com.worrysprite.model.image.AEPFile;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	/**
	 * 动作播放器，播放使用工具打包出来的动作文件
	 * <p>Action player, play actions packed by tools.</p>
	 * @author WorrySprite
	 */
	public class ActionPlayer extends EffectPlayer
	{
		private var _actionList:Vector.<ActionVo>;
		private var actionDic:Dictionary = new Dictionary();
		
		private var _actionIndex:int;
		private var _actionName:String;
		
		/**
		 * 动作播放器，播放使用工具打包出来的动作文件
		 * <p>Action player, play actions packed by tools.</p>
		 */
		public function ActionPlayer()
		{
			super();
		}
		
		/**
		 * 加载完后保存动作列表，设置动作名和动作索引
		 * <p>Save action list on loaded and set action name and index.</p>
		 */
		override protected function onFileLoaded(fileData:ByteArray = null):void
		{
			if (fileData)
			{
				aepFile = AEPFile.createFromBytes(fileData);
			}
			if (aepFile && aepFile.actionList.length)
			{
				_actionList = aepFile.actionList;
				for (var i:int = 0; i < _actionList.length; ++i)
				{
					var action:ActionVo = _actionList[i];
					if (action.directory)
					{
						actionDic[action.directory] = action;
					}
				}
				if (_actionName)
				{
					actionName = _actionName;
				}
				else
				{
					actionIndex = _actionIndex;
				}
				if (onEffectLoaded != null)
				{
					onEffectLoaded.apply(null, onEffectLoadedParams);
				}
				EffectCache.addCache(_effectURL, aepFile);
			}
		}
		
		private function changeAction(action:ActionVo):void
		{
			effectData = action;
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
			}
		}
		
		/**
		 * 当前正在播放的动作索引，从0开始
		 * <p>Action index of current playing, starts from 0.</p>
		 */
		public function get actionIndex():int
		{
			return _actionIndex;
		}
		
		public function set actionIndex(value:int):void
		{
			if (!_actionList)
			{
				_actionIndex = value;	//update on loaded
				return;
			}
			if (value < 0 || value >= _actionList.length)
			{
				trace("action index out of range!");
				value = 0;
			}
			_actionIndex = value;
			changeAction(_actionList[_actionIndex]);
		}
		
		/**
		 * 当前正在播放的动作名
		 * <p>Action name of current playing.</p>
		 */
		public function get actionName():String
		{
			return _actionName;
		}
		
		public function set actionName(value:String):void
		{
			if (!_actionList)
			{
				_actionName = value;	//update on loaded
				return;
			}
			var action:ActionVo = actionDic[value];
			if (action)
			{
				_actionName = value;
				changeAction(action);
			}
			else
			{
				trace("action name does not exist!");
				actionIndex = 0;
			}
		}
		
		/**
		 * 总动作数量
		 * <p>Total action count.</p>
		 */
		public function get actionCount():int
		{
			if (_actionList)
			{
				return _actionList.length;
			}
			return 0;
		}
		
		/**
		 * 动作列表，返回一个浅复制
		 * <p>Action list, return a shallow copy.</p>
		 */
		public function get actionList():Vector.<ActionVo>
		{
			return _actionList.slice();
		}
		
		/**
		 * 当前动作
		 * <p>Current action object.</p>
		 */
		public function get currentAction():ActionVo
		{
			return effectData;
		}
	}
}