package com.macro.utils.compressor
{
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;


	public class Compressor extends EventDispatcher
	{
		
		public var framesData:ByteArray;
		
		
		private var _bmps:Vector.<BitmapData>;
		
		private var _index:int;
		
		private var _timer:int;
		
		private var _keyCount:int;
		
		private var _offsetX:int;
		
		private var _offsetY:int;
		

		public function Compressor(imageQuality:int = 0, alphaQuality:int = 0)
		{
			this.imageQuality = imageQuality;
			this.alphaQuality = alphaQuality;
		}


		private var _imageQuality:int;

		public function set imageQuality(value:int):void
		{
			if (value == CompressQuality.LOW)
				_imageQuality = 40;
			else if (value == CompressQuality.MEDIUM)
				_imageQuality = 50;
			else if (value == CompressQuality.HIGH)
				_imageQuality = 60;
			else
				_imageQuality = 80;
		}


		private var _alphaQuality:int;

		public function set alphaQuality(value:int):void
		{
			_alphaQuality = value < 0 ? 0 : (value > 2 ? 2 : value);
		}


		public function compress(bmps:Vector.<BitmapData>, offsetX:int, offsetY:int):void
		{
			_timer = getTimer();

			framesData = new ByteArray();
			framesData.writeByte(_alphaQuality);
			
			_offsetX = offsetX;
			_offsetY = offsetY;
			_index = 0;
			_keyCount = 0;
			_bmps = bmps;
			compressFrame();
		}
		
		private function compressFrame():void
		{
			var msg:String;
			
			if (_index >= _bmps.length)
			{
				framesData.compress();
				
				msg = format("关键帧数：{2}\n文件大小：{1}\n压缩耗时：{0}", getTimer() - _timer, framesData.length, _keyCount);
				dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, msg));
				
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			var bmp:BitmapData = _bmps[_index];
			var bts:ByteArray = new ByteArray();
			
			var ret:int = -1;
			if (_index > 0)
			{
				ret = findSameBmp();
			}
			
			
			if (ret >= 0)
			{
				// 使用指定帧
				bts.writeByte(0);
				bts.writeShort(ret);
				
				dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, format("【{0}】引用〖{1}〗", _index + 1, ret + 1)));
			}
			else
			{
				var rect:Rectangle = bmp.getColorBoundsRect(0xFF000000, 0x00000000, false);
				
				if (rect.width * rect.height == 0)
				{
					// 空帧
					bts.writeByte(1);
					
					dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, format("【{0}】null", _index + 1)));
				}
				else
				{
					var tmp:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
					tmp.copyPixels(bmp, rect, new Point());
					
					// 优化调色板
					ColorUtil.optimalPalette(tmp, 128);
					
					// 取Alpha通道
					var alphaData:ByteArray = AlphaUtil.getAlphaData(tmp, _alphaQuality);
					
					// JPEG压缩
					var imageData:ByteArray = new ByteArray();
					tmp.encode(tmp.rect, new JPEGEncoderOptions(_imageQuality), imageData);
					
					bts.writeByte(2);
					bts.writeShort(rect.left - _offsetX);
					bts.writeShort(rect.top - _offsetY);
					bts.writeShort(rect.width);
					bts.writeShort(rect.height);
					bts.writeInt(alphaData.length);
					bts.writeBytes(alphaData);
					bts.writeInt(imageData.length);
					bts.writeBytes(imageData);
					
					_keyCount++;
					msg = format("【{0}】帧大小：{1}　　Alpha通道：{2}", _index + 1, imageData.length, alphaData.length);
					dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, msg));
				}
			}
			framesData.writeBytes(bts);
			
			_index++;
			setTimeout(compressFrame, 1);
		}
		
		private function findSameBmp():int
		{
			var bmp:BitmapData = _bmps[_index];
			var r:Object;
			for (var i:int; i < _index; i++)
			{
				r = bmp.compare(_bmps[i]);
				if (r == 0)
				{
					return i;
				}
			}
			return -1;
		}


		public function format(message:String, ... params):String
		{
			var len:int = params.length;
			for (var i:int = 0; i < len; i++)
			{
				var param:* = params[i];
				if (param is Error)
				{
					var e:Error = param as Error;
					param = "\n" + e.getStackTrace();
				}
				message = message.replace(new RegExp("\\{" + i + "\\}", "g"), param);
			}
			return message;
		}

	}
}
