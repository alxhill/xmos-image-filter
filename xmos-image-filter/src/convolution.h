/*
 * File: 	convolution.h
 * Date: 	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 */
#ifndef CONVOLUTION_H_
#define CONVOLUTION_H_

#include "pgmIO.h"

#define BIT_DEPTH 255

typedef enum {BLUR, SHARPEN, EDGES, EMBOSS} filter_t;
typedef char pixel;

pixel convolution_handler(filter_t filter, pixel p1, pixel p2, pixel p3, pixel p4, pixel p5, pixel p6, pixel p7, pixel p8, pixel p9);
pixel convolution(float filter[3][3], pixel pixels[3][3]);

#endif
