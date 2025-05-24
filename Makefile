V_SRCS := hdl/top.v hdl/sim_top.v hdl/spi.sv hdl/timer.sv hdl/presc.sv hdl/headers/seven_segment_defines.vh hdl/bcd_register.sv hdl/ss_display.sv hdl/counter.sv hdl/eink_data.sv
SIM_TOP := sim_top
SIM_SNAPSHOT := sim_snapshot

.xvlog: $(V_SRCS)
	xvlog -sv $(V_SRCS) hdl/test_benches/*

.xelab: .xvlog
	xelab -debug typical -top $(SIM_TOP) -snapshot $(SIM_SNAPSHOT)

.xsim: .xelab
	xsim $(SIM_SNAPSHOT) --tclbatch tcl/sim.tcl

all: .xsim

clean:
	rm -Rf xsim.dir > /dev/null
	rm -Rf *.log > /dev/null
	rm -Rf *.jou > /dev/null
	rm -Rf *.pb  > /dev/null
	rm -Rf *.str > /dev/null
	rm -Rf *.wdb > /dev/null
	rm -Rf .Xil  > /dev/null
	rm -Rf *.dcp  > /dev/null
	rm -Rf reports/* > /dev/null
	rm -Rf *.txt > /dev/null
	rm -Rf *.bit > /dev/null
	rm -Rf reports/*

synth:
	vivado -mode batch -script tcl/synth.tcl

impl:
	rm -rf spi_temp_sens.bit
	vivado -mode batch -script tcl/impl.tcl

flash:
	vivado -mode batch -script tcl/flash.tcl
