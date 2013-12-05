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
 
pixel convolution(filter_t f, pixel pixels[3][3]);


#endif
