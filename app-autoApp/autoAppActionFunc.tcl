#
# autoAppActionFunc.tcl
# ----------------------------------------------------------------------
# An application for run tcl/tk program
# v7.5
# v7.6		Base on v7.5, and edit 'autoLoadFile' procedure to version2
#			add 'listFileTree' procedure
#			add 'selectDir' procedure
# v7.7		Add 'tclpath' procedure,->save to sc::scVariables(tclpath)
#			edit 'runScript' procedure for supporting tcl-exe
#			edit 'runScriptBox' procedure with sc::scVariables(tclpath)
#			edit 'csvReportToHtml' procedure to analysis csv report
# v7.8		create a new module named with 'autoAppSysFunc' which will deal with system function's proceduces
#			move  "clearTask isHostReachable listFileTree getTclPath runScript runScriptBox getQCConnection getQCTestSetInfo getQTPConnection" to the module of 'autoAppSysFunc' in order to support AML/QC and QTP scripts
#			add procedure 'sc::initALM' 'sc::mailSender'
#			add 'sc::initALM'
#			add 'sc::scriptRunner' to instead the deleted procedures: 'sc::runSelectFile' 'sc::runFile'
# 7.8.1		improve 'sc::initALM' procedure to communicate with main process for get the var "almQTPScriptsDict" in "load" district
#			imporeve 'classifyRunScript' sub-procedure which belongs to sc::scriptRunner
# 7.8.2		add 'sc::applyLicence' and 'sc::loadLicence' procedures for the TclRunner Authorization.
#			add 'sc::scheduleRunner' procedures to support schedule task.
#			improve 'sc::scriptRunner' procedure to collect all PC QTP test report 
# 		
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoAppActionFunc.tcl,v 7.8 2015/03/10 $
#	START:	 2014/12/23
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a TK actions for automation test
#
set version 7.8
package provide autoAppActionFunc $version

package require autoAppSysFunc

proc setWmState {wm_path state} {
	
	switch $state {		
		"withdrawn" {
			wm withdraw $wm_path
			puts "state: [wm state $wm_path]"
		}
		"iconic" {
			wm iconify $wm_path
			puts "state: [wm state $wm_path]"
		}
		"normal" {
			wm deiconify $wm_path
			puts "state: [wm state $wm_path]"
		}
		default {
			tk_messageBox -title "error" -type ok -icon info -message "Unknow state:'$state'\nShould be 'withdrawn' 'iconic' 'normal'"
		}
	}
}

proc setLeftListBoxValue {base_on_list {mod create}} {
	
	switch $mod {
		"append" {
			foreach i $base_on_list {
				lappend sc::tkNameVar(fpath) $i
				set length [llength $sc::tkNameVar(fpath)]
				dict lappend sc::tkNameVar(scriptList) $length "abs_path" $i
				dict lappend sc::tkNameVar(scriptList) $length "tcl_run_id" $length
			}
		}
		"create" {			
			set id 1
			set dict_tmp ""
			foreach i $base_on_list {				
				dict lappend dict_tmp $id "abs_path" $i
				dict lappend dict_tmp $id "tcl_run_id" $id
				incr id
			}
			set sc::tkNameVar(fpath) $base_on_list
			set sc::tkNameVar(scriptList) $dict_tmp
		}
		"alm_append" {			
			set len [llength $base_on_list]
			for {set i 0} {$i < $len} {incr i} {
				set abs_path [lindex $base_on_list $i]
				lappend sc::tkNameVar(fpath) $abs_path
				set t_id [llength $sc::tkNameVar(fpath)]
				
				dict lappend sc::tkNameVar(scriptList) $t_id "abs_path" $abs_path
				dict lappend sc::tkNameVar(scriptList) $t_id "tcl_run_id" $t_id
				
				set exec_id_index [expr $i * 2]
				set exec_id [lindex $alm::almVariables(almQTPScriptsDict) $exec_id_index]
				dict lappend sc::tkNameVar(scriptList) $t_id "exec_id" $exec_id
				set alm_script_property [dict get $alm::almVariables(almQTPScriptsDict) $exec_id]
				foreach {key value} $alm_script_property {
					dict lappend sc::tkNameVar(scriptList) $t_id $key $value
				}
			}
		}
	}
}

namespace eval sc {
	
