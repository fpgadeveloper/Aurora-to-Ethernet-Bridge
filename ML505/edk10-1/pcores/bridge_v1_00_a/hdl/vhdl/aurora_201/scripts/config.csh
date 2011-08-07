#!/bin/csh -f

##=============================================================================
##
##    File Name:  config.csh         
##      Version:  1.0
##         Date:  05/13/2003
##      Company:  Xilinx, Inc.
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
##=============================================================================

#################################################################################
## This is a shell script to setup environment on Linux for the Aurora core
##
## Following these steps to setup the environment:
## (1) Install software tools (Xilinx ISE, EDK, ModelSim, SmartModel, etc.)
## (2) Modify all the lines containing "<...>" in this script
## (3) Run this script.
##
## A summary of environment variables follows.
## 
## Variable that need to be modified by user:
## setenv XILINX           <Path_to_Xilinx_ISE_software>
## setenv LMC_HOME         <Path_to_SmartModels_installation>
## setenv MODEL_TECH       <Path_to_ModelSim_installation>
## setenv MTI_LIBS         <Path_to_ModelSim_Sim_Library>
##
## Variables derived from above items:
## setenv LMC_FOUNDRY_HOME $LMC_HOME
## setenv LMC_PATH         $LMC_HOME/foundry
## setenv LMC_CONFIG       $LMC_HOME/data/x86_linux.lmc 
## setenv MODEL_TECH_LIBSM $MODEL_TECH/linux/libsm.sl
## setenv MODELSIM         ${MTI_LIBS}/modelsim.ini 
## setenv LD_LIBRARY_PATH  $XILINX/bin/lin:$XILINX_EDK/bin/lin:$LMC_HOME/lib/sun4Solaris.lib:${LD_LIBRARY_PATH}
## setenv PATH             $XILINX/bin/lin:$MODEL_TECH/sunos5:$LMC_HOME/bin:$XILINX_EDK/bin/lin:$XILINX_EDK/gnu/microblaze/lin/bin:$XILINX_EDK/gnu/powerpc-eabi/lin/bin:${PATH}
##
## Optional variables:
## setenv LM_LICENSE_FILE  ${LM_LICENSE_FILE}:<Port@LicenseServer>
#################################################################################

set xilinx_ver =   < "J.32">
set mti_ver =       <"6.2e"> # Change it to your local installation version
set userid = `whoami`

#################################################################################
## Step 1: Setup Xilinx ISE Tool Environment
#################################################################################

if $?XILINX then
echo  "Xilinx ISE software environment ready."
else
echo  "Setup Xilinx ISE software environment ..."
    
    setenv XILINX    /proj/xbuilds/${xilinx_ver}/rtf 
    setenv XILENV    /proj/xbuilds/${xilinx_ver}/env
    setenv MYXILINX  /home/${userid}/IPHsandbox/rtf  
endif

    setenv PATH $XILINX/bin/lin:${PATH}

    if ($?LD_LIBRARY_PATH) then
        setenv LD_LIBRARY_PATH $XILINX/bin/lin:${LD_LIBRARY_PATH}
    else
        setenv LD_LIBRARY_PATH $XILINX/bin/lin
    endif

#################################################################################
## Step 2: Synthesis Tool Environment Setup
#################################################################################
if $?SYNPLIFY_PRO then
echo  "Synthesis tool environment ready."
else
echo  "Setup Synthesis tool environment ..."
	
	setenv SYNPLIFY_PRO </tools/gensys/synplicity/8.8.0/linux/fpga_88>
	setenv PATH < $SYNPLIFY_PRO/bin:${PATH} >

endif

#################################################################################
## Step 3: Setup SmartModels Environment 
#################################################################################
## Note: SmartModels are included in the Xilinx ISE software under
## $XILINX/smartmodel.

if $?LMC_HOME then
    echo  "SmartModels environment ready."
else
    echo  "SmartModels environment is set up"
    setenv LMC_HOME <$MTI_LIBS >
    setenv LMC_FOUNDRY_HOME <$LMC_HOME>
    setenv LMC_PATH <$LMC_HOME/foundry>
    setenv LMC_CONFIG <$LMC_HOME/data/x86_linux.lmc>
endif

#################################################################################
## Step 4: Setup ModelSim Environment
#################################################################################
## Note:       Environment variable MODELSIM points to the ModelSim
##             initialization file provided in the BERT Reference Design at 
##             modelsim_solaris.ini
##             This file contains proper setup for SmartModels simulation
##             Refer to Xilinx Answer Record #15501 and #14019 for further
##             information regarding SmartModel/Swift Interface and
##             installation of SmartModels. 
if $?MODEL_TECH then
    echo  "ModelSim environment ready."
else
    echo  "ModelSim environment is set up"
    setenv MODEL_TECH </tools/gensys/modelsim/${mti_ver}>
    setenv MODEL_TECH_LIBSM <$MODEL_TECH/linux/libsm.sl  >
    setenv PATH $MODEL_TECH/linux:${PATH}  
endif
setenv MODELSIM  <${MTI_LIBS}/modelsim.ini >

#################################################################################
## Step 5: Setup User's Local Simulation Library Environment 
##
## MTI_LIBS    points to the directory that is used to store
##             Verilog/VHDL based ModelSim libraries for 
##             Virtex-5 family, including unisim,
##             simprim and SmartModel libraries.
#################################################################################
echo  "Setup local simulation library environment..."
#Path to ModelSim Library
setenv MTI_LIBS </home/${userid}/Xilinx_Libs/${xilinx_ver}/mti_se_${mti_ver} >


#################################################################################
## Step 6: LocalLink BFM Environment Setup
##
#################################################################################
if $?LL_BFM then
    echo  "LocalLink BFM environment ready."
else
   echo  "Setup LocalLink BFM environment..."
   setenv LL_BFM  /home/nigelg/BFM/LL_BFM
   setenv PATH  ${PATH}:${LL_BFM}/src
endif

#################################################################################
## Step 7: If necessary, setup licenses for EDA tools. 
##
## For example:
##
## if $?LM_LICENSE_FILE then
##    setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:<Port@LicenseServer>
## else
##    setenv LM_LICENSE_FILE <Port@LicenseServer>
## endif
##
#################################################################################
echo  "Setup EDA tools licenses ..."

#synplify
setenv LM_LICENSE_FILE 1709@xmask

#modelsim
setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:1717@xmask

#foundation
setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:/devl/flex/license.dat

#xhdl
setenv LM_LICENSE_FILE ${LM_LICENSE_FILE}:7300@xmask

echo  "DONE."
echo  ""

