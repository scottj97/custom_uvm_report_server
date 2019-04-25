# UVM_VERSION     = 1p1d
UVM_VERSION     = 1p2

ifeq ($(UVM_VERSION),1p2)
	UVM_HOME = ../../..
else
	UVM_HOME = ../../../../uvm-1.1d
endif

include Makefile.master.vcs
include Makefile.master.nc

UVM_VERBOSITY =	UVM_HIGH
EXTRA_COMP_ARGS =

all:	ncall
ncall:	nccomp ncrun
vcsall:	comp run

comp:
	$(VCS) +incdir+. \
                +define+UVM_NO_DEPRECATED \
                +define+UVM_$(UVM_VERSION) \
		$(EXTRA_COMP_ARGS) \
		hello_world.sv

run:
	$(SIMV)
	$(CHECK)

nccomp:
	$(NC2) -c \
	$(EXTRA_COMP_ARGS) \
	hello_world.sv

ncrun:
	$(NC2) \
	-R \
	-input ida_probe.tcl \
	$(EXTRA_RUN_ARGS)

# Run with lots of different cmdline options to test everything
regress: nccomp
	$(NC2) -R
	$(NC2) -R +UVM_REPORT_NOCOLOR
	$(NC2) -R                     +UVM_REPORT_NOMSGWRAP
	$(NC2) -R +UVM_REPORT_NOCOLOR +UVM_REPORT_NOMSGWRAP
	$(NC2) -R                                           +UVM_REPORT_TRACEBACK=NONE
	$(NC2) -R +UVM_REPORT_NOCOLOR                       +UVM_REPORT_TRACEBACK=NONE
	$(NC2) -R                     +UVM_REPORT_NOMSGWRAP +UVM_REPORT_TRACEBACK=NONE
	$(NC2) -R +UVM_REPORT_NOCOLOR +UVM_REPORT_NOMSGWRAP +UVM_REPORT_TRACEBACK=NONE
	$(NC2) -R                                           +UVM_REPORT_TRACEBACK=ALL
	$(NC2) -R +UVM_REPORT_NOCOLOR                       +UVM_REPORT_TRACEBACK=ALL
	$(NC2) -R                     +UVM_REPORT_NOMSGWRAP +UVM_REPORT_TRACEBACK=ALL
	$(NC2) -R +UVM_REPORT_NOCOLOR +UVM_REPORT_NOMSGWRAP +UVM_REPORT_TRACEBACK=ALL
	TERM_BG_LIGHT=1 $(NC2) -R
	time $(NC2) -R +longtest
