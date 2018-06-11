package
{
	import com.worrysprite.manager.HeartbeatManager;
	import com.worrysprite.manager.LoaderManager;
	import com.worrysprite.utils.StaticConfig;
	import com.worrysprite.view.component.menu.Menu;
	import com.worrysprite.view.component.menu.MenuItem;
	import com.worrysprite.view.component.menu.PopupMenu;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.URLLoaderDataFormat;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public final class Test extends Sprite
	{
		public function Test()
		{
			HeartbeatManager.init(stage);
			
			// test static config
			//testConfig();
			
			// test menu
			testMenu();
			
			// test popup menu
			//testPopupMenu();
			
			// test radio button
			
		}
		
		private function testConfig():void
		{
			LoaderManager.getInstance().loadNow("test.xml", URLLoaderDataFormat.TEXT, function(txt:String):void
			{
				var config:StaticConfig = StaticConfig.createFromString(txt);
				trace(config.getConfigByName("aa"));
				trace(config.getConfigByName("bb"));
				trace(config.getConfigByName("cc"));
				trace(config.getConfigByName("dd"));
				var data:DataVo = config.getConfigByName("ee") as DataVo;
				trace(data.id, data.name);
			});
		}
		
		private function testMenu():void
		{
			var menu:Menu = new Menu();
			var file:MenuItem = new MenuItem("文件");
			
			var subMenu:PopupMenu = new PopupMenu();
			subMenu.addItem(new MenuItem("新建"));
			subMenu.addItem(new MenuItem("打开"));
			subMenu.addItem(new MenuItem("保存"));
			subMenu.addItem(new MenuItem("关闭"));
			file.subMenu = subMenu;
			
			menu.addItem(file);
			menu.addItem(new MenuItem("编辑"));
			menu.addItem(new MenuItem("视图"));
			menu.addItem(new MenuItem("项目"));
			menu.addItem(new MenuItem("帮助"));
			addChild(menu);
		}
		
		private function testPopupMenu():void
		{
			var menu:PopupMenu = new PopupMenu();
			menu.addItem(new MenuItem("文件"));
			menu.addItem(new MenuItem("编辑"));
			menu.addItem(new MenuItem("视图"));
			menu.addItem(new MenuItem("项目"));
			menu.addItem(new MenuItem("帮助"));
			
			stage.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				menu.popup(e.stageX, e.stageY, stage);
			});
		}
		
	}

}