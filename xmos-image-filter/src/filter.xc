/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////////////////

#include <platform.h>
#include <stdio.h>
#include "convolution.h"

#define IMHT 16
#define IMWD 16
#define WORKERS 3

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out)
{
    pixel line[ IMWD ];

    printf( "DataInStream:Start...\n" );

    if(_openinpgm( infname, IMWD, IMHT ))
    {
        printf( "DataInStream:Error openening %s\n.", infname );
        return;
    }

    for( int y = 0; y < IMHT; y++ )
    {
        _readinline( line, IMWD );
        for( int x = 0; x < IMWD; x++ )
        {
            c_out <: line[x];
            printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
        }
        printf( "\n" ); //uncomment to show image values
    }

    _closeinpgm();
    printf( "DataInStream:Done...\n" );
    return;
}

void DataOutStream(char outfname[], chanend c_out)
{
    pixel line[ IMWD ];

    printf( "DataOutStream:Start...\n" );

    if(_openoutpgm( outfname, IMWD, IMHT ))
    {
        printf( "DataOutStream:Error openening %s\n.", outfname );
        return;
    }

    for( int y = 0; y < IMHT; y++ )
    {
        for( int x = 0; x < IMWD; x++ )
        {
            c_out :> line[x];
            printf( "+%4.1d ", line[ x ] ); //uncomment to show image values
        }
        _writeoutline(line, IMWD);
        printf( "\n" ); //uncomment to show image values
    }

    _closeinpgm();
    printf( "DataOutStream:Done...\n" );
    return;
}

void processPixel(chanend c_in)
{
	while (1)
	{
		int shouldProcess;
		// the matrix of pixels needed to calculate the convolution
		pixel pixelsIn[3][3];
		pixel pixelOut;

		c_in :> shouldProcess;
		if (shouldProcess == 0) return;

//		printf("worker ready to receive\n");

		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				c_in :> pixelsIn[i][j];
			}
		}

//		printf("worker finished receiving\n");

		pixelOut = convolution_handler(BLUR,
					pixelsIn[0][0], pixelsIn[1][0], pixelsIn[2][0],
					pixelsIn[0][1], pixelsIn[1][1], pixelsIn[2][1],
					pixelsIn[0][2], pixelsIn[1][2], pixelsIn[2][2]);

		c_in <: pixelOut;
	}
}

void fillLine(chanend c_in, pixel line[IMWD+2])
{
	// ensures the edges are black
	line[0] = 0;
	line[IMWD+1] = 0;

	for (int i = 1; i <= IMWD; i++)
	{
		c_in :> line[i];
//		printf("x");
	}
}

void distributor(chanend c_in, chanend c_filters[WORKERS], chanend c_out)
{
    // buffer of the last three lines received, with black edges
    pixel lines[3][IMWD+2];
    // start on the second line so the first line is a black edge
    int currLine = 1;

    pixel val;

    printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );

    // initialise the line buffer with a black edge and the first line
    for (int i = 0; i<IMWD+2; i++)
    	lines[0][i] = 0;
    fillLine(c_in, lines[1]);

    // process the current line of pixels, passing each pixel to a separate worker
    while (currLine <= IMHT)
    {
    	if (currLine == IMHT)
    	{
//    		printf("filling black bottom line %d\n", currLine+1);
			for (int l = 0; l < IMWD+2; l++)
				lines[(currLine+1)%3][l] = 0;
		}
		else
		{
//			printf("filling line %d\n", currLine+1);
			fillLine(c_in, lines[(currLine+1)%3]);
		}

//    	printf("\n==== LINE %d ====\n", currLine);
		for (int i = 1; i <= IMWD; i) // incrementing is done manually later
		{
			int workCount = IMWD-(i-1) > WORKERS ? WORKERS : IMWD-(i-1);
			for (int j = 0; j < workCount; j++)
			{
				c_filters[j] <: 1;
//				printf("sending data for (%d, %d) to worker %d\n", j+i, currLine, j);
				// loop through the line above and below the current
				// goes from 2 to 5 due to % not working on negative numbers
				for (int l = 2; l < 5; l++)
				{
					int line = (currLine+l)%3;
//					printf("sending line %d to worker %d\n", line, j);

					c_filters[j] <: lines[line][j+i-1];
					c_filters[j] <: lines[line][j+i];
					c_filters[j] <: lines[line][j+i+1];
				}
//				printf("sent\n");
			}

			// send each of the values from the workers back to the out channel
			for (int k=0;k<workCount;k++)
			{
				c_filters[k] :> val;
				c_out <: val;
			}

			// increment i by the number of pixels processed.
			i += workCount;
		}

//		printf("\n==== LINE %d DONE ===\n", currLine);

		currLine++;
    }

    // tell all the workers to stop.
    for (int i=0; i < WORKERS; i++)
    	c_filters[i] <: 0;

    printf( "ProcessImage:Done...\n" );
}

int main()
{
	chan c_in, c_collect, c_out;
	chan c_filters[WORKERS];

	par {
		DataInStream("/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/test0.pgm", c_in);
		distributor(c_in, c_filters, c_out);
		par (int i = 0; i < WORKERS; i++)
			processPixel(c_filters[i]);
		DataOutStream("/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/test0_out.pgm", c_out);
	}

	printf("filtering complete, terminating\n");

	return 0;
}
