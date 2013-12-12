#include "convolution.h"
#include <platform.h>

//out port cled[4] = {PORT_CLOCKLED_0, PORT_CLOCKLED_1, PORT_CLOCKLED_2, PORT_CLOCKLED_3};
//out port cledR = PORT_CLOCKLED_SELR;
//in port buttons = PORT_BUTTON;
//out port speaker = PORT_SPEAKER;
//out port buttonLED = PORT_BUTTONLED;

int main()
{
	_openinpgm("test.pgm", 16, 16);

	pixel imageIn[18][18];
	pixel imageOut[16][16];

	// fill in the edges of the image so it's all black
	for (int i = 0; i < 18; i++)
	{
		imageIn[i][0] = BIT_DEPTH;
		imageIn[i][17] = BIT_DEPTH;
		imageIn[0][i] = BIT_DEPTH;
		imageIn[17][i] = BIT_DEPTH;
	}

	printf("about to load data\n");

	for (int i = 0; i < 16; i++)
		printf("line: %s\n", _readlinepgm);



	// go through the middle pixels and apply the filter
	// this currently works in sequence...for now
	for (int j = 1; j < 17; j++)
	{
		for (int k = 1; k < 17; k++)
		{
			imageOut[j-1][k-1] = convolution_handler(BLUR,
					imageIn[j-1][k-1], imageIn[j][k-1], imageIn[j+1][k-1],
					imageIn[j-1][k],   imageIn[j][k],   imageIn[j+1][k],
					imageIn[j-1][k+1], imageIn[j][k+1], imageIn[j+1][k+1]
			);
		}
	}



	return 0;
}
