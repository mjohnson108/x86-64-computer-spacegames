# x86-64-computer-spacegames

In the Eighties, Usborne published some books aimed at young aspiring programmers. Once of these books was "Computer Spacegames" and it contained program listings in BASIC for the Spectrum, BBC micro, ZX81 etc. In this repo are my x86-64 assembly language conversions of some of these program listings. These were written under Linux kernel 5.15.0-130-generic and are unlikely to be very portable! PDFs of the original Usborne books can be found at https://usborne.com/gb/books/computer-and-coding-books

## Starship Takeoff

This is a straightforward variant of the number guessing game. To create a routine that generates small random numbers within a range, a byte from /dev/urandom is used a scaling value in the unit interval with some fixed-point mathematics.

## Intergalactic Games

In this game there are two numbers to guess. Some mathematics are required which makes this a more difficult implementation, an arctangent and a square root. It seems possible to do both of these with the old maths coprocessor instructions, but to be a little more modern the SSE2 instructions were used. That took care of the square root, but faced with having to approximate the arctangent with a series, the easier route seemed the best and a lookup table was generated. Unfortunately for the game, the way the mathematics works out, the angle is almost always in the mid eighties and the speed is almost always close to 3000. Because of the SIMD (SSE2) instructions, data alignment becomes critically important.

## Evil Alien

Another number guessing game, this time there are three numbers to guess.

## Moonlander

This game uses a simple physics simulation. The only implementation consideration was that the velocity can quickly go negative, requiring the display function to be able to handle negative numbers. This was straightforwardly achieved by checking if the number is below zero to determine whether to write a minus sign and then displaying the absolute value of the number as usual.

## Trip into the Future

The basis of this game is an adaptation of the time dilation equation, the prediction of Relativity that time would pass slower for a space traveller making a round trip from Earth and back at a high percentage of light speed. The player gets only one chance to input the correct speed and distance parameters to achieve a certain amount of time passing on Earth.

The new challenge here in terms of implementation was that the program has to be able to handle numbers containing a fractional part, both for input and display. It's no longer possible to work just with integers. This was done using a fixed point representation. On the input side, a number with integer and fractional parts can be represented as two integers, e.g. 12.34 can be represented by 1234 and 100 as the multiplier after detecting the location of the decimal point. For output, the same number can be represented as 12 for the integer part and 34 for the fractional part, separated by a decimal point when displayed.

## Asteroid Belt

The main challenge presented by this game was replicating the INKEY$ command. Previous games allowed the player whatever time they wanted to enter numbers, which was easily achieved with the read syscall, but this game requires the player to enter input within a time window. After some experimentation, this was achieved using the poll syscall on STDIN with a timeout, followed by a read if any input was detected. There was a further issue, which is that terminals seem to buffer input until the return key is pressed. To overcome this, the ioctl syscall was used to switch off canonical mode in the terminal, which makes it send input as soon as it appears, rather than buffering it. While in there, input echo is switched off also. To complete the effect, ANSI codes are used to switch off the cursor in the terminal.

In this game FOR loops are used to create a delay. Since looping to fifty (as in lines 290 and 300) would execute in nanoseconds in assembly on modern CPUs, the nanosleep syscall is used to create a reasonable delay.

## Alien Snipers

With the INKEY$ function figured out, the Alien Snipers game is straightforward.



