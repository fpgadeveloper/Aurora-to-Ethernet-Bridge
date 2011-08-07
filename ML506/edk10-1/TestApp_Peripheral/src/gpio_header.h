#define TESTAPP_GEN

/* $Id: gpio_header.h,v 1.1.2.1 2008/02/12 13:28:38 svemula Exp $ */


#include "xbasic_types.h"
#include "xstatus.h"

XStatus GpioOutputExample(Xuint16 DeviceId, Xuint32 GpioWidth);
XStatus GpioInputExample(Xuint16 DeviceId, Xuint32 *DataRead);


