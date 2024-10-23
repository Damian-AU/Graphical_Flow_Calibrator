### By Damian Brakel ###
set plugin_name "Graphical_Flow_Calibrator"

if {![info exist ::settings(calibration_flow_multiplier_default)]} {
    set ::settings(calibration_flow_multiplier_default) $::settings(calibration_flow_multiplier)
}
if {![info exist ::settings(calibration_flow_multiplier_profiles)]} {
    set ::settings(calibration_flow_multiplier_profiles) {}
}
set ::gfc_espresso_profile_title $::settings(profile_title)
if {[info exist ::settings(espresso_clock)]} {
    set ::gfc_espresso_clock $::settings(espresso_clock)
} else {
    set ::gfc_espresso_clock 1722382437
}
set ::gfc_flow_cal_showing $::settings(calibration_flow_multiplier)
set ::gfc_flow_cal_history $::settings(calibration_flow_multiplier)
set ::gfc_espresso_profile_cal_value $::settings(calibration_flow_multiplier_default)
set ::gfc_flow_cal_profile_backup 1
if {$::gfc_espresso_profile_title in $::settings(calibration_flow_multiplier_profiles) == 1 } {
    set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::gfc_espresso_profile_title]
    set ::gfc_espresso_profile_cal_value [lindex $::settings(calibration_flow_multiplier_profiles) [expr {$idx + 1}]]
}
set ::gfc_history_file 0
set ::gfc_orig_flow ""
set ::gfc_espresso_flow ""
if {$::settings(skin) == "DSx2"} {
    set ::gfc_orig_flow $::skin_graphs(live_graph_espresso_flow)
    set ::gfc_espresso_flow $::skin_graphs(live_graph_espresso_flow)
}

namespace eval ::plugins::${plugin_name} {
    variable author "Damian"
    variable contact "via Diaspora"
    variable description "Adjust flow calibration using historic shot graphs and per profile calibration"
    variable version 2.8
    variable min_de1app_version {1.43.12}

    proc main {} {
        plugins gui Graphical_Flow_Calibrator "GFC"
    }

    set page_name "GFC"
    set background_colour #fff
    set disabled_colour #ccc
    set foreground_colour #2b6084
    set button_label_colour #fAfBff
    set text_colour #2b6084
    set red #DA515E
    set green #0CA581
    set blue #49a2e8
    set brown #A1663A
    set orange #fe7e00
    set font "notosansuiregular"
    set font_bold "notosansuibold"

