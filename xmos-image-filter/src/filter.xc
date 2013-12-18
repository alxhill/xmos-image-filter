/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// TITLE: "Concurrent Image Filter"
// AUTHORS: sw12690, ah12466
//
/////////////////////////////////////////////////////////////////////////////////////////

#include <platform.h>
#include "convolution.h"

//Useful Boolean Defines
#define FALSE 0
#define TRUE 1

//Board Specific Constants
#define NUM_WORKERS 9 //Number of workers (max 9 on xc-1a due to channel restraints)
#define NUM_LED 12 //Number of LEDs

//File Information
#define FILE_IN_NAME "C:\\Users\\Sam\\Desktop\\xmos\\test.pgm" //Input file path
#define FILE_OUT_NAME "C:\\Users\\Sam\\Desktop\\xmos\\test_out.pgm" //Output file path
#define IMWD 16 //Image width
#define IMHT 16 // Image height
#define FILTER BLUR //Starting filter

//Port assignments
out port cled[4] = {PORT_CLOCKLED_0, PORT_CLOCKLED_1, PORT_CLOCKLED_2, PORT_CLOCKLED_3};
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;

//Useful state typedef, allowing easy control of how functions react to stimulus
typedef enum {
	START, EDIT, RUNNING, PAUSED, ENDING, END = NUM_LED
} state_t;

//Useful delay function, taking a time to delay for, effectivly pausing a function.
void waitMoment(unsigned int myTime)
{
	timer tmr;
	unsigned int waitTime;
	tmr :> waitTime;
	waitTime += myTime;
	tmr when timerafter(waitTime) :> void;
}

//Button listener function taking input from the buttons and passing it to the controller.
void buttonListener(in port buttons, chanend toControl)
{
	int lastButtonInput = 0, newButtonInput, isRunning = TRUE;

	while(isRunning)
	{
		buttons :> newButtonInput;
		if(newButtonInput != 15){
			toControl <: newButtonInput;
			toControl :> isRunning;
			waitMoment(10000000);
		}
		lastButtonInput = newButtonInput;
	}

	return;
}

//Takes LED information from the controller and updates the board LEDs accordingly
void showLED(out port cled, chanend fromControl)
{
	unsigned int lightPattern;
	char isRunning = TRUE;

	while(isRunning){
		fromControl :> lightPattern;
		if(lightPattern == END) isRunning = FALSE;
		else cled <: lightPattern;
	}

	return;
}

