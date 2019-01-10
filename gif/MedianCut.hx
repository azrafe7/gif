/**
 * Implementation of the median cut quantization algorithm, based on
 * "Median cut" article from Dr Dobb's 1994 Sept, and related median.c code.
 * (http://www.drdobbs.com/database/median-cut-color-quantization/184409309?pgno=24)
 *
 * Original author copyright info follows:
 *
 * File:        median.c             Copyright (c) Truda Software
 * Author:      Anton Kruger         215 Marengo Rd, #2,
 * Date:        March 1992           Oxford, IA 52322-9383
 * Revision:    1.0                  March 1992
 *
 * Description: Contains an implementation of Heckbert's median-
 *              cut color quantization algorithm.
 */

package gif;

import haxe.ds.ArraySort;
import haxe.io.UInt8Array;

@:allow(gif.MedianCut)
class Cube {       /* structure for a cube in color space */
  var /*word */ lower:Int;         /* one corner's index in histogram     */
  var /*word */ upper:Int;         /* another corner's index in histogram */
  var /*dword*/ count:Int;         /* cube's histogram count              */
  var /*int  */ level:Int;         /* cube's level                        */

  var /*byte*/ rmin:Int; var rmax:Int;
  var /*byte*/ gmin:Int; var gmax:Int;
  var /*byte*/ bmin:Int; var bmax:Int;

  function new() {}

  function clone():Cube {
    var cloned = new Cube();
    cloned.lower = this.lower;
    cloned.upper = this.upper;
    cloned.count = this.count;
    cloned.level = this.upper;
    cloned.rmin = this.rmin; cloned.rmax = this.rmax;
    cloned.gmin = this.gmin; cloned.gmax = this.gmax;
    cloned.bmin = this.bmin; cloned.bmax = this.bmax;
    return cloned;
  }
}

class MedianCut implements IPaletteAnalyzer
{
  static inline var MAXCOLORS:Int = 256;            /* maximum # of output colors */
  static inline var HSIZE:Int = 32768;          /* size of image histogram    */

  /* Functions for converting between (r,g,b)-colors and 15-bit     */
  /* colors follow.                                              */
  static function RGB15(r, g, b):Int return /*(word)*/ (((b) & ~7) << 7) | (((g) & ~7) << 2) | ((r) >> 3);
  static function RED(x):Int   return /*(byte)*/ (((x) & 31) << 3) & 255;
  static function GREEN(x):Int return /*(byte)*/ ((((x) >> 5) & 255) << 3) & 255;
  static function BLUE(x):Int  return /*(byte)*/ ((((x) >> 10) & 255) << 3) & 255;
  static public function RGB24_TO_RGB15(x):Int {
    var r = (x & 0xFF0000) >> 16;
    var g = (x & 0x00FF00) >> 8;
    var b = (x & 0x0000FF);
    return RGB15(r, g, b);
  }

  var /*cube_t[MAXCOLORS]*/ list:Array<Cube> = [for (c in 0...MAXCOLORS) null];   /* list of cubes              */
  var longdim:Int;              /* longest dimension of cube  */
  var /*word[HSIZE]*/ HistPtr:Array<Int> = [for (i in 0...HSIZE) 0];      /* points to colors in "Hist" */

  var histogram:Array<Int> = [for (i in 0...HSIZE) 0];

  var maxColors:Int;

  var rgbMap:Map<Int, Int>;
  var rgb2index = new Map<Int, Int>(); // maps rgb to index


  public function new(?maxColors:Int)
  {
    this.maxColors = (maxColors != null) ? maxColors : 256;
    if (this.maxColors < 1 || this.maxColors > 256) throw "maxColors must be in the range [1-256]";
  }

  public function analyze(pixels:UInt8Array):UInt8Array
  {
    var pixelCount = Std.int(pixels.length / 3);
    var pixelArray:Array<Int> = [];

    for (i in 0...pixelCount) {
      var pos = i * 3;
      pixelArray[i] = (pixels[pos] << 16) | (pixels[pos + 1] << 8) | pixels[pos + 2];
    }
    var rgb = 0;
    for (i in 0...pixelCount) {
      rgb = RGB24_TO_RGB15(pixelArray[i]);
      histogram[rgb]++;
    }
    var colorMap = [for (c in 0...maxColors) [0, 0, 0]];
    var numColors = medianCut(histogram, colorMap, maxColors);

    rgbMap = new Map();
    rgb2index = new Map();
    var originalUniqueColors = 0;
    for (i in 0...pixelArray.length) {
      var rgb15 = MedianCut.RGB24_TO_RGB15(pixelArray[i]);
      //trace(rgb15);
      var colMapIdx = histogram[rgb15];
      var mappedRgb = colorMap[colMapIdx];
      var rgb = (mappedRgb[0] << 16) | (mappedRgb[1] << 8) | mappedRgb[2];
      if (!rgbMap.exists(pixelArray[i])) originalUniqueColors++;
      rgbMap[pixelArray[i]] = rgb;
      rgb2index[pixelArray[i]] = colMapIdx;
      //trace(colorMap[colMapIdx]);
    }

    trace(colorMap.length);
    var colorTab = new UInt8Array(colorMap.length * 3);
    var paletteUniqueColors = 0;
    for (i in 0...colorMap.length) {
      if (colorMap[i].join("") != "000") paletteUniqueColors++;
      var pos = i * 3;
      colorTab[pos] = colorMap[i][0];
      colorTab[pos + 1] = colorMap[i][1];
      colorTab[pos + 2] = colorMap[i][2];
    }

    trace("unique " + paletteUniqueColors + " / " + originalUniqueColors);

    return colorTab;
  }

