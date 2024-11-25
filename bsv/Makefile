help:
	@echo "Targets:"
	@echo "  sim:       Compiles all bsv files to Bluesim executables"
	@echo "  verilog:   Converts all bsv files to Verilog"
	@echo "  FILE.out:  Compiles a specific FILE for Bluesim executable "
	@echo "  FILE.v:    Convert a specific FILE to verilog "
	@echo "  clean      Delete intermediate files and dirs"

all :
.PHONY : all

SOURCES = $(wildcard *.bsv)

test:
	@echo "Hello $(basename $(SOURCES))"

.PHONY: verilog
verilog:  $(SOURCES:.bsv=.v)

.PHONY: sim
sim: $(SOURCES:.bsv=.out)

%.v: %.bsv
	@echo "Converting $(basename $<) to verilog"
	bsc -verilog -g mk$(basename $<) -u $<
	
%.out: %.bsv
	@echo "Converting $(basename $<) to simulation executable"
	bsc -sim -g mk$(basename $<) -u $<
	bsc -sim -e mk$(basename $<) -o $@ 

.PHONY: clean 
clean:
	rm -f *.ba *.bo *.out *.cxx *.h *.o *.so *.v