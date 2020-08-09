cls

pasmo -v --tapbas clock.asm clock.tap

bas2tap -a10 -sloader loader.bas loader.tap

copy /b loader.tap +  clock.tap output.tap

del clock.tap
del loader.tap
