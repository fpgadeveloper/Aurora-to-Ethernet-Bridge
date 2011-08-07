####################################################################################
##
##         Project:  Aurora Module Generator version 2.8
##
##         Date:  $Date: 2007/08/08 11:13:34 $
##          Tag:  $Name: i+IP+144838 $
##         File:  $RCSfile: wave_do_v5.ejava,v $
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
####################################################################################
##
## SAMPLE_WAVE.DO
##
##
## Description: This file is a wave file used for simulations with SAMPLE_TB and 
##              the frame generator and checker.
##


onerror {resume}
quietly WaveActivateNextPane {} 0
    


add wave -noupdate -divider {aurora_201 Core 1}
add wave -noupdate -divider {Core 1 LocalLink TX Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_D
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_REM
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_SRC_RDY_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_SOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_EOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_DST_RDY_N
add wave -noupdate -divider {Core 1 LocalLink RX Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RX_D
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RX_REM
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RX_SRC_RDY_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RX_SOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RX_EOF_N
add wave -noupdate -divider {Core 1 Error Detection Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/HARD_ERROR
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/SOFT_ERROR
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/FRAME_ERROR
add wave -noupdate -divider {Core 1 Status Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/CHANNEL_UP
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/LANE_UP
add wave -noupdate -divider {Core 1 Clock Compensation Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/WARN_CC
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/DO_CC
add wave -noupdate -divider {Core 1 System Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/DCM_NOT_LOCKED
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/RESET
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_1_i/aurora_module_i/POWER_DOWN
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_1_i/aurora_module_i/TX_OUT_CLK
add wave -noupdate -divider {Frame Checker Error Count for Core 1 }
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_1_i/ERROR_COUNT



add wave -noupdate -divider {aurora_201 Core 2}
add wave -noupdate -divider {Core 2 LocalLink TX Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_D
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_REM
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_SRC_RDY_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_SOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_EOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_DST_RDY_N
add wave -noupdate -divider {Core 2 LocalLink RX Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RX_D
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RX_REM
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RX_SRC_RDY_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RX_SOF_N
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RX_EOF_N
add wave -noupdate -divider {Core 2 Error Detection Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/HARD_ERROR
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/SOFT_ERROR
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/FRAME_ERROR
add wave -noupdate -divider {Core 2 Status Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/CHANNEL_UP
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/LANE_UP
add wave -noupdate -divider {Core 2 Clock Compensation Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/WARN_CC
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/DO_CC
add wave -noupdate -divider {Core 2 System Interface}
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/USER_CLK
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/DCM_NOT_LOCKED
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/RESET
add wave -noupdate -format Logic /SAMPLE_TB/aurora_example_2_i/aurora_module_i/POWER_DOWN
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_2_i/aurora_module_i/TX_OUT_CLK
add wave -noupdate -divider {Frame Checker Error Count for Core 2 }
add wave -noupdate -format Literal /SAMPLE_TB/aurora_example_2_i/ERROR_COUNT




TreeUpdate [SetDefaultTree]
WaveRestoreCursors {11841771 ps}
WaveRestoreZoom {0 ps} {26705705 ps}
configure wave -namecolwidth 273
configure wave -valuecolwidth 37
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
