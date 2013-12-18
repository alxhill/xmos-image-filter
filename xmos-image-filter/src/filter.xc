/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// TITLE: "Concurrent Image Filter"
// AUTHORS: sw12690, ah12466
//
/////////////////////////////////////////////////////////////////////////////////////////

#include <platform.h>
#include <stdio.h>
#include "convolution.h"

#define FALSE 0
#define TRUE 1
#define NUM_WORKERS 9
#define NUM_LED 12

#define FILE_IN_NAME "C:\\Users\\Sam\\Desktop\\xmos\\test.pgm"
#define FILE_OUT_NAME "C:\\Users\\Sam\\Desktop\\xmos\\test_out.pgm"
#define IMWD 400
#define IMHT 256
#define FILTER BLUR

out port cled[4] = {PORT_CLOCKLED_0, PORT_CLOCKLED_1, PORT_CLOCKLED_2, PORT_CLOCKLED_3};
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;

typedef enum {
	START,
	EDIT,
	RUNNING,
	PAUSED,
	END = NUM_LED
} state_t;

void showLED(out port cled, chanend fromVisualiser)
{
	unsigned int lightPattern;
	char isRunning = TRUE;

	while(isRunning)
	{
		fromVisualiser :> lightPattern;
		if(lightPattern == END) isRunning = FALSE;
		else cled <: lightPattern;
	}

	return;
}

void waitMoment(unsigned int myTime)
{
	timer tmr;
	unsigned int waitTime;
	tmr :> waitTime;
	waitTime += myTime;
	tmr when timerafter(waitTime) :> void;
}

void buttonListener(in port buttons, chanend toController)
{
	int lastButtonInput = 0, newButtonInput, isRunning = TRUE;

	while(isRunning)
	{
		buttons :> newButtonInput;
		lastButtonInput = newButtonInput;
		if(newButtonInput != 15){
			toController <: newButtonInput;
			toController :> isRunning;
			if(newButtonInput == 11) isRunning = FALSE;
			else waitMoment(10000000);
		}
	}

	return;
}

void controller(chanend fromButtons, chanend toDistributer, chanend toDataOut, chanend toQuadrant[])
{
	int i, k, button, completion = 0, isRunning = TRUE, currLine;
	filter_t filter = FILTER;
	state_t state = START;

	cledG <: 1;
	while(state != END && state != RUNNING){
		for(i = 0; i < 4; i++)
			toQuadrant[i] <: (16<<(filter%3))*(filter/3==i);
		fromButtons :> button;
		fromButtons <: TRUE;
		switch(button){
			case 14:
				if(state == EDIT) filter = (filter + (NUM_FILTERS - 1)) % NUM_FILTERS;
				else state = RUNNING;
				break;
			case 13:
				if(state == EDIT) filter = (filter + 1) % NUM_FILTERS;
				break;
			case 11:
				toDistributer <: END;
				toDistributer <: END;
				toDataOut <: END;
				for(i = 0; i < 4; i++)
					toQuadrant[i] <: END;
				state = END;
				break;
			case 7:
				if(state == START){
					cledG <: 0;
					cledR <: 1;
					state = EDIT;
				}
				else if(state == EDIT){
					cledR <: 0;
					cledG <: 1;
					state = START;
				}
				break;
			default:
				break;
		}
	}
	if(state != END){
		toDistributer <: RUNNING;
		toDistributer <: filter;
		toDataOut <: RUNNING;
	}
	while(state != END){
		for(i = 0; i < 4; i++){
			k = (16<<(completion%3))*(completion/3==i);
			toQuadrant[i] <: k;
		}
		select{
			case toDataOut :> completion:
				toDataOut <: RUNNING;
				break;
			default: break;
		}
		if(completion == NUM_LED){
			fromButtons :> button;
			fromButtons <: FALSE;
			state = END;
			for(i = 0; i < 4; i++)
				toQuadrant[i] <: END;
		}
		else{
			select{
				case fromButtons :> button:
					switch(button){
						case 13:
							if(state == PAUSED){
								toDistributer <: RUNNING;
								toDataOut <: RUNNING;
								state = RUNNING;
							}
							else if (state == RUNNING){
								toDistributer <: PAUSED;
								toDataOut :> completion;
								toDataOut <: PAUSED;
								state = PAUSED;
							}
							break;
						case 11:
							toDistributer <: END;
							toDistributer :> currLine;
							toDataOut :> completion;
							toDataOut <: END;
							toDataOut <: currLine;
							for(i = 0; i < 4; i++)
								toQuadrant[i] <: END;
							state = END;
							break;
						default:
							break;
					}
					fromButtons <: TRUE;
					break;
				default:
					break;
			}
		}
	}

	printf("Controller Ended!\n");
	return;
}

void dataInStream(char file_name[], chanend stream_in)
{
	int x, y, isRunning = TRUE;
	pixel line[IMWD];

	if(_openinpgm(file_name, IMWD, IMHT))
	{
		printf( "dataInStream: Error opening '%s'!\n", file_name);
		return;
	}
	for(y = 0; y < IMHT && isRunning; y++)
	{
		_readinline(line, IMWD);
		for(x = 0; x < IMWD; x++) stream_in <: line[x];
		stream_in :> isRunning;
	}
	_closeinpgm();

	printf("DataIn Ended\n");
	return;
}