    dui add dbutton "calibrate" 1450 1460 -style insight_ok -anchor nw -command {page_show GFC} -label_width 400 -label_font [dui font get $font 14] -label [translate "Graphical Flow Calibrator"]
    dui add canvas_item rect $page_name 0 0 2560 1600 -fill $background_colour -width 0
    dui add dtext $page_name 1280 100 -text [translate "Graphical Flow Calibrator (GFC)"] -font [dui font get $font_bold 28] -fill $text_colour -anchor "center" -justify "center"
    dui add variable $page_name 2510 1560 -font [dui font get $font 12] -fill $text_colour -anchor e -justify right -textvariable {Version $::plugins::Graphical_Flow_Calibrator::version  by $::plugins::Graphical_Flow_Calibrator::author}
    add_de1_widget GFC graph 30 280 {
        set ::gfc_graph $widget
        bind $widget [platform_button_press] {}
        $widget element create gfc_pressure -xdata espresso_elapsed -ydata espresso_pressure -symbol none -label "" -linewidth [rescale_x_skin 10] -color #0CA581 -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
        $widget element create gfc_flow -xdata espresso_elapsed -ydata espresso_flow -symbol none -label "" -linewidth [rescale_x_skin 10] -color #49a2e8 -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
        $widget element create gfc_weight -xdata espresso_elapsed -ydata espresso_flow_weight -symbol none -label "" -linewidth [rescale_x_skin 10] -color #A1663A -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
        $widget axis configure x -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0;
        $widget axis configure y -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0 -max 10 -subdivisions 1 -majorticks {0  2  4  6  8  10  12} -hide 0;
        $widget axis configure y2 -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0 -max 5 -subdivisions 1 -majorticks {0  1  2  3  4  5  6} -hide 1;
        $widget grid configure -color #2b6084 -dashes {2 12} -linewidth 1
    } -plotbackground $background_colour -width [rescale_x_skin 1900] -height [rescale_y_skin 990] -borderwidth 1 -background $background_colour -plotrelief flat -initial_state normal
    dui add variable $page_name 100 1280 -font [dui font get $font 14] -fill $text_colour -anchor w -textvariable {$::gfc_espresso_profile_title [::plugins::Graphical_Flow_Calibrator::time_format $::gfc_espresso_clock]}
    dui add dbutton $page_name 2000 340 -bwidth 520 -bheight 800 -width 2 -shape outline -outline $foreground_colour -command {}
    dui add dtext $page_name 2260 390 -font [dui font get $font_bold 20] -text [translate "Calibrator"] -fill $text_colour -anchor center
    dui add dtext $page_name 2260 570 -font [dui font get $font 14] -text [translate "tap to update"] -fill #ccc -anchor center
    dui add dtext $page_name 2160 490 -font [dui font get $font 14] -text [translate "default"] -fill $text_colour -anchor center
    dui add dtext $page_name 2360 490 -font [dui font get $font 14] -text [translate "profile"] -fill $text_colour -anchor center
    dui add variable $page_name 2160 530 -font [dui font get $font_bold 18] -fill $text_colour -anchor center -textvariable {$::settings(calibration_flow_multiplier_default)}
    dui add variable $page_name 2360 530 -font [dui font get $font_bold 18] -fill $text_colour -anchor center -tags gfc_espresso_profile_cal_value -textvariable {$::gfc_espresso_profile_cal_value}
    dui add dbutton $page_name 2100 470 -bwidth 120 -bheight 120 \
        -command {::plugins::Graphical_Flow_Calibrator::save_default_flow_cal}
    dui add dbutton $page_name 2300 470 -bwidth 120 -bheight 120 \
       -command {::plugins::Graphical_Flow_Calibrator::save_profile_flow_cal}
    dui add dtext $page_name 2340 800 -font [dui font get $font 14] -text [translate "showing"] -fill $text_colour -anchor w
    dui add variable $page_name 2260 800 -font [dui font get $font_bold 18] -fill $text_colour -anchor center -textvariable {$::gfc_flow_cal_showing}
    dui add dbutton $page_name 2200 670 -bwidth 120 -bheight 100 \
        -shape round -fill $foreground_colour -radius 60 \
        -label \Uf106 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill $button_label_colour -label_pos {0.5 0.5} \
        -command {::plugins::Graphical_Flow_Calibrator::flow_cal_up}
    dui add dbutton $page_name 2200 832 -bwidth 120 -bheight 100 \
        -shape round -fill $foreground_colour -radius 60 \
        -label \Uf107 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill $button_label_colour -label_pos {0.5 0.5} \
        -command {::plugins::Graphical_Flow_Calibrator::flow_cal_down}
    dui add dtext $page_name 2260 1024 -font [dui font get $font 15] -text [translate "select a"] -fill $text_colour -anchor center
    dui add dtext $page_name 2260 1060 -font [dui font get $font 15] -text [translate "graph"] -fill $text_colour -anchor center
    dui add dbutton $page_name 2070 1000 -bwidth 100 -bheight 100 -tags select_older_button \
        -label \Uf104 -label_font [dui font get "Font Awesome 5 Pro-light-300" 28] -label_disabledfill $disabled_colour -label_fill $text_colour -label_pos {0.5 0.5} \
        -command {
            ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file 1
        }
    dui add dbutton $page_name 2350 1000 -bwidth 100 -bheight 100 -tags select_newer_button -initial_state disabled \
        -label \uf105 -label_font [dui font get "Font Awesome 5 Pro-light-300" 28] -label_disabledfill $disabled_colour -label_fill $text_colour -label_pos {0.5 0.5} \
        -command {
            ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file -1
        }
    dui add dtext $page_name 2260 1220 -font [dui font get $font 14] -text [translate "It is best to adjust flow rate data for where the pressure curve is flat"] -width 480 -fill $orange -anchor center -justify center
    dui add dbutton $page_name 1080 1440 \
        -bwidth 400 -bheight 120 \
        -shape round -fill $foreground_colour -radius 60\
        -label [translate "Exit"] -label_font [dui font get $font_bold 18] -label_fill $button_label_colour -label_pos {0.5 0.5} \
        -command {::plugins::Graphical_Flow_Calibrator::exit}

