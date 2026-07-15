#define UART_BASE   0x30000000
#define UART_TX     (*(volatile unsigned int*)(UART_BASE + 0))
#define UART_STATUS (*(volatile unsigned int*)(UART_BASE + 8))

void uart_send(char c)
{
    while ((UART_STATUS & 0x2) == 0);  // wait for TX ready
    UART_TX = c;
}

int main()
{
    uart_send('A');
    uart_send('r');
    uart_send('y');
    uart_send('a');
    uart_send('n');
    uart_send('\r');
    uart_send('\n');

    return 0;
}