	array set tmpVars {
		almConButState "normal"
		almDisConButState "disabled"
		almLogButState "normal"
		almLogoutButState "disabled"
		almLoadButState "normal"
		almUnloadButState "disabled"
		trConButState "normal"
		trDisConButState "disabled"
		scheduleRunAllEntryState "normal"
		scheduleRunAllButtonText "Setup ok."
	}
		
	array set tkNameVar {
		fpath ""
		flog ""
		flog2 ""
		freport ""
	}	
	
	array set scVariables {
		scriptList ""
		runningSelID ""
		tclHtmlReport ""
		qcHtmlReport ""
		qtpHtmlReport ""
	}
	set sc::scVariables(p_file) [file join $env(APPDATA) scr_autoApp.cfg]
	set sc::scVariables(currentScript) [info script]
	
	proc getSelectDir {} {		
		if {[file exists $sc::scVariables(p_file)]} {
			set a [open $sc::scVariables(p_file) r]
			set cfgDict [read $a]
			close $a
			
			foreach i [dict keys $cfgDict] {
				set $i [dict get $cfgDict $i]
			}	
			catch {unset a i}
			
		} else {
			puts "Will using default path."
			
		}
	}
	
	getSelectDir
	
	
	
	proc startTclRunner {swt} {		
		
		catch {
			destroy $sc::mapStartUI(frame)
			destroy $sc::mapStartUI(frame2)
		}
		switch $swt {			
			"client" {
				
				trClientGUI
			}
			default {				
				
				autoAppMain
			}
		}
		
		if {![scf::getTclPath]} {tk_messageBox -title "" -type ok -icon info -message "Can't found the tcl interpreter.\n\tHave some error at TclRunner.";exit}

		
		if {![file isdirectory $scf::scfVariables(reportPath)] || ![file isdirectory $scf::scfVariables(logPath)]} {	
			tk_messageBox -title "" -type ok -icon info -message "Please setup your preference paths."
			preferenceGUI
		}
		
		scf::listenSock start
	}	
	
	
	
	proc selectDir {var} {		
		global tcl_library env				
		
		
		
		set chooseDir [tk_chooseDirectory -parent $sc::mapPre(top)]
		if {[llength $chooseDir] != 0} {		
			set $var $chooseDir			
			if {[file exists $sc::scVariables(p_file)]} {
				set a [open $sc::scVariables(p_file) r]
				set b [read $a]
				close $a
				after 500
				
				
				set a [open $sc::scVariables(p_file) w+]
				puts $a "[dict merge $b "$var {$chooseDir}"]"
				close $a
			} else {			
				puts "configScriptPath"					
				
				set a [open $sc::scVariables(p_file) w+]
				puts $a "$var {$chooseDir}"
				close $a
			}
		}
	}
	
	
	
	proc applyLicence {swt {afile ""}} {
		
		
		
		global env		
		switch $swt {
			decode64 {
				
				
				if {[file exists $afile]} {
					
					set a [open $afile r]
					set b [read $a]
					close $a
					set msg_en64 [string range $b 3 end]
					set msg [base64::decode $msg_en64]
					regexp {(.*) TclRunner-bruce-luo.*} $msg match dev_name
					
					
					set licence [file join [file dirname $afile] tclRunner.lic]					
					set a [open $licence w] 
					puts $a [rsaencry::getAuthCode $dev_name]
					close $a
					
					puts "generation success: $licence"
				} else {
					puts "not a file: '$afile'"
				}		
			}
			encode64 {
				
				set dev_name [info hostname]
				set plus "TclRunner-bruce-luo"
				set time [clock format [clock second] -format "%Y-%m-%d %H:%M:%S"]
				set msg "$dev_name $plus $time"
				set msg_en64 [base64::encode $msg]
				
				set apply_file [file join $env(systemdrive)/ "tclRunnerApplyFor"]
				set a [open $apply_file w]
				puts $a "lkf$msg_en64"
				close $a			
				
				tk_messageBox -title "Success" -type ok -icon info -message "Successfuly.\n'$apply_file'\nPlease send it to administrator of TclRunner."				
			}
		}		
	}
	