    proc history_list {{limit 7}} {
        set result {}
        set files [lsort -dictionary -decreasing [glob -nocomplain -tails -directory "[homedir]/history/" *.shot]]
        set history_count [llength $files]
        set count 0
        foreach file $files {
            set tailname [file tail $file]
            if {$count == $limit} {
                break;
            }
            lappend result $tailname
            incr count
        }
        return $result
    }

    proc history_position { pos } {
        set list [::plugins::Graphical_Flow_Calibrator::history_list]
        set name [lindex $list $pos 0]
        return $name
    }

    proc graph_list {} {
        return [list \
            espresso_elapsed \
            espresso_pressure \
            espresso_flow \
            espresso_flow_weight \
        ]
    }

    proc load_GFC_graph {pos direction} {
        set p [expr $pos + $direction]
        if {$p < 0} {
            return
        }
        if {$p > 6} {
            return
        }

        if {$pos == 1 && $direction == -1} {
            ::plugins::Graphical_Flow_Calibrator::disable select_newer_button
        }
        if {$pos == 0 && $direction == 1} {
            ::plugins::Graphical_Flow_Calibrator::enable select_newer_button
        }
        if {$pos == 5 && $direction == 1} {
            ::plugins::Graphical_Flow_Calibrator::disable select_older_button
        }
        if {$pos == 6 && $direction == -1} {
            ::plugins::Graphical_Flow_Calibrator::enable select_older_button
        }

        ::plugins::Graphical_Flow_Calibrator::clear_GFC_graph
        set file_name [::plugins::Graphical_Flow_Calibrator::history_position $p]
        array set history_data [read_file "[homedir]/history/$file_name"]
        foreach lg [::plugins::Graphical_Flow_Calibrator::graph_list] {
            $lg length 0
            $lg append $history_data($lg)
        }

        set ::gfc_orig_flow $history_data(espresso_flow)
        set ::gfc_espresso_flow $history_data(espresso_flow)
        espresso_flow length 0


        if {[info exists history_data(settings)] == 1} {
            array set h_settings $history_data(settings)
        }
        if {[info exists h_settings(profile_title)] == 1} {
            set ::gfc_espresso_profile_title $h_settings(profile_title)
        }
        if {[info exists history_data(clock)] == 1} {
            set ::gfc_espresso_clock $history_data(clock)
        }
        if {[info exists h_settings(calibration_flow_multiplier)] == 1} {
            set ::gfc_flow_cal_showing $h_settings(calibration_flow_multiplier)
            set ::gfc_flow_cal_history $h_settings(calibration_flow_multiplier)
        }
        foreach flow $::gfc_espresso_flow {
            espresso_flow append [expr $::gfc_flow_cal_showing * $flow / $::gfc_flow_cal_history]
        }
        set ::gfc_history_file [expr $::gfc_history_file + $direction]
        if {$::gfc_espresso_profile_title in $::settings(calibration_flow_multiplier_profiles) == 1 } {
            set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::gfc_espresso_profile_title]
            set ::gfc_espresso_profile_cal_value [lindex $::settings(calibration_flow_multiplier_profiles) [expr {$idx + 1}]]
            dui item config GFC gfc_espresso_profile_cal_value -fill $::plugins::Graphical_Flow_Calibrator::text_colour
        } else {
            set ::gfc_espresso_profile_cal_value $::settings(calibration_flow_multiplier_default)
            dui item config GFC gfc_espresso_profile_cal_value -fill $::plugins::Graphical_Flow_Calibrator::disabled_colour
        }
    }

    proc clear_GFC_graph {} {
        espresso_elapsed length 0
        espresso_pressure length 0
        espresso_flow_weight length 0
        espresso_weight length 0

    }

    proc time_format { time } {
        set date [clock format $time -format {%a %d}]
        if {$::settings(enable_ampm) == 0} {
            set a [clock format $time -format {%H}]
            set b [clock format $time -format {:%M}]
            set c $a
        } else {
            set a [clock format $time -format {%I}]
            set b [clock format $time -format {:%M}]
            set c $a
            regsub {^[0]} $c {\1} c
        }
        if {$::settings(enable_ampm) == 1} {
            set pm [clock format $time -format %P]
        } else {
            set pm ""
        }
        set s {  }
        return "$s$s$s$date$s$c$b$pm"
    }

    proc flow_cal_up {} {
        if {$::gfc_orig_flow == ""} {
            ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file 0
        }
        if {$::gfc_flow_cal_showing >= 2.0} {
            popup [translate "maximum setting reached"]
            return
        }
        set ::gfc_flow_cal_showing [round_to_two_digits [expr $::gfc_flow_cal_showing + 0.01]]
        espresso_flow length 0
        foreach flow $::gfc_espresso_flow {
            espresso_flow append [expr $::gfc_flow_cal_showing * $flow / $::gfc_flow_cal_history]
        }
    }

    proc flow_cal_down {} {
        if {$::gfc_orig_flow == ""} {
            ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file 0
        }
        if {$::gfc_flow_cal_showing <= 0.35} {
            popup [translate "minimum setting reached"]
            return
        }
        set ::gfc_flow_cal_showing [round_to_two_digits [expr $::gfc_flow_cal_showing - 0.01]]
        espresso_flow length 0
        foreach flow $::gfc_espresso_flow {
            espresso_flow append [expr $::gfc_flow_cal_showing * $flow / $::gfc_flow_cal_history]
        }
    }

    proc save_default_flow_cal {} {
        set ::settings(calibration_flow_multiplier) $::gfc_flow_cal_showing
        set ::settings(calibration_flow_multiplier_default) $::gfc_flow_cal_showing
        save_settings
        set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
    }

    proc save_profile_flow_cal {} {
        set ::settings(calibration_flow_multiplier) $::gfc_flow_cal_showing
        set ::gfc_espresso_profile_cal_value $::gfc_flow_cal_showing
        if {$::gfc_espresso_profile_title in $::settings(calibration_flow_multiplier_profiles) == 0 } {
            if {$::settings(calibration_flow_multiplier_default) != $::gfc_espresso_profile_cal_value} {
                lappend ::settings(calibration_flow_multiplier_profiles) {*}[list $::gfc_espresso_profile_title $::settings(calibration_flow_multiplier)]
                dui item config GFC gfc_espresso_profile_cal_value -fill $::plugins::Graphical_Flow_Calibrator::text_colour
            }
        } else {
            set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::gfc_espresso_profile_title]
            if {$::settings(calibration_flow_multiplier_default) != $::gfc_espresso_profile_cal_value} {
                set ::settings(calibration_flow_multiplier_profiles) [lreplace $::settings(calibration_flow_multiplier_profiles) $idx [expr {$idx + 1}] $::gfc_espresso_profile_title $::settings(calibration_flow_multiplier) ]
            } else {
                set ::settings(calibration_flow_multiplier_profiles) [lreplace $::settings(calibration_flow_multiplier_profiles) $idx [expr {$idx + 1}]]
                dui item config GFC gfc_espresso_profile_cal_value -fill $::plugins::Graphical_Flow_Calibrator::disabled_colour
            }
        }
        save_settings
        set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
    }

    proc save_profile_flow_cal_s1 {} {
        set ::settings(calibration_flow_multiplier) $::gfc_flow_cal_showing
        set ::gfc_espresso_profile_cal_value $::gfc_flow_cal_showing
        if {$::settings(profile_title) in $::settings(calibration_flow_multiplier_profiles) == 0 } {
            if {$::settings(calibration_flow_multiplier_default) != $::gfc_espresso_profile_cal_value} {
                lappend ::settings(calibration_flow_multiplier_profiles) {*}[list $::settings(profile_title) $::settings(calibration_flow_multiplier)]
            }
        } else {
            set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::settings(profile_title)]
            if {$::settings(calibration_flow_multiplier_default) != $::gfc_espresso_profile_cal_value} {
                set ::settings(calibration_flow_multiplier_profiles) [lreplace $::settings(calibration_flow_multiplier_profiles) $idx [expr {$idx + 1}] $::settings(profile_title) $::settings(calibration_flow_multiplier) ]
            } else {
                set ::settings(calibration_flow_multiplier_profiles) [lreplace $::settings(calibration_flow_multiplier_profiles) $idx [expr {$idx + 1}]]
            }
        }
        save_settings
        set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
    }

    proc disable {button} {
        dui item config GFC $button* -state disabled
    }

    proc enable {button} {
        dui item config GFC $button* -state normal
    }

    proc exit {} {
        ::plugins::Graphical_Flow_Calibrator::clear_GFC_graph
        if {$::settings(skin) == "DSx"} {restore_DSx_live_graph}
        if {$::settings(skin) == "DSx2"} {restore_live_graphs}
        #set_next_page off off
        #dui page load off
        dui page load $::gfc_start_page
        set ::gfc_history_file 0
    }
}

