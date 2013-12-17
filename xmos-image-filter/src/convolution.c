/*
 * File: 	convolution.c
 * Date: 	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 */
#include "convolution.h"

float blur[3][3] = {
		{0.111,0.111,0.111},
		{0.111,0.111,0.111},
		{0.111,0.111,0.111}
};


float sharpen[3][3] = {
		{-1,-1,-1},
		{-1,9,-1},
		{-1,-1,-1}
};

float edges[3][3] = {
		{-1,-1,-1},
		{-1,8,-1},
		{-1,-1,-1}
};

float emboss[3][3] = {
		{-2,-1,0},
		{-1,1,1},
		{0,1,2}
};


pixel convolution_handler(filter_t filter, pixel p1, pixel p2, pixel p3, pixel p4, pixel p5, pixel p6, pixel p7, pixel p8, pixel p9)
{
	pixel pixels[3][3] = {
			{p1, p2, p3},
			{p4, p5, p6},
			{p7, p8, p9}
	};

	switch (filter)
	{
		case BLUR:
			return convolution(blur, pixels);
		case SHARPEN:
			return convolution(sharpen, pixels);
		case EDGES:
			return convolution(edges, pixels);
		case EMBOSS:
			return convolution(emboss, pixels);
		default: break;
	}
	return 0;
}

pixel convolution(float filter[3][3], pixel pixels[3][3])
{
	float row1, row2, row3, final;

	row1 = filter[0][0]*pixels[0][0]+filter[0][1]*pixels[0][1]+filter[0][2]*pixels[0][2];
	row2 = filter[1][0]*pixels[1][0]+filter[1][1]*pixels[1][1]+filter[1][2]*pixels[1][2];
	row3 = filter[2][0]*pixels[2][0]+filter[2][1]*pixels[2][1]+filter[2][2]*pixels[2][2];

	final = row1+row2+row3;
	if (final > BIT_DEPTH) final = BIT_DEPTH;
	if (final < 0) final = 0;
	// otherwise it comes back inverted...
	final = BIT_DEPTH - final;

	return (pixel) (final+0.5);
}


