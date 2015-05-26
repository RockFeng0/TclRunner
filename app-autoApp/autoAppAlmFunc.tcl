#
# autoAppAlmFunc.tcl
# ----------------------------------------------------------------------
# This script is impelement for ALM functions
# v1.0		split some ALM procedures from the module 'autoAppSysFunc version 1.0'
#			these procedures are : "getQCConnection getQCTestSetInfo getQTPConnection getQCCycleCondition assembleReport getQCReport"
# 			add procedure 'alm::getConditionList' to get the info of ALM CycleCondition and procedure 'alm::listConditionTree' to resolve the ALM CycleCondition
# 1.0.1		improve 'alm::getQCReport' procedure with "exec_id"
#
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoAppAlmFunc.tcl,v 1.0 2015/02/26 $
#	START:	 2015/01/07
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a system function for automation test
#

package provide autoAppAlmFunc 1.0

package require tcom

namespace eval alm {
	array set tmpVars {
		file_list ""
		file_code ""
		test_start_seconds ""
		test_end_seconds ""
		template_html_report ""
		template_html_qtp_part_report ""
		template_html_qc_part_report ""
		almConditionDictResult ""
		cond_tree ""
		cond_root ""
	}
	
	array set almVariables {
		almDomainServerIP "172.17.65.136"
		almDomainName "infogotest.com"
		almServerURL "http://172.17.65.136:8080/qcbin"
		almUsername ""
		almPassword ""
		almDomain "ASM"
		almProject "ASM6000"		
		almQCTestSetPath {Root\ASM_5.2.6038.2839\ASM_5.2.6038.2839}
		almTDConnection ""
		almTestSet ""
		almQTPTestSet ""
		almQTPScriptsDict ""
		almConditionDict ""
		qtpApp ""
		qtpTest ""
		qtpTestActions ""
		qtpTestAction ""
		qtpTestResults ""
		qtpTestScriptsDict ""
	}

	proc getConditionList {dicts} {		
		alm::listConditionTree $dicts root
		set cond_tree $alm::tmpVars(cond_tree)
		set cond_root $alm::tmpVars(cond_root)
		unset alm::tmpVars(cond_tree) alm::tmpVars(cond_root)
		puts "all child root node: $cond_root"
		
		foreach node $cond_root {
			alm::listConditionTree $dicts $node		
			set cond_tree_tmp $alm::tmpVars(cond_tree)
			set cond_root_tmp $alm::tmpVars(cond_root)
			unset alm::tmpVars(cond_tree) alm::tmpVars(cond_root)
			puts "all child root node tree: $cond_tree_tmp-->$cond_root_tmp"
			
			foreach del_v $cond_tree_tmp {
				set del_index [lsearch $cond_tree $del_v]
				set cond_tree [lreplace $cond_tree $del_index $del_index]
			}
		}
		return $cond_tree
	}
	
	proc listConditionTree {dicts {execId root}} {
		
		append alm::tmpVars(cond_tree) ""
		append alm::tmpVars(cond_root) ""
		if {[catch {
			set key_list [dict keys $dicts]
			set key_len [llength $key_list]
		} res]} {
			error "not a dict"
		}
		
		if {$execId == "root"} {
			set exec_ids [dict keys $alm::almVariables(almQTPScriptsDict)]
			set exec_ids_len [llength $exec_ids]
			foreach exec_id $exec_ids {
				if {![regexp "cond_target $exec_id" $dicts]} {set execId $exec_id;break}
				if {[lsearch $exec_ids $exec_id] == [expr $exec_ids_len - 1]} {puts "\n\tnot have a root node: $start_cond";return}
			}			
			puts "root($execId) condition."
		}		
		
		set currentnodes ""
		foreach key $key_list {
			set c_source [dict get $dicts $key cond_source]
			if {$c_source == $execId} {
				lappend currentnodes $key
			}
		}
		
		if {[llength $currentnodes] <= 0} {
			lappend alm::tmpVars(cond_tree) $execId
			return
		} else {			
			lappend alm::tmpVars(cond_tree) $execId
			foreach node $currentnodes {
				set targetExecId [dict get $dicts $node cond_target]
				set len_targetExecId [regexp -all -inline "cond_value \\d cond_type \\d cond_source \\d+ cond_target $targetExecId" $dicts]			
				if {[llength $len_targetExecId] > 1} {
					if {[lsearch $alm::tmpVars(cond_root) $targetExecId] == -1} {lappend alm::tmpVars(cond_root) $targetExecId}				
					puts "child node(root): $targetExecId"
				}
				listConditionTree $dicts $targetExecId
			}			
		}
	}
	