proc ::flow_calibration_multiplier_type {} {
    if {$::settings(calibration_flow_multiplier) == $::settings(calibration_flow_multiplier_default)} {
        return "default"
    } else {
        return "custom"
    }
}
proc ::preset_page_flow_cal_label {} {
    if {[ifexists ::profiles_hide_mode] == 1} {
        return ""
    } else {
        set l [translate "Calibration"]
        set c $::settings(calibration_flow_multiplier)
        if {$::settings(calibration_flow_multiplier) == $::settings(calibration_flow_multiplier_default)} {
            set t [translate "default"]
        } else {
            set t [translate "custom"]
        }
        set s { }
        return $l$s$s$c$s$s$t
    }
}

$::preview_graph_pressure configure -height [rescale_y_skin 430]
$::preview_graph_flow configure -height [rescale_y_skin 430]
$::preview_graph_advanced configure -height [rescale_y_skin 430]

#dui add dtext settings_1 1360 750 -font [dui font get "notosansuibold" 16] -text [translate "Flow calibration"] -fill #7f879a -anchor w
dui add variable settings_1 1360 750 -font [dui font get "notosansuiregular" 16] -fill #4e85f4 -anchor w -textvariable {[preset_page_flow_cal_label]}

dui add dbutton settings_1 1320 710 \
    -bwidth 1000 -bheight 90 \
    -labelvariable {} -label_font [dui font get "notosansuiregular" 16] -label_fill #7f879a -label_pos {0.5 0.5} \
