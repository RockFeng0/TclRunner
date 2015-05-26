#
# autoAppPubFunc.tcl
# ----------------------------------------------------------------------
# This script is impelement for public functins
# v1.0		add socket procedure 'timeout' 'client_info' 'server_connect'
# v1.0.1	improve the registry command which defines by 'after'
#			improve 'server_connect' with kill the port process which is occupied
# 
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoAppPubFunc.tcl,v 1.0 2015/03/12 $
#	START:	 2015/01/26
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a system function for automation test
#

package provide autoAppPubFunc 1.0

proc timeout {msg} {
	
	
	
	
	global Timeout_Tag
	puts stderr $msg
	set Timeout_Tag true
}






proc setGlobalVar {var value} {global $var;set $var $value}
proc getGlobalVar {var} {global $var;return [subst $$var]}
proc setNSVar {var value} {set $var $value}
proc getNSVar {var} {return [subst $$var]}
proc getFileCont {file_abs_path} {
	
	
	if {![file isfile $file_abs_path]} {return}
	set a [open $file_abs_path r]
	fconfigure $a -encoding utf-8;
	set b [read $a];close $a
	return $b
}
	

proc client_info {server_ip request {timeout_min 5}} {
	global c_handle Timeout_Tag server_result
	catch {unset Timeout_Tag}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	proc waitforServerResp {sock interv} {			
		global Timeout_Tag server_result
		
		
		set value ""
		set is_dict "False"
		set response_key {Type Resp Rest Over}
		
		if {[eof $sock] || [catch {set value [read $sock]}]} {		
			puts "\n\tThe End Of Sock."			
			set Timeout_Tag True
			return
		}
		if {[string compare $value ""] != 0} {		
			puts "\n\nClient Info:\n\t+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			
			
			
			foreach key $response_key {
				set dict_over [dict exists $value $key]
				if {$dict_over == 0} {break}
			}
			
			
			set string_over [regexp {Over True|Over False} $value match]
		
			if {$dict_over} {					
				puts "\n\tDict Info End."
				set is_dict "True"				
				set dict_value $value
			} elseif {$string_over} {
				puts "\n\tSegment Info End."
				
				append server_result $value
				set dict_value $server_result
				set is_dict "True"
			} else {				 
				
				append server_result $value
				puts "\n\tSegment Info."
				set is_dict "False"
			}
			if {$is_dict} {
				set st [catch {
					set type [dict get $dict_value Type]
					set resp [dict get $dict_value Resp]
					set server_result [dict get $dict_value Rest]
				} res]
				
				if {$st} {
					puts "\n\tThis request lead to a invalid response:$res."
				} elseif {$resp} {			
					set Timeout_Tag False
					return
				} else {
					puts "\n\tThis request is used for releting the connection."
				}
				puts "\n\tServerResponse# Type: $type - Resp: $resp - Over: $dict_over"
			}	
			
			puts "\n\t+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\nClient Info End."			
		}
		after $interv waitforServerResp "$sock" $interv
	}
	
	set client_result False	
	
	set request_field "Type Name Param Data"
	set type_field "DATA EXEC EXIT END"
	
	
	if {[catch {set keys [dict keys $request]} res]} {error "not a valid request."}	
	foreach key $keys {
		if {[lsearch $request_field $key] == -1} {puts "\n\tnot a valid request field '$key'";return $client_result}
	}
	set type [dict get $request Type]
	set name [dict get $request Name]
	if {[lsearch $type_field $type] == -1} {puts "\n\tnot a valid type field";return $client_result}
	
	
	
	set con_judge [info exists c_handle(addr,$server_ip)]	
	set new_con "False"
	if {$con_judge} {
		
		set valid_con_judge [catch {puts $c_handle(addr,$server_ip) $request} res]
		if {$valid_con_judge} {
			set new_con "True"
			puts "Not a usefull connection '$res',will create a new connection."
		} else {
			puts "\n\n----------Client Send Request# Type $type Name $name"
		}
	} else {
		set new_con "True"
		puts "Will create a new connection."		
	}
	
	
	if {$new_con} {
		
		set port 5821		
		if {[catch {set c_handle(addr,$server_ip) [socket $server_ip $port]} res]} {puts "\n\t $res";return $client_result}
		
		fconfigure $c_handle(addr,$server_ip) -buffering none -blocking 0
		puts "Create connection complete."
		puts $c_handle(addr,$server_ip) $request
		
		puts "\n\n----------Client Send Request# Type $type Name $name"
	}
	
	
	set timeout_handle [after [expr $timeout_min * 60 * 1000] {timeout "client_info: Time has run out, stopping."}]
	waitforServerResp "$c_handle(addr,$server_ip)" "1000"	
	after 2000 {puts "\tSuccessfully listen 5821 handle."}
	
	vwait Timeout_Tag		
	puts "[after info]"
	
	after cancel $timeout_handle
	puts "----------Release timeout command."	
	
	
	
	if {$Timeout_Tag} {		
		return $client_result
	} else {
		if {[info exists server_result] && [string compare $server_result ""] !=0} {
			set client_result $server_result
			unset server_result
		} else {
			set client_result True
		}		
	}
	
	
	set disconnect_list "EXIT END"
	if {[lsearch $disconnect_list $type] != -1} {
		
		
		catch {close $c_handle(addr,$server_ip)}
		catch {unset c_handle(addr,$server_ip)}
	}
	
	
	return $client_result
}
proc server_connect {} {
	global sock_arr end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	array set sock_arr ""	
	
	proc Accept {src_sock src_ip src_port} {	
		global sock_arr				
		set sock_arr(addr,$src_sock) [list $src_ip $src_port]			
		if {[catch {parray sock_arr} res]} {
			foreach name [array names sock_arr] {
				puts "sock_arr($name)\t=\t$sock_arr($name)"
			}
		}
		fconfigure $src_sock -blocking 0 -buffering none
		fileevent $src_sock readable [list Guide $src_sock]		
	}

	proc Guide {sock} {
		global sock_arr end
		
		
		
		if {[eof $sock] || [catch {set request [read $sock]}]} {return}
		if {$request == ""} {return}
		
		
		puts "\n\nServer Info:\n>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"			
		set request_field "Type Name Param Data"
		set type_field "DATA EXEC EXIT END"		
		
		foreach field $request_field {
			if {[lsearch $request $field] == -1} {puts "Invalid request '$request'";return}
		}
		set st [catch {
			set type [dict get $request Type]
			set name [dict get $request Name]
			set param [dict get $request Param]
			set data [dict get $request Data]
		} res]
		if {$st} {puts "Invalid dict request '$request'";return}		
		
		if {[lsearch $type_field $type] == -1} {puts "Invalid field '$type'";return}
		
		
		set response {Type "" Resp "False" Rest "" Over "True"}
		dict set response Type $type
		
		puts stdout "Received request: '$request'"		
		if {[catch {puts $sock $response;flush $sock} res] && [regexp {reset by peer} $res]} {
			puts "$res\n\tWill closing current connection."
			set type "EXIT"
		}
		after 1000
		switch $type {
			"DATA" {
				flush $sock
				puts "Data: $data"
				if {[string compare $data "SOCK_VOLIDATION"] == 0} {puts "Already connect."}
				
				dict set response Resp True
				puts $sock $response
			}
			"EXEC" {				
				
				if {[catch {eval "$name $param"} res]} {
					puts "---- exec error: $res"					
				} else {
					
					puts "---- exec complete."
				}
				dict set response Resp True
				dict set response Rest "$res"
				puts $sock $response
				flush $sock
			}
			"EXIT" {
				
				dict set response Resp True
				puts $sock $response
				flush $sock				
				unset sock_arr(addr,$sock)
				parray sock_arr
			}
			"END" {
				
				dict set response Resp True
				puts $sock $response
				flush $sock
				unset sock_arr(addr,$sock)
				close $sock_arr(main)
				unset sock_arr(main)
				set end " "
			}
			default {
				dict set response Resp "True"
				dict set response Rest "None"
				puts $sock $response
				flush $sock
			}
		}
		puts "<+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\nServer Info End"		
	}
	
	set port 5821
	
	catch {set a [open "|netstat -nao | findstr 5821" r];set b [read $a];close $a}	
	if {[regexp {0.0.0.0:5821.*LISTENING.* (\d+)} $b match pid_tmp]} {
		
		close [open "|taskkill /f /pid $pid_tmp"]
		after 500
	}
	
	set sock_arr(main) [socket -server Accept $port]
	set sock_tag [open c:/tag.tmp w+];close $sock_tag
	if {[file exists c:/tag.tmp]} {
		puts "Succesfully create tag.tmp"
	} else {
		file copy c:/ip.tmp c:/tag.tmp
		puts "Succesfully copy to tag.tmp"
	}
	vwait end
}
