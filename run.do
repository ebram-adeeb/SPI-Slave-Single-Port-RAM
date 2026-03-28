quit -sim
vlib work
vlog +acc Design/counter.v Design/SPI_Slave.v Design/single_port_RAM.v Design/top_module.v Testbench/top_module_tb.sv
vsim -voptargs=+acc work.SPI_slave_RAM_tb

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider clk/rst
add wave -noupdate -radix binary /SPI_slave_RAM_tb/clk
add wave -noupdate -radix binary /SPI_slave_RAM_tb/rst
add wave -noupdate -divider {Slave Select}
add wave -noupdate -radix binary /SPI_slave_RAM_tb/SS_n
add wave -noupdate -divider Master-Out,Slave-In
add wave -noupdate -radix binary /SPI_slave_RAM_tb/MOSI
add wave -noupdate -divider Master-In,Slave-Out
add wave -noupdate -radix binary /SPI_slave_RAM_tb/MISO
add wave -noupdate -divider Capture&Compare
add wave -noupdate -radix binary /SPI_slave_RAM_tb/captured
add wave -noupdate -radix binary /SPI_slave_RAM_tb/expected
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 140
configure wave -valuecolwidth 70
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {128 ns}


run -all