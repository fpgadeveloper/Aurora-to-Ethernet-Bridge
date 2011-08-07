#include <xparameters.h>
#include "xgpio.h"
#include <xstatus.h>
#include <bridge.h>

// DIP Switch flags
#define DIPS_1  0x00000080
#define DIPS_2  0x00000040
#define DIPS_3  0x00000020
#define DIPS_4  0x00000010
#define DIPS_5  0x00000008
#define DIPS_6  0x00000004
#define DIPS_7  0x00000002
#define DIPS_8  0x00000001

// LCD Display strings
#define INIT_LCD1			"Design by FPGA"
#define INIT_LCD2			"   Developer.com"
#define WELCOME_LCD1		"Aurora to"
#define WELCOME_LCD2		" Ethernet Bridge"

// Masks to the pins on the GPIO port
#define LCD_DB4    0x01
#define LCD_DB5    0x02
#define LCD_DB6    0x04
#define LCD_DB7    0x08
#define LCD_RW     0x10
#define LCD_RS     0x20
#define LCD_E      0x40
#define LCD_TEST   0x80

// Global variables

// Pointer and base address of Bridge peripheral
Xuint32 *bridge_0_baseaddr_p = (Xuint32 *) XPAR_BRIDGE_0_BASEADDR;
Xuint32 bridge_0_baseaddr;

// LCD GPIO peripheral
XGpio LCD;

// LCD Control Function prototypes
void writeLCD(Xuint8 *str1, Xuint8 *str2);
void delay(Xuint32 period);
void gpio_write(Xuint32 c);
Xuint32 gpio_read(void);
void lcd_clk(void);
void lcd_set_test(void);
void lcd_reset_test(void);
void lcd_set_rs(void);
void lcd_reset_rs(void);
void lcd_set_rw(void);
void lcd_reset_rw(void);
void lcd_write(Xuint32 c);
void lcd_clear(void);
void lcd_puts(const char * s);
void lcd_putch(Xuint32 c);
void lcd_goto(Xuint32 line,Xuint32 pos);
void lcd_init(void);

// Loopback mode function prototypes
void enable_loopback(void);
void disable_loopback(void);

// ------------------------------------------------------------------
// Main function
// ------------------------------------------------------------------

int main (void)
{
  XGpio DIPs;
  XStatus status;
  Xuint32 value;
  Xuint32 oldvalue;
	
  // Check the peripheral pointers
  XASSERT_NONVOID(bridge_0_baseaddr_p != XNULL);
  bridge_0_baseaddr = (Xuint32) bridge_0_baseaddr_p;
	
  // Initialize the GPIO driver for the DIP switches
  status = XGpio_Initialize(&DIPs,XPAR_DIP_SWITCHES_8BIT_DEVICE_ID);
  if (status != XST_SUCCESS)
    return XST_FAILURE;
  // Set the direction for all signals to be inputs
  XGpio_SetDataDirection(&DIPs, 1, 0xFFFFFFFF);
  // Read the initial state of the DIP switches
  value = XGpio_DiscreteRead(&DIPs,1);
  // Enable loopback if set by DIP switches
  if(value & DIPS_1)
    enable_loopback();
  else
    disable_loopback();

  // Initialize the GPIO driver for the LCD
  status = XGpio_Initialize(&LCD,XPAR_LCD_DEVICE_ID);
  if (status != XST_SUCCESS)
    return XST_FAILURE;
  // Set the direction for all signals to be outputs
  XGpio_SetDataDirection(&LCD, 1, 0x00);

  // Initialize the LCD
  lcd_init();
  writeLCD(INIT_LCD1,INIT_LCD2);
  delay(12500000);
  writeLCD(WELCOME_LCD1,WELCOME_LCD2);
	
  while(1){
    // Record the old DIP settings
    oldvalue = value;
    // Read the new DIP settings
    value = XGpio_DiscreteRead(&DIPs,1);
    // If DIP settings have changed, then change loopback mode
    if(value != oldvalue){
      // Enable loopback if set by DIP switches
      if(value & DIPS_1)
        enable_loopback();
      else
        disable_loopback();
    }
  }
}


// LCD Control Functions

void writeLCD(Xuint8 *str1, Xuint8 *str2)
{
  lcd_clear();
  lcd_puts(str1);
  lcd_goto(1,0);
  lcd_puts(str2);
}

