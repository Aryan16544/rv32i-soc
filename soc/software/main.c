#include <stdint.h>

// =============================================================================
// HARDWARE MAPPING
// =============================================================================
#define UART_BASE 0x30000000
#define UART_TX   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STAT (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_TX_FULL 0x02

#define GPIO_BASE 0x20000000
#define GPIO_IN   (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OUT  (*(volatile uint32_t *)(GPIO_BASE + 0x04))

// Switch Mapping (SW[0] is Reset)
#define SW_UP    (1 << 1) // Switch 1
#define SW_DOWN  (1 << 2) // Switch 2
#define SW_LEFT  (1 << 3) // Switch 3
#define SW_RIGHT (1 << 4) // Switch 4

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================
void delay(int cycles) {
    for (volatile int i = 0; i < cycles; i++);
}

void uart_putc(char c) {
    while (UART_STAT & UART_TX_FULL);
    UART_TX = c;
}

void uart_puts(const char *str) {
    while (*str) uart_putc(*str++);
}

// VT100 Terminal Control
void clear_screen() {
    uart_puts("\033[2J\033[H"); // Clear + Home
}

void move_cursor(int x, int y) {
    // Basic integer to string conversion
    uart_puts("\033[");
    if (y >= 10) uart_putc('0' + (y / 10));
    uart_putc('0' + (y % 10));
    uart_putc(';');
    if (x >= 10) uart_putc('0' + (x / 10));
    uart_putc('0' + (x % 10));
    uart_putc('H');
}

// Random Number Generator (Pseudo - Hardware based?)
// We use a counter + user input timing as seed
uint32_t rand_seed = 1234;
uint32_t rand() {
    rand_seed = rand_seed * 1103515245 + 12345;
    return (rand_seed / 65536) % 32768;
}

// =============================================================================
// GAME LOGIC
// =============================================================================
#define WIDTH  20
#define HEIGHT 15
#define MAX_LEN 50

int snake_x[MAX_LEN], snake_y[MAX_LEN];
int length = 3;
int dir_x = 1, dir_y = 0; // Moving Right
int fruit_x, fruit_y;
int score = 0;
int game_over = 0;

void spawn_fruit() {
    fruit_x = (rand() % (WIDTH - 2)) + 2;
    fruit_y = (rand() % (HEIGHT - 2)) + 2;
}

void draw_frame() {
    // We only redraw changes to be fast? 
    // For simplicity, redraw everything (UART 115200 is fast enough for 20x15)
    clear_screen();
    
    // Draw Borders
    uart_puts("  RV32I SNAKE SOC  \r\n");
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            if (y == 0 || y == HEIGHT-1 || x == 0 || x == WIDTH-1) {
                uart_putc('#');
            } else if (x == fruit_x && y == fruit_y) {
                uart_putc('@'); // Fruit
            } else {
                int is_body = 0;
                for (int i = 0; i < length; i++) {
                    if (snake_x[i] == x && snake_y[i] == y) {
                        uart_putc('O');
                        is_body = 1;
                        break;
                    }
                }
                if (!is_body) uart_putc(' ');
            }
        }
        uart_puts("\r\n");
    }
    uart_puts("Score: ");
    // Print Score logic... (simplified)
    uart_putc('0' + (score % 10));
    uart_puts("\r\nControls: SW1=U, SW2=D, SW3=L, SW4=R");
}

int main() {
    // Fast Blink 5 times
    for (int i=0; i<5; i++) {
        GPIO_OUT = 0xFFFF; // All ON
        delay(500000);
        GPIO_OUT = 0x0000; // All OFF
        delay(500000);
    }
    // Set to known pattern (0xA5A5)
    GPIO_OUT = 0xA5A5;

    // Reset Game State
    length = 3;
    snake_x[0] = 5; snake_y[0] = 5;
    snake_x[1] = 4; snake_y[1] = 5;
    snake_x[2] = 3; snake_y[2] = 5;
    spawn_fruit();

    clear_screen();
    uart_puts("Welcome to RV32I Snap!\r\n");
    uart_puts("Game Starting...\r\n");
    uart_puts("Press SW1-SW4 to start.\r\n");
    delay(2000000);

    while (!game_over) {
        // 1. Read Input
        uint32_t sw = GPIO_IN;
        
        // Direction Logic (Toggle Switch - Active High wins)
        // Prevent 180 reversals
        if ((sw & SW_UP) && dir_y != 1)    { dir_x = 0; dir_y = -1; }
        else if ((sw & SW_DOWN) && dir_y != -1) { dir_x = 0; dir_y = 1; }
        else if ((sw & SW_LEFT) && dir_x != 1)  { dir_x = -1; dir_y = 0; }
        else if ((sw & SW_RIGHT) && dir_x != -1) { dir_x = 1; dir_y = 0; }
        
        // 2. Update Position
        // Move body
        for (int i = length - 1; i > 0; i--) {
            snake_x[i] = snake_x[i-1];
            snake_y[i] = snake_y[i-1];
        }
        snake_x[0] += dir_x;
        snake_y[0] += dir_y;
        
        // 3. Collision Detection
        // Walls
        if (snake_x[0] <= 0 || snake_x[0] >= WIDTH-1 || 
            snake_y[0] <= 0 || snake_y[0] >= HEIGHT-1) {
            game_over = 1;
        }
        // Self
        for (int i = 1; i < length; i++) {
            if (snake_x[i] == snake_x[0] && snake_y[i] == snake_y[0]) game_over = 1;
        }
        
        // 4. Fruit
        if (snake_x[0] == fruit_x && snake_y[0] == fruit_y) {
            score++;
            length++;
            if (length >= MAX_LEN) length = MAX_LEN;
            spawn_fruit();
        }
        
        // 5. Draw
        draw_frame();
        
        // 6. Wait
        delay(200000); // Game Speed
    }

    uart_puts("\r\n\r\nGAME OVER!\r\n");
    uart_puts("Restart: Press Reset Button (SW0)\r\n");
    
    while(1);
    return 0;
}

// =============================================================================
// SOFT MATH LIBRARY (Since RV32I has no hardware Multiply/Divide)
// =============================================================================

// Signed Multiply
int __mulsi3(int a, int b) {
    int res = 0;
    while (b != 0) {
        if (b & 1) res += a;
        a <<= 1;
        b = (unsigned int)b >> 1; // Logical shift for unsigned
    }
    return res;
}

// Unsigned Divide
unsigned int __udivsi3(unsigned int n, unsigned int d) {
    unsigned int q = 0;
    unsigned int r = 0;
    for (int i = 31; i >= 0; i--) {
        r <<= 1;
        r |= (n >> i) & 1;
        if (r >= d) {
            r -= d;
            q |= (1 << i);
        }
    }
    return q;
}

// Unsigned Modulo
unsigned int __umodsi3(unsigned int n, unsigned int d) {
    unsigned int r = 0;
    for (int i = 31; i >= 0; i--) {
        r <<= 1;
        r |= (n >> i) & 1;
        if (r >= d) {
            r -= d;
        }
    }
    return r;
}

// Signed Divide
int __divsi3(int n, int d) {
    int neg = 0;
    if (n < 0) { n = -n; neg = !neg; }
    if (d < 0) { d = -d; neg = !neg; }
    int q = __udivsi3(n, d);
    return neg ? -q : q;
}

// Signed Modulo
int __modsi3(int n, int d) {
    int neg = 0;
    if (n < 0) { n = -n; neg = 1; }
    if (d < 0) { d = -d; }
    int r = __umodsi3(n, d);
    return neg ? -r : r;
}
