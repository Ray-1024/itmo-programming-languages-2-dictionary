ASM=nasm
ASM_FLAGS=-f elf64
LD=ld
ANNIHILATE=rm -rf

run: main
	./main
	$(ANNIHILATE) *.o main

main: main.o lib.o dict.o
	$(LD) -o $@ $^

dict.o: dict.asm lib.inc
	$(ASM) $(ASM_FLAGS) -o $@ $<

main.o: main.asm colon.inc words.inc lib.inc dict.inc
	$(ASM) $(ASM_FLAGS) -o $@ $<

%.o: %.asm
	$(ASM) $(ASM_FLAGS) -o $@ $<

clean:
	$(ANNIHILATE) *.o main