package com.macro.utils.compressor
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;


	public class AlphaUtil
	{
		public static function getAlphaData(image:BitmapData, alphaQuality:int):ByteArray
		{
			var alphaData:ByteArray = new ByteArray();
			var colors:Vector.<uint> = image.getVector(image.rect);

			if (alphaQuality == CompressQuality.LOW)
				getLowAlphaData(alphaData, colors);
			else if (alphaQuality == CompressQuality.MEDIUM)
				getMediumAlphaData(alphaData, colors);
			else
				getHighAlphaData(alphaData, colors);

			alphaData.compress();
			return alphaData;
		}

		private static function getLowAlphaData(alphaData:ByteArray, colors:Vector.<uint>):void
		{
			var len:uint = colors.length;
			for (var j:int = 0; j < len; j++)
			{
				var c1:uint = colors[j];
				var c2:uint = (++j < len) ? colors[j] : 0;
				var c3:uint = (++j < len) ? colors[j] : 0;
				var c4:uint = (++j < len) ? colors[j] : 0;
				var c5:uint = (++j < len) ? colors[j] : 0;
				var c6:uint = (++j < len) ? colors[j] : 0;
				var c7:uint = (++j < len) ? colors[j] : 0;
				var c8:uint = (++j < len) ? colors[j] : 0;

				var a1:int = (c1 >>> 24) / 255;
				var a2:int = (c2 >>> 24) / 255;
				var a3:int = (c3 >>> 24) / 255;
				var a4:int = (c4 >>> 24) / 255;
				var a5:int = (c5 >>> 24) / 255;
				var a6:int = (c6 >>> 24) / 255;
				var a7:int = (c7 >>> 24) / 255;
				var a8:int = (c8 >>> 24) / 255;

				alphaData.writeByte(a1 << 7 | a2 << 6 | a3 << 5 | a4 << 4 | a5 << 3 | a6 << 2 | a7 << 1 | a8);
			}
		}

		private static function getMediumAlphaData(alphaData:ByteArray, colors:Vector.<uint>):void
		{
			var len:uint = colors.length;
			for (var j:int = 0; j < len; j++)
			{
				var c1:uint = colors[j];
				var c2:uint = (++j < len) ? colors[j] : 0;
				var c3:uint = (++j < len) ? colors[j] : 0;
				var c4:uint = (++j < len) ? colors[j] : 0;

				var a1:int = (c1 >>> 24) / 85;
				var a2:int = (c2 >>> 24) / 85;
				var a3:int = (c3 >>> 24) / 85;
				var a4:int = (c4 >>> 24) / 85;

				alphaData.writeByte(a1 << 6 | a2 << 4 | a3 << 2 | a4);
			}
		}

		private static function getHighAlphaData(alphaData:ByteArray, colors:Vector.<uint>):void
		{
			var len:uint = colors.length;
			for (var j:int = 0; j < len; j++)
			{
				var c1:uint = colors[j];
				var c2:uint = (++j < len) ? colors[j] : 0;

				var a1:int = (c1 >>> 24) / 17;
				var a2:int = (c2 >>> 24) / 17;

				alphaData.writeByte(a1 << 4 | a2);
			}
		}
	}
}
