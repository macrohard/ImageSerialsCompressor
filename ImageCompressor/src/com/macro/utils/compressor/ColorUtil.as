package com.macro.utils.compressor
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;


	public class ColorUtil
	{

		/**
		 * 是否预处理输入
		 */
		public static var preprocessInput:Boolean = true;




		/**
		 * 获取调色盘
		 * @param source
		 * @param maximum 最大色彩数
		 * @param tolerance
		 * @return
		 *
		 */
		public static function colorPalette(source:BitmapData, maximum:int = 16, tolerance:Number = 0.01):Array
		{
			var copy:BitmapData = source.clone();
			var palette:Array = uniqueColors(orderColors(copy), maximum, tolerance);
			copy.dispose();

			return palette;
		}


		/**
		 * 优化调色盘到指定色彩数
		 * @param source
		 * @param colorDepth
		 * @param tolerance
		 *
		 */
		public static function optimalPalette(source:BitmapData, maximum:int = 64, tolerance:Number = 0.001):void
		{
			var palette:Array = colorPalette(source, maximum, tolerance);
			var redArray:Array = new Array(256);
			var greenArray:Array = new Array(256);
			var blueArray:Array = new Array(256);

			for (var i:int = 0; i < palette.length; i++)
			{
				var c:uint = palette[i];
				var r:uint = c >>> 16 & 0xFF;
				var g:uint = c >>> 8 & 0xFF;
				var b:uint = c & 0xFF;
				redArray[r] = r << 16;
				greenArray[g] = g << 8;
				blueArray[b] = b;
			}

			r = 0;
			g = 0;
			b = 0;
			for (i = 1; i < 256; i++)
			{
				if (redArray[i] == null)
					redArray[i] = r;
				else
					r = redArray[i];

				if (greenArray[i] == null)
					greenArray[i] = g;
				else
					g = greenArray[i];

				if (blueArray[i] == null)
					blueArray[i] = b;
				else
					b = blueArray[i];
			}

			source.paletteMap(source, source.rect, new Point(), redArray, greenArray, blueArray);
		}
		
		
		/**
		 * 两个颜色是否相似
		 * @param color1
		 * @param color2
		 * @param tolerance 容差范围
		 * @return
		 *
		 */
		public static function similar(color1:uint, color2:uint, tolerance:Number = 0.01):Boolean
		{
			var RGB1:RGB = Hex24ToRGB(color1);
			var RGB2:RGB = Hex24ToRGB(color2);
			
			tolerance = tolerance * (255 * 255 * 3) << 0;
			
			var distance:Number = 0;
			
			distance += Math.pow(RGB1.red - RGB2.red, 2);
			distance += Math.pow(RGB1.green - RGB2.green, 2);
			distance += Math.pow(RGB1.blue - RGB2.blue, 2);
			
			return distance <= tolerance;
		}
		
		
		/**
		 * 与一组颜色比较是否相似
		 * @param color
		 * @param colors
		 * @param tolerance
		 * @return
		 *
		 */
		public static function different(color:uint, colors:Array, tolerance:Number = 0.01):Boolean
		{
			for (var i:int = 0; i < colors.length; i++)
			{
				if (similar(color, colors[i], tolerance))
				{
					return false;
				}
			}
			return true;
		}
		

		/**
		 * 过滤重复的色彩
		 * @param colors
		 * @param maximum
		 * @param tolerance
		 * @return
		 *
		 */
		public static function uniqueColors(colors:Array, maximum:int, tolerance:Number = 0.01):Array
		{
			var unique:Array = [];

			for (var i:int = 0; i < colors.length && unique.length < maximum; i++)
			{
				if (different(colors[i], unique, tolerance))
				{
					unique.push(colors[i]);
				}
			}

			return unique;
		}


		/**
		 * 索引所有颜色，并按使用次数排序。
		 * 返回一个对象数组，每个对象有两个属性，color和count
		 * @param source
		 * @param sort
		 * @param order
		 * @return
		 *
		 */
		public static function indexColors(source:BitmapData, sort:Boolean = true, order:uint = Array.DESCENDING):Array
		{
			if (preprocessInput)
			{
				reduceColors(source, 64);
			}

			var n:Dictionary = new Dictionary();
			var a:Array = [];
			var p:int;

			for (var x:int = 0; x < source.width; x++)
			{
				for (var y:int = 0; y < source.height; y++)
				{
					p = source.getPixel(x, y);
					n[p] ? n[p]++ : n[p] = 1;
				}
			}

			for (var c:String in n)
			{
				a.push(new ColorCounter(c, n[c]));
			}

			if (!sort)
				return a;

			function byCount(a:ColorCounter, b:ColorCounter):int
			{
				if (a.count > b.count)
					return 1;
				if (a.count < b.count)
					return -1;
				return 0;
			}

			return a.sort(byCount, order);
		}


		/**
		 * 索引所有颜色，并按使用次数排序。
		 * 返回色彩数组
		 * @param source
		 * @param order
		 * @return 
		 * 
		 */
		public static function orderColors(source:BitmapData, order:uint = Array.DESCENDING):Array
		{
			var colors:Array = [];
			var index:Array = indexColors(source, true, order);

			for (var i:int = 0; i < index.length; i++)
			{
				colors.push(index[i].color);
			}

			return colors;
		}

		
		/**
		 * 计算图形的平均色彩
		 * @param source
		 * @return 
		 * 
		 */
		public static function averageColor(source:BitmapData):uint
		{
			var R:Number = 0;
			var G:Number = 0;
			var B:Number = 0;
			var n:Number = 0;
			var p:Number;

			for (var x:int = 0; x < source.width; x++)
			{
				for (var y:int = 0; y < source.height; y++)
				{
					p = source.getPixel(x, y);

					R += p >> 16 & 0xFF;
					G += p >> 8 & 0xFF;
					B += p & 0xFF;

					n++
				}
			}

			R /= n;
			G /= n;
			B /= n;

			return R << 16 | G << 8 | B;
		}

		
		/**
		 * 将位图分割成若干区块，并求出每块的平均色彩
		 * @param source
		 * @param colors
		 * @return 
		 * 
		 */
		public static function averageColors(source:BitmapData, colors:int):Array
		{
			var averages:Array = new Array();
			var columns:int = Math.round(Math.sqrt(colors));

			var row:int = 0;
			var col:int = 0;

			var x:int = 0;
			var y:int = 0;

			var w:int = Math.round(source.width / columns);
			var h:int = Math.round(source.height / columns);

			for (var i:int = 0; i < colors; i++)
			{
				var rect:Rectangle = new Rectangle(x, y, w, h);

				var box:BitmapData = new BitmapData(w, h, false);
				box.copyPixels(source, rect, new Point());

				averages.push(averageColor(box));
				box.dispose();

				col = i % columns;

				x = w * col;
				y = h * row;

				if (col == columns - 1)
					row++;
			}

			return averages;
		}


		/**
		 * 减少位图色彩
		 * @param source
		 * @param colors
		 * 
		 */
		public static function reduceColors(source:BitmapData, colors:int = 16):void
		{
			var Ra:Array = new Array(256);
			var Ga:Array = new Array(256);
			var Ba:Array = new Array(256);

			var n:Number = 256 / (colors / 3);

			for (var i:int = 0; i < 256; i++)
			{
				Ba[i] = Math.floor(i / n) * n;
				Ga[i] = Ba[i] << 8;
				Ra[i] = Ga[i] << 8;
			}

			source.paletteMap(source, source.rect, new Point(), Ra, Ga, Ba);
		}

		
		/**
		 * 转换24bit色彩值到一个对象
		 * @param hex
		 * @return 
		 * 
		 */
		public static function Hex24ToRGB(hex:uint):RGB
		{
			var r:Number = hex >> 16 & 0xFF;
			var g:Number = hex >> 8 & 0xFF;
			var b:Number = hex & 0xFF;

			return new RGB(r, g, b);
		}

	}

}

class RGB
{
	public var red:int;
	
	public var green:int;
	
	public var blue:int;
	
	public function RGB(r:int, g:int, b:int)
	{
		red = r;
		green = g;
		blue = b;
	}
}

class ColorCounter
{
	public var color:String;
	
	public var count:uint;
	
	public function ColorCounter(color:String, count:uint)
	{
		this.color = color;
		this.count = count;
	}
}