-command {page_show GFC} -longpress_cmd {show_GFC_profile_setting}

proc ::show_GFC_profile_setting {} {
    dui item config settings_1 GFC_profile_setting -state normal
}

proc ::hide_GFC_profile_setting {} {
    dui item config settings_1 GFC_profile_setting -initial_state hidden -state hidden
}

dui add shape rect settings_1 1080 270 1300 1400 -width 1 -outline #fff -fill #fff -tags {GFC_profile_setting_bg GFC_profile_setting} -initial_state hidden
dui add dbutton settings_1 0 0 -bwidth 2560 -bheight 1600 -tags {GFC_profile_setting_bg_button GFC_profile_setting} -initial_state hidden \
    -command {hide_GFC_profile_setting}

dui add variable settings_1 1200 490 -font [dui font get "notosansuiregular" 16] -fill #7f879a -anchor center -tags {GFC_profile_down_variable GFC_profile_setting} -initial_state hidden -textvariable {$::gfc_flow_cal_showing}
dui add dbutton settings_1 1136 320 -bwidth 132 -bheight 120 -initial_state hidden \
    -shape round -fill #c0c4e1 -radius 60 -tags {GFC_profile_up_button GFC_profile_setting} \
    -label \Uf106 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill #fff -label_pos {0.5 0.5} \
    -command {::plugins::Graphical_Flow_Calibrator::flow_cal_up}
