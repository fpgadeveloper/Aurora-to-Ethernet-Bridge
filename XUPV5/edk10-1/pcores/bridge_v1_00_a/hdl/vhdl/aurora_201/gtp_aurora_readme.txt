                                       

                    Core Name: GTP Aurora
                    Version: 2.8 
                    Release Date: 10/10/2007


================================================================================

This document contains the following sections: 

1. Introduction
2. New Features
3. Resolved Issues
4. Known Issues 
5. Technical Support
6. Core Release History
 
================================================================================
 
1. INTRODUCTION

For the most recent updates to the IP installation instructions for this core,
please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm

 
For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm 



This file contains release notes for the Xilinx LogiCORE GTP Aurora v2.8 
solution. For the latest core updates, see the product page at:
 
  http://www.xilinx.com/aurora


2. NEW FEATURES  
 
   - ISE 9.2i software support
   - ChipScope Pro cores can be added to the GTP Aurora core from 
     Xilinx CORE Generator tool
   - GTP Aurora core has been enhanced to include Timer-based Simplex mode


3. RESOLVED ISSUES 
 
   - CR 441535: CORE generator aborts with an error due to nonexistence of 
                UCF file
   - CR 438148: UCF file is generated only for LX50T device
   - CR 435843: Removal of MTI_LIBS variable setting from Modelsim do file
   - CR 439460: Changing lane assignments between transceivers in a tile 
                has no effect on core implementation
   - CR 440385: CORE generaor issues error when 'No silicon version selected'
                option 
                                             
 
4. KNOWN ISSUES 
   
   - Remember to set pin constraints in the aurora_example.ucf file before using
     the aurora_example design

   For a list of all known issues with the Aurora core, please refer to Answer Record 25067:

   http://support.xilinx.com/xlnx/xil_ans_display.jsp?iLanguageID=1&iCountryID=1&getPagePath=25067


5. TECHNICAL SUPPORT 

   To obtain technical support, create a WebCase at www.xilinx.com/support.
   Questions are routed to a team with expertise using this product.  
     
   Xilinx provides technical support for use of this product when used
   according to the guidelines described in the core documentation, and
   cannot guarantee timing, functionality, or support of this product for
   designs that do not follow specified guidelines.


6. CORE RELEASE HISTORY 

Date        By            Version      Description
========================================================================================
10/10/2007  Xilinx, Inc.  2.8          Timer-based Simplex mode, ChipScope Pro cores and CR fixes 
05/17/2007  Xilinx, Inc.  2.7          Bug fixes 
03/01/2007  Xilinx, Inc.  2.6          Synplify support, Aurora for LXT and SXT Devices
11/30/2006  Xilinx, Inc.  2.5          First release, Aurora for LXT Devices
=========================================================================================

(c) 2006-2007 Xilinx, Inc. All Rights Reserved. 


XILINX, the Xilinx logo, and other designated brands included herein are
trademarks of Xilinx, Inc. All other trademarks are the property of their
respective owners.

Xilinx is disclosing this user guide, manual, release note, and/or
specification (the Documentation) to you solely for use in the development
of designs to operate with Xilinx hardware devices. You may not reproduce, 
distribute, republish, download, display, post, or transmit the Documentation
in any form or by any means including, but not limited to, electronic,
mechanical, photocopying, recording, or otherwise, without the prior written 
consent of Xilinx. Xilinx expressly disclaims any liability arising out of
your use of the Documentation.  Xilinx reserves the right, at its sole 
discretion, to change the Documentation without notice at any time. Xilinx
assumes no obligation to correct any errors contained in the Documentation, or
to advise you of any corrections or updates. Xilinx expressly disclaims any
liability in connection with technical support or assistance that may be
provided to you in connection with the information. THE DOCUMENTATION IS
DISCLOSED TO YOU AS-IS WITH NO WARRANTY OF ANY KIND. XILINX MAKES NO 
OTHER WARRANTIES, WHETHER EXPRESS, IMPLIED, OR STATUTORY, REGARDING THE
DOCUMENTATION, INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE, OR NONINFRINGEMENT OF THIRD-PARTY RIGHTS. IN NO EVENT 
WILL XILINX BE LIABLE FOR ANY CONSEQUENTIAL, INDIRECT, EXEMPLARY, SPECIAL, OR
INCIDENTAL DAMAGES, INCLUDING ANY LOSS OFDATA OR LOST PROFITS, ARISING FROM
YOUR USE OF THE DOCUMENTATION.

