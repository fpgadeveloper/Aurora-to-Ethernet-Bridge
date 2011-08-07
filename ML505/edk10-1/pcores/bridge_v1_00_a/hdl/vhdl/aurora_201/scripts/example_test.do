##############################################################################
##
##         Project:  Aurora Module Generator version 2.8
##
##         Date:  $Date: 2007/08/08 11:13:33 $
##          Tag:  $Name: i+IP+144838 $
##         File:  $RCSfile: example_test_do.ejava,v $
##          Rev:  $Revision: 1.1.2.1 $
##
##      Company:  Xilinx
##
##   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
##                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
##                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
##                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
##                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
##                APPLICATION OR STANDARD, XILINX IS MAKING NO
##                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
##                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
##                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
##                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
##                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
##                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
##                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
##                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
##                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
##                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
##                PURPOSE.
##
##                (c) Copyright 2004 Xilinx, Inc.
##                All rights reserved.
##
##############################################################################
##
## SAMPLE_TEST.DO
##
##
## Description: A .do file to run a simulation using the aurora_201_aurora_example module, 
##              an example design which instantiates aurora_201.
##
##              Environment variable MTI_LIBS must be set to the directory containing 
##              your precompiled unisims libraries (ie the path to the directory containing
##              the unisims or unisims_ver directory)
##
##

        

# Get environment variables needed for finding precompiled libraries and ISE source code
set MTI_LIBS $env(MTI_LIBS)
set XILINX   $env(XILINX)


# Create and map a work directory 
vlib work
vmap work work


# Compile the Aurora package in the work directory
vcom -93 -work work ../src/aurora_201_aurora_pkg.vhd;




# Compile the HDL for the Device Under Test
    # Aurora Lane Modules  
    vcom -93 -work work ../src/aurora_201_chbond_count_dec.vhd;
    vcom -93 -work work ../src/aurora_201_error_detect.vhd;
    vcom -93 -work work ../src/aurora_201_lane_init_sm.vhd;
    vcom -93 -work work ../src/aurora_201_sym_dec.vhd;
    vcom -93 -work work ../src/aurora_201_sym_gen.vhd;
    vcom -93 -work work ../src/aurora_201_aurora_lane.vhd;


    # Global Logic Modules
    vcom -93 -work work ../src/aurora_201_channel_error_detect.vhd;
    vcom -93 -work work ../src/aurora_201_channel_init_sm.vhd;
    vcom -93 -work work ../src/aurora_201_idle_and_ver_gen.vhd;
    vcom -93 -work work ../src/aurora_201_global_logic.vhd; 


    # TX LocalLink User Interface modules
    vcom -93 -work work ../src/aurora_201_tx_ll_control.vhd;
    vcom -93 -work work ../src/aurora_201_tx_ll_datapath.vhd;
    vcom -93 -work work ../src/aurora_201_tx_ll.vhd;




    #RX_LL Pdu Modules
    vcom -93 -work work ../src/aurora_201_rx_ll_pdu_datapath.vhd;



    #RX_LL top level
    vcom -93 -work work ../src/aurora_201_rx_ll.vhd;






    #Top Level Modules and wrappers
    vcom -93 -work work ../clock_module/aurora_201_clock_module.vhd;

    vcom -93 -work work ../cc_manager/aurora_201_standard_cc_module.vhd;


    vcom -93 -work work ../src/aurora_201_gtp_wrapper.vhd;
    vcom -93 -work work ../src/aurora_201.vhd;
    vcom -93 -work work ../examples/aurora_201_frame_check.vhd;
    vcom -93 -work work ../examples/aurora_201_frame_gen.vhd;    
    vcom -93 -work work ../examples/aurora_201_aurora_example.vhd;


    # Testbench
    vcom -93 -work work ../testbench/example_tb.vhd;
    
    
# Begin the test

vsim -L unisim work.SAMPLE_TB
view wave
do example_wave.do
run -all
