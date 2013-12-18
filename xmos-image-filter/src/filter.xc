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

#define FALSE 0
#define TRUE 1
#define NUM_WORKERS 4
#define NUM_LED 12

#define FILE_IN_NAME "/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/BristolCathedral.pgm"
#define FILE_OUT_NAME "/Users/alexander/dev/csyear2/xmos-image-filter/xmos-image-filter/src/pictures/BristolCathedral_out.pgm"
#define IMHT 256
#define IMWD 400

void dataInStream(char file_name[], chanend stream_in)
{
	int x, y;
	pixel line[ IMWD ];

	if(_openinpgm(file_name, IMWD, IMHT))
	{
		printf( "DataInStream:Error openening %s\n.", file_name);
		return;
	}
	for(y = 0; y < IMHT; y++)
	{
		_readinline(line, IMWD);
		for(x = 0; x < IMWD; x++) stream_in <: line[x];
	}
	_closeinpgm();

	return;
}

void dataOutStream(chanend workers_out[], char file_name[])
{
	int x, i;
	pixel line[IMWD];
	int currLine = 1;
	int lineNum;

	if(_openoutpgm(file_name, IMWD, IMHT))
	{
		printf("DataOutStream:Error openening %s\n.", file_name);
		return;
	}

	for(x = 0; x < IMWD; x++)
	{
		line[x] = 0;
	}
	_writeoutline(line, IMWD);

	while(currLine < (IMHT - 1))
	{
		for(i = 0; i < NUM_WORKERS; i++)
		{
			select{
				case workers_out[i] :> lineNum:
					if(lineNum == currLine)
					{
						workers_out[i] <: TRUE;
						for(x = 1; x < (IMWD - 1); x++)
						{
							workers_out[i] :> line[x];
						}
						_writeoutline(line, IMWD);
						currLine++;
					}
					else workers_out[i] <: FALSE;
					break;
				default:
					break;
			}
		}
	}

	for(x = 0; x < IMWD; x++)
	{
		line[x] = 0;
	}
	_writeoutline(line, IMWD);
	_closeinpgm();

	return;
}

void processLine(chanend worker_in, chanend worker_out)
{
	int x, y, lineNumber = 0, proceed;
	pixel pixelsIn[3][IMWD];
	pixel pixelsOut[IMWD - 2];
	filter_t filter;

	worker_in :> filter;
	while(lineNumber < IMHT)
	{
		worker_in <: TRUE;
		worker_in :> lineNumber;
		if(lineNumber < IMHT)
		{
			for(y = 0; y < 3; y++)
				for(x = 0; x < IMWD; x++)
				{
					worker_in :> pixelsIn[y][x];
				}
			for(x = 0; x < (IMWD - 2); x++)
				pixelsOut[x] = convolution_handler(filter,
						pixelsIn[0][x], pixelsIn[0][x + 1], pixelsIn[0][x + 2],
						pixelsIn[1][x], pixelsIn[1][x + 1], pixelsIn[1][x + 2],
						pixelsIn[2][x], pixelsIn[2][x + 1], pixelsIn[2][x + 2]);

			proceed = FALSE;
			while(proceed == FALSE){
				worker_out <: lineNumber;
				worker_out :> proceed;
			}
			for (x = 0; x < (IMWD - 2); x++) worker_out <: pixelsOut[x];
		}
	}

	return;
}

void distributor(chanend stream_in, chanend workers_in[NUM_WORKERS])
{
	int x, y, i, currLine = 1;
	pixel lines[3][IMWD];
	int sent;

	for(y = 1; y < 3; y++)
		for(x = 0; x < IMWD; x++)
			stream_in :> lines[y][x];

	for(i = 0; i < NUM_WORKERS; i++){
		workers_in[i] <: BLUR;
	}

	while(currLine < (IMHT - 1))
	{
		for(x = 0; x < IMWD; x++)
		{
			lines[0][x] = lines[1][x];
			lines[1][x] = lines[2][x];
			stream_in :> lines[2][x];
		}
		sent = FALSE;
		while(sent == FALSE)
		{
			for(i = 0; i < NUM_WORKERS && sent == FALSE; i++)
			{
				select{
					case workers_in[i] :> sent:
						printf("Using Worker %d\n", i);
						workers_in[i] <: currLine;
						for(y = 0; y < 3; y++)
							for(x = 0; x < IMWD; x++)
								workers_in[i] <: lines[y][x];
						break;
					default:
						break;
				}
			}
		}
		currLine++;
    }

	for(i = 0; i < NUM_WORKERS; i++)
	{
		workers_in[i] :> sent;
		workers_in[i] <: IMHT;
	}

	return;
}

int main()
{
	chan stream_in;
	chan workers_in[NUM_WORKERS];
	chan workers_out[NUM_WORKERS];

	par {
		on stdcore[0]: dataInStream(FILE_IN_NAME, stream_in);
		on stdcore[1]: distributor(stream_in, workers_in);

		par(int i = 0; i < NUM_WORKERS; i++)
			on stdcore[i%4]: processLine(workers_in[i], workers_out[i]);

		on stdcore[3]: dataOutStream(workers_out, FILE_OUT_NAME);
	}

	//printf("Filter application complete, terminating.\n");

	return 0;
}