	proc loadLicence {} {
		
		if {[rsaencry::verifyAuthCode]} {
			tk_messageBox -title "Success" -type ok -icon info -message "Successfully load TclRunner licence."
			
			catch {
				destroy $sc::mapAuthMain(frame)
				destroy $sc::mapAuthMain(frame1)
			}
			autoAppStartUI
		} else {
			tk_messageBox -title "Info" -type ok -icon info -message "Invalid TclRunner licence for this PC."
		}		
	}
	
	
	
	proc loadFile {{swt "def"}} {
		global env
		puts "loadFile:"
		switch $swt {
			"licence" {
				puts "\tload licence"
				set rsaencry::authfile [tk_getOpenFile -filetypes {{Lic .lic} {All *}} -multiple false -initialdir $env(SystemDrive)]
			}
			default {
				puts "\tload script"
				
				set fpath_tmp [tk_getOpenFile -filetypes {{Tcl .tcl} {All *}} -multiple true -initialdir $env(SystemDrive)]
				setLeftListBoxValue $fpath_tmp append
			}
		}		
	}	
	
	
	
		
		
		
		
	
	
	
	proc autoLoadFile {} {
		
		puts "autoLoadFile"		
		
		set srcPath $scf::scfVariables(autoloadPath)
		scf::listFileTree $srcPath *ATP*.tcl
		set script_list $scf::x
		unset scf::x
		scf::listFileTree $srcPath *Compatible*.tcl
		set compatible_list $scf::x
		unset scf::x
		
		if {[llength $script_list] == 0 && [llength $compatible_list] == 0} {
			tk_messageBox -title "" -type ok -icon info -message "Do not find script which content ATP or Compatible string."
		} else {
			
			setLeftListBoxValue [concat $script_list $compatible_list]
		}		
	}
		
	
	proc logFile_v1 {} {
		puts "configFile"
		set l_t [tk_chooseDirectory]
		if {[string compare $l_t ""] != 0} {
			set scf::scfVariables(logPath) $l_t
		}
	}
	proc logFile {} {
		
		puts "configFile"
		preferenceGUI
	}
	
	
	
	
	proc scriptRunner {swt} {
		global flength
		
		
		
		
		
		
		
		proc classifyRunScript {selection_index} {			
			set sc::scVariables(runningSelID) $selection_index
			set tid [expr $selection_index + 1]
			set i_file [dict get $sc::tkNameVar(scriptList) $tid abs_path]			
			
			
			set host_judge [dict exists $sc::tkNameVar(scriptList) $tid host_name]
			
			if {$host_judge} {
				set i_name [dict get $sc::tkNameVar(scriptList) $tid test_name]
				set pc_name [dict get $sc::tkNameVar(scriptList) $tid host_name]
				set pc_ip [scf::getDomainPCAddress $pc_name $alm::almVariables(almDomainName) $alm::almVariables(almDomainServerIP)]
				if {[lsearch $scf::tmpVars(client_ip_list) $pc_ip] == -1} {lappend scf::tmpVars(client_ip_list) $pc_ip}
	
				if {[string compare $pc_ip ""] != 0} {
					puts "$i_file: $pc_ip"					
					set result_list [list True False]
					set timeout_min 120					
					
					
					set STS_getNSVar_tr_server_ip "Type EXEC Name getNSVar Param {scf::scfVariables(tr_server_ip)} Data {}"
					set result_tr_server_ip [client_info localhost $STS_getNSVar_tr_server_ip]
					
					if {[lsearch $result_list $result_tr_server_ip] == -1} {
						set scf::scfVariables(tr_server_ip) $result_tr_server_ip
					} else {
						puts "\n\tNot found the 'tr_server_ip' which is reported by client connect action.Will use '$scf::scfVariables(host_ip)'"
						set scf::scfVariables(tr_server_ip) $scf::scfVariables(host_ip)						
					}
					
					
					set request_tr_server_ip "Type EXEC Name setNSVar Param {scf::scfVariables(tr_server_ip) $scf::scfVariables(tr_server_ip)} Data {}"
					set request_tr_server_ip [client_info $pc_ip $request_tr_server_ip]
					
					
					set request "Type EXEC Name scf::runScriptBox Param {$selection_index {$i_file}} Data {}"	
					set result [client_info $pc_ip $request $timeout_min]
					
					
					set request_flog "Type EXEC Name getNSVar Param {sc::tkNameVar(flog)} Data {}"
					set result_flog [client_info $pc_ip $request_flog]
					if {[lsearch $result_list $result_flog] == -1} {set sc::tkNameVar(flog) $result_flog}
					
					
					set request_flog2 "Type EXEC Name getNSVar Param {sc::tkNameVar(flog2)} Data {}"
					set result_flog2 [client_info $pc_ip $request_flog2]
					if {[lsearch $result_list $result_flog2] == -1} {set sc::tkNameVar(flog2) $result_flog2}				

					
					set request_freport "Type EXEC Name getNSVar Param {scf::scfVariables(reportPath)} Data {}"					
					set result_freport [client_info $pc_ip $request_freport]
					if {[lsearch $result_list $result_freport] == -1} {
						set file_abs_path [file join $result_freport $i_name.xml]
						set request_xml "Type EXEC Name getFileCont Param {{$file_abs_path}} Data {}"
						set result_xml [client_info $pc_ip $request_xml]
						if {[lsearch $result_list $result_xml] == -1} {
							set sc::tkNameVar(flog2) $result_flog2
							set a [open [file join $scf::scfVariables(reportPath) $i_name.xml] w]
							fconfigure $a -encoding utf-8;
							regsub -linestop {(.*xml.*)} $result_xml {<!--TclRunner Comment: \1 -->} result_xml;
							puts $a $result_xml;close $a
						} else {
							
							set a [open [file join $scf::scfVariables(reportPath) $i_name.xml] w]
							fconfigure $a -encoding utf-8;puts $a "<!--TclRunner Comment: $result_xml -->";close $a
						}	
					}
				} else {
					puts "'$i_file' do not specify a test device"
				}
			} else {							
				scf::runScriptBox $selection_index $i_file
			}		
		}
		
		if {![file isdirectory $scf::scfVariables(logPath)]} {
			tk_messageBox -title "" -type ok -icon info -message "Please set the path of saving logs."
			
			logFile
		} elseif {![info exists sc::tkNameVar(scriptList)]} {
			clearTask
			tk_messageBox -title "Complete." -type ok -icon info -message "Run successfully."
		} else {
			puts "scriptRunner"
			set alm::tmpVars(template_html_report) ""
			set alm::tmpVars(test_start_seconds) [clock seconds]
			
			$sc::mapMain(r_progressbar) start
			
			switch $swt {
				"All" {
					puts "All scripts will be run."
					set flength [dict size $sc::tkNameVar(scriptList)]
					set tcl_run_id_list [dict keys $sc::tkNameVar(scriptList)]
										
					$sc::mapMain(leftProgressbar) configure -value 0
													
					for {set selection_index 0} {$selection_index < $flength} {incr selection_index} {
						
						set sc::scVariables(runningSelID) $selection_index
						
						set tid [expr $selection_index + 1]
						$sc::mapMain(leftListbox) selection clear 0 end
						$sc::mapMain(leftListbox) selection set $selection_index
						$sc::mapMain(leftProgressbar) configure -value [expr $tid * (100/$flength)]
						update
						classifyRunScript $selection_index
					}
				}
				"Only" {
					puts "Selection script will be run."
					set selection_index [$sc::mapMain(leftListbox) curselection]
					if {[string compare $selection_index ""] != 0} {classifyRunScript $selection_index}
				}
				default {
					tk_messageBox -title "Error Switch" -type ok -icon info -message "Unknow '$swt'."
					return
				}
			}
			
			
			set result_list [list True False]
			set a ""
			set b ""
			puts "With client pc: $scf::tmpVars(client_ip_list) "
			foreach pc_ip $scf::tmpVars(client_ip_list) {
				
				set request_dict "Type EXEC Name getNSVar Param {alm::almVariables(qtpTestScriptsDict)} Data {}"
				set result_dict [client_info $pc_ip $request_dict]
				if {[lsearch $result_list $result_dict] == -1} {append a $result_dict}

				
				set request_html "Type EXEC Name getNSVar Param {alm::tmpVars(template_html_qtp_part_report)} Data {}"
				set result_html [client_info $pc_ip $request_html]
				if {[lsearch $result_list $result_html] == -1} {append b $result_html}
			}			
			set alm::almVariables(qtpTestScriptsDict) $a
			set alm::tmpVars(template_html_qtp_part_report) $b
			
			
			$sc::mapMain(r_progressbar) stop
			set alm::tmpVars(test_end_seconds) [clock seconds]
			clearTask
			tk_messageBox -title "Complete." -type ok -icon info -message "Run successfully."			
		}	
	}
	
