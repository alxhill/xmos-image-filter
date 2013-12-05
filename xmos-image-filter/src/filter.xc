#include "pgmIO.h"
#include <platform.h>

out port cled[4] = {PORT_CLOCKLED_0, PORT_CLOCKLED_1, PORT_CLOCKLED_2, PORT_CLOCKLED_3};
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;
out port buttonLED = PORT_BUTTONLED;

int main()
{
	return 0;
}
