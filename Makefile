CC = avr-gcc
CFLAGS = -Wall -Os -mmcu=atmega328p
OBJCOPY = avr-objcopy

OBJ = main.o os.o os_asm.o


all: image.hex image.bin

%.o: %.c
	$(CC) $(CFLAGS) -c $<

os_asm.o: os_asm.S
	$(CC) $(CFLAGS) -c $<

image.elf: $(OBJ)
	$(CC) $(CFLAGS) -o image.elf $(OBJ)

image.hex: image.elf
	$(OBJCOPY) image.elf -O ihex image.hex

image.bin: image.elf
	$(OBJCOPY) image.elf -O binary image.bin

clean:
	rm -f *.o *.elf *.hex *.bin
