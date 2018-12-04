# Helper makefile to build etherscope, make the image and flash it.

GPRBUILD=gprbuild --target=arm-eabi

all:  hestia gallery

ada-enet/anet_stm32fxxx.gpr:
	cd ada-enet && ./configure --with-board=stm32f746 --with-ada-drivers=../Ada_Drivers_Library

stm32-ui/ui_stm32fxxx.gpr:
	cd stm32-ui && ./configure --with-board=stm32f746 --with-ada-drivers=../Ada_Drivers_Library

stm32-ui/stamp-gui: stm32-ui/ui_stm32fxxx.gpr
	cd stm32-ui && make stamp-gui

hestia: ada-enet/anet_stm32fxxx.gpr stm32-ui/ui_stm32fxxx.gpr stm32-ui/stamp-gui
	$(GPRBUILD) -Phestia -p -cargs -mno-unaligned-access
	arm-eabi-objcopy -O binary obj/stm32f746disco/hestia hestia.bin

flash:		all
	st-flash write hestia.bin 0x8000000

clean:
	rm -rf obj

checkout:
	git submodule init
	git submodule update
	cd ada-enet/Ada_Drivers_Library && git submodule init && git submodule update