dui add dbutton settings_1 1136 540 -bwidth 132 -bheight 120 -initial_state hidden \
    -shape round -fill #c0c4e1 -radius 60 -tags {GFC_profile_down_button GFC_profile_setting} \
    -label \Uf107 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill #fff -label_pos {0.5 0.5} \
    -command {::plugins::Graphical_Flow_Calibrator::flow_cal_down}

dui add dbutton settings_1 1136 780 -bwidth 132 -bheight 120 -initial_state hidden \
    -shape round -fill #c0c4e1 -radius 60 -tags {GFC_profile_save GFC_profile_setting} \
    -label \uf00c -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill #fff -label_pos {0.5 0.5} \
    -command {::plugins::Graphical_Flow_Calibrator::save_profile_flow_cal_s1}

set ::gfc_start_page off

rename ::page_show ::page_show_orig
proc ::page_show {page_to_show args} {
	if {$page_to_show == "GFC"} {
	    set ::gfc_start_page [dui page current]
	}
	page_show_orig $page_to_show $args
	if {$page_to_show == "GFC"} {
		::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file 0
	}
}

rename ::select_profile ::select_profile_orig
proc ::select_profile {profile} {
    select_profile_orig $profile
    if {$::settings(profile_title) in $::settings(calibration_flow_multiplier_profiles) == 1} {
        set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::settings(profile_title)]
        set ::settings(calibration_flow_multiplier) [lindex $::settings(calibration_flow_multiplier_profiles) [expr {$idx + 1}]]
        set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
        popup [translate "Flow calibration set to: "]$::settings(calibration_flow_multiplier)
    } else {
        if {$::settings(calibration_flow_multiplier) != $::settings(calibration_flow_multiplier_default)} {
            set ::settings(calibration_flow_multiplier) $::settings(calibration_flow_multiplier_default)
            set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
            popup [translate "Flow Calibration set to: "]$::settings(calibration_flow_multiplier)
        }
    }
}

rename ::delete_selected_profile ::delete_selected_profile_orig
proc ::delete_selected_profile {} {
    set w $::globals(profiles_listbox)
	if {[$w curselection] != ""} {
		set idx [lsearch $::settings(calibration_flow_multiplier_profiles) $::settings(profile_title)]
	    set ::settings(calibration_flow_multiplier_profiles) [lreplace $::settings(calibration_flow_multiplier_profiles) $idx [expr {$idx + 1}]]
        dui item config GFC gfc_espresso_profile_cal_value -fill $::plugins::Graphical_Flow_Calibrator::disabled_colour
        set ::settings(calibration_flow_multiplier) $::settings(calibration_flow_multiplier_default)
	}
    delete_selected_profile_orig
    select_profile $::settings(profile)
}
