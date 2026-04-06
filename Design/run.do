vlib work
vlog single_port_RAM.v counter.v SPI_Slave.v top_module.v SPI_tb.v
vsim -voptargs=+acc work.SPI_tb
add wave *
run -all