	proc scheduleRunner {} {
		set text {"Setup ok." "Reset time."}
		set bt_text [$sc::mapPre(scheduleRunAllButton) cget -text]
		puts $bt_text
		set bt_index [lsearch $text $bt_text]
		switch $bt_index {
			0 {
				$sc::mapPre(scheduleRunAllEntry) configure -state disable
				$sc::mapPre(scheduleRunAllButton) configure -text "Reset time."	
				set sc::tmpVars(scheduleRunAllEntryState) disable
				set sc::tmpVars(scheduleRunAllButtonText) "Reset time."
				
				if {![string compare $scf::tmpVars(schedule_time) ""]} {puts "Without schedule task.";return}
				set after_seconds [expr $scf::tmpVars(schedule_time) * 60 * 1000]
				after $after_seconds {
					
					sc::scriptRunner All					
				}
			}
			1 {
				puts "Clean up the schedule task: [after info]"
				
				foreach i [after info] {after cancel $i}			
				$sc::mapPre(scheduleRunAllEntry) configure -state normal
				$sc::mapPre(scheduleRunAllButton) configure -text "Setup ok."
				set sc::tmpVars(scheduleRunAllEntryState) normal
				set sc::tmpVars(scheduleRunAllButtonText) "Setup ok."
			}
		}
	}
	
	
	proc runStop {} {
		global flength
		puts "runStop"
		
		set flength [expr $sc::scVariables(runningSelID) + 1]
		
		
		catch {
			if {[thread::exists $sc::scVariables(threadID)]} {			
				thread::release $sc::scVariables(threadID)
			}
		}
		clearTask
	}
	
	
	
	
	proc csvReportStat {{swt On}} {
		puts "csvReportStat"
		
		if {![file isdirectory $scf::scfVariables(reportPath)]} {
			tk_messageBox -title "" -type ok -icon info -message "Please set the path of report."
			
			logFile
		} else {
			scf::listFileTree $scf::scfVariables(reportPath) *ATP*.csv
			set script_list $scf::x ; unset scf::x
			scf::listFileTree $scf::scfVariables(reportPath) *Compatible*.csv
			set compatible_list $scf::x ; unset scf::x
			set sc::tkNameVar(freport) [concat $script_list $compatible_list]
		}
		switch $swt {
			"On" {
				tk_messageBox -title "Statistics" -type ok -icon info -message "Total report : [llength $sc::tkNameVar(freport)]"
			}
			"default" {
				puts "csvReportStat->Off mod."
			}
		}
	}
	
	
	
	
	proc createHtmlReport {} {	
		
		set current_time [clock format [clock seconds] -format "%m_%d_%Y_%H%M%S"]
		set sc::scVariables(tclHtmlReport) "$scf::scfVariables(reportPath)/tclSummary_$current_time.html"		
		set sc::scVariables(qcHtmlReport) "$scf::scfVariables(reportPath)/qcSummary_$current_time.html"
		set sc::scVariables(qtpHtmlReport) "$scf::scfVariables(reportPath)/qtpSummary_$current_time.html"
		puts "createHtmlReport"
	}
	
	
	proc csvReportToHtml {filepath} {				
		
		
		
		
		
		set a [open $filepath r]
		set failFile [read $a]
		close $a ; after 500
		if {![regexp {[Ff][Aa][Ii][Ll]} $failFile match]} {return PASS}
				
		set failInfo [regexp -linestop -all -inline {.*,.*,.*,.*,.*,[fF][aA][iI][lL]} $failFile]	
		if {[regexp {Testlink} $failFile match]} {		
			puts "-->用例测试脚本报告:[file tail $filepath]"
			set testLink "true"
		} else {
			puts "-->功能测试脚本报告:[file tail $filepath]"
			set testLink "false"
			set failInfo [regexp -linestop -all -inline {.*\n.*,[fF][aA][iI][lL]} $failFile]
			
		}
		set failLen [llength $failInfo]
				
		
		
		array set arrResult {
			testCase ""
			testStep ""
			stepInfo ""
			expectResult ""
			testResult ""
			rsStatus ""
		}
		
		
		set handle [open $sc::scVariables(tclHtmlReport) a]
		set title [file rootname [file tail $filepath]]
		set tdStyle {style='border-right:1px solid #CCC;border-top:1px solid #CCC;'}
		
		puts $handle "
		<table border='0' cellSpacing='0' cellPadding='0' width='90%' style='border:1px solid #DDDDDD;margin:0px auto ;font-size:15px'  >
			<tr style='font-weight:900;font-size:25px;'  ><td align='center' colspan='6'>$title</td></tr>

			<tr style='background-color:#0080C0;color:fff;font-weight:900' >
				<td align='center' style='border-right:1px solid #CCC;' >TestCase</td>
				<td align='center' style='border-right:1px solid #CCC;' >TestStep</td>
				<td align='center' style='border-right:1px solid #CCC;' >StepInfo</td>
				<td align='center' style='border-right:1px solid #CCC;' >ExpectResult</td>
				<td align='center' style='border-right:1px solid #CCC;' >TestResult</td>
				<td align='center'    >ResultStatus</td>
			</tr>
		"
		
		foreach line $failInfo {
			
			foreach i [array names arrResult] {
				if {[string compare $arrResult($i) ""] == 0} {set arrResult($i) "&nbsp;"}
			}		
			
			if {$testLink} {
				regexp {(.*),(.*),(.*),(.*),(.*),(.*)} $line match arrResult(testCase) arrResult(testStep) arrResult(stepInfo) arrResult(expectResult) arrResult(testResult) arrResult(rsStatus)
				set srcIndex [lsearch $failFile [lindex [lindex $line 0] 0]];
				
				for {} {$srcIndex > 0} {incr srcIndex -1} {
					set vList [regexp -inline -all {v1.0-[0-9]+} [lindex $failFile $srcIndex]]
					if {[llength $vList]>0} {break}
				}
				foreach v $vList {
					lappend arrResult(testCase) "<a href='http://192.168.46.241:8080/testlink/lib/testcases/tcSearch2.php?id=$v' target='_blank'>$v</a>"
				}				
			} else {	
				
					
				
					
				
					
				
					
				
				
				regsub {[[:space:]]} $line {} line_tmp
				regsub {,{2,}} $line_tmp {,} line_value
				
				regexp {,(.*),(.*),(.*),(.*),(.*)} $line_value match arrResult(testStep) arrResult(stepInfo) arrResult(expectResult) arrResult(testResult) arrResult(rsStatus)
			}	
			
			puts $handle "
			<tr>
				<td  $tdStyle >$arrResult(testCase)</td>
				<td  $tdStyle >$arrResult(testStep)</td>
				<td  $tdStyle >$arrResult(stepInfo)</td>
				<td  $tdStyle >$arrResult(expectResult)</td>
				<td  $tdStyle >$arrResult(testResult)</td>
				<td  style='border-top:1px solid #CCC;' >$arrResult(rsStatus)</td>
			</tr>
			"	
		}
		puts $handle "</table>"	
		close $handle
	}
	
	
	proc analysisReport {} {
		
		puts "collect tcl report."
		sc::csvReportStat "Off"
		
		
		sc::createHtmlReport
		
		
		puts "analysis tcl report."		
		foreach i $sc::tkNameVar(freport) {
			sc::csvReportToHtml $i
			update
		}
		
		
		if {[string compare $alm::almVariables(qtpTestScriptsDict) ""] != 0} {
			puts "analysis qtp report."
			
			
			alm::assembleReport QTP
			set a [open $sc::scVariables(qtpHtmlReport) w];puts $a $alm::tmpVars(template_html_report);close $a						
			
		}
		
		
		if {[string compare $alm::almVariables(almQTPScriptsDict) ""] != 0} {			
			puts "analysis qc report."
			alm::getQCReport QCPartReport
			
			set result [alm::assembleReport QC]
			set a [open $sc::scVariables(qcHtmlReport) w];puts $a $result;close $a						
			
		}
		
		if {[file isfile $sc::scVariables(tclHtmlReport)]} {
			catch {exec cmd /c start $sc::scVariables(tclHtmlReport)}
			tk_messageBox -title "HTML Report Path" -type ok -icon info -message "Success.\n $sc::scVariables(tclHtmlReport)"
		} else {
			tk_messageBox -title "HTML Report Path" -type ok -icon info -message "Complete."
		}
	}

	
	
