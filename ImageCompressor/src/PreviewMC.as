package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class PreviewMC extends MovieClip
	{
		private var _currentFrame:int;
		
		private var _totalFrames:int;
		
		public function PreviewMC(source:SerialFrames)
		{
			addChild(source);
			
			_totalFrames = source.totalFrames;
			addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
		}
		
		override public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		protected function onEnterFrameHandler(e:Event):void
		{
			_currentFrame++;
			if (_currentFrame > _totalFrames)
				_currentFrame = 1;
		}
	}
}