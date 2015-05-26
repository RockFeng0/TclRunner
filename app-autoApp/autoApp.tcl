#
# autoApp.tcl
# ----------------------------------------------------------------------
# GUI design
# v7.6		add 'preferenceGUI' and 'autoAppMain'
# v7.8		add 'almConnectionGUI' to support ALM/QC
# v7.9		add 'scf::listenSock' to open 5821 port when autoApp has been called
# 			add 'trConnectionGUI' procedure
#			add 'autoAppStartUI' to guide the GUI which contents server and client
#			add 'trClientGUI' which modify from 'trConnectionGUI' to support the client GUI
# v7.9.1	require 'autoAppAuthFunc' pkg for the authorization of autoApp
# v7.9.2	delete procedure 'trConnectionGUI'
#
# ----------------------------------------------------------------------
#   AUTHOR:  Bruce Luo
#	MAIL:	 lkf20031988@163.com
#      RCS:  $Id: autoApp.tcl,v 7.9 2015/03/09 $
#	START:	 2014/12/23
# ----------------------------------------------------------------------
# ======================================================================
#
# Provide a TK view for automation test
#
package provide app-autoApp 7.9
package require Tk
package require Ttk

package require autoAppActionFunc
package require autoAppAuthFunc

proc preferenceGUI {} {
	
	
	

	
	array set sc::mapPre {
		top {.w2}
		frame {.w2.fm}
		scriptLabel {.w2.fm.lbs}
		scriptEntry {.w2.fm.ens}
		scriptButton {.w2.fm.bts}
		frame2 {.w2.fm2}
		logLabel {.w2.fm2.lbl}
		logEntry {.w2.fm2.enl}
		logButton {.w2.fm2.btl}
		frame3 {.w2.fm3}
		reportLabel {.w2.fm3.lbr}
		reportEntry {.w2.fm3.enr}
		reportButton {.w2.fm3.btr}	
		frame4 {.w2.fm4}
		scheduleRunLabel {.w2.fm4.lbr}
		scheduleRunAllEntry {.w2.fm4.enr}
		scheduleRunAllButton {.w2.fm4.btr}
	}
	
	
	
	
	toplevel $sc::mapPre(top)
	wm title $sc::mapPre(top) "Preference"
	wm geometry $sc::mapPre(top) 510x260
	wm resizable $sc::mapPre(top) 0 0

	
	ttk::labelframe $sc::mapPre(frame) -text "Autoload path"
	label $sc::mapPre(scriptLabel) -text "Script load from:" -width 16 -anchor w
	entry $sc::mapPre(scriptEntry) -width 40 -state disable -textvariable scf::scfVariables(autoloadPath)
	button $sc::mapPre(scriptButton) -text "Select dir." -command "sc::selectDir scf::scfVariables(autoloadPath)"
	pack $sc::mapPre(scriptLabel) $sc::mapPre(scriptEntry) -side left
	pack $sc::mapPre(scriptButton) -side left -pady 5 -padx 10
	pack $sc::mapPre(frame) -side top -expand no -fill both -pady 2 -padx 2m
	
	

	
	ttk::labelframe $sc::mapPre(frame2) -text "Logs path"
	label $sc::mapPre(logLabel) -text "Logs save to:" -width 16 -anchor w
	entry $sc::mapPre(logEntry) -width 40 -state disable -textvariable scf::scfVariables(logPath)
	button $sc::mapPre(logButton) -text "Select dir." -command "sc::selectDir scf::scfVariables(logPath)"
	pack $sc::mapPre(logLabel) $sc::mapPre(logEntry) -side left
	pack $sc::mapPre(logButton) -side left -pady 5 -padx 10
	pack $sc::mapPre(frame2) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	
	
	ttk::labelframe $sc::mapPre(frame3) -text "Report path"
	label $sc::mapPre(reportLabel) -text "Analysis from:" -width 16 -anchor w
	entry $sc::mapPre(reportEntry) -width 40 -state  disable -textvariable scf::scfVariables(reportPath)
	button $sc::mapPre(reportButton) -text "Select dir." -command "sc::selectDir scf::scfVariables(reportPath)"
	pack $sc::mapPre(reportLabel) $sc::mapPre(reportEntry) -side left
	pack $sc::mapPre(reportButton) -side left -pady 5 -padx 10
	pack $sc::mapPre(frame3) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	
	
	ttk::labelframe $sc::mapPre(frame4) -text "Run time setup"
	label $sc::mapPre(scheduleRunLabel) -text "Run after(minutes):" -width 16 -anchor w
	entry $sc::mapPre(scheduleRunAllEntry) -width 40 -state $sc::tmpVars(scheduleRunAllEntryState) -validate key -vcmd {expr {[string length %P]<10};string is integer %P} -invalidcommand {puts "String should be integer and lenth <10"} -textvariable scf::tmpVars(schedule_time)
	button $sc::mapPre(scheduleRunAllButton) -text $sc::tmpVars(scheduleRunAllButtonText) -command "sc::scheduleRunner"
	
	pack $sc::mapPre(scheduleRunLabel) $sc::mapPre(scheduleRunAllEntry) -side left	
	pack $sc::mapPre(scheduleRunAllButton) -side left -pady 5 -padx 10
	pack $sc::mapPre(frame4) -side top -expand no -fill both -pady 2 -padx 2m
}

