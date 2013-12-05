/*
 * File: 	convolution.c
 * Date: 	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 */
#include "convolution.h"

float const blur[3][3] = {
		{0.333, 0.333, 0.333},
		{0.333, 0.333, 0.333},
		{0.333, 0.333, 0.333}
};

float const sharpen[3][3] = {
		{-1,-1,-1},
		{-1,9,-1},
		{-1,-1,-1}
};

float const edges[3][3] = {
		{-1,-1,-1},
		{-1,8,-1},
		{-1,-1,-1}
};

float const emboss[3][3] = {
		{-2,-1,0},
		{-1,1,1},
		{0,1,2}
};

pixel convolution(filter_t f, pixel pixels[3][3])
{
	float filter[3][3];
	float row1, row2, row3, final;

	switch (f)
	{
		case BLUR:
			filter = blur;
			break;
		case SHARPEN:
			filter = sharpen;
			break;
		case EDGES:
			filter = edges;
			break;
		case EMBOSS:
			filter = emboss;
			break;
		default: break;
	}

	row1 = filter[0][0]*pixels[0][0]+filter[0][1]*pixels[0][1]+filter[0][2]*pixels[0][2];
	row2 = filter[1][0]*pixels[1][0]+filter[1][1]*pixels[1][1]+filter[1][2]*pixels[1][2];
	row3 = filter[2][0]*pixels[2][0]+filter[2][1]*pixels[2][1]+filter[2][2]*pixels[2][2];

	final = row1+row2+row3;
	if (final > BIT_DEPTH) final = BIT_DEPTH;
	if (final < 0) final = 0;

	return (pixel) (final+0.5);
}


