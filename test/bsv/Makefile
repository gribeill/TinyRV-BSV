.SUFFIXES:

sim: build 

Makefile: ;

SOURCES = $(wildcard *.bsv)

%.out: %.bsv
	bsc -sim -g mkTbCPU -u -p ../../bsv:.:%/Libraries:$(HOME)/workspace/bsc-libs/BlueLib/src:$(HOME)/workspace/bsc-libs/BlueAXI/src $<
	bsc -sim -e mkTbCPU -p ../../bsv:.:%/Libraries:$(HOME)/workspace/bsc-libs/BlueLib/src:$(HOME)/workspace/bsc-libs/BlueAXI/src -o $@ 
# 	rm -f *.ba *.bo *.cxx *.h 

.PHONY: build 
build: $(SOURCES:.bsv=.out)

.PHONY: clean 
clean:
	rm -f *.ba *.bo *.out *.cxx *.h