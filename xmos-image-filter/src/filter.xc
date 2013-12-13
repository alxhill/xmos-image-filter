/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////////////////

typedef unsigned char uchar;

#include <platform.h>
#include <stdio.h>
#include "convolution.h"

#define IMHT 16
#define IMWD 16


/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out)
{
    uchar line[ IMWD ];

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
    uchar line[ IMWD ];

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
            printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
        }
        _writeoutline(line, IMWD);
        printf( "\n" ); //uncomment to show image values
    }

    _closeinpgm();
    printf( "DataInStream:Done...\n" );
    return;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to farm out parts of the image...
//
/////////////////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, chanend c_out)
{
    uchar val;

    printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );

//This code is to be replaced Ð it is a place holder for farming out the work...
    for( int y = 0; y < IMHT; y++ )
    {
        for( int x = 0; x < IMWD; x++ )
        {
            c_in :> val;
            c_out <: (uchar)( val ^ 0xFF ); //Need to cast
        }
    }
    printf( "ProcessImage:Done...\n" );
}

void processimage(chanend c_in, chanend c_out, int width, int height)
{
	pixel imageIn[18][18];
	 pixel pixelOut;

	// fill in the edges of the image so it's all black
	for (int i = 0; i < 18; i++)
	{
		imageIn[i][0] = 0;
		imageIn[i][17] = 0;
		imageIn[0][i] = 0;
		imageIn[17][i] = 0;
	}

	for (int i = 1; i < width+1; i++)
	{
		for (int j = 1; j < height+1; j++)
		{
			//printf("proccessing pixel\n");
			c_in :> imageIn[i][j];
			printf("i");
		}
	}

	for (int j = 1; j < 17; j++)
	{
		for (int k = 1; k < 17; k++)
		{
			pixelOut = convolution_handler(BLUR,
				imageIn[j-1][k-1], imageIn[j][k-1], imageIn[j+1][k-1],
				imageIn[j-1][k],   imageIn[j][k],   imageIn[j+1][k],
				imageIn[j-1][k+1], imageIn[j][k+1], imageIn[j+1][k+1]
			);
//			printf("processed pixel %d %d\n", j-1, k-1);
			c_out <: pixelOut;
		}
	}
}

int main()
{
	chan cin, cout;


	printf("about to load data\n");
	par {
		DataInStream("/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/test0.pgm", cin);
		//distributor(cin, cout);
		processimage(cin, cout, IMWD, IMHT);
		DataOutStream("/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/test0_out.pgm", cout);
	}

	printf("filtering complete, terminating\n");

	return 0;
}
