YOSYS := yosys
ECPPACK := ecppack
NEXTPNR := nextpnr-ecp5
OPENFPGALOADER := openFPGALoader

DEVICE := um-85k
PACKAGE := CABGA381
SPEED := 7

PIN_DEF := ../mmm.lpf
SRC := top.sv

DEFINES :=

all: top.bin

clean:
	rm -f *.hex *.asc *.json *.bin *.log

top.json: $(SRC)
	$(YOSYS) -ql top.log -p 'verilog_defines $(DEFINES) ; read_verilog -sv $(SRC); synth_ecp5 -top top -json top.json'

top.asc: top.json $(PIN_DEF)
	$(NEXTPNR) -l top_nextpnr.log --$(DEVICE) --package $(PACKAGE) --speed $(SPEED) --json top.json --lpf $(PIN_DEF) --textcfg top.asc --randomize-seed

top.bin: top.asc
	$(ECPPACK) --compress --input top.asc --bit top.bin

prog: top.bin
	$(OPENFPGALOADER) --verbose --cable ft4232 top.bin

.PHONY: all prog
