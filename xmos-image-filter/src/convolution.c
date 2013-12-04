/*
 * File: 	convolution.c
 * Date: 	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 */

float blur[3][3] = {
		{0.333, 0.333, 0.333},
		{0.333, 0.333, 0.333},
		{0.333, 0.333, 0.333}
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

int convolution(float filter[3][3], int pixels[3][3])
{
	int row1 = filter[0][0]*pixels[0][0]+filter[0][1]*pixels[0][1]+filter[0][2]*pixels[0][2];
	int row2 = filter[1][0]*pixels[1][0]+filter[1][1]*pixels[1][1]+filter[1][2]*pixels[1][2];
	int row3 = filter[2][0]*pixels[2][0]+filter[2][1]*pixels[2][1]+filter[2][2]*pixels[2][2];
	return row1+row2+row3;
}
