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

// Structure containing the file pointer and information about dimensions the picture.
typedef struct {FILE* filePointer; unsigned int width; unsigned int height;}
	fileContainer;

// Opens a new file for reading or writing, outputting the fileContainer.
fileContainer openInPGM(char fname[]);
fileContainer openOutPGM(char fname[], int outWidth, int outHeight);

// Reads or writes lines from or into a fileContainer using a char array.
int readLinePGM(fileContainer PGM, unsigned char line[]);
int writeLinePGM(fileContainer PGM, unsigned char line[]);

// Closes the PGM file and sets filePointer = NULL.
int closePGM();

#endif /*PGMIO_H_*/