	proc initALM {swt} {
		puts "initial ALM with action '$swt'"
		
		
		set result [alm::getQCConnection $swt $alm::almVariables(almServerURL) $alm::almVariables(almUsername) $alm::almVariables(almPassword) $alm::almVariables(almDomain) $alm::almVariables(almProject)]
		if {!$result} {
			tk_messageBox -title "$swt error." -type ok -icon info -message "Get QC connection error with parameter: $swt"
			catch {destroy $sc::mapALM(top)}
			return False
		}		
		
		
		switch $swt {
			"connect" {
				set tmp [list "serverUrlEntry" "usernameEntry" "passwordEntry" "connectButton"]
				foreach i $tmp {					
					$sc::mapALM($i) configure -state disabled
				}
				$sc::mapALM(disconnectButton) configure -state normal
				set sc::tmpVars(almConButState) disabled
				set sc::tmpVars(almDisConButState) normal
			}
			"disconnect" {
				set tmp [list "serverUrlEntry" "usernameEntry" "passwordEntry" "domainEntry" "projectEntry" "loadPathEntry" "connectButton" "loginButton" "loadButton"]
				foreach i $tmp {
					$sc::mapALM($i) configure -state normal
				}
				$sc::mapALM(disconnectButton) configure -state disabled
				$sc::mapALM(logoutButton) configure -state disabled
				set sc::tmpVars(almConButState) normal
				set sc::tmpVars(almDisConButState) disable
				set sc::tmpVars(almLogButState) normal
				set sc::tmpVars(almLogoutButState) disabled
				set sc::tmpVars(almLoadButState) normal
				set sc::tmpVars(almUnloadButState) disabled
				sc::delAllSelection
			}
			"login" {
				set tmp [list "domainEntry" "projectEntry" "loginButton"]
				foreach i $tmp {
					$sc::mapALM($i) configure -state disabled
				}
				$sc::mapALM(logoutButton) configure -state normal
				set sc::tmpVars(almLogButState) disabled
				set sc::tmpVars(almLogoutButState) normal
			}
			"logout" {
				set tmp [list "domainEntry" "projectEntry" "loadPathEntry" "loginButton" "loadButton"]
				foreach i $tmp {
					$sc::mapALM($i) configure -state normal
				}
				$sc::mapALM(logoutButton) configure -state disabled
				set sc::tmpVars(almLogButState) normal
				set sc::tmpVars(almLogoutButState) disabled
				set sc::tmpVars(almLoadButState) normal
				set sc::tmpVars(almUnloadButState) disabled
				sc::delAllSelection
			}
			"load" {
				
				setLeftListBoxValue $alm::tmpVars(file_list) "alm_append"
				
				set tmp [list "loadPathEntry" "loadButton"]
				foreach i $tmp {
					$sc::mapALM($i) configure -state disabled
				}
				$sc::mapALM(unLoadButton) configure -state normal
				set sc::tmpVars(almLoadButState) disabled
				set sc::tmpVars(almUnloadButState) normal
				
				
				
					
					
					
					
					
				set request_almScript "Type EXEC Name setNSVar Param {alm::almVariables(almQTPScriptsDict) {$alm::almVariables(almQTPScriptsDict)}} Data {}"
				set request "Type EXEC Name setNSVar Param {sc::tkNameVar(scriptList) {$sc::tkNameVar(scriptList)}} Data {}"	
				set request_exit "Type EXIT Name {} Param {} Data {}"	
				set result [client_info localhost $request_almScript ]
				set result [client_info localhost $request]		
				set result [client_info localhost $request_exit]		
			}
			"unload" {
				set tmp [list "loadPathEntry" "loadButton"]
				foreach i $tmp {
					$sc::mapALM($i) configure -state normal
				}
				$sc::mapALM(unLoadButton) configure -state disabled
				set sc::tmpVars(almLoadButState) normal
				set sc::tmpVars(almUnloadButState) disabled
				sc::delAllSelection
			}
		}
	}	
	
	
	