//Controller function, coordinating the running of the program including graceful termination and change of filters.
void controller(chanend fromButtons, chanend toDistributer, chanend toDataOut, chanend toQuadrant[])
{
	int i, k, button, completion = 0, isRunning = TRUE, currLine, startTime, stopTime;
	filter_t filter = FILTER;
	state_t state = START;
	timer tmr;

	//Starts by showing the current filter on the LEDs
	cledG <: 1;
	for(i = 0; i < 4; i++)
		toQuadrant[i] <: (16<<(filter%3))*(filter/3==i);

	while(state == START){
		fromButtons :> button;
		if(button == 14) state = RUNNING;
		else if(button == 11) state = END;
		else if(button == 7){
			cledG <: 0;
			cledR <: 1;
			state = EDIT;
			while(state == EDIT){
				fromButtons <: TRUE;
				fromButtons :> button;
				if(button == 14) filter = (filter + (NUM_FILTERS - 1)) % NUM_FILTERS;
				else if(button == 13) filter = (filter + 1) % NUM_FILTERS;
				else if(button == 11) state = END;
				else if(button == 7){
					cledR <: 0;
					cledG <: 1;
					state = START;
				}
				for(i = 0; i < 4; i++)
					toQuadrant[i] <: (16<<(filter%3))*(filter/3==i);
			}
		}
		fromButtons <: TRUE;
	}

	if(state == END){
		toDistributer <: END;
		toDistributer <: END;
		toDataOut <: END;
	}
	else{
		tmr :> startTime;
		toDistributer <: RUNNING;
		toDistributer <: filter;
		toDataOut <: RUNNING;
		for(i = 0; i < 4; i++)
			toQuadrant[i] <: (16<<(completion%3))*(completion/3==i);

		while(state == RUNNING){
			select{
				case toDataOut :> completion:
					for(i = 0; i < 4; i++)
						toQuadrant[i] <: (16<<(completion%3))*(completion/3==i);
					if(completion == NUM_LED){
						toDataOut <: END;
						state = END;
					}
					else toDataOut <: RUNNING;
					break;
				case fromButtons :> button:
					if(button == 13){
						state = PAUSED;
						toDistributer <: PAUSED;
						toDataOut :> completion;
						toDataOut <: PAUSED;
						while(state == PAUSED){
							fromButtons <: TRUE;
							fromButtons :> button;
							if(button == 13){
								state = RUNNING;
								toDistributer <: RUNNING;
								toDataOut <: RUNNING;
							}
							if(button == 11){
								state = ENDING;
							}
						}
					}
					else if(button == 11) state = ENDING;
					fromButtons <: TRUE;
					break;
				default: break;
			}
		}
	}

	if(state == ENDING){
		toDistributer <: END;
		toDistributer :> currLine;
		toDataOut :> completion;
		toDataOut <: END;
		toDataOut <: currLine;
		state = END;
	}
	tmr :> stopTime;

	fromButtons :> button;
	fromButtons <: FALSE;
	for(i = 0; i < 4; i++)
		toQuadrant[i] <: END;

	printf("Time Taken: %d seconds\n", (stopTime - startTime) / 100000000);

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

		for(i = 0; i < NUM_WORKERS && state ; i++)
		{
			workers_in[i] :> sent;
			workers_in[i] <: IMHT;
		}
	}

	for(x = 0; x < IMWD; x++) stream_in :> lines[0][x];
	stream_in <: FALSE;

	printf("Distributer Ended\n");
	return;
}

//
void worker(chanend worker_in, chanend worker_out)
{
	int x, y, lineNumber = 0, waiting, filter;
	pixel pixelsIn[3][IMWD];
	pixel pixelsOut[IMWD - 2];

	worker_in :> filter;
	if(filter == END) return;

	while(lineNumber < IMHT)
	{
		worker_in <: TRUE;
		worker_in :> lineNumber;
		if(lineNumber == IMHT) return;
		for(y = 0; y < 3; y++)
			for(x = 0; x < IMWD; x++)
				worker_in :> pixelsIn[y][x];

		for(x = 0; x < (IMWD - 2); x++)
			pixelsOut[x] = convolution_handler(filter,
					pixelsIn[0][x], pixelsIn[0][x + 1], pixelsIn[0][x + 2],
					pixelsIn[1][x], pixelsIn[1][x + 1], pixelsIn[1][x + 2],
					pixelsIn[2][x], pixelsIn[2][x + 1], pixelsIn[2][x + 2]);

		waiting = TRUE;
		while(waiting){
			worker_out <: lineNumber;
			worker_out :> waiting;
		}
		for (x = 0; x < (IMWD - 2); x++) worker_out <: pixelsOut[x];
	}

	printf("Worker Ended\n");
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
			for(i = 0; i < NUM_WORKERS; i++)
			{
				select{
					case workers_out[i] :> lineNum:
						if(lineNum == currLine)
						{
							workers_out[i] <: FALSE;
							for(x = 1; x < (IMWD - 1); x++)
								workers_out[i] :> line[x];
							_writeoutline(line, IMWD);
							currLine++;
							toControl <: ((currLine * NUM_LED) - 1) / IMHT;
							toControl :> state;
							while(state == PAUSED) toControl :> state;
							if(state == END) toControl :> totalLines;
						}
						else workers_out[i] <: TRUE;
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
			on stdcore[(i%3)+1]: worker(workers_in[i], workers_out[i]);
		}
		par(int i = 0; i < 4; i++){
			on stdcore[i%4]: showLED(cled[i], quadrant[i]);
		}
	}

	return 0;
}