	proc getQCConnection {swt server_url username password domain project} {
		set result False
		
		switch $swt {
			"connect" {
				set st [catch {
					set alm::almVariables(almTDConnection) [tcom::ref createobject TDApiOle80.TDConnection]
					$alm::almVariables(almTDConnection) InitConnectionEx $server_url
					$alm::almVariables(almTDConnection) Login $username $password
					set result True
					puts "Successfully create ALM client obj."
				} res]
				puts $res
			}
			"login" {
				set st [catch {
					
					puts "Connected:[$alm::almVariables(almTDConnection) Connected];Loggedin:[$alm::almVariables(almTDConnection) LoggedIn]"
					$alm::almVariables(almTDConnection) InitConnectionEx $server_url
					$alm::almVariables(almTDConnection) Login $username $password
					$alm::almVariables(almTDConnection) Connect $domain $project
					set result True
					puts "Successfully login to ALM server."
				} res]
				puts $res
			}
			"disconnect" {
				catch {$alm::almVariables(almTDConnection) DisconnectProject}
				catch {$alm::almVariables(almTDConnection) Disconnect}
				set result True
				puts "Disconnect complete."
			}			
			"logout" {catch {$alm::almVariables(almTDConnection) DisconnectProject};set result True;puts "Logout complete."}
			"load" {
				if {[alm::getQCTestSetInfo]} {
					set qc_cycle_judge [alm::getQCCycleCondition]
					if {$qc_cycle_judge} {						
						set qc_test_execID_list [alm::getConditionList $alm::tmpVars(almConditionDictResult)]						
					}
					set tmp $alm::almVariables(almQTPScriptsDict)
					
					if {![string compare $qc_test_execID_list ""]} {
						puts "\n\tQC Cycle Conditions info error: None Info is Grabbed."
						catch {
							setWmState $sc::mapALM(top) withdrawn
							tk_messageBox -title "QC Cycle Conditions Error" -type ok -icon info -message "执行流信息获取失败，依据执行网络执行"							
							setWmState $sc::mapALM(top) normal
						}
						set qc_test_execID_list [dict keys $tmp]				
					}					
					
					foreach i $qc_test_execID_list {
						puts "执行流ID: $i"
						set test_name [dict get $tmp $i test_name]
						set name [dict get $tmp $i name]
						set exec_status [dict get $tmp $i exec_status]
						set tester_name [dict get $tmp $i tester_name]
						set actual_tester [dict get $tmp $i actual_tester]
						set exec_time [dict get $tmp $i exec_time]
						set host_name [dict get $tmp $i host_name]
						set exec_date [dict get $tmp $i exec_date]	
						set subject_path [dict get $tmp $i subject_path]
											
						lappend load_scripts "\[ALM\] $subject_path\\$test_name"
						dict lappend tmp_result $i "test_name" $test_name "name" $name "exec_status" $exec_status "tester_name" $tester_name "actual_tester" $actual_tester "exec_time" $exec_time "host_name" $host_name "exec_date" $exec_date "subject_path" $subject_path
					}												
					set alm::tmpVars(file_list) $load_scripts
					set alm::almVariables(almQTPScriptsDict) $tmp_result
					puts "Successfully load QTP scripts with dict."
					set result True
				}
			}
			"unload" {				
				set alm::almVariables(almQTPScriptsDict) ""
				set result True
				puts "Unload complete."
			}
			default {puts "Unknow value 'swt':$swt"}
		}
		if {![string compare $result "False"]} {
			catch {$alm::almVariables(almTDConnection) DisconnectProject}
			catch {$alm::almVariables(almTDConnection) Disconnect}			
		}
		return $result
	}
	
