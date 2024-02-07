set_property PACKAGE_PIN L19 [get_ports {AUDIO_CLK}];  # "FMC-CLK0_N"
set_property PACKAGE_PIN L18 [get_ports {AUDIO_DO}];  # "FMC-CLK0_P"

set_property IOSTANDARD LVCMOS33 [get_ports {AUDIO_CLK}];  # "FMC-CLK0_N"
set_property IOSTANDARD LVCMOS33 [get_ports {AUDIO_DO}];  # "FMC-CLK0_P"

create_clock -period 40.000 -name pclk -waveform {0.000 20.000} [get_ports PCLK]
set_input_delay -clock [get_clocks pclk] 20 [get_ports DATA]
set_input_delay -clock [get_clocks pclk] 20 [get_ports VSYNC]
set_input_delay -clock [get_clocks pclk] 20 [get_ports HREF]

create_clock -period 400.000 -name audio_clk -waveform {0.000 200.000} [get_ports AUDIO_CLK]
set_input_delay -clock [get_clocks audio_clk] 200 [get_ports AUDIO_DO]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets AUDIO_CLK_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets design_1_i/processing_system7_0/inst/FCLK_CLK1]
set_clock_groups -group [get_clocks {pclk}] -group [get_clocks clk_fpga_1] -logically_exclusive
set_clock_groups -group [get_clocks {audio_clk}] -group [get_clocks clk_fpga_2] -logically_exclusive
set_clock_groups -group [get_clocks {pclk}] -group [get_clocks clk_fpga_0] -asynchronous
set_clock_groups -group [get_clocks {audio_clk}] -group [get_clocks clk_fpga_0] -asynchronous
set_clock_groups -group [get_clocks {clk_fpga_1}] -group [get_clocks clk_fpga_0] -asynchronous
set_clock_groups -group [get_clocks {clk_fpga_2}] -group [get_clocks clk_fpga_0] -asynchronous
