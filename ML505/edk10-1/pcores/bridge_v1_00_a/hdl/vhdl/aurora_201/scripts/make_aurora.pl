#!xilperl
##############################################################################
##
##         Project:  Aurora Module Generator version 2.8
##
##         Date:  $Date: 2007/08/08 11:13:33 $
##          Tag:  $Name: i+IP+144838 $
##         File:  $RCSfile: make_aurora_gtp_pl.ejava,v $
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
## MAKE_AURORA
##
##
## Description: A Perl script to synthesize and build the aurora reference design
##
##              * Supports designs with 1 2-byte lanes
## Notes:
##      (1) Uses xilperl, a version of the PERL interpreter that ships with Xilinx tools
##      (2) Before running this program, set your simulation environment using config.csh (UNIX) or
##             config.bash (PC with Xilinx Bash shell)
##
##  Check for required environment variables
    unless($xilinx_path = $ENV{XILINX})
    {
            print" XILINX environment variable has not been set.  This variable\n";
            print" points to your Xilinx ISE tools, and is required to run Aurora\n";
            print" scripts.  Consult the user guide to find out how to edit and run\n";
            print" the appropriate Aurora config script for your system.\n";
            exit;
    }
    ##_____________________Set default values__________________________
    my $use_xst = 1;
    my $use_synplify = 0;
    my $files_only = 0;
    my $npl_only = 0;
    my $black_box = 0;
    my $include_cc = 0;
    my $run_map = 0;
    my $run_par = 0;
    my $run_bit = 0;
    my $use_ngc = 0;
    my $use_edf = 0;
    my $use_example = 0;
    my $run_trace = 0;
    my $use_win = 0;
    ##_____________________Read command line arguments_________________
    while( $option = shift @ARGV )
    {
        # -synplify                 : Use synplify instead of XST. XST is used by default
        if($option =~ /^-synplify/)
        {
            $use_xst = 0;
            $use_synplify = 1;
        }

        # -blackbox                :   Create black box instantiation file
        if($option =~ /^-blackbox/)
        {
            $black_box = 1;
        }

        # -cc                      :   Include clock compensation in black box
        if($option =~ /^-cc/)
        {
            $include_cc = 1;
        }

        # -files                   :   Generate project file only
        if($option =~ /^-files/)
        {
            $files_only = 1;
        }

        # -m                       :   Run map to get a resource cost measurement for the module
        #
        if($option =~ /^-m/)
        {
            $run_map  =   1;
        }

        # -npl                     :   Generate iSE npl project file only
        #
        if($option =~ /^-npl/)
        {
            $npl_only =   1;
        }

        # -p                       :   Run par to get a minimum clock period estimate for the module
        #                              using the constraints defined in the current ucf file.
        if($option =~ /^-p/)
        {
            $run_par  =   1;
        }

        # -h                        : this option produces a brief help message
        if($option =~ /^-h/)
        {
            show_help();
            exit;
        }

        # -b                        : Create a bitstream for the design
        if($option =~ /^-b/)
        {
            $run_bit = 1;
        }

        # -example                   : use the example design instead of the raw aurora design. The raw design shouldn't
        #                             be instantiated directly on a device - it's user I/O is set up for internal
        #                             connections rather than external connections
        if($option =~ /^-example/)
        {
            $use_example = 1;
        }

        # -t                       : Create trace report for the design
        if($option =~ /^-t/)
        {
            $run_trace = 1;
        }
        
        # -win                      : switch for OS
        if($option =~ /^-win/)
        {
            $use_win = 1;
        }
    }#next command line argument
    ##_____________________Read environment variables for synplify if neccessary__________
        unless($synplicity_path = $ENV{SYNPLICITY})
        {
            if($use_synplify == 1)
            {
                print" SYNPLICITY environment variable has not been set.  This variable\n";
                print" points to your copy of Synplify, and is required if you wish to\n";
                print" use Synplify as your synthesis tool.\n";
                exit;
            }
        }
    ##__________________________Check for Synplicity and XST_____________________________
        if($use_synplify == 1 && $npl_only == 1)
        {
            print" Cannot specify -synplify and -npl together.  -npl may, optionally, be\n";
            print" used with -example.\n\n";
            exit;
        }
    ##__________________________________Run Synthesis____________________________________
        #Generate synthesis project file
        if ($npl_only == 1)
        {
            print "### Generating iSE npl project file ...\n\n";
        } else {
            print "### Generating synthesis project file ...\n\n";
        }
        #Make a list of files that must be synthesized to create a working module
        my @AURORA_MODULES = (
        #Aurora Package
        "../src/aurora_201_aurora_pkg",
        #Aurora Lane Modules
        "../src/aurora_201_error_detect",
        "../src/aurora_201_lane_init_sm",
        "../src/aurora_201_sym_dec",
        "../src/aurora_201_sym_gen",
        "../src/aurora_201_aurora_lane",
        "../src/aurora_201_chbond_count_dec",
        #Global Logic Modules
        "../src/aurora_201_channel_error_detect",
        "../src/aurora_201_channel_init_sm",
        "../src/aurora_201_idle_and_ver_gen",
        "../src/aurora_201_global_logic",
        #TX_LL Logic Modules
        "../src/aurora_201_tx_ll_control",
        "../src/aurora_201_tx_ll_datapath",
        "../src/aurora_201_tx_ll",
        #RX_LL Pdu Modules
        "../src/aurora_201_rx_ll_pdu_datapath",
        #RX_LL top level
        "../src/aurora_201_rx_ll",
        #Clock Module
        "../clock_module/aurora_201_clock_module",
        #GTP Wrapper
        "../src/aurora_201_gtp_wrapper",
        #Top Level Files
        "../src/aurora_201"
 ); #end AURORA_MODULE list
    if($use_example)
    {
        @AURORA_MODULES = (@AURORA_MODULES,
        "../examples/aurora_201_frame_gen",
        "../examples/aurora_201_frame_check",
        "../cc_manager/aurora_201_standard_cc_module",
        "../examples/aurora_201_aurora_example");
    }
   ##______________ Generate Project file for Xilinx Project Navigator_______________
    if($npl_only == 1)
    {
        #Create an iSE npl project file
        open NPL_FILE, ">make_aurora.npl";
        print NPL_FILE "JDF G\n";
        print NPL_FILE "// Created by Make_Aurora ver 2.2\n";
        print NPL_FILE "PROJECT work\n";
        print NPL_FILE "DESIGN work\n";
        print NPL_FILE "DEVFAM virtex5\n";
        print NPL_FILE "DEVFAMTIME 0\n";
        print NPL_FILE "DEVICE xc5vlx50t\n";
        print NPL_FILE "DEVICETIME 0\n";
        print NPL_FILE "DEVPKG ff1136\n";
        print NPL_FILE "DEVPKGTIME 0\n";
        print NPL_FILE "DEVSPEED -1\n";
        print NPL_FILE "DEVSPEEDTIME 0\n";
        print NPL_FILE "DEVTOPLEVELMODULETYPE HDL\n";
        print NPL_FILE "TOPLEVELMODULETYPETIME 0\n";
        print NPL_FILE "DEVSYNTHESISTOOL XST (VHDL/Verilog)\n";
        print NPL_FILE "SYNTHESISTOOLTIME 0\n";
        print NPL_FILE "DEVSIMULATOR Other\n";
        print NPL_FILE "SIMULATORTIME 0\n";
        print NPL_FILE "DEVGENERATEDSIMULATIONMODEL VHDL\n";
        print NPL_FILE "GENERATEDSIMULATIONMODELTIME 0\n";
        foreach $module (@AURORA_MODULES)
        {
            print NPL_FILE "SOURCE " . $module . ".vhd\n";
        }
        if($use_example == 1)
        {
            print NPL_FILE "DEPASSOC aurora_201_aurora_example ../ucf/aurora_201_aurora_example.ucf\n";
        } else {
            print NPL_FILE "DEPASSOC aurora_201 ../ucf/aurora_201.ucf\n";
        }
        print NPL_FILE "[Normal]\n";
        print NPL_FILE "p_xstBusDelimiter=xstvhd, virtex5, VHDL.t_synthesize, 0, ()\n";
        print NPL_FILE "p_xstHierarchySeparator=xstvhd, virtex5, VHDL.t_synthesize, 0, /\n";
        if($use_example == 1)
        {
            print NPL_FILE "p_xstPackIORegister=xstvhd, virtex5, VHDL.t_synthesize, 0, Yes\n";
        }
        print NPL_FILE "p_xstVerilog2001=xstvhd, virtex5, VHDL.t_synthesize, 0, False\n";
        print NPL_FILE "_SynthExtractRAM=xstvhd, virtex5, VHDL.t_synthesize, 0, False\n";
        print NPL_FILE "_SynthExtractROM=xstvhd, virtex5, VHDL.t_synthesize, 0, False\n";
        print NPL_FILE "[STRATEGY-LIST]\n";
        print NPL_FILE "Normal=True\n";
        close NPL_FILE;
        exit;
    }
    ##__________________________________ Create XST Project File _________________________________
    if($use_xst == 1)
    {
        #Create an XST project file
        open PRJ_FILE, ">make_aurora.prj";
        foreach $module (@AURORA_MODULES)
        {
            print PRJ_FILE $module . ".vhd\n";
        }
        close PRJ_FILE;
    ##__________________________________ Create XST Script File __________________________________
        #Create an XST script file
        open SCR_FILE, ">make_aurora.scr";
        print SCR_FILE "\n";
        print SCR_FILE "run\n";
        print SCR_FILE "-ifn make_aurora.prj\n";
        print SCR_FILE "-ifmt VHDL\n";
        if($use_example){print SCR_FILE "-ofn aurora_201_aurora_example.ngc\n";}
        else{print SCR_FILE "-ofn aurora_201.ngc\n";}
        print SCR_FILE "-ofmt NGC\n";

        print SCR_FILE "-p xc5vlx50t-1ff1136\n";
    if($use_example){
        print SCR_FILE "-top aurora_201_aurora_example\n";
        }else{
            print SCR_FILE "-top aurora_201\n";
        }
        print SCR_FILE "-opt_mode Speed\n";
        print SCR_FILE "-opt_level 1\n";
        print SCR_FILE "-iuc NO\n";
        print SCR_FILE "-keep_hierarchy NO\n";
        print SCR_FILE "-glob_opt AllClockNets\n";
        print SCR_FILE "-rtlview Yes\n";
        print SCR_FILE "-read_cores YES\n";
        print SCR_FILE "-write_timing_constraints NO\n";
        print SCR_FILE "-cross_clock_analysis NO\n";
        print SCR_FILE "-hierarchy_separator /\n";
        print SCR_FILE "-bus_delimiter ()\n";
        print SCR_FILE "-case maintain\n";
        print SCR_FILE "-slice_utilization_ratio 100\n";
        print SCR_FILE "-fsm_extract YES\n";
        print SCR_FILE "-fsm_encoding Auto\n";
        print SCR_FILE "-ram_extract No\n";
        print SCR_FILE "-ram_style Auto\n";
        print SCR_FILE "-rom_extract No\n";
        print SCR_FILE "-rom_style Auto\n";
        print SCR_FILE "-mux_extract YES\n";
        print SCR_FILE "-mux_style Auto\n";
        print SCR_FILE "-decoder_extract YES\n";
        print SCR_FILE "-priority_extract YES\n";
        print SCR_FILE "-shreg_extract YES\n";
        print SCR_FILE "-shift_extract YES\n";
        print SCR_FILE "-xor_collapse YES\n";
        print SCR_FILE "-resource_sharing YES\n";
        print SCR_FILE "-mult_style auto\n";
        print SCR_FILE "-iobuf YES\n";
        print SCR_FILE "-max_fanout 500\n";
        print SCR_FILE "-bufg 16\n";
        print SCR_FILE "-register_duplication YES\n";
        print SCR_FILE "-equivalent_register_removal YES\n";
        print SCR_FILE "-register_balancing No\n";
        print SCR_FILE "-slice_packing YES\n";
        print SCR_FILE "-signal_encoding user\n";
        if($use_example){print SCR_FILE "-iob true\n";}
        else{print SCR_FILE "-iob false\n";}
        print SCR_FILE "-slice_utilization_ratio_maxmargin 5\n";
        close SCR_FILE;
        #Run xst
        if($files_only == 0)
        {
            system ("xst -ifn make_aurora.scr");
        }
    }
    ##end if use_xst
    if($use_synplify == 1)
    {
        #Create a Synplify project file
        open  PRJ_FILE, ">make_aurora.prj";
        print PRJ_FILE "#Synplify project file for aurora_201\n";
        print PRJ_FILE "\n\n";
        foreach $module (@AURORA_MODULES)
        {
            print PRJ_FILE "add_file -vhdl \"" . $module . ".vhd\"\n";
        }
        print PRJ_FILE "\n\n";
        if($use_example){print PRJ_FILE "project -result_file \"aurora_201_aurora_example.edf\"\n";}
        else{print PRJ_FILE "project -result_file \"aurora_201.edf\"\n";}
        if($use_example){print PRJ_FILE "set_option -top_module aurora_201_aurora_example\n";}
        else{print PRJ_FILE "set_option -top_module aurora_201\n";}
        print PRJ_FILE "set_option -technology virtex5\n";
        print PRJ_FILE "set_option -part xc5vlx50t\n";
        print PRJ_FILE "set_option -package ff1136\n";
        print PRJ_FILE "set_option -speed_grade -1\n";
        print PRJ_FILE "\n\n";
        print PRJ_FILE "#compilation/mapping options\n";
        print PRJ_FILE "set_option -default_enum_encoding default\n";
        print PRJ_FILE "set_option -symbolic_fsm_compiler 1\n";
        print PRJ_FILE "set_option -resource_sharing 1\n";
        print PRJ_FILE "\n";
        print PRJ_FILE "#map options\n";
        print PRJ_FILE "set_option -frequency 160.000\n";
        print PRJ_FILE "set_option -fanout_limit 100\n";
        print PRJ_FILE "set_option -disable_io_insertion 0\n";
        print PRJ_FILE "set_option -pipe 0\n";
        print PRJ_FILE "set_option -retiming 0\n";
        print PRJ_FILE "\n";
        print PRJ_FILE "#simulation options\n";
        print PRJ_FILE "set_option -write_verilog 0\n";
        print PRJ_FILE "set_option -write_vhdl 0\n";
        print PRJ_FILE "set_option -vlog_std v2001\n";
        print PRJ_FILE "\n";
        print PRJ_FILE "#Do not generate ncf constraints file\n";
        print PRJ_FILE "set_option -write_apr_constraint 0\n";
        close PRJ_FILE;
        #Run synplify_pro using the script
        if($files_only == 0)
        {
           unless($synplify_command = $ENV{SYNPLIFY_COMMAND})
           {
               $synplify_command = "synplify";
           }
            print "### Running Synplify Pro - ";
            print "command is: <SYNPLIFY_COMMAND> -batch make_aurora.prj\n";
            print " where <SYNPLIFY_COMMAND> = ".$synplify_command."\n";
            print "\n";
            print "To customize <SYNPLIFY_COMMAND>, set the SYNPLIFY_COMMAND environment variable\n";
            print "\n\n";
            if($use_example){print "see \"aurora_201_aurora_example.srr\" for results...\n\n";}
            else{print "see \"aurora_201.srr\" for results...\n\n";}
            system ("$synplify_command -batch make_aurora.prj");
        }
    }
    ##end if use_synplify
    if($files_only == 1)
    {
        exit;
    }
    #_____________________________ Run ngdbuild __________________________________
    if($run_map == 1 || $run_par == 1)
    {
        if($use_example)
        {
            $use_ngc  =   (-e "aurora_201_aurora_example.ngc");
            $use_edf  =   (-e "aurora_201_aurora_example.edf");
        }
        else
        {
            $use_ngc  =   (-e "aurora_201.ngc");
            $use_edf  =   (-e "aurora_201.edf");
        }

        if( $use_ngc && $use_edf )
        {
            #if there are 2 netlists available, decide which one to use based on the command
            #line arguments
            if($use_xst == 1){$use_edf = 0;}
            else
            {
                if($use_synplify == 1){$use_ngc = 0;}
                else
                {
                    print "Its not clear which netlist you wish to use. Please delete either aurora_201.ngc\n";
                    print " or aurora_201.edf\n";
                    exit;
                }
            }
        }

        if( !$use_ngc && !$use_edf)
        {
            print "No netlist found\n";
            exit;
        }

        if($use_ngc == 1)
        {
            if($use_example)
            {
                system ("ngdbuild -uc ../ucf/aurora_201_aurora_example.ucf -p xc5vlx50t-ff1136-3 aurora_201_aurora_example.ngc aurora_201_aurora_example.ngd");
            }
            else
            {
                system ("ngdbuild -uc ../ucf/aurora_201.ucf -p xc5vlx50t-ff1136-3 aurora_201.ngc aurora_201.ngd");
            }
        }
        else
        {
            #use_edf
            if($use_example)
            {
                system ("ngdbuild -uc ../ucf/aurora_201_aurora_example.ucf -p xc5vlx50t-ff1136-3 aurora_201_aurora_example.edf aurora_201_aurora_example.ngd");
            }
            else
            {
                system ("ngdbuild -uc ../ucf/aurora_201.ucf -p xc5vlx50t-ff1136-3 aurora_201.edf aurora_201.ngd");
            }
        }
    }
    #end run ngdbuild section
    #_____________________________   Run map   ___________________________________
    if($run_map == 1)
    {
        if($use_example)
        {
            system("map -w -p xc5vlx50t-ff1136-1 -timing -o aurora_201_aurora_example_map.ncd aurora_201_aurora_example.ngd aurora_201_aurora_example.pcf");
         if($use_win)
         {
            system("find  \"Number of Slice LUTs\" aurora_201_aurora_example_map.mrp");
            system("find  \"Number of Slice Registers\" aurora_201_aurora_example_map.mrp");
         }
         else
         {
            system("grep \"Number of Slice LUTs\" aurora_201_aurora_example_map.mrp");
            system("grep \"Number of Slice Registers\" aurora_201_aurora_example_map.mrp");
         }
        }
        else
        {
            system("map -w -p xc5vlx50t-ff1136-1 -timing -o aurora_201_map.ncd aurora_201.ngd aurora_201.pcf");
            if($use_win)
            { 
            system("find  \"Number of Slice LUTs\" aurora_201_map.mrp");
            system("find  \"Number of Slice Registers\" aurora_201_map.mrp");
            } 
            else
            {
            system("grep \"Number of Slice LUTs\" aurora_201_map.mrp");
            system("grep \"Number of Slice Registers\" aurora_201_map.mrp");
            }
        }
    }
    #_____________________________ Run par _______________________________________
    if($run_par == 1)
    {
        if($use_example)
        {
            system("par -w -t 1 aurora_201_aurora_example_map.ncd aurora_201_aurora_example.ncd aurora_201_aurora_example.pcf");
        }
        else
        {
            system("par -w -t 1 aurora_201_map.ncd aurora_201.ncd aurora_201.pcf");
        }

    }
    #______________________________ Report par results ___________________________
    if($run_bit == 1)
    {
        if($use_example)
        {
            system("bitgen -g GWE_cycle:Done -g GTS_cycle:Done -g DriveDone:Yes -g StartupClk:JTAGClk -w aurora_201_aurora_example.ncd");
        }
        else
        {
            system("bitgen -g GWE_cycle:Done -g GTS_cycle:Done -g DriveDone:Yes -g StartupClk:JTAGClk -w aurora_201.ncd");
        }

    }

   #______________________________ Trace Report ___________________________

    if($run_trace == 1)
    {
        if($use_example)
       {
            system("trce -e -l 1000 -s 3 aurora_201_aurora_example.ncd -o aurora_201_aurora_example.twr aurora_201_aurora_example.pcf");
        }
        else
        {
            system("trce -e -l 1000 -s 3 aurora_201 -o aurora_201.twr aurora_201.pcf");
       }

   }
