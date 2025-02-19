include config.mk

PFM := /opt/xilinx/platforms/xilinx_u250_gen3x16_xdma_4_1_202210_1/xilinx_u250_gen3x16_xdma_4_1_202210_1.xpfm

NCPUS := $(shell grep -c ^processor /proc/cpuinfo)
JOBS := $(shell expr $(NCPUS) - 1)

VISION_LIB_FLAGS := -I. -I/mnt/scratch/rhyhuo/Vitis_Libraries/vision/L1/include --config vision_config.ini

VPPFLAGS := --platform $(PFM) -t $(TARGET) -s -g
VPPLFLAGS := --jobs $(JOBS) --config profile.ini

BOARD_CONFIG := connectivity_u250.ini
ifeq (u250, $(findstring u250, $(PLATFORM)))
	BOARD_CONFIG := connectivity_u250.ini
endif
ifeq (u50, $(findstring u50, $(PLATFORM)))
	BOARD_CONFIG := connectivity_u50.ini
endif
VPPLFLAGS += --config $(BOARD_CONFIG)

XOS = vadd.xo wide_vadd.xo resize_rgb.xo resize_blur.xo

IP_CACHE_DIR ?= ./ip_cache

.phony: clean traces help

all: alveo_examples.xclbin

alveo_examples.xclbin: $(XOS) $(BOARD_CONFIG)
	v++ -l $(VPPFLAGS) $(VPPLFLAGS) -o $@ $(XOS) --remote_ip_cache ${IP_CACHE_DIR}

vadd.xo: vadd.cpp
	v++ --kernel vadd $(VPPFLAGS) -c -o $@ $<

wide_vadd.xo: wide_vadd.cpp
	v++ --kernel wide_vadd $(VPPFLAGS) -c -o $@ $<

resize_rgb.xo: resize_rgb.cpp vision_config.ini
	v++ --kernel resize_accel_rgb $(VPPFLAGS) $(VISION_LIB_FLAGS) -c -o $@ $<

resize_blur.xo: resize_blur.cpp vision_config.ini
	v++ --kernel resize_blur_rgb $(VPPFLAGS) $(VISION_LIB_FLAGS) -c -o $@ $<

clean:
	$(RM) -r *.xo _x .Xil sd_card *.xclbin *.ltx *.log *.info *compile_summary* vitis_analyzer* *link_summary*
