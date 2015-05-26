#
# autoAppSysFunc.tcl
# ----------------------------------------------------------------------
# This script is impelement for system functions
# v1.0		split some system procedures from the module 'autoAppfunc version 7.7'
#			these procedures are : "clearTask isHostReachable listFileTree getTclPath runScript runScriptBox getQCConnection getQCTestSetInfo getQTPConnection assembleReport getQCReport"
# v2.0		move ALM functions procedure to module 'autoAppAlmFunc'
# v2.1		add 'scf::nslookupTcl' procedure and require 'autoAppPubFunc' module
#			add 'scf::getDomainPCAddress' procedure to resolve a remote PC IP address
#			add 'scf::listenSock' procedure to create and connect 5821 sock
#			add 'scf::getPCScripts' procedure to get PC scripts which is specified test task by ALM
# 2.1.1		improve 'scf::runScriptBox' procedure after thread end
# 			add parameter 'scf::tmpVars(client_ip_list)' which record the ClientPC_IP that QTP have tested
# 
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoAppSysFunc.tcl,v 2.1 2015/03/10 $
#	START:	 2014/12/25
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a system function for automation test
#

package provide autoAppSysFunc 2.1

package require autoAppAlmFunc
package require autoAppPubFunc
package require Ttrace
package require base64
package require dns
package require mime
package require smtp

proc clearTask {} {
	set taskName "java.exe iexplore.exe mshta.exe"
	puts "clear task: $taskName."
	foreach i $taskName {
		catch {exec cmd /c taskkill /f /im $i}
	}	
}