#************************************ Subroutines **********************************************
    sub show_help
    {
        print"\nMAKE AURORA HELP\n\n";
        print"  make_aurora [synthesis options]\n\n";
        print"synthesis options:\n\n";
        print" -b        Generate a bitstream for the design.\n\n";
        print" -files    Creates an XST project file only.  If used in conjunction with\n";
        print"           -synplify, below, creates a synplicity project file only.\n\n";
        print" -h        Displays this message.  For more info, please see the Aurora user\n";
        print"           guide.\n\n";
        print" -m        Runs ngdbuild followed by map to get a resource cost measurement for\n";
        print"           the module.\n\n";
        print" -npl      Creates an ISE .npl project file only.  Can be used by itself or\n";
        print"           with -example, below.\n\n";
        print" -p        Runs par to get a minimum clock period estimate for the module using\n";
        print"           the timing constraints defined in the UFC file.  Will run ngdbuild\n";
        print"           and map if neccessary.\n\n";
        print" -example   Use aurora_201_aurora_example as the top level.  Use this option when\n";
        print"           instantiating the design in hardware.\n\n";
        print" -synplify Use Synplify to synthesize the aurora design.  XST is used by\n";
        print" -t        Runs trace and creates a timing report\n";
        print" -win      Generates windows equivalent grep command\n";
        print"           default.\n\n";
    }