proc almConnectionGUI {} {
	
	
	

	
	array set sc::mapALM {
		top {.w3}
		frame {.w3.fm}
		serverUrlLabel {.w3.fm.lbs1}
		serverUrlEntry {.w3.fm.ens1}
		usernameLabel {.w3.fm.lbs2}
		usernameEntry {.w3.fm.ens2}
		passwordLabel {.w3.fm.lbs3}
		passwordEntry {.w3.fm.ens3}
		connectButton {.w3.fm.bt1}		
		disconnectButton {.w3.fm.bt2}
				
		frame2 {.w3.fm2}
		domainLabel {.w3.fm2.lbl}
		domainEntry {.w3.fm2.enl}
		projectLabel {.w3.fm2.lb2}
		projectEntry {.w3.fm2.en2}		
		loginButton {.w3.fm2.btsl}		
		logoutButton {.w3.fm2.bts2}
			
		frame3 {.w3.fm3}
		loadPathLabel {.w3.fm3.lb3}
		loadPathEntry {.w3.fm3.en3}
		loadButton {.w3.fm3.btl}
		unLoadButton {.w3.fm3.bt2}
	}
	

	
	toplevel $sc::mapALM(top)
	wm title $sc::mapALM(top) "ALM Connection"
	wm geometry $sc::mapALM(top) 436x310
	wm resizable $sc::mapALM(top) 0 0

	
	ttk::labelframe $sc::mapALM(frame) -text "Connect to server."
	label $sc::mapALM(serverUrlLabel) -text "Server URL:" -width 18 -anchor w
	entry $sc::mapALM(serverUrlEntry) -width 40 -state $sc::tmpVars(almConButState) -textvariable alm::almVariables(almServerURL)
	label $sc::mapALM(usernameLabel) -text "Username:" -width 18 -anchor w
	entry $sc::mapALM(usernameEntry) -width 40 -state $sc::tmpVars(almConButState) -textvariable alm::almVariables(almUsername)
	label $sc::mapALM(passwordLabel) -text "Password:" -width 18 -anchor w
	entry $sc::mapALM(passwordEntry) -width 40 -state $sc::tmpVars(almConButState) -textvariable alm::almVariables(almPassword) -show *
	button $sc::mapALM(connectButton) -text "Connect" -state $sc::tmpVars(almConButState) -command "sc::initALM connect"
	button $sc::mapALM(disconnectButton) -text "Disconnect" -state $sc::tmpVars(almDisConButState) -command "sc::initALM disconnect"
	
	grid $sc::mapALM(serverUrlLabel) $sc::mapALM(serverUrlEntry)
	grid $sc::mapALM(usernameLabel) $sc::mapALM(usernameEntry)
	grid $sc::mapALM(passwordLabel) $sc::mapALM(passwordEntry)
	grid $sc::mapALM(connectButton) $sc::mapALM(disconnectButton)	
	pack $sc::mapALM(frame) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	ttk::labelframe $sc::mapALM(frame2) -text "Login to project."
	label $sc::mapALM(domainLabel) -text "Domain:" -width 18 -anchor w
	entry $sc::mapALM(domainEntry) -width 40 -state $sc::tmpVars(almLogButState) -textvariable alm::almVariables(almDomain)			
	label $sc::mapALM(projectLabel) -text "Project:" -width 18 -anchor w
	entry $sc::mapALM(projectEntry) -width 40 -state $sc::tmpVars(almLogButState) -textvariable alm::almVariables(almProject)	
	button $sc::mapALM(loginButton) -text "Login" -state $sc::tmpVars(almLogButState) -command "sc::initALM login"
	button $sc::mapALM(logoutButton) -text "Login out" -state $sc::tmpVars(almLogoutButState) -command "sc::initALM logout"
	
	grid $sc::mapALM(domainLabel) $sc::mapALM(domainEntry)
	grid $sc::mapALM(projectLabel) $sc::mapALM(projectEntry)	
	grid $sc::mapALM(loginButton) $sc::mapALM(logoutButton)	
	pack $sc::mapALM(frame2) -side top -expand no -fill both -pady 2 -padx 2m	
	
	
	ttk::labelframe $sc::mapALM(frame3) -text "QTP path."
	label $sc::mapALM(loadPathLabel) -text "Load QTP from ALM:" -width 18 -anchor w
	entry $sc::mapALM(loadPathEntry) -width 40 -state $sc::tmpVars(almLoadButState) -textvariable alm::almVariables(almQCTestSetPath)	
	button $sc::mapALM(loadButton) -text "Load" -state $sc::tmpVars(almLoadButState) -command "sc::initALM load"
	button $sc::mapALM(unLoadButton) -text "Unload" -state $sc::tmpVars(almUnloadButState) -command "sc::initALM unload"
	
	grid $sc::mapALM(loadPathLabel) $sc::mapALM(loadPathEntry)
	grid $sc::mapALM(loadButton) $sc::mapALM(unLoadButton)	
	pack $sc::mapALM(frame3) -side top -expand no -fill both -pady 2 -padx 2m	
}

