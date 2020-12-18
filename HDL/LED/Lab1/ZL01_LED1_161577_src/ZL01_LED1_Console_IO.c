/*
 * LED_test.c
 *
 *  Created on: 	13 June 2013
 *      Author: 	Ross Elliot
 *     Version:		1.2
 */

/********************************************************************************************
 * VERSION HISTORY
 ********************************************************************************************
 * 	v1.2 - 13 February 2015
 * 		Modified for Zybo Development Board ~ DN
 *
 * 	v1.1 - 27 January 2014
 * 		GPIO_DEVICE_ID definition updated to reflect new naming conventions in
 *Vivado 2013.3 onwards.
 *
 *	v1.0 - 13 June 2013
 *		First version created.
 *******************************************************************************************/

/********************************************************************************************
 * This file contains an example of using the GPIO driver to provide
 *communication between the Zynq Processing System (PS) and the AXI GPIO block
 *implemented in the Zynq Programmable Logic (PL). The AXI GPIO is connected to
 *the LEDs on the Zybo.
 *
 * The provided code demonstrates how to use the GPIO driver to write to the
 *memory mapped AXI GPIO block, which in turn controls the LEDs.
 ********************************************************************************************/

/* Include Files */
#include "xgpio.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xstatus.h"

/* Definitions */
#define GPIO_DEVICE_ID \
    XPAR_AXI_GPIO_0_DEVICE_ID /* GPIO device that LEDs are connected to */
#define LED 0x0               /* Initial LED value - X00X */
#define LED_CHANNEL 1         /* GPIO port for LEDs */

XGpio Gpio; /* GPIO Device driver instance */

int LEDOutputExample(void);

/* Main function. */
int main(void) {
    int Status;

    xil_printf("Start LED lighting!\r\n");
    /* Execute the LED output. */
    Status = LEDOutputExample();
    if (Status != XST_SUCCESS) {
        xil_printf("GPIO output to the LEDs failed!\r\n");
    }
    xil_printf("Bye!\r\n");

    return 0;
}

int LEDOutputExample(void) {
    int Status;
    int led = LED; /* Hold current LED value. Initialize to LED definition */
    char8 ch;

    /* GPIO driver initialization */
    Status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Set the direction for the LEDs to output. */
    XGpio_SetDataDirection(&Gpio, LED_CHANNEL, 0x0);
    /* Turn off LED */
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led);

    while (1) {
        xil_printf("Enter an LED value in hex: ");
        ch = inbyte();    // Input a char
        if (ch == 'q') {  // If 'q', exit
            xil_printf("%c\r\n", ch);
            break;
        } else if ((0x40 < ch && ch < 0x47) || (0x60 < ch && ch < 0x67) ||
                   (0x2f < ch && ch < 0x3a)) {
            led = (int) (ch > 0x40 ? ((ch & 0xf) + 0x09)
                                   : (ch & 0x0f));  // To hex
            xil_printf("%c\r\n", ch);
        } else {
            led = 0;
            xil_printf("%c : not a number!\r\n", ch);
        }
        XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led);
    }

    return XST_SUCCESS; /* Should be unreachable */
}
