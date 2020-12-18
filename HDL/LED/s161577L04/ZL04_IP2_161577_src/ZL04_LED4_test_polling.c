/*
 *  * ZL04_LED4_test.c
 *
 *  Created on: 2018. 12. 30.
 *      Author: CSRim
 */
#include "led_btn_ip.h"	    // IP 입출력 관련 (파일 명 변경)
#include "xparameters.h"    // device 관련 parameters
#include "xscugic.h"	    // interrupt controller 관련 header file
#include "xil_exception.h"	// 예외 처리 drfinitions
#include "xil_printf.h"	    // 입출력 함수

#define IP_BASE_ADDR XPAR_LED_BTN_IP_0_S00_AXI_BASEADDR
#define LED_OFFSET   LED_BTN_IP_S00_AXI_SLV_REG0_OFFSET // offset 0
#define BTN_OFFSET   LED_BTN_IP_S00_AXI_SLV_REG1_OFFSET // offset 4
#define INT_OFFSET   LED_BTN_IP_S00_AXI_SLV_REG3_OFFSET // offset 12
#define IRQ_OFFSET   LED_BTN_IP_S00_AXI_SLV_REG4_OFFSET // offset 16
#define INT_EN	0x00000001	// bit 0
#define INT_DEN	0x00000000	// bit 0
#define INT_CLR	0x00000002	// bit 1
#define INT_CLR_RST	0x00000000	// bit 1

#define SCUGIC_DEVICE_ID   XPAR_PS7_SCUGIC_0_DEVICE_ID // int ctrller
#define BTN_INT_ID        XPAR_FABRIC_LED_BTN_IP_0_VEC_ID // btn int

XScuGic   XScuGic_Inst;	// interrupt controller instance
static int  led_val = 0;
static int  btn_val;

// basic in/out functions
static u32   BTN_Read( void );
static void  LED_Out( u32 value );
static u32   IRQ_Read( void );      // can read btn by polling
// the functions below set/reset a single bit.
// other bits are not preserved(reset to 0)
static void  BTN_INT_Enable( void );
static void  BTN_INT_Disable( void );
static void  BTN_INT_Clear( void );
static void  BTN_INT_Clear_Reset( void );
// interrupt related functions
static void  BTN_Intr_Handler(void *baseaddr_p);
static int   IntcInitFunction(u16 DeviceId);
static int   InterruptSystemSetup(XScuGic *XScuGicInstPtr);
static void  BTN_Intr_Handler(void *InstancePtr);

int main ( void ) {
	// BTN -> LED by polling
    int btn_pushed;
	// init control
    //BTN_INT_Disable();
	BTN_INT_Clear( );   // clear int_req
	BTN_INT_Clear_Reset( );
	led_val = 0x5;
	LED_Out(led_val);  // test flashing
	xil_printf("Testing btn->led by polling.\r\n");
	while ( 1 ) {
		btn_pushed = IRQ_Read();  // read int_req
		if (btn_pushed == 1) {
			btn_val = BTN_Read();
			BTN_INT_Clear( );     // clear int_req
			BTN_INT_Clear_Reset( );
			led_val = led_val + btn_val;
			LED_Out(led_val);
			btn_pushed = IRQ_Read();
			if (btn_pushed != 0) {
				xil_printf("Flag must be reset!\r\n");
				break;
			}
		}
	}
}

int IntcInitFunction (u16 DeviceId) {
    XScuGic_Config *IntcConfig;
    int status;
    // Interrupt controller initialisation
    IntcConfig = XScuGic_LookupConfig (DeviceId);
    status = XScuGic_CfgInitialize (&XScuGic_Inst, IntcConfig,
                                             IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS) return XST_FAILURE;
    // Call to interrupt setup
    status = InterruptSystemSetup (&XScuGic_Inst);
    if (status != XST_SUCCESS) return XST_FAILURE;
    // Connect BTN interrupt handler(int source 마다 호출해야 한다)
    // 마지막 파라미터는 Int Handler의 callback 변수인데 불필요할 경우 NULL
    status = XScuGic_Connect (&XScuGic_Inst, BTN_INT_ID,
               (Xil_ExceptionHandler) BTN_Intr_Handler, (void *)NULL );
    if (status != XST_SUCCESS) return XST_FAILURE;
    BTN_INT_Enable ( );   // enable interrupt(device side, 각 소스 마다 호출)
    // Enable BTN interrupt in the controller(각 int source 마다 호출해야 함)
    XScuGic_Enable ( &XScuGic_Inst, BTN_INT_ID );  // int controller side
    return XST_SUCCESS;
}

int InterruptSystemSetup (XScuGic *XScuGicInstancePtr) {
    Xil_ExceptionRegisterHandler ( XIL_EXCEPTION_ID_INT,
	        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
			 	          XScuGicInstancePtr);
    Xil_ExceptionEnable ( );
    return XST_SUCCESS;
}

void BTN_Intr_Handler(void *InstancePtr)
{
	// Disable GPIO interrupts
	//XGpio_InterruptDisable(&BTNInst, BTN_INT);
	BTN_INT_Disable ( );
	// Ignore additional button presses
	//if ((XGpio_InterruptGetStatus(&BTNInst) & BTN_INT) != BTN_INT) {
	//	return;
	//}
	//btn_value = XGpio_DiscreteRead(&BTNInst, 1);
	btn_val = BTN_Read( );
	// Increment counter based on button value

	led_val = led_val + btn_val;

    //XGpio_DiscreteWrite(&LEDInst, 1, led_data);
	//LED_IP_mWriteReg(LED_BASE_ADDR, LED_OFFSET, led_data); // csrim
	LED_Out(led_val);
    //(void)XGpio_InterruptClear(&BTNInst, BTN_INT);
	BTN_INT_Clear();
	BTN_INT_Clear_Reset();
    // Enable GPIO interrupts
    //XGpio_InterruptEnable(&BTNInst, BTN_INT);
	BTN_INT_Enable();
}

void BTN_INT_Enable( void ) {
    LED_BTN_IP_mWriteReg(IP_BASE_ADDR, INT_OFFSET, INT_EN);
}
void BTN_INT_Disable( void ) {
    LED_BTN_IP_mWriteReg(IP_BASE_ADDR, INT_OFFSET, INT_DEN);
}
void BTN_INT_Clear( void ) {
    LED_BTN_IP_mWriteReg(IP_BASE_ADDR, INT_OFFSET, INT_CLR);
}
void BTN_INT_Clear_Reset( void ) {
    LED_BTN_IP_mWriteReg(IP_BASE_ADDR, INT_OFFSET, INT_CLR_RST);
}
u32 BTN_Read( void ) {
     return (LED_BTN_IP_mReadReg(IP_BASE_ADDR, BTN_OFFSET));
}
u32 IRQ_Read( void ) {  // for btn input by polling
     return (LED_BTN_IP_mReadReg(IP_BASE_ADDR, IRQ_OFFSET));
}
void LED_Out( u32 value ) {
     LED_BTN_IP_mWriteReg(IP_BASE_ADDR, LED_OFFSET, value);
}


