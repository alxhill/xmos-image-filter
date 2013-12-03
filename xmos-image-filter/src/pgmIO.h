/*
 * File: 	pgmIO.h
 * Date: 	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 * Brief:	Header file for pgmIO.c. For more detailed information, view file 'pgmIO.c'
 */
#ifndef PGMIO_H_
#define PGMIO_H_

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Useful defines to help with like of boolean suport in xc.
#define TRUE 1
#define FALSE 0

// Allows writing of 'unsigned char' as 'pixel' and 'unsigned int' as 'fPointer' for ease of use.
typedef unsigned char pixel;
typedef unsigned int fPointer;

// Opens a new file for reading or writing, outputting the file pointer (as an unsigned int as xc can't handle anything more complex than integer division).
fPointer openInPGM(char fname[], unsigned int inWidth, unsigned int inHeight);
fPointer openOutPGM(char fname[], unsigned int outWidth, unsigned int outHeight);

// Reads or writes pixels into a PGM file.
pixel readCharPGM(fPointer file);
unsigned char writeCharPGM(fPointer file, pixel toAdd);

// Closes the PGM file.
unsigned char closePGM(fPointer file);

#endif /*PGMIO_H_*/