// Simple delay function
// Very approximately 1 period = 80ns
void delay(Xuint32 period)
{
  volatile Xuint32 i;
  for(i = 0; i < period; i++){}
}

// Write to GPIO outputs
void gpio_write(Xuint32 c)
{
  // Write to the GP IOs
  XGpio_DiscreteWrite(&LCD, 1, c & 0x0FF);
}

// Read the GPIO outputs
Xuint32 gpio_read()
{
  // Read from the GP IOs
  return(XGpio_DiscreteRead(&LCD, 1));
}

// Clock the LCD (toggles E)
void lcd_clk()
{
  Xuint32 c;
  // Get existing outputs
  c = gpio_read();
  delay(10);
  // Assert clock signal
  gpio_write(c | LCD_E);
  delay(10);
  // Deassert the clock signal
  gpio_write(c & (~LCD_E));
  delay(10);
}

// Assert the RS signal
void lcd_set_rs()
{
  Xuint32 c;
  // Get existing outputs
  c = gpio_read();
  // Assert RS
  gpio_write(c | LCD_RS);
  delay(10);
}

// Deassert the RS signal
void lcd_reset_rs()
{
  Xuint32 c;
  // Get existing outputs
  c = gpio_read();
  // Assert RS
  gpio_write(c & (~LCD_RS));
  delay(10);
}

// Assert the RW signal
void lcd_set_rw()
{
  Xuint32 c;
  // Get existing outputs
  c = gpio_read();
  // Assert RS
  gpio_write(c | LCD_RW);
  delay(10);
}

// Deassert the RW signal
void lcd_reset_rw()
{
  Xuint32 c;
  // Get existing outputs
  c = gpio_read();
  // Assert RS
  gpio_write(c & (~LCD_RW));
  delay(10);
}

// Write a byte to LCD (4 bit mode)
void lcd_write(Xuint32 c)
{
  Xuint32 temp;
  // Get existing outputs
  temp = gpio_read();
  temp = temp & 0xF0;
  // Set the high nibble
  temp = temp | ((c >> 4) & 0x0F);
  gpio_write(temp);
  // Clock
  lcd_clk();
  // Delay for "Write data into internal RAM 43us"
  delay(2500);
  // Set the low nibble
  temp = temp & 0xF0;
  temp = temp | (c & 0x0F);
  gpio_write(temp);
  // Clock
  lcd_clk();
  // Delay for "Write data into internal RAM 43us"
  delay(2500);
}

// Clear LCD
void lcd_clear(void)
{
  lcd_reset_rs();
  // Clear LCD
  lcd_write(0x01);
  // Delay for "Clear display 1.53ms"
  delay(125000);
}

// Write a string to the LCD
void lcd_puts(const char * s)
{
  lcd_set_rs();
  while(*s)
    lcd_write(*s++);
}

// Write character to the LCD
void lcd_putch(Xuint32 c)
{
  lcd_set_rs();
  lcd_write(c);
}

// Change cursor position
// (line = 0 or 1, pos = 0 to 15)
void lcd_goto(Xuint32 line, Xuint32 pos)
{
  lcd_reset_rs();
  pos = pos & 0x3F;
  if(line == 0)
    lcd_write(0x80 | pos);
  else
    lcd_write(0xC0 | pos);
}
 
// Initialize the LCD
void lcd_init(void)
{
  Xuint32 temp;

  // Write mode (always)
  lcd_reset_rw();
  // Write control bytes
  lcd_reset_rs();

  // Delay 15ms
  delay(200000);

  // Initialize
  temp = gpio_read();
  temp = temp | LCD_DB5;
  gpio_write(temp);
  lcd_clk();
  lcd_clk();
  lcd_clk();

  // Delay 15ms
  delay(200000);

  // Function Set: 4 bit mode, 1/16 duty, 5x8 font, 2 lines
  lcd_write(0x28);
  // Display ON/OFF Control: ON
  lcd_write(0x0C);
  // Entry Mode Set: Increment (cursor moves forward)
  lcd_write(0x06);
 
  // Clear the display
  lcd_clear();
}

// Enable loopback mode
void enable_loopback(void)
{
  BRIDGE_mWriteSlaveReg0(bridge_0_baseaddr,0,1);
}

// Disable loopback mode
void disable_loopback(void)
{
  BRIDGE_mWriteSlaveReg0(bridge_0_baseaddr,0,0);
}
