ARCH := arm
obj-m := axi_mic.o
PWD := $(shell pwd)
export
default:
	$(MAKE) -C $(KERNEL) M=$(PWD) modules
clean:
	$(MAKE) -C $(KERNEL) M=$(PWD) clean
