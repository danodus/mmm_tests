YOSYS := yosys
ECPPACK := ecppack
NEXTPNR := nextpnr-ecp5
OPENFPGALOADER := openFPGALoader

DEVICE := um-85k
PACKAGE := CABGA381
SPEED := 7

PIN_DEF := ../mmm.lpf
SRC := display_demo_dvi.v \
	display_timings.v \
	hdmi_device.v \
	tmds_encoder.v \
	ecp5pll.v \
	test_card_simple.v

DEFINES :=

all: top.bin

clean:
	rm -f *.hex *.asc *.json *.bin *.log

top.json: $(SRC)
	$(YOSYS) -ql top.log -p 'verilog_defines $(DEFINES) ; read_verilog -sv $(SRC); synth_ecp5 -top display_demo_dvi -json top.json'

top.asc: top.json $(PIN_DEF)
	$(NEXTPNR) -l top_nextpnr.log --$(DEVICE) --package $(PACKAGE) --speed $(SPEED) --json top.json --lpf $(PIN_DEF) --textcfg top.asc --randomize-seed

top.bin: top.asc
	$(ECPPACK) --compress --input top.asc --bit top.bin

prog: top.bin
	$(OPENFPGALOADER) --cable ft4232 top.bin

.PHONY: all prog
