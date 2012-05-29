package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.system.JPEGLoaderContext;
	import flash.utils.ByteArray;


	public class SerialFrames extends Sprite
	{
		private var _framesData:ByteArray;

		private var _alphaQuality:int;


		private var _serialFrames:Vector.<Frame>;

		private var _parent:MovieClip;
		
		private var _canvas:Bitmap;
		
		

		public function SerialFrames(bts:ByteArray)
		{
			_framesData = bts;
			_framesData.uncompress();
			_framesData.position = 0;
			_alphaQuality = _framesData.readByte();

			_canvas = new Bitmap();
			addChild(_canvas);
			
			_serialFrames = new Vector.<Frame>();
			loadNext();
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler, false, 0, true);
		}
		
		public function get totalFrames():int
		{
			return _serialFrames.length;
		}
		
		protected function addedToStageHandler(e:Event):void
		{
			if (parent is MovieClip)
				_parent = parent as MovieClip;
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}	
		
		protected function removedFromStageHandler(e:Event):void
		{
			_parent = null;
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		protected function enterFrameHandler(e:Event):void
		{
			if (_parent != null)
			{
				var index:int = _parent.currentFrame - 1;
				if (index < 0 || index >= _serialFrames.length)
				{
					_canvas.bitmapData = null;
				}
				else
				{
					var f:Frame = _serialFrames[index];
					_canvas.bitmapData = f;
					if (f != null)
					{
						_canvas.x = f.offsetX;
						_canvas.y = f.offsetY;
					}
				}
			}
		}
		

		/**
		 * 解析字节数组
		 * 
		 */
		private function loadNext():void
		{
			// 解析完成
			if (_framesData.bytesAvailable == 0)
			{
				_framesData.clear();
				_framesData = null;
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}

			// 读取标记位
			var flag:int = _framesData.readByte();
			if (flag == 0) // 使用指定帧
			{
				var index:int = _framesData.readShort();
				_serialFrames.push(_serialFrames[index]);
				loadNext();
			}
			else if (flag == 1) // 空帧
			{
				_serialFrames.push(null);
				loadNext();
			}
			else if (flag == 2) // 解析帧数据
			{
				parseImage();
			}
		}
		
		/**
		 * 解析帧
		 * 
		 */
		private function parseImage():void
		{
			// 解析参数
			var offsetX:int = _framesData.readShort();
			var offsetY:int = _framesData.readShort();
			var width:int = _framesData.readShort();
			var height:int = _framesData.readShort();

			// 解析Alpha通道
			var alphaData:ByteArray = new ByteArray();
			var len:int = _framesData.readInt();
			_framesData.readBytes(alphaData, 0, len);
			alphaData.uncompress();
			alphaData.position = 0;
			var alphaValues:Vector.<int> = _alphaQuality <= 0 ? getLowAlphaData(alphaData) : (_alphaQuality == 1 ? getMediumAlphaData(alphaData) : getHighAlphaData(alphaData));

			// 解析图形字节数组
			var imageData:ByteArray = new ByteArray();
			len = _framesData.readInt();
			_framesData.readBytes(imageData, 0, len);

			// 加载图形
			var loader:Loader = new Loader();
			loader.loadBytes(imageData, new JPEGLoaderContext(1.0));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);

				var tmp:BitmapData = (loader.content as Bitmap).bitmapData;
				var colors:Vector.<uint> = tmp.getVector(tmp.rect);
				for (var i:int = 0; i < colors.length; i++)
				{
					var c:uint = colors[i] & 0xffffff;
					var a:int = alphaValues[i];
					colors[i] = a << 24 | c;
				}

				var f:Frame = new Frame(width, height, true, 0);
				f.setVector(f.rect, colors);
				f.offsetX = offsetX;
				f.offsetY = offsetY;

				_serialFrames.push(f);
				loadNext();
			});
		}

		/**
		 * 解出低品质的Alpha通道
		 * @param alphaData
		 * @return 
		 * 
		 */
		private static function getLowAlphaData(alphaData:ByteArray):Vector.<int>
		{
			var values:Vector.<int> = new Vector.<int>();
			while (alphaData.bytesAvailable > 0)
			{
				var c:int = alphaData.readByte();
				var a1:int = (c >>> 7 & 3) * 255;
				var a2:int = (c >>> 6 & 3) * 255;
				var a3:int = (c >>> 5 & 3) * 255;
				var a4:int = (c >>> 4 & 3) * 255;
				var a5:int = (c >>> 3 & 3) * 255;
				var a6:int = (c >>> 2 & 3) * 255;
				var a7:int = (c >>> 1 & 3) * 255;
				var a8:int = (c & 3) * 255;

				values.push(a1, a2, a3, a4, a5, a6, a7, a8);
			}
			return values;
		}

		/**
		 * 解析中等品质的Alpha通道
		 * @param alphaData
		 * @return 
		 * 
		 */
		private static function getMediumAlphaData(alphaData:ByteArray):Vector.<int>
		{
			var values:Vector.<int> = new Vector.<int>();
			while (alphaData.bytesAvailable > 0)
			{
				var c:int = alphaData.readByte();
				var a1:int = (c >>> 6 & 3) * 85;
				var a2:int = (c >>> 4 & 3) * 85;
				var a3:int = (c >>> 2 & 3) * 85;
				var a4:int = (c & 3) * 85;

				values.push(a1, a2, a3, a4);
			}
			return values;
		}

		/**
		 * 解析高品质的Alpha通道
		 * @param alphaData
		 * @return 
		 * 
		 */
		private static function getHighAlphaData(alphaData:ByteArray):Vector.<int>
		{
			var values:Vector.<int> = new Vector.<int>();
			while (alphaData.bytesAvailable > 0)
			{
				var c:int = alphaData.readByte();
				var a1:int = (c >>> 4 & 0xf) * 17;
				var a2:int = (c & 0xf) * 17;

				values.push(a1, a2);
			}
			return values;
		}
	}
}


import flash.display.BitmapData;

/**
 * 帧定义
 * @author Macro <macro776@gmail.com>
 * 
 */
class Frame extends BitmapData
{
	/**
	 * 偏移量
	 */
	public var offsetX:int;
	
	/**
	 * 偏移量
	 */
	public var offsetY:int;
	
	public function Frame(width:int, height:int, transparent:Boolean = true, fillColor:uint = 0)
	{
		super(width, height, transparent, fillColor);
	}
}