	proc getQCTestSetInfo {} {
				
		if {![regexp {(.*)\\(.*)} $alm::almVariables(almQCTestSetPath) match QCTestSetPath QCTestSetName]} {
			puts "\n\tautoAppAlmFunc.tcl->Exception1.1: Invalid file path '$alm::almVariables(almQCTestSetPath)' which QTP scripts load from."
			return False
		}
		set st [catch {
			set TSTreeManager [$alm::almVariables(almTDConnection) TestSetTreeManager]
			
			set TSFolder [$TSTreeManager NodeByPath $QCTestSetPath]
			if {$TSFolder == ""} {				
				puts "\n\tautoAppAlmFunc.tcl->Exception1.2: Not found the folder '$QCTestSetPath' in ALM server."
				return False
			}
			
			set TSList [$TSFolder FindTestSets $QCTestSetName]
			set all [$TSList Count]
			if {$all == 0} {
				puts "\n\tautoAppAlmFunc.tcl->Exception1.3: Not found the test set '$QCTestSetName' in ALM server."
				return False
			}

			for {set i 1} {$i<=$all} {incr i} {
				set TestSet [$TSList Item $i]
				set test_set_name [$TestSet Name]
				puts $test_set_name
				if {![string compare $test_set_name $QCTestSetName]} {
					puts "Have get the result"
					set alm::almVariables(almTestSet) $TestSet
					break
				}
			}
			$TestSet AutoPost True			
			
			set TSTestFactory [$TestSet TSTestFactory]
			set QTPTestListObj [$TSTestFactory NewList ""]			
			set all_qtp_list [$QTPTestListObj Count]
			
			for {set i 1} {$i<=$all_qtp_list} {incr i} {
				set qtTest [$QTPTestListObj Item $i]
				
				set exec_id [$qtTest ID]
				set test_name [$qtTest TestName]
				set name [$qtTest Name]	
				set exec_status [$qtTest Field TS_EXEC_STATUS]
				set tester_name [$qtTest Field TC_TESTER_NAME]
				set actual_tester [$qtTest Field TC_ACTUAL_TESTER]				
				set exec_time [$qtTest Field TC_EXEC_TIME]
				set host_name [$qtTest Field TC_HOST_NAME]
				set exec_date [$qtTest Field TC_EXEC_DATE]
				set subject_path [[$qtTest Field TS_SUBJECT] Path]
				
				dict lappend qtp_name_dict $exec_id "test_name" $test_name "name" $name "exec_status" $exec_status "tester_name" $tester_name "actual_tester" $actual_tester "exec_time" $exec_time "host_name" $host_name "exec_date" $exec_date "subject_path" $subject_path
			}
		} res]
		if {$st} {			
			puts "\n\tautoAppAlmFunc.tcl->Exception1.4: $res"
			return False
		}
		set alm::almVariables(almQTPTestSet) $qtTest
		set alm::almVariables(almQTPScriptsDict) $qtp_name_dict
		return True
	}
	
	proc getQCCycleCondition {} {
		
		set st [catch {		
			set TSCond [$alm::almVariables(almTestSet) ConditionFactory]
			set TSCondListObj [$TSCond NewList ""]
			set all_cycle_list_count [$TSCondListObj Count]			
			if {$all_cycle_list_count == 0} {
				puts "\n\tautoAppAlmFunc.tcl->Exception5.1: without the cycle condition in ALM server."
				return False
			}
			for {set i 1} {$i <= $all_cycle_list_count} {incr i} {
				set TSCondObj [$TSCondListObj Item $i]
				set cond_id [$TSCondObj ID] 
				set cond_value [$TSCondObj Value]
				set cond_type [$TSCondObj Type]
				set cond_source	[$TSCondObj Source]
				set cond_target [$TSCondObj Target]
				dict lappend cond_dict_tmp $i "cond_id" $cond_id "cond_value" $cond_value  "cond_type" $cond_type "cond_source" $cond_source "cond_target" $cond_target
			}					
		} res]
		if {$st} {			
			puts "\n\tautoAppAlmFunc.tcl->Exception5.2: $res"
			return False
		}
		set alm::almVariables(almConditionDict) $cond_dict_tmp
		
		set st [catch {
			set exec_id_list [dict keys $alm::almVariables(almQTPScriptsDict)]
			set cond_id_list [dict keys $cond_dict_tmp]	
			set del_keys ""
			foreach key $cond_id_list {
				set source_value [dict get $cond_dict_tmp $key cond_source]
				set target_value [dict get $cond_dict_tmp $key cond_target]
				set s_judge [lsearch $exec_id_list $source_value]
				set t_judge [lsearch $exec_id_list $target_value]
				if {$s_judge < 0 || $t_judge < 0} {		
					lappend del_keys $key
				}
			}
			foreach i $del_keys {				
				set cond_dict_tmp [dict remove $cond_dict_tmp $i]
			}		
		} res]
		if {$st} {			
			puts "\n\tautoAppAlmFunc.tcl->Exception5.3: $res"
			return False
		}		
		set alm::tmpVars(almConditionDictResult) $cond_dict_tmp			
		return True
	}
	