	proc initTR {swt} {
		puts "initial TclRunner client with action '$swt'"		
		
		set result [scf::listenSock $swt $scf::scfVariables(tr_server_ip)]		
		if {$result} {
			set fpath_len [llength $sc::tkNameVar(fpath)]			
			tk_messageBox -title "Action Complete" -type ok -icon info -message "Action takes effect on $fpath_len scripts."			
		
			
			
			
			thread::send $scf::tmpVars(threadID_sock) {setNSVar scf::scfVariables(reportPath) $scf::scfVariables(reportPath)}
			thread::send $scf::tmpVars(threadID_sock) {setNSVar scf::scfVariables(logPath) $scf::scfVariables(logPath)}					
		} else {
			tk_messageBox -title "Action error." -type ok -icon info -message "TclRunner connection error. Maybe '$scf::scfVariables(host_name)' :\n1.not a domain PC.\n2.not a PC which is specified test task.\n3.the server you are connecting don't load ALM scripts"			
			
			catch {scf::listenSock "disconnect" $scf::scfVariables(tr_server_ip)}
			
			
			return False
		}
		
		switch $swt {			
			"connect" {
				set tmp [list "serverIPEntry" "connectButton"]
				foreach i $tmp {					
					$sc::mapTR($i) configure -state disabled
				}
				$sc::mapTR(disconnectButton) configure -state normal
				set sc::tmpVars(trConButState) disabled
				set sc::tmpVars(trDisConButState) normal
			}
			"disconnect" {
				set tmp [list "serverIPEntry" "connectButton"]
				foreach i $tmp {
					$sc::mapTR($i) configure -state normal
				}
				set sc::tmpVars(trConButState) normal
				set sc::tmpVars(trDisConButState) disable				
				sc::delAllSelection
			}
		}
	}	
	
	
	
	
	proc mailSender {swt} {
		
		
		
		
		set switches [list "tclHtmlReport" "qtpHtmlReport" "qcHtmlReport"]
		if {[lsearch $switches $swt] >= 0} {
			if {[file isfile $sc::scVariables($swt)]} {
				set a [open $sc::scVariables($swt) r];set body [read $a];close $a
				setWmState $sc::mapEmail(top) withdrawn
				scf::send_email $scf::scfVariables(emailFrom) $scf::scfVariables(emailTo) [encoding convertto cp936 $scf::scfVariables(emailSubject)] [encoding convertto cp936 $body] $scf::scfVariables(emailServer)				
				tk_messageBox -title "Mail Send success" -type ok -icon info -message "Successful."				
			} else {
				setWmState $sc::mapEmail(top) withdrawn
				tk_messageBox -title "Mail Send error" -type ok -icon info -message "Not hava a report."
				
			}	
			setWmState $sc::mapEmail(top) normal
		} else {
			tk_messageBox -title "error" -type ok -icon info -message "Unknow mailSender:'$swt'\nShould be 'tclHtmlReport' 'qtpHtmlReport' 'qcHtmlReport'"
			catch {destroy $sc::mapEmail(top)}
		}		
	}
	
	
	
	
	proc delSelectFile {} {
		puts "delSelectFile"
		set current_selection_index [$sc::mapMain(leftListbox) curselection]
		catch {$sc::mapMain(leftListbox) delete $current_selection_index}
		
		set current_tcl_run_id [expr $current_selection_index + 1]
		catch {
			
			foreach {tid value} $sc::tkNameVar(scriptList) {
				if {$tid == $current_tcl_run_id} {continue}
				if {$tid > $current_tcl_run_id} {					
					
					set key_tmp [expr $tid - 1]
					dict set value tcl_run_id $key_tmp
					
					foreach {tname tvalue} $value {dict lappend tmp $key_tmp $tname $tvalue}
				} else {
					
					foreach {tname tvalue} $value {dict lappend tmp $tid $tname $tvalue}					
				}
			}
			set sc::tkNameVar(scriptList) $tmp
		} res
		
		
	}
	
	
	proc delAllSelection {} {
		puts "delAllSelection"		
		catch {$sc::mapMain(leftListbox) delete 0 end}
		catch {$sc::mapTR(leftListbox) delete 0 end}
		set sc::tkNameVar(scriptList) ""
	}
	
	
	
	
	proc helpFile {} {
		global version
		puts "helpFile"
		
		tk_messageBox -title "AutoApp Version $version" -type ok -icon info -message "Automation test tool-autoApp. \n\nAutoApp Version $version \n\nCopyright (c) 2012-2017  Infogo Technology Co.,Ltd. \n\n-Bruce Luo (Mail: lkf20031988@163.com)"
	}	
}