  public function map(r:Int, g:Int, b:Int):Int
  {
    //var rgb15 = MedianCut.RGB24_TO_RGB15(r << 16 | g << 8 | b);
    //return rgbMap[rgb15];
    var rgb = r << 16 | g << 8 | b;
    return rgb2index[rgb];
  }

  /*word*/ public function medianCut(/*word[]*/ Hist:Array<Int>, /*byte[][3]*/ ColMap:Array<Array<Int>>, maxcubes:Int):Int
  {
    /* Accepts "Hist", a 32,768-element array that contains 15-bit color counts
    ** of input image. Uses Heckbert's median-cut algorithm to divide color
    ** space into "maxcubes" cubes, and returns centroid (average value) of each
    ** cube in ColMap. Hist is also updated so that it functions as an inverse
    ** color map. MedianCut returns the actual number of cubes, which may be
    ** less than "maxcubes". */
    var /*byte  */ lr,lg,lb;
    var /*word  */ median,color;
    var /*dword */ count;
    var /*int   */ level,ncubes,splitpos;
    var /*void *base */ baseIdx:Int;
    var /*size_t*/ num;
    var /*cube_t*/ cube:Cube = new Cube(), cubeA:Cube, cubeB:Cube;

    /* Create the initial cube, which is the whole RGB-cube. */
    ncubes = 0;
    cube.count = 0;
    color = 0;
    for (i in 0...HSIZE){
      if (Hist[i] != 0){
        HistPtr[color++] = i;
        cube.count = cube.count + Hist[i];
      }
    }
    cube.lower = 0; cube.upper = color-1;
    cube.level = 0;
    Shrink(cube);
    list[ncubes++] = cube;

    /* Main loop follows. Search the list of cubes for next cube to split, which
    ** is the lowest level cube. A special case is when a cube has only one
    ** color, so that it cannot be split. */
    while (ncubes < maxcubes){
      level = 255; splitpos = -1;
      for (k in 0...ncubes){
        if (list[k].lower == list[k].upper)
                {};                            /* single color */
        else if (list[k].level < level){
          level = list[k].level;
          splitpos = k;
        }
      }
      if (splitpos == -1)            /* no more cubes to split */
        break;

      /* Must split the cube "splitpos" in list of cubes. Next, find longest
      ** dimension of cube, and update external variable "longdim" which is
      ** used by sort routine so that it knows along which axis to sort. */
      cube = list[splitpos];
      lr = cube.rmax - cube.rmin;
      lg = cube.gmax - cube.gmin;
      lb = cube.bmax - cube.bmin;
      if (lr >= lg && lr >= lb) longdim = 0;
      if (lg >= lr && lg >= lb) longdim = 1;
      if (lb >= lr && lb >= lg) longdim = 2;

      /* Sort along "longdim". This prepares for the next step, namely finding
      ** median. Use standard lib's "qsort". */
      baseIdx = /*(void *)& */ cube.lower;
      num  = /*(size_t)*/ (cube.upper - cube.lower + 1);

      //qsort(base, num, width, compare);
      @:privateAccess ArraySort.rec(HistPtr, compare, baseIdx, num);


      /* Find median by scanning through cube, computing a running sum. When
      ** running sum equals half the total for cube, median has been found. */
      count = 0;
      var i = cube.lower;
      while (i < cube.upper){
        if (count >= Std.int(cube.count / 2)) break;
        color = HistPtr[i];
        count = count + Hist[color];
        i++;
      }
      median = i;


      /* Now split "cube" at median. Then add two new cubes to list of cubes.*/
      cubeA = cube.clone(); cubeA.upper = median-1;
      cubeA.count = count;
      cubeA.level = cube.level + 1;
      Shrink(cubeA);
      list[splitpos] = cubeA;               /* add in old slot */

      cubeB = cube.clone(); cubeB.lower = median;
      cubeB.count = cube.count - count;
      cubeB.level = cube.level + 1;
      Shrink(cubeB);
      list[ncubes++] = cubeB;               /* add in new slot */
      //if ((ncubes % 10) == 0)
      //   fprintf(stderr,".");               /* pacifier        */
    }

    /* We have enough cubes, or we have split all we can. Now compute the color
    ** map, inverse color map, and return number of colors in color map. */
    InvMap(Hist, ColMap, ncubes);
    return(/*(word)*/ncubes);
  }

