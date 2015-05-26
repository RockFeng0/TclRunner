#
# autoAppAuthFunc.tcl
# ----------------------------------------------------------------------
# This script is implemented for an authorization of autoApp
# v1.0	Use RSA encryption
# 
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoAppAuthFunc.tcl,v 1.0 2015/03/04 $
#	START:	 2015/03/04
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a system function for automation test
#

package provide autoAppAuthFunc 1.0

package require math::bignum

namespace eval rsaencry {
	variable pub pri n authfile
	array set base {
		P 61
		Q 53
		N 3233
		E 17
		D 2753
	}
	# Turn into bignums:
	set pub [math::bignum::fromstr $base(E)]
	set pri [math::bignum::fromstr $base(D)]
	set n [math::bignum::fromstr $base(N)]
	
	proc rsa { c key pq } {return [math::bignum::powm $c $key $pq]}

	proc encrypt { text key pq } {
		set crypted {}
		foreach char [split $text ""] {			
			lappend crypted [math::bignum::tostr [rsa [math::bignum::fromstr [scan $char %c]] $key $pq]]
		}
		return $crypted
	}

	proc decrypt { crypt key pq } {
		set plain ""
		foreach cypher $crypt {
			append plain [format %c [math::bignum::tostr [rsa [math::bignum::fromstr $cypher] $key $pq]]]
		}
		return $plain
	}
	
	proc getAuthCode {msg} {return [rsaencry::encrypt $msg $rsaencry::pub $rsaencry::n]}
	
	proc getAuthMsg {crypt} {return [rsaencry::decrypt $crypt $rsaencry::pri $rsaencry::n]}
	
	proc verifyAuthCode {} {
		global env
		set licence [file join $env(APPDATA) scr_autoApp.lic]
		
		if {[info exists rsaencry::authfile]} {
			if {[file isfile $rsaencry::authfile]} {file copy -force $rsaencry::authfile $licence}
		}		
		
		if {![file exists $licence]} {return False}
			
		set current_dev_code [getAuthCode [info hostname]]
		set a [open $licence r]
		set result False
		while {![eof $a]} {	
			if {![string compare $current_dev_code [gets $a]]} {set result True;break}
		}
		close $a
		return $result
	}
}

