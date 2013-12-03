/*
 * File: 	pmgIO.c
 * Date:	3rd December 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 * Brief:	Library dealing with PGM files, including opening, writing, reading and closing.
 */
#include "pgmIO.h"

/*
 * Brief:	Opens a PGM file, reading the header and returning a fPointer to the picture.
 * Param:	fname - The name of the file to be opened
 * Return:	Returns a fileContainer containing the width/height of the picture and the file pointer to the picture.
 * Note:	On fail the file is closed and the filePointer set to NULL.
 * Note:	Will fail if file cannot be opened.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
fPointer openInPGM(char fname[], unsigned int inWidth, unsigned int inHeight)
{
	FILE* filePointer;
	char input[64];
	fPointer newFile;
	unsigned int width, height;
	
	filePointer = fopen(fname, "rb");
	newFile = (fPointer)filePointer;
	if(filePointer == NULL) return newFile;

	fgets(input, 64, filePointer); ///< Obtains the Version Number
	if(input[0] != 'P' || input[1] != '5' || input[2] != '\n')
	{
		closePGM(newFile);
		return newFile;
	}
	
	fgets(input, 64, filePointer); ///< Obtains the Width and Height
	sscanf(input, "%d%d", &width, &height);
	if(width != inWidth || height != inHeight)
	{
		closePGM(newFile);
		return newFile;
	}

	fgets(input, 64, filePointer); ///< Obtains Bit Depth
	if(input[0] != '2' || input[1] != '5' || input[2] != '5' || input[3] != '\n'){
		closePGM(newFile);
		return newFile;
	}
	
	return newFile;
}

/*
 * Brief:	Opens a PGM file, writing the header and returning a fileContainer with the height/width of the picture and the filePointer.
 * Param:	fname 		- The name of the file to be opened
 * Param:	outWidth	- The width of the picture to be outputted.
 * Param:	outHeight	- The height of the picture to be outputted.
 * Return:	Returns a fileContainer containing the width/height of the picture and the file pointer to the picture.
 * Note:	On fail the file is closed and the filePointer set to NULL.
 * Note:	Will fail if file cannot be opened.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
fPointer openOutPGM(char fname[], unsigned int outWidth, unsigned int outHeight)
{
	FILE* filePointer;
    char output[64];
	fPointer newFile;
	
	filePointer = fopen(fname, "wb");
	newFile = (fPointer)filePointer;
	if(filePointer == NULL) return newFile;

    sprintf(output, "P5\n%d %d\n255\n", outWidth, outHeight);
    fprintf(filePointer, "%s", output);

	return newFile;
}

/*
 * Brief:	Reads a single line from a PGM file based on the width of the file.
 * Param:	PGM - The fileContainer of the picture to be read.
 * Param:	line - The string that the line will be outputted to.
 * Return:	Returns 0 on successful reading, -1 if fails.
 * Note:	Will fail if it cannot read a full line, or reaches EOF.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
pixel readCharPGM(fPointer file)
{
	pixel new = fgetc((FILE*)file);
	
	return new;
}

/*
 * Brief:	Writes a single line to a PGM file based on the width of the file.
 * Param:	PGM - The fileContainer of the picture to be written to.
 * Param:	line - The string that will be written into the file.
 * Return:	Returns 0 on successful writing, -1 if fails.
 * Note:	Will fail if it cannot write a full line.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
unsigned char writeCharPGM(fPointer file, pixel toAdd)
{
	if(file == (fPointer)NULL ) return FALSE;

	fputc(toAdd, (FILE*)file);

	return TRUE;
}

/*
 * Brief:	Closes a PGM file.
 * Param:	PGM - The fileContainer of the picture to be closed.
 * Return:	Returns 0 on successful closing, -1 if fails.
 * Note:	Will fail if it cannot close the file.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
unsigned char closePGM(fPointer file)
{
	if(fclose((FILE*)file) != 0) return FALSE;
	
	return TRUE;
}