	proc getQTPConnection {script_dir} {
		if {![string compare $scf::tmpVars(log_abs_path) ""]} {
			set date_start [clock format [clock seconds] -format "%Y_%m_%d_%H%M%S"]				
			set log "[file rootname [file tail $script_dir]]_$date_start.log"
			set scf::tmpVars(log_abs_path) [file join $scf::scfVariables(logPath) $log]	
		}
		set log_hd [open $scf::tmpVars(log_abs_path) w+]
		set f_hd [open $scf::tmpVars(code_file) w+]
		
		if {[file isdirectory $script_dir]} {
			puts "May be local QTP script."		
		} elseif {[regexp {\[ALM\] } $script_dir match]} {
			puts "May be ALM QTP script."			
		} else {
			puts "\n\tautoAppAlmFunc.tcl->Exception2.1: Invalid QTP script: $script_dir"
			close $log_hd;close $f_hd
			return False
		}
		
		if {![string compare $alm::almVariables(qtpApp) ""]} {
			set alm::almVariables(qtpApp) [tcom::ref createobject "QuickTest.Application"]	
			puts "Successfully create QTP obj."			
		} else {
			puts "QTP has been connected"
		}		
								
		set st [catch {	
			$alm::almVariables(qtpApp) Launch
			$alm::almVariables(qtpApp) Visible true
			puts "QTP obj launch complete"
				
			if {[string compare $alm::almVariables(qtpTest) ""] != 0} {
				set qtp_is_running [$alm::almVariables(qtpTest) IsRunning]
				catch {$alm::almVariables(qtpTest) Stop} res
				puts "QTP Test obj already exists. IsRunning: $qtp_is_running - Stopping it."
			}
			
			$alm::almVariables(qtpApp) Open $script_dir true false
		} res]
		if {$st} {
			puts "\n\tautoAppAlmFunc.tcl->Exception2.2: $res"
			puts "Sencond times to launch QTP--return False if error occurs."			

			catch {$alm::almVariables(qtpApp) Quit}
			after 2000
			if {[catch {
				$alm::almVariables(qtpApp) Launch
				$alm::almVariables(qtpApp) Visible true
				$alm::almVariables(qtpApp) Open $script_dir true false				
			} res]} {puts "\n\tautoAppAlmFunc.tcl->Exception2.2: $res";close $log_hd;close $f_hd;return False}
		}		
				
		set st [catch {					
			set qtpTest [$alm::almVariables(qtpApp) Test]	
			set qtpTestActions [$qtpTest Actions]
			set qtpTestAction [$qtpTestActions Item 1]
			
			set qtp_script_name [$qtpTest Name]
			set qtp_script_path [$qtpTest Location]
			set qtp_script_actions [$qtpTestActions Count]	
			set qtp_action_name [$qtpTestAction Name]		
			set qtp_action_path [$qtpTestAction Location]
			set qtp_action_source_code [$qtpTestAction GetScript]
			
			puts $log_hd "QTP脚本名称: $qtp_script_name"	
			puts $log_hd "QTP脚本路径: $qtp_script_path"
			puts $log_hd "QTP行为数(取Item 1): $qtp_script_actions"			
			puts $log_hd "QTP行为名称(Item 1): $qtp_action_name"
			puts $log_hd "QTP行为路径(Item 1): $qtp_action_path"	
			flush $log_hd
			
			puts $f_hd $qtp_action_source_code
			close $f_hd
						
			$qtpTest Run "" "true" ""
			
			set qtpTestResults [$qtpTest LastRunResults]			
			set qtp_result_path [$qtpTestResults Path]
			set qtp_result_status [$qtpTestResults Status]
			
			puts $log_hd "最新测试报告路径: $qtp_result_path" 			
			puts $log_hd "最新测试结果: $qtp_result_status" 
			close $log_hd
			
			dict lappend qtp_test_dict $qtp_script_name "qtp_script_path" $qtp_script_path "qtp_script_actions" $qtp_script_actions "qtp_action_name" $qtp_action_name "qtp_action_path" $qtp_action_path "qtp_result_path" $qtp_result_path "qtp_result_status" $qtp_result_status			
			
			catch {file copy -force [file join $qtp_result_path "Report/Results.xml"] [file join $scf::scfVariables(reportPath) "$qtp_script_name.xml"]}
			set alm::almVariables(qtpTest) $qtpTest
			set alm::almVariables(qtpTestActions) $qtpTestActions
			set alm::almVariables(qtpTestAction) $qtpTestAction
			set alm::almVariables(qtpTestResults) $qtpTestResults
			set alm::tmpVars(file_code) $qtp_action_source_code
			set alm::almVariables(qtpTestScriptsDict) $qtp_test_dict
			set a [open $scf::tmpVars(tmp_file) w];puts $a $alm::almVariables(qtpTestScriptsDict);close $a
						
		} res]
		
		if {$st} {
			puts "\n\tautoAppAlmFunc.tcl->Exception2.3: $res";
			return False
		} else {
			return True
		}		
	}
	proc assembleReport {swt} {
		
		set qtpJudge False
		switch $swt {
			"QTP" {
				set assemble_data $alm::tmpVars(template_html_qtp_part_report)
				set qtpJudge True
			}
			"QC" {
				set assemble_data $alm::tmpVars(template_html_qc_part_report)		
			}
			default {
				puts "\n\tautoAppAlmFunc.tcl->Exception4.1: Unknow $swt"
			}		
		}
		
		if {[catch {
			set start_date [clock format $alm::tmpVars(test_start_seconds) -format "%Y_%m_%d"]
			set finish_date [clock format $alm::tmpVars(test_end_seconds) -format "%Y_%m_%d"]
			set duration_seconds "[expr $alm::tmpVars(test_end_seconds) - $alm::tmpVars(test_start_seconds)] seconds"
		} res]} {				
			set start_date ""
			set finish_date [clock format [clock seconds] -format "%Y_%m_%d"]
			set duration_seconds ""
		}
		
		set template_report_result "
			<META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=gbk'>
			<HTML>
				<HEAD>
					<TITLE>QC TestSet Execution - Custom Report</TITLE>
					<STYLE>
						.textfont {font-weight: normal; font-size: 12px; color: #000000; font-family: verdana, arial, helvetica, sans-serif }
						.owner {width:100%; border-right: #6d7683 1px solid; border-top: #6d7683 1px solid; border-left: #6d7683 1px solid; border-bottom: #6d7683 1px solid; background-color: #a3a9b1; padding-top: 3px; padding-left: 3px; padding-right: 3px; padding-bottom: 10px; }
						.product {color: white; font-size: 22px; font-family: Calibri, Arial, Helvetica, Geneva, Swiss, SunSans-Regular; background-color: #54658c; padding: 5px 10px; border-top: 5px solid #a9b2c5; border-right: 5px solid #a9b2c5; border-bottom: #293f6f; border-left: 5px solid #a9b2c5;}
						.rest {color: white; font-size: 24px; font-family: Calibri, Arial, Helvetica, Geneva, Swiss, SunSans-Regular; background-color: white; padding: 10px; border-right: 5px solid #a9b2c5; border-bottom: 5px solid #a9b2c5; border-left: 5px solid #a9b2c5 }
						.chl {font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; width: 17%; height: 20px; border-bottom: 1px solid white }
						a {color: #336 }
						a:hover {color: #724e6d }
						.ctext {font-size: 11px; padding-right: 5px; padding-left: 5px; width: 80%; height: 20px; border-bottom: 1px solid #eee }
						.hl {color: #724e6d; font-size: 12px; font-weight: bold; background-color: white; height: 20px; border-bottom: 2px dotted #a9b2c5 }
						.space {height: 10px;}
						h3 {font-weight: bold; font-size: 11px; color: white; font-family: verdana, arial, helvetica, sans-serif;}
					</STYLE>
					<META content='MSHTML 6.00.2800.1106'>
				</HEAD>
				<body leftmargin='0' marginheight='0' marginwidth='0' topmargin='0'>
					<table width='100%' border='0' cellspacing='0' cellpadding='0'>
						<tr>
							<td class='product'>Quality Center-report for $swt</td>
						</tr>
						<tr>
							<td class='rest'>
								<table class='space' width='100%' border='0' cellspacing='0' cellpadding='0'>
									<tr>
										<td></td>
									</tr>
								</table>																		
								<table class='textfont' cellspacing='0' cellpadding='0' width='100%' align='center' border='0'>
									<tbody>
										<tr>
											<td>
												<table class='textfont' cellspacing='0' cellpadding='0' width='100%' align='center' border='0'>
													<tbody>
														<tr>
															<td class='chl' width='20%'>Server</td>
															<td class='ctext'>$alm::almVariables(almServerURL) </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>Domain Name</td>
															<td class='ctext'>$alm::almVariables(almDomain) </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>Project Name</td>
															<td class='ctext'>$alm::almVariables(almProject) </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>TestSet</td>
															<td class='ctext'>$alm::almVariables(almQCTestSetPath) </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>Started</td>
															<td class='ctext'>$start_date </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>Finished</td>
															<td class='ctext'>$finish_date </td>
														</tr>
														<tr>
															<td class='chl' width='20%'>Duration</td>
															<td class='ctext'>$duration_seconds </td>
														</tr>
													</tbody>
												</table>
											</td>
										</tr>
										<tr>
											<td class='space'></td>
										</tr>
									</tbody>
								</table>
								<table class='textfont' cellspacing='0' cellpadding='0' width='100%' align='center' border='0'>
									<tbody>
										<tr>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Test</td>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Status</td>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Responsible Tester</td>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Tester</td>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Exec Date</td>
											<td style='font-size: 10px; font-weight: bold; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>Exec Time</td>
										</tr>												
										$assemble_data
									</tbody>
								</table>
							</td>
						</tr>
					</table>
				</body>
			</HTML>
		"
		if {$qtpJudge} {
			set alm::tmpVars(template_html_report) $template_report_result
		}
		return $template_report_result
	}
	
	proc getQCReport {swt} {
		
		puts "create QC/ALM report"
		switch $swt {			
			"QTPPartReport" {
				set test_name [dict keys $alm::almVariables(qtpTestScriptsDict)]
				set test_status [dict get $alm::almVariables(qtpTestScriptsDict) $test_name qtp_result_status]
				foreach {i j} $alm::almVariables(almQTPScriptsDict) {
					if {![string compare [dict get $j test_name] $test_name]} {set exec_id $i;break}					
				}
				set test_resp_tester [dict get $alm::almVariables(almQTPScriptsDict) $exec_id tester_name]
				set test_tester [dict get $alm::almVariables(almQTPScriptsDict) $exec_id actual_tester]
				set test_exec_date [clock format [clock seconds] -format "%Y-%m-%d"]
				set test_exec_time [clock format [clock seconds] -format "%H:%M:%S"]
				append alm::tmpVars(template_html_qtp_part_report) "
					<tr>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_name</td>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_status</td>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_resp_tester</td>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_tester</td>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_exec_date</td>
						<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_exec_time</td>
					</tr>
				"				
			}
			"QCPartReport" {
				set tmp $alm::almVariables(almQTPScriptsDict)				
				set qc_test_execID_list [dict keys $tmp]		
				
				foreach i $qc_test_execID_list {
					set test_name [dict get $tmp $i test_name]
					set exec_status [dict get $tmp $i exec_status]
					set tester_name [dict get $tmp $i tester_name]
					set actual_tester [dict get $tmp $i actual_tester]
					set exec_date [dict get $tmp $i exec_date]
					set exec_time [dict get $tmp $i exec_time]
					append qc_test_part_report "
						<tr>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$test_name</td>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$exec_status</td>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$tester_name</td>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$actual_tester</td>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$exec_date</td>
							<td style='font-size: 10px; font-weight: normal; background-color: #eee; padding-right: 5px; padding-left: 5px; height: 20px; border-bottom: 1px solid white;'>$exec_time</td>
						</tr>			
					"
				}
				set alm::tmpVars(template_html_qc_part_report) $qc_test_part_report
			}
			default {
				puts "\n\tautoAppAlmFunc.tcl->Exception3.1: Unknow $swt"
			}
		}
	}
}
