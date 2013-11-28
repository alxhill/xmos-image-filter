/*
 * File: 	pmgIO.c
 * Date:	28th November 2013
 * Author: 	Samuel Whitehouse 	- sw12690@my.bristol.ac.uk
 * Author: 	Alexander Hill		- ah12466@my.bristol.ac.uk
 * Brief:	Library dealing with PGM files, including opening, writing, reading and closing.
 */
#include "pgmIO.h"

/*
 * Brief:	Opens a PGM file, reading the header and returning a fileContainer with the height/width of the picture and the filePointer.
 * Param:	fname - The name of the file to be opened
 * Return:	Returns a fileContainer containing the width/height of the picture and the file pointer to the picture.
 * Note:	On fail the file is closed and the filePointer set to NULL.
 * Note:	Will fail if file cannot be opened.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
fileContainer openInPGM(char fname[])
{
	char input[64];
	int inWidth, inHeight;
	fileContainer newFile;
	
	newFile.filePointer = fopen(fname, "rb");
	if(newFile.filePointer == NULL) return newFile;

	
	fgets(input, 64, newFile.filePointer); ///< Obtains the Version Number
	if(input[0] != 'P' || input[1] != '5' || input[2] != '\n'){
		closePGM(newFile);
		return newFile;
	}
	
	fgets(input, 64, newFile.filePointer); ///< Obtains the Width and Height
	sscanf(input, "%d%d", &inWidth, &inHeight);
	newFile.width = inWidth;
	newFile.height = inHeight;

	fgets(input, 64, newFile.filePointer); ///< Obtains Bit Depth
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
fileContainer openOutPGM(char fname[], int outWidth, int outHeight)
{
    char output[64];
	fileContainer newFile;
	
	newFile.filePointer = fopen(fname, "wb");
	
	if(newFile.filePointer == NULL)	return newFile;

    sprintf(output, "P5\n%d %d\n255\n", outWidth, outHeight );
    fprintf(newFile.filePointer, "%s", output);
	newFile.width = outWidth;
	newFile.height = outHeight;

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
int readLinePGM(fileContainer PGM, unsigned char line[])
{
	int lineLength;

	if(PGM.filePointer == NULL ) return -1;

	lineLength = fread(line, 1, PGM.width, PGM.filePointer);

	if(lineLength != PGM.width){
		closePGM(PGM);
		return -1;
	}
	
	return 0;
}

/*
 * Brief:	Writes a single line to a PGM file based on the width of the file.
 * Param:	PGM - The fileContainer of the picture to be written to.
 * Param:	line - The string that will be written into the file.
 * Return:	Returns 0 on successful writing, -1 if fails.
 * Note:	Will fail if it cannot write a full line.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
int writeLinePGM(fileContainer PGM, unsigned char line[])
{
	int lineLength;

	if(PGM.filePointer == NULL ) return -1;

	lineLength = fwrite(line, 1, PGM.width, PGM.filePointer);

	if(lineLength != PGM.width){
		closePGM(PGM);
		return -1;
	}

	return 0;
}

/*
 * Brief:	Closes a PGM file.
 * Param:	PGM - The fileContainer of the picture to be closed.
 * Return:	Returns 0 on successful closing, -1 if fails.
 * Note:	Will fail if it cannot close the file.
 * Author:	Samuel Whitehouse - sw12690@my.bristol.ac.uk
 */
int closePGM(fileContainer PGM)
{
	if(fclose(PGM.filePointer) != 0) return -1;
	PGM.filePointer = NULL;
	
	return 0;
}

