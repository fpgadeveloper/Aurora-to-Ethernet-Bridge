##############################################################################
## Filename:          C:\ML505\Tutorials\AEBridge/drivers/bridge_v1_00_a/data/bridge_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Wed Sep 23 10:41:32 2009 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "bridge" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