  function Shrink(cube:Cube):Void
  {
    /* Encloses "cube" with a tight-fitting cube by updating (rmin,gmin,bmin)
    ** and (rmax,gmax,bmax) members of "cube". */
    var /*byte*/ r,g,b;
    var /*word*/ color;

    cube.rmin = 255; cube.rmax = 0;
    cube.gmin = 255; cube.gmax = 0;
    cube.bmin = 255; cube.bmax = 0;
    for (i in cube.lower...cube.upper + 1){
      color = HistPtr[i];
      r = RED(color);
      if (r > cube.rmax) cube.rmax = r;
      if (r < cube.rmin) cube.rmin = r;
      g = GREEN(color);
      if (g > cube.gmax) cube.gmax = g;
      if (g < cube.gmin) cube.gmin = g;
      b = BLUE(color);
      if (b > cube.bmax) cube.bmax = b;
      if (b < cube.bmin) cube.bmin = b;

    }
  }

  function InvMap(/*word **/ Hist:Array<Int>, /*byte[][3]*/ ColMap:Array<Array<Int>>, /*word*/ ncubes:Int):Void
  {
    /* For each cube in list of cubes, computes centroid (average value) of
    ** colors enclosed by that cube, and loads centroids in the color map. Next
    ** loads histogram with indices into the color map. A preprocessor directive
    ** #define FAST_REMAP controls whether cube centroids become output color
    ** for all the colors in a cube, or whether a "best remap" is followed. */
    var /*byte  */ r = 0.0, g = 0.0, b = 0.0;
    var /*word  */ index = 0, color = 0;
    var /*float */ rsum = 0.0, gsum = 0.0, bsum = 0.0;
    var /*float */ dr = 0.0, dg = 0.0, db = 0.0, d = 0.0, dmin = 0.0;
    var /*cube_t*/ cube:Cube;

    for (k in 0...ncubes){
      cube = list[k];
      rsum = gsum = bsum = /*(float)*/0.0;
      for (i in cube.lower...cube.upper + 1){
        color = HistPtr[i];
        r = RED(color);
        rsum += /*(float)*/r * /*(float)*/Hist[color];
        g = GREEN(color);
        gsum += /*(float)*/g * /*(float)*/Hist[color];
        b = BLUE(color);
        bsum += /*(float)*/b * /*(float)*/Hist[color];
      }

      /* Update the color map */
      ColMap[k][0] = /*(byte)*/Std.int((rsum / /*(float)*/cube.count));
      ColMap[k][1] = /*(byte)*/Std.int((gsum / /*(float)*/cube.count));
      ColMap[k][2] = /*(byte)*/Std.int((bsum / /*(float)*/cube.count));
    }
  #if FAST_REMAP
    /* Fast remap: for each color in each cube, load the corresponding slot
    ** in "Hist" with the centroid of the cube. */
    for (k in 0...ncubes){
      cube = list[k];
      for (i in cube.lower...cube.upper + 1){
        color = HistPtr[i];
        Hist[color] = k;
      }

      //if ((k % 10) == 0) fprintf(stderr,".");   /* pacifier    */
    }
  #else
    /* Best remap: for each color in each cube, find entry in ColMap that has
    ** smallest Euclidian distance from color. Record this in "Hist". */
    for (k in 0...ncubes){
      cube = list[k];
      for (i in cube.lower...cube.upper + 1){
        color = HistPtr[i];
        r = RED(color);  g = GREEN(color); b = BLUE(color);

        /* Search for closest entry in "ColMap" */
        //dmin = (float)FLT_MAX;
        dmin = Math.POSITIVE_INFINITY;
        for (j in 0...ncubes){
          dr = /*(float)*/ColMap[j][0] - /*(float)*/r;
          dg = /*(float)*/ColMap[j][1] - /*(float)*/g;
          db = /*(float)*/ColMap[j][2] - /*(float)*/b;
          d = dr*dr + dg*dg + db*db;
          if (d == /*(float)*/0.0){
            index = j; break;
          }
          else if (d < dmin){
            dmin = d; index = j;
          }
        }
        Hist[color] = index;
      }
      //if ((k % 10) == 0) fprintf(stderr,".");   /* pacifier    */
    }
  #end
    return;
  }

  function compare(/*const void * */ a1:Int, /*const void * */ a2:Int):Int
  {
    /* Called by the sort routine in "MedianCut". Compares two
    ** colors based on the external variable "longdim". */
    /*word*/ var color1,color2;
    /*byte*/ var C1,C2;

    color1 = /*(word)*(word *)*/a1;
    color2 = /*(word)*(word *)*/a2;
    switch (longdim){

      case 0:
        C1 = RED(color1);  C2 = RED(color2);
      case 1:
        C1 = GREEN(color1); C2 = GREEN(color2);
      case 2:
        C1 = BLUE(color2); C2 = BLUE(color2);
      default:
        throw "Unreacheable";
    }

    return (/*(int)*/(C1-C2));
  }
}
