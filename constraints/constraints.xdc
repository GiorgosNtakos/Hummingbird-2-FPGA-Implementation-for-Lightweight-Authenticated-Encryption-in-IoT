# Define the primary clock with the desired period
create_clock -name clk_primary -period 2.2 [get_ports clk]

# Set maximum delay for specific paths (if needed)
#set_max_delay -from [get_ports text] -to [get_ports output] 400