proc emailGUI {} {
	
	
	
	
	
	array set sc::mapEmail {
		top {.w4}
		frame {.w4.fm}
		emailServerLabel {.w4.fm.lb1}
		emailServerEntry {.w4.fm.en1}		
		emailSubjectLabel {.w4.fm.lb2}
		emailSubjectEntry {.w4.fm.en2}	
		emailFromLabel {.w4.fm.lb3}
		emailFromEntry {.w4.fm.en3}	
		emailToLabel {.w4.fm.lb4}
		emailToEntry {.w4.fm.en4}
		emailSendButton {.w4.fm.bt1}
		frame2 {.w4.fm2}
		emailTclButton {.w4.fm2.bt1}
		emailQcButton {.w4.fm2.bt2}
		emailQtpButton {.w4.fm2.bt3}
				
	}
	
	
	toplevel $sc::mapEmail(top)
	wm title $sc::mapEmail(top) "TckRunner e-mail"
	wm geometry $sc::mapEmail(top) 485x176
	wm resizable $sc::mapEmail(top) 0 0
	
	
	ttk::labelframe $sc::mapEmail(frame) -text "Email sender box"
	label $sc::mapEmail(emailServerLabel) -text "Email smtp server:" -width 20 -anchor w
	entry $sc::mapEmail(emailServerEntry) -width 45 -state disable -textvariable scf::scfVariables(emailServer)
	label $sc::mapEmail(emailSubjectLabel) -text "Email subject:" -width 20 -anchor w
	entry $sc::mapEmail(emailSubjectEntry) -width 45 -state disable -textvariable scf::scfVariables(emailSubject)	
	label $sc::mapEmail(emailFromLabel) -text "Send from:" -width 20 -anchor w
	entry $sc::mapEmail(emailFromEntry) -width 45 -state normal -textvariable scf::scfVariables(emailFrom)
	label $sc::mapEmail(emailToLabel) -text "Send to:" -width 20 -anchor w
	entry $sc::mapEmail(emailToEntry) -width 45 -state normal -textvariable scf::scfVariables(emailTo)

	grid $sc::mapEmail(emailServerLabel) $sc::mapEmail(emailServerEntry) -sticky nswe
	grid $sc::mapEmail(emailSubjectLabel) $sc::mapEmail(emailSubjectEntry) -sticky nswe
	grid $sc::mapEmail(emailFromLabel) $sc::mapEmail(emailFromEntry) -sticky nswe
	grid $sc::mapEmail(emailToLabel) $sc::mapEmail(emailToEntry) -sticky nswe
	pack $sc::mapEmail(frame) -side top -expand no -fill both -pady 2 -padx 2m	

	
	ttk::labelframe $sc::mapEmail(frame2) -text "Send report with e-mail"
	button $sc::mapEmail(emailTclButton) -text "SendTclReport" -command "sc::mailSender tclHtmlReport"
	button $sc::mapEmail(emailQcButton) -text "SendQcReport" -command "sc::mailSender qcHtmlReport"
	button $sc::mapEmail(emailQtpButton) -text "SendQtpReport" -command "sc::mailSender qtpHtmlReport"
	
	pack $sc::mapEmail(emailTclButton) $sc::mapEmail(emailQcButton) $sc::mapEmail(emailQtpButton) -side left -expand no -fill both -pady 2 -padx 2m	
	pack $sc::mapEmail(frame2) -side top -expand yes -fill both -pady 2 -padx 2m
}

