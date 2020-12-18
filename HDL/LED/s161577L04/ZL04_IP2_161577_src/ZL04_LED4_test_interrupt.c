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

XScuGic   XScuGic_Inst;	// interrupt controller driver instance
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
    int status;
	// init control
    BTN_INT_Disable();
	BTN_INT_Clear( );   // clear int_req
	BTN_INT_Clear_Reset( );

	led_val = 0x5;
	LED_Out(led_val);  // test flashing

	// Initialize interrupt controller
	status = IntcInitFunction(SCUGIC_DEVICE_ID);
	if(status != XST_SUCCESS) return XST_FAILURE;

	xil_printf("Testing btn->led by interrupt.\r\n");
	BTN_INT_Enable();

	while ( 1 ) {
		/*
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
		*/
	}
}

int IntcInitFunction (u16 DeviceId) {  // DeviceId = an scugic driver id
    XScuGic_Config *IntcConfig;  // vector table의 config 정보
    int status;
    // Interrupt controller initialization
    IntcConfig = XScuGic_LookupConfig (DeviceId);  // int controlle에 대한 config
    status = XScuGic_CfgInitialize (&XScuGic_Inst, IntcConfig, // controller를 초기화
               IntcConfig->CpuBaseAddress);  // 하고 해당 instance의 pointer 반환
    if (status != XST_SUCCESS) return XST_FAILURE;
    // Call to interrupt setup(exception source와 driver를 연결)
    status = InterruptSystemSetup (&XScuGic_Inst);
    if (status != XST_SUCCESS) return XST_FAILURE;
    // Connect BTN interrupt handler to scugic controller(각 source 마다 호출(1))
    // 마지막 파라미터는 Int Handler의 callback 변수인데 불필요할 경우 NULL
    status = XScuGic_Connect (&XScuGic_Inst, BTN_INT_ID,
               (Xil_ExceptionHandler) BTN_Intr_Handler, (void *)NULL );
    if (status != XST_SUCCESS) return XST_FAILURE;
    // Enable BTN interrupt in the controller side(각 source 마다 호출해야 함)
    XScuGic_Enable ( &XScuGic_Inst, BTN_INT_ID );  // int controller side
    return XST_SUCCESS;
}

int InterruptSystemSetup (XScuGic *XScuGicInstancePtr) {
    Xil_ExceptionRegisterHandler( XIL_EXCEPTION_ID_INT,  // exception source와
        (Xil_ExceptionHandler) XScuGic_InterruptHandler,     // handler를 연결
        XScuGicInstancePtr);  // XScuGic_CfgInitialize( )에서 만든 XScuGic instance
    Xil_ExceptionEnable ( );
    return XST_SUCCESS;
}

void BTN_Intr_Handler(void *InstancePtr) {  // InstancePtr = btn call back 변수
   // 그런데 우리는 btn instance가 불필요하여 정의하지 않았으므로 의미가 없다.
   // 따라서, 함수 XScuGic_Connect에서 콜백 변수를 NULL로 설정한다.
   BTN_INT_Disable ( );     		// disable btn interrupt
   xil_printf("btn interrupt!\r\n"); // just to show that btn interrupt is requested.
   btn_val = BTN_Read( ); 		 // read btn value
   led_val = led_val + btn_val;
   LED_Out(led_val);         		// output to led
   BTN_INT_Clear();          		// clear interrupt
   BTN_INT_Clear_Reset();
   BTN_INT_Enable();        		// enable btn interrupt
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