namespace eval scf {
	
	
	array set tmpVars {		
		file_log ""
		log_abs_path ""
		PingIP ""
		threadID_sock ""
		client_ip_list ""
	}
	set scf::tmpVars(code_file) [file join $env(temp) autoApp_qtpSource.tmp]	
	set scf::tmpVars(tmp_file) [file join $env(temp) autoApp_buffer.tmp]	
	
	
	array set scfVariables {
		tclpath ""
		binPath ""
		logPath "D:/Auto/buffer"
		autoloadPath "D:/Auto/tcl"	
		reportPath "D:/Auto/ASM_report"	
		threadID ""		
		emailServer "mail.infogo.com.cn"
		emailSubject "系统邮件-执行事件通知(From TclRunner)"
		emailFrom "Bruce@infogo.com.cn"
		emailTo "jsb@infogo.com.cn pmd_product@infogo.com.cn"
		tr_server_ip "172.17.160.150"
		host_name ""
		host_ip ""
	}
	set scf::scfVariables(host_name) [info hostname]
	
	

	
	
	
	proc getDomainPCAddress {pcname {domain "infogotest.com"} {domainserver 172.17.65.136}} {
		
		
		
		
		
		
		if {![string compare $pcname ""]} {puts "\n\tNot a valid PC name:'$pcname'";return}
		
		
		set iplist [scf::nslookupTcl "$pcname.$domain" $domainserver]
		set len [llength $iplist]
		if {$len == 0} {puts "\n\t'$pcname' is not a valid domain PC in '$domain'";return}
		
		
		foreach ip $iplist {
			if {[scf::isHostReachable $ip]} {break}		
			if {[lsearch $iplist $ip] == [expr $len - 1]} {puts "\n\t'$pcname' do not have a reachable ip in '$iplist'";return}
		}
		
		puts "$pcname.$domain --> $ip"
		return $ip		
	}
	
	
	proc nslookupTcl {query nameserver} {
		
		
		
		if {[catch {set tok [dns::resolve $query -nameserver $nameserver]} res]} {return}
		set st [dns::status $tok]
		if {[string compare $st "ok"] != 0} {dns::cleanup $tok;return}
		
		set name_list [dns::name $tok]
		set ip_list [dns::address $tok]
		dns::cleanup $tok
		return $ip_list		
	}
	
	
	proc isHostReachable {ip} {
		
		
		if {[catch {exec ping $ip -n 1 -4} ping]} {set ping 0}
		if {[lindex $ping 0] == "0"} { 
			puts "\n\tautoAppSysFunc.tcl->Exception1.1: $ip is not reachable"
			return False
		}
		if {[lindex $ping 0] != "0"} {
			if {[regexp { Average = (.*)ms} $ping -> time]} {
				regexp {Reply from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):} $ping -> scf::tmpVars(PingIP)
					
					
					return True
			} elseif {[regexp {平均 = (.*)ms} $ping -> time]} {
				regexp {来自 ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) 的回复:} $ping -> scf::tmpVars(PingIP)
				
				
				return True			
			} else {
				return False
			}
		 }
	}	
	isHostReachable $scf::scfVariables(host_name)
	set $scf::scfVariables(host_ip) $scf::tmpVars(PingIP)	
	
	
	proc listFileTree {rootdir_ fname} {
		
		
		
		
		variable x
		append x ""
		
		set currentnodes [glob -nocomplain -directory $rootdir_ -types d *]
		if {[llength $currentnodes] <= 0} {
		
			set x [concat $x [glob -nocomplain -dir $rootdir_ $fname]]
			
			return
		} else {
			
					
			set x [concat $x [glob -nocomplain -dir $rootdir_ $fname]]
			
			
					
			foreach node $currentnodes {
				listFileTree $node $fname
			}
		}
	}	
	
	
	proc getTclPath {} {	
		global env
		catch {unset scf::scfVariables(tclpath)}				
		set env_path_tmp [split $env(path) {;}]
		foreach i $env_path_tmp {
			if {[regexp {InfogoAuto[\\/]bin|Tcl[\\/]bin} $i match]} {set scf::scfVariables(tclpath) $i;break}
		}
		
		if {[string compare $scf::scfVariables(tclpath) ""] == 0} {
			set scf::scfVariables(tclpath) [file join [file dirname [info nameofexecutable]] tclsh.exe]
		} else {			
			
			set scf::scfVariables(tclpath) [file join $scf::scfVariables(tclpath) "tclsh.exe"]						
		}
		
		if {[file isfile $scf::scfVariables(tclpath)]} {
			puts "\tHave got: $scf::scfVariables(tclpath)"
			return True
		} else {
			puts "\n\tautoAppSysFunc.tcl->Exception2.1: Can't get tcl path"
			return False
		}		
	}
	
	
	proc send_email {from recipient subject body {email_server mail.infogo.com.cn}} {	
		
		
		
		
		
		set token [mime::initialize -canonical text/html -string $body]
		mime::setheader $token Subject $subject
		mime::setheader $token From $from
		catch {
			mime::setheader $token To $recipient
		} res
		puts "set header(To)- $res"
		catch {
			foreach i $recipient {
				smtp::sendmessage $token -recipients $i -servers $email_server
			}
		} res
		puts "send_message- $res"
		mime::finalize $token
	}

	proc send_email_tmp {from to subject body} {
		
		
		
		
		set opts {} 
		
		lappend opts -servers [list mail.infogo.com.cn] 
		lappend opts -ports [list 25] 
		
		
		
		lappend opts -header [list "Subject" $subject] 
		lappend opts -header [list "From" $from] 
		lappend opts -header [list "To" $to] 

		set mime_msg [mime::initialize -canonical "text/html" -string $body]
		smtp::sendmessage $mime_msg {*}$opts -queue false -atleastone false -usetls false
		mime::finalize $mime_msg
	}


	
	proc getPCScripts {pcname} {	
		
		
		
		if {![info exists sc::tkNameVar(scriptList)]} {return False}
		
		set host_dict ""
		foreach {i j} $sc::tkNameVar(scriptList) {
			set host_tmp [dict get $j host_name]
			dict lappend host_dict $host_tmp $i
		}
		set host_dict [string tolower $host_dict]
		if {![dict exists $host_dict $pcname]} {return False}
		
		
		set script_tcl_id [dict get $host_dict $pcname]
		set script_paths ""
		foreach tid $script_tcl_id {
			lappend script_paths [dict get $sc::tkNameVar(scriptList) $tid abs_path]
		}
		return $script_paths
	}
	
	
	proc listenSock {swt {serverIP localhost}} {
		
		
		
		
		
		
		
		
		
		
		
		set request_EXEC_getPCScripts "Type EXEC Name scf::getPCScripts Param $scf::scfVariables(host_name) Data {}"			
		set request_EXIT "Type EXIT Name {} Param {} Data {}"	
		set request_END "Type END Name {} Param {} Data {}"	
		switch $swt {
			"start" {
				
				set scf::tmpVars(threadID_sock) [thread::create {
					package require Ttrace
					package require autoAppActionFunc
					puts "Listen 5821 started."
					thread::wait
				}]
				
				ttrace::eval {package require autoAppActionFunc}
				thread::send -async $scf::tmpVars(threadID_sock) [list server_connect]
				return True
			}
			"connect" {
				
				set result [client_info $serverIP $request_EXEC_getPCScripts]	
				
				switch $result {
					"True" {
						return True
					}
					"False" {
						return False
					}
					default {				
						set sc::tkNameVar(fpath) $result
						
						set CTS_setNSVar_tr_server_ip "Type EXEC Name setNSVar Param {scf::scfVariables(tr_server_ip) $scf::scfVariables(tr_server_ip)} Data {}"	
						set result [client_info $serverIP $CTS_setNSVar_tr_server_ip]
						return True	
					}
				}			
			}
			"disconnect" {
				
				set result [client_info $serverIP $request_EXIT]
				switch $result {					
					"False" {
						return False
					}
					default {						
						return True	
					}
				}			
			}
			"close" {
				
				set a [client_info $serverIP $request_END]
				thread::release
				set scf::tmpVars(threadID_sock) ""
				return True
			}
			default {
				return False
			}
		}
	}
	
	
	proc runScript {scName lgPath} {
		
		
		
		
		if {[regexp {\[ALM\] } $scName match]} {
			set scf::tmpVars(log_abs_path) $lgPath
			if {![alm::getQTPConnection $scName]} {				
				puts "autoApp error has been occured."
			}
		} else {			
			if {[scf::getTclPath] && [catch {exec $scf::scfVariables(tclpath) $scName >&$lgPath} res]} {				
				puts "autoApp error:\n$res."
			}
		}
		thread::release
		puts "Run script complete."
	}
	
	
	proc runScriptBox {id sc_path} {
		
		set date_start [clock format [clock seconds] -format "%Y_%m_%d_%H%M%S"]
		set log [file rootname [file tail $sc_path]]_$date_start.log	
		set scf::tmpVars(log_abs_path) [file join $scf::scfVariables(logPath) $log]
		
		set scf::scfVariables(binPath) [file join [file dirname [info nameofexecutable]] autoApp.bin]		
	
		
		puts "Begin->$date_start"
		puts "Execute list id: $id ->script:$sc_path"
		
		
		set file_ext [file extension $sc_path]
		switch -regexp $file_ext {
			{\.tcl|\.tbc} {puts "tcl script";set qc_judge False}
			default {puts "qtp script";set qc_judge True}
		}
		
		
		
		
		
		set scf::scfVariables(threadID) [thread::create {
			package require Ttrace
			package require autoAppActionFunc
			puts "Running script."
			thread::wait
		}]
		
		ttrace::eval {package require autoAppActionFunc}
		thread::send $scf::scfVariables(threadID) {setNSVar scf::scfVariables(tr_server_ip) $scf::scfVariables(tr_server_ip)}	
		thread::send -async $scf::scfVariables(threadID) [list scf::runScript $sc_path $scf::tmpVars(log_abs_path)]
		
		
		if {$qc_judge} {
			while {![file exists $scf::tmpVars(code_file)]} {continue}
			set a [open $scf::tmpVars(code_file) r+]
		} else {			
			set a [open $sc_path r+]
		}
		set f_line 1
		set sc::tkNameVar(flog) ""
		while {![eof $a]} {lappend sc::tkNameVar(flog) "[format "%8d" $f_line]   [gets $a]";incr f_line;update}
		close $a
		
		
		while {![file exists $scf::tmpVars(log_abs_path)]} {continue}		
		set log_view [open $scf::tmpVars(log_abs_path) r]		
		set sc::tkNameVar(flog2) ""
		set f_line 1
					
		
		while {[thread::exists $scf::scfVariables(threadID)]} {
			set v [gets $log_view]
			if {[string compare $v ""] != 0} {
				lappend sc::tkNameVar(flog2) "[format "%8d" $f_line]  $v"
				incr f_line
				catch {$sc::mapMain(rightListboxDown) yview moveto 1}
			}			
			update
			
			
		}
		
		while {![eof $log_view]} {lappend sc::tkNameVar(flog2) "[format "%8d" $f_line]  [gets $log_view]";incr f_line}
		close $log_view
		
		
		if {$qc_judge} {
			
			set request_EXEC_getAlmQTPScripts "Type EXEC Name getNSVar Param {alm::almVariables(almQTPScriptsDict)} Data {}"
			set result_tmp [client_info $scf::scfVariables(tr_server_ip) $request_EXEC_getAlmQTPScripts]
			if {[lsearch "True False" $result_tmp] == -1} {set alm::almVariables(almQTPScriptsDict) $result_tmp }
			
			set a [open $scf::tmpVars(tmp_file) r];set alm::almVariables(qtpTestScriptsDict) [read $a];close $a
			
			alm::getQCReport QTPPartReport
			catch {file delete $scf::tmpVars(tmp_file)}
		}
		
		set date_end [clock format [clock seconds] -format "%Y_%m_%d_%H%M%S"]
		puts "End->$date_end\n\n"
	}
}