void distributor(chanend fromControl, chanend stream_in, chanend workers_in[NUM_WORKERS])
{
	int x, y, i, sent, currLine = -1, checkingIn = TRUE, filter;
	pixel lines[3][IMWD];
	state_t state = START;

	while(state == START) fromControl :> state;

	fromControl :> filter;

	for(y = 1; y < 3; y++){
		for(x = 0; x < IMWD; x++)
			stream_in :> lines[y][x];
		stream_in <: TRUE;
		currLine++;
	}
	for(i = 0; i < NUM_WORKERS; i++)
		workers_in[i] <: filter;

	if(state != END){
		while(currLine < (IMHT - 1) && state != END)
		{
			for(x = 0; x < IMWD; x++)
			{
				lines[0][x] = lines[1][x];
				lines[1][x] = lines[2][x];
				stream_in :> lines[2][x];
			}
			stream_in <: TRUE;
			currLine++;
			sent = FALSE;
			select{
				case fromControl :> state:
					if(state == END) fromControl <: currLine;
					break;
				default: break;
			}
			while(state == PAUSED) fromControl :> state;
			while(sent == FALSE && state != END)
			{
				for(i = 0; i < NUM_WORKERS && sent == FALSE; i++)
				{
					select{
						case workers_in[i] :> sent:
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
		}

		printf("Distributor Ending!\n");
		for(i = 0; i < NUM_WORKERS && state ; i++)
		{
			workers_in[i] :> sent;
			workers_in[i] <: IMHT;
		}
	}

	for(x = 0; x < IMWD; x++) stream_in :> lines[0][x];
	stream_in <: FALSE;

	printf("Distributor Ended!\n");
	return;
}

void processLine(int i, chanend worker_in, chanend worker_out)
{
	int x, y, lineNumber = 0, proceed, filter;
	pixel pixelsIn[3][IMWD];
	pixel pixelsOut[IMWD - 2];

	worker_in :> filter;
	while(lineNumber < IMHT && filter != END)
	{
		worker_in <: TRUE;
		worker_in :> lineNumber;
		printf("Worker[%d] processing line %d\n", i, lineNumber);
		if(lineNumber < IMHT)
		{
			for(y = 0; y < 3; y++)
				for(x = 0; x < IMWD; x++)
					worker_in :> pixelsIn[y][x];
			for(x = 0; x < (IMWD - 2); x++)
				pixelsOut[x] = convolution_handler(filter,
						pixelsIn[0][x], pixelsIn[0][x + 1], pixelsIn[0][x + 2],
						pixelsIn[1][x], pixelsIn[1][x + 1], pixelsIn[1][x + 2],
						pixelsIn[2][x], pixelsIn[2][x + 1], pixelsIn[2][x + 2]);

			proceed = FALSE;
			printf("Worker[%d] processed line %d\n", i, lineNumber);
			while(proceed == FALSE){
				worker_out <: lineNumber;
				worker_out :> proceed;
			}
			for (x = 0; x < (IMWD - 2); x++) worker_out <: pixelsOut[x];
			printf("Worker[%d] sent line %d\n", i, lineNumber);
		}
	}

	printf("Worker[%d] Ended!\n", i);
	return;
}

void dataOutStream(chanend toControl, chanend workers_out[], char file_name[])
{
	int x, i, lineNum, currLine = 2, totalLines = IMHT;
	pixel line[IMWD];
	state_t state = START;

	while(state == START) toControl :> state;

	if(state != END){
		if(_openoutpgm(file_name, IMWD, IMHT))
		{
			printf("dataOutStream:Error opening '%s'!\n", file_name);
			return;
		}

		for(x = 0; x < IMWD; x++)
			line[x] = 0;
		_writeoutline(line, IMWD);

		while(currLine < totalLines)
		{
			printf("%d out of %d\n", currLine, totalLines);
			for(i = 0; i < NUM_WORKERS; i++)
			{
				select{
					case workers_out[i] :> lineNum:
						if(lineNum == currLine)
						{
							workers_out[i] <: TRUE;
							for(x = 1; x < (IMWD - 1); x++)
								workers_out[i] :> line[x];
							_writeoutline(line, IMWD);
							currLine++;
							toControl <: ((currLine * NUM_LED) - 1) / IMHT;
							toControl :> state;
							while(state == PAUSED) toControl :> state;
							if(state == END) toControl :> totalLines;
						}
						else workers_out[i] <: FALSE;
						break;
					default:
						break;
				}
			}
		}

		if(state != END){
			toControl <: NUM_LED;
			toControl :> state;
			for(x = 0; x < IMWD; x++)
				line[x] = 0;
			_writeoutline(line, IMWD);
		}

		_closeinpgm();
	}

	printf("Data Out Ended!\n");
	return;
}

int main(){
	chan stream_in, buttonToController, controlDistributer, controlDataOut;
	chan quadrant[4];
	chan workers_in[NUM_WORKERS];
	chan workers_out[NUM_WORKERS];

	par{
		on stdcore[0]: buttonListener(buttons, buttonToController);
		on stdcore[0]: controller(buttonToController, controlDistributer, controlDataOut, quadrant);
		on stdcore[0]: dataInStream(FILE_IN_NAME, stream_in);
		on stdcore[0]: distributor(controlDistributer, stream_in, workers_in);
		on stdcore[0]: dataOutStream(controlDataOut, workers_out, FILE_OUT_NAME);
		par(int i = 0; i < NUM_WORKERS; i++){
			on stdcore[(i%3)+1]: processLine(i, workers_in[i], workers_out[i]);
		}
		par(int i = 0; i < 4; i++){
			on stdcore[i%4]: showLED(cled[i], quadrant[i]);
		}
	}

	return 0;
}