proc trClientGUI {} {
	
	
	

	
	array set sc::mapTR {
		top {.}
		frame {.fm}
		domainServerLabel {.fm.lbs1}
		domainServerEntry {.fm.ens1}
		domainNameLabel {.fm.lbs2}
		domainNameEntry {.fm.ens2}		
		
		frame2 {.fm1}
		hostnameLabel {.fm1.lbs1}
		hostnameEntry {.fm1.ens1}		
		serverIPLabel {.fm1.lbs4}
		serverIPEntry {.fm1.ens5}		
		connectButton {.fm1.bt1}		
		disconnectButton {.fm1.bt2}
		
		frame3 {.fm2}		
		leftListbox {.fm2.list}
		leftXScrollbar {.fm2.xscr}
		leftYScrollbar {.fm2.yscr}		
	}

	
	wm title $sc::mapTR(top) "TclRunner Connection"
	wm geometry $sc::mapTR(top) 441x414
	wm resizable $sc::mapTR(top) 0 0

	
	ttk::labelframe $sc::mapTR(frame) -text "ALM Domain Info."
	label $sc::mapTR(domainServerLabel) -text "Domain server:" -width 18 -anchor w
	entry $sc::mapTR(domainServerEntry) -width 40 -state disable -textvariable alm::almVariables(almDomainServerIP)
	label $sc::mapTR(domainNameLabel) -text "Domain name:" -width 18 -anchor w
	entry $sc::mapTR(domainNameEntry) -width 40 -state disable -textvariable alm::almVariables(almDomainName)
		
	grid $sc::mapTR(domainServerLabel) $sc::mapTR(domainServerEntry)
	grid $sc::mapTR(domainNameLabel) $sc::mapTR(domainNameEntry)	
	pack $sc::mapTR(frame) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	ttk::labelframe $sc::mapTR(frame2) -text "Connect to server."
	label $sc::mapTR(hostnameLabel) -text "Current PC:" -width 18 -anchor w
	entry $sc::mapTR(hostnameEntry) -width 40 -state disable -textvariable scf::scfVariables(host_name)
	label $sc::mapTR(serverIPLabel) -text "TR Server IP:" -width 18 -anchor w
	entry $sc::mapTR(serverIPEntry) -width 40 -state $sc::tmpVars(trConButState) -textvariable scf::scfVariables(tr_server_ip)	
	button $sc::mapTR(connectButton) -text "Connect" -state $sc::tmpVars(trConButState) -command "sc::initTR connect"
	button $sc::mapTR(disconnectButton) -text "Disconnect" -state $sc::tmpVars(trDisConButState) -command "sc::initTR disconnect"
	
	grid $sc::mapTR(hostnameLabel) $sc::mapTR(hostnameEntry)
	grid $sc::mapTR(serverIPLabel) $sc::mapTR(serverIPEntry)	
	grid $sc::mapTR(connectButton) $sc::mapTR(disconnectButton)	
	pack $sc::mapTR(frame2) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	ttk::labelframe $sc::mapTR(frame3) -text "Scripts"
	listbox $sc::mapTR(leftListbox) -xscrollcommand "$sc::mapTR(leftXScrollbar) set" -yscrollcommand "$sc::mapTR(leftYScrollbar) set" -listvariable sc::tkNameVar(fpath)
	scrollbar $sc::mapTR(leftXScrollbar) -orient horizontal -command "$sc::mapTR(leftListbox) xview"
	scrollbar $sc::mapTR(leftYScrollbar) -orient vertical -command "$sc::mapTR(leftListbox) yview"	
		
		
	
	
	
	
	pack $sc::mapTR(leftXScrollbar) -side bottom -fill x
	pack $sc::mapTR(leftYScrollbar) -side right -fill y
	pack $sc::mapTR(leftListbox) -side top -expand no -fill both -pady 2 -padx 2m
	pack $sc::mapTR(frame3) -side top -expand no -fill both -pady 2 -padx 2m	
}

