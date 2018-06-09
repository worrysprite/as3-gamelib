package 
{
	import com.worrysprite.manager.LoaderManager;
	import com.worrysprite.utils.StaticConfig;
	import flash.display.Sprite;
	import flash.net.URLLoaderDataFormat;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public final class Test extends Sprite 
	{
		
		public function Test() 
		{
			// test static config
			LoaderManager.getInstance().loadNow("test.xml", URLLoaderDataFormat.TEXT, onLoaded);
		}
		
		private function onLoaded(txt:String):void 
		{
			var config:StaticConfig = StaticConfig.createFromString(txt);
			trace(config);
		}
		
	}

}