proc autoAppMain {} {
	
	
	
	
	
	
	array set sc::mapMain {
		top {.}
		menuBar {.m}
		menuCasFile {.m.file}
		menuCasEdit {.m.edit}
		menuCasRun {.m.run}
		menuCasReport {.m.report}
		menuCasALM {.m.alm}
		menuCasHelp {.m.help}
		panedWin {.pw}
		frame1 {.pw.left}		
		leftListbox {.pw.left.list}
		leftXScrollbar {.pw.left.xscr}
		leftYScrollbar {.pw.left.yscr}
		leftProgressbar {.pw.left.p1}
		frame2 {.pw.right}
		rightListboxUp {.pw.right.list}
		rightXScrollbarUp {.pw.right.xscr}
		rightYScrollbarUp {.pw.right.yscr}
		rightListboxDown {.pw.right.list2}
		rightXScrollbarDown {.pw.right.xscr2}
		rightYScrollbarDown {.pw.right.yscr2}
		r_progressbar {.pw.right.p2}
	}
	
	
	
	wm title . "Automation Test App"
	wm geometry . 800x600

	option add *Menu.tearOff 0
	
	
	
	
	
	
	
	
	menu $sc::mapMain(menuBar)
	$sc::mapMain(top) configure -menu $sc::mapMain(menuBar)
	$sc::mapMain(menuBar) add cascade -label "文件" -menu $sc::mapMain(menuCasFile)
	$sc::mapMain(menuBar) add cascade -label "编辑" -menu $sc::mapMain(menuCasEdit)
	$sc::mapMain(menuBar) add cascade -label "执行" -menu $sc::mapMain(menuCasRun)
	$sc::mapMain(menuBar) add cascade -label "分析报告" -menu $sc::mapMain(menuCasReport)
	$sc::mapMain(menuBar) add cascade -label "ALM" -menu $sc::mapMain(menuCasALM)
	$sc::mapMain(menuBar) add cascade -label "帮助" -menu $sc::mapMain(menuCasHelp)

	menu $sc::mapMain(menuCasFile)
	$sc::mapMain(menuCasFile) add command -label "加载" -command "sc::loadFile"
	$sc::mapMain(menuCasFile) add command -label "自动加载" -command "sc::autoLoadFile"	
	$sc::mapMain(menuCasFile) add command -label "偏好设置" -command "catch {preferenceGUI}"

	menu $sc::mapMain(menuCasEdit)
	$sc::mapMain(menuCasEdit) add command -label "移除选中项" -command "sc::delSelectFile"
	$sc::mapMain(menuCasEdit) add command -label "列表清空" -command "sc::delAllSelection"

	menu $sc::mapMain(menuCasRun)
	$sc::mapMain(menuCasRun) add command -label "停止" -command "sc::runStop"
	$sc::mapMain(menuCasRun) add command -label "单项运行" -command "sc::scriptRunner Only"
	$sc::mapMain(menuCasRun) add command -label "全部运行" -command "sc::scriptRunner All"	
	
	menu $sc::mapMain(menuCasReport)
	$sc::mapMain(menuCasReport) add command -label "查看原始报告数" -command "sc::csvReportStat"
	$sc::mapMain(menuCasReport) add command -label "生成html统计报告" -command "sc::analysisReport"
	$sc::mapMain(menuCasReport) add command -label "邮件发送html报告" -command "catch {emailGUI}"
	
	menu $sc::mapMain(menuCasALM)
	$sc::mapMain(menuCasALM) add command -label "连接ALM/QC服务器" -command "catch {almConnectionGUI}"		
	
	menu $sc::mapMain(menuCasHelp)
	$sc::mapMain(menuCasHelp) add command -label "版本信息" -command "sc::helpFile"

	
	
	
	
	panedwindow $sc::mapMain(panedWin)
	pack $sc::mapMain(panedWin) -side top -expand yes -fill both -pady 2 -padx 2m
	
	
	
	set f [ttk::labelframe $sc::mapMain(frame1) -text "Scripts"]
	listbox $sc::mapMain(leftListbox) -xscrollcommand "$sc::mapMain(leftXScrollbar) set" -yscrollcommand "$sc::mapMain(leftYScrollbar) set" -listvariable sc::tkNameVar(fpath)
	scrollbar $sc::mapMain(leftXScrollbar) -orient horizontal -command "$sc::mapMain(leftListbox) xview"
	scrollbar $sc::mapMain(leftYScrollbar) -orient vertical -command "$sc::mapMain(leftListbox) yview"
	ttk::progressbar $sc::mapMain(leftProgressbar) -mode determinate
		
	pack $sc::mapMain(leftProgressbar) -side bottom -fill x
	pack $sc::mapMain(leftXScrollbar) -side bottom -fill x
	pack $sc::mapMain(leftYScrollbar) -side right -fill y
	pack $sc::mapMain(leftListbox) -fill both -expand 1

	
	
	set f [ttk::labelframe $sc::mapMain(frame2) -text "Debugging And Output Info"]	
	listbox $sc::mapMain(rightListboxUp) -xscrollcommand "$sc::mapMain(rightXScrollbarUp) set" -yscrollcommand "$sc::mapMain(rightYScrollbarUp) set" -listvariable sc::tkNameVar(flog) -height 20
	scrollbar $sc::mapMain(rightXScrollbarUp) -orient horizontal -command "$sc::mapMain(rightListboxUp) xview"
	scrollbar $sc::mapMain(rightYScrollbarUp) -orient vertical -command "$sc::mapMain(rightListboxUp) yview"
	listbox $sc::mapMain(rightListboxDown) -xscrollcommand "$sc::mapMain(rightXScrollbarDown) set" -yscrollcommand "$sc::mapMain(rightYScrollbarDown) set" -listvariable sc::tkNameVar(flog2) -height 20
	scrollbar $sc::mapMain(rightXScrollbarDown) -orient horizontal -command "$sc::mapMain(rightListboxDown) xview"
	scrollbar $sc::mapMain(rightYScrollbarDown) -orient vertical -command "$sc::mapMain(rightListboxDown) yview"
	ttk::progressbar $sc::mapMain(r_progressbar) -mode determinate
	
		
	grid $sc::mapMain(rightListboxUp) $sc::mapMain(rightYScrollbarUp) -sticky nsew
	grid $sc::mapMain(rightXScrollbarUp)         -sticky nsew
	grid $sc::mapMain(rightListboxDown) $sc::mapMain(rightYScrollbarDown) -sticky nsew
	grid $sc::mapMain(rightXScrollbarDown)         -sticky nsew
	grid $sc::mapMain(r_progressbar)			 -sticky nsew
	grid columnconfigure $sc::mapMain(frame2) 0 -weight 1
	grid rowconfigure    $sc::mapMain(frame2) 0 -weight 1
	
	
	
	
	
	$sc::mapMain(panedWin) paneconfigure -orient horizontal
	$sc::mapMain(panedWin) add $sc::mapMain(frame1) $sc::mapMain(frame2)	
	pack $sc::mapMain(panedWin) -side top -expand yes -fill both -pady 2 -padx 2m	
}

proc autoAppStartUI {} {
	
	
	
	
	
	array set sc::mapStartUI {
		top {.}
		frame {.fm}
		serverButton {.fm.bt1}
		
		frame2 {.fm1}			
		clientButton {.fm1.bt1}
	}
	
	
	
	wm title $sc::mapStartUI(top) "TclRunner Program"
	wm geometry $sc::mapStartUI(top) 484x136+437+281
	wm resizable $sc::mapStartUI(top) 1 1

	
	ttk::labelframe $sc::mapStartUI(frame) -text "TclRunner Server"
	button $sc::mapStartUI(serverButton) -text "Start-Server" -state normal -command "sc::startTclRunner server"
		
	pack $sc::mapStartUI(serverButton) -side top -expand yes -fill both
	pack $sc::mapStartUI(frame) -side top -expand yes -fill both -pady 2 -padx 2m

	
	ttk::labelframe $sc::mapStartUI(frame2) -text "TclRunner Client"	
	button $sc::mapStartUI(clientButton) -text "Start-Client" -state normal -command "sc::startTclRunner client"
	
	pack $sc::mapStartUI(clientButton) -side top -expand yes -fill both
	pack $sc::mapStartUI(frame2) -side top -expand yes -fill both -pady 2 -padx 2m
}

proc autoAppAuthMain {} {
	
	
	
	
	global env
	
	array set sc::mapAuthMain {
		top {.}
		frame {.fm}
		authLabel {.fm.lb}
		authEntry {.fm.en}
		authButton1 {.fm.bt1}
		authButton2 {.fm.bt2}
		frame1 {.fm1}
		submitButton {.fm1.bt1}
		cancelButton {.fm1.bt2}		
	}
	
	
	
	wm title $sc::mapAuthMain(top) "TclRunner Licence."
	wm geometry $sc::mapAuthMain(top) 620x120+437+281
	wm resizable $sc::mapAuthMain(top) 1 1	

	
	
	ttk::labelframe $sc::mapAuthMain(frame) -text "TclRunner Licence Path"		
	label $sc::mapAuthMain(authLabel) -text "Licence load from:" -width 16 -anchor w
	entry $sc::mapAuthMain(authEntry) -width 40 -state disable -textvariable rsaencry::authfile
	button $sc::mapAuthMain(authButton1) -text "Select dir." -command "sc::loadFile licence"	
	button $sc::mapAuthMain(authButton2) -text "Apply for." -command "sc::applyLicence encode64";
	
	pack $sc::mapAuthMain(authLabel) -side left
	pack $sc::mapAuthMain(authEntry) -side left -pady 5 -padx 10
	pack $sc::mapAuthMain(authButton1) -side left -pady 5 -padx 10
	pack $sc::mapAuthMain(authButton2) -side left -pady 5 -padx 10
	pack $sc::mapAuthMain(frame) -side top -expand no -fill both -pady 2 -padx 2m
	
	
	ttk::labelframe $sc::mapAuthMain(frame1) -text "Agreement"			
	button $sc::mapAuthMain(submitButton) -text "load" -state normal -command "sc::loadLicence"
	button $sc::mapAuthMain(cancelButton) -text "cancel" -state normal -command "catch {unset rsaencry::authfile};exit"
	
	pack $sc::mapAuthMain(submitButton) -side left -expand yes -fill both
	pack $sc::mapAuthMain(cancelButton) -side left -expand yes -fill both
	pack $sc::mapAuthMain(frame1) -side top -expand yes -fill both -pady 2 -padx 2m		
}

if {[rsaencry::verifyAuthCode]} {
	puts "已经授权的设备"
	
	autoAppStartUI
} else {
	puts "未被授权的设备"
	
	autoAppAuthMain	
}

