### By Damian Brakel ###
set plugin_name "Graphical_Flow_Calibrator"


namespace eval ::plugins::${plugin_name} {
    variable author "Damian Brakel"
    variable contact "via Diaspora"
    variable description "Adjust flow calibration using historic shot graphs"
    variable version 1.0
    variable min_de1app_version {1.43.0}

    proc build_ui {} {
        set page_name "GFC"
        dui page add $page_name
        set background_colour #fff
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
        set ::gfc_espresso_profile_title $::settings(profile_title)
        set ::gfc_espresso_clock $::settings(espresso_clock)
        set ::gfc_flow_cal_backup $::settings(calibration_flow_multiplier)
        set ::gfc_history_file 1
        set ::history_button_label ""
        set ::gfc_orig_flow ""
        set ::gfc_espresso_flow ""

        if {$::settings(skin) == "DSx2"} {
            set ::gfc_orig_flow $::skin_graphs(live_graph_espresso_flow)
            set ::gfc_espresso_flow $::skin_graphs(live_graph_espresso_flow)
        }

        dui add dbutton "calibrate" 1450 1460 -style insight_ok -anchor nw -command {page_show GFC} -label_width 400 -label_font [dui font get $font 14] -label [subst {[translate "go to the"]\r[translate "Graphical Flow Calibrator"]}]

        # Background image and "Done" button
        dui add canvas_item rect $page_name 0 0 2560 1600 -fill $background_colour -width 0

        # Headline
        dui add dtext $page_name 1280 100 -text [translate "Graphical Flow Calibrator (GFC)"] -font [dui font get $font_bold 28] -fill $text_colour -anchor "center" -justify "center"
        dui add variable $page_name 2500 1560 -font [dui font get $font 12] -fill $text_colour -anchor e -justify right -textvariable {Version $::plugins::Graphical_Flow_Calibrator::version  by $::plugins::Graphical_Flow_Calibrator::author}

        add_de1_widget GFC graph 30 280 {
            set ::gfc_graph $widget
            bind $widget [platform_button_press] {

            }
            $widget element create gfc_pressure -xdata espresso_elapsed -ydata espresso_pressure -symbol none -label "" -linewidth [rescale_x_skin 10] -color #0CA581 -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
            $widget element create gfc_flow -xdata espresso_elapsed -ydata espresso_flow -symbol none -label "" -linewidth [rescale_x_skin 10] -color #49a2e8 -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
            $widget element create gfc_weight -xdata espresso_elapsed -ydata espresso_flow_weight -symbol none -label "" -linewidth [rescale_x_skin 10] -color #A1663A -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
            #$widget element create gfc_flow_2x -xdata gespresso_elapsed -ydata espresso_flow_2x -symbol none -label "" -linewidth [rescale_x_skin 10] -color #49a2e8 -smooth $::settings(live_graph_smoothing_technique) -pixels 0;
            #$widget element create gfc_weight_2x -xdata espresso_elapsed -ydata espresso_flow_weight_2x -symbol none -label "" -linewidth [rescale_x_skin 10] -color #A1663A -smooth $::settings(live_graph_smoothing_technique) -pixels 0;

            $widget axis configure x -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0;
            $widget axis configure y -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0 -max 10 -subdivisions 1 -majorticks {0  2  4  6  8  10  12} -hide 0;
            $widget axis configure y2 -color #2b6084 -tickfont [dui font get "notosansuiregular" 12] -min 0.0 -max 5 -subdivisions 1 -majorticks {0  1  2  3  4  5  6} -hide 1;
            $widget grid configure -color #2b6084 -dashes {2 12} -linewidth 1
        } -plotbackground $background_colour -width [rescale_x_skin 1900] -height [rescale_y_skin 990] -borderwidth 1 -background $background_colour -plotrelief flat -initial_state normal

        dui add variable $page_name 600 1290 -font [dui font get $font 14] -fill $text_colour -anchor center -textvariable {$::gfc_espresso_profile_title [::plugins::Graphical_Flow_Calibrator::time_format $::gfc_espresso_clock]}
        dui add variable $page_name 1280 240 -font [dui font get $font 14] -fill $red -anchor center -textvariable {[::plugins::Graphical_Flow_Calibrator::gfc_warning]}
        dui add dbutton $page_name 2000 400 -bwidth 520 -bheight 740 -width 2 -shape outline -outline $foreground_colour -command {do_nothing}
        dui add dtext $page_name 2260 460 -font [dui font get $font_bold 20] -text [translate "flow rate calibrator"] -fill $text_colour -anchor center
        dui add dtext $page_name 2160 550 -font [dui font get $font 18] -text [translate "current"] -fill $text_colour -anchor center
        dui add dtext $page_name 2360 550 -font [dui font get $font 18] -text [translate "showing"] -fill $text_colour -anchor center
        dui add variable $page_name 2160 590 -font [dui font get $font_bold 18] -fill $text_colour -anchor center -textvariable {$::gfc_flow_cal_backup}
        dui add variable $page_name 2360 590 -font [dui font get $font_bold 18] -fill $text_colour -anchor center -textvariable {$::settings(calibration_flow_multiplier)}

        dui add dbutton $page_name 2210 650 -bwidth 100 -bheight 100 \
            -shape round -fill $foreground_colour -radius 60 \
            -label \Uf106 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill $button_label_colour -label_pos {0.5 0.5} \
            -command {::plugins::Graphical_Flow_Calibrator::flow_cal_up}

        dui add dbutton $page_name 2210 760 -bwidth 100 -bheight 100 \
            -shape round -fill $foreground_colour -radius 60 \
            -label \Uf107 -label_font [dui font get "Font Awesome 5 Pro-Regular-400" 20] -label_fill $button_label_colour -label_pos {0.5 0.5} \
            -command {::plugins::Graphical_Flow_Calibrator::flow_cal_down}

        dui add dbutton $page_name 2110 1000 -bwidth 100 -bheight 100 \
            -label \Uf00d -label_font [dui font get "Font Awesome 5 Pro-light-300" 30] -label_fill $red -label_pos {0.5 0.5} \
            -command {::plugins::Graphical_Flow_Calibrator::cancel_flow_cal}
        dui add dbutton $page_name 2310 1000 -bwidth 100 -bheight 100 \
            -label \uf00c -label_font [dui font get "Font Awesome 5 Pro-light-300" 30] -label_fill $green -label_pos {0.5 0.5} \
            -command {::plugins::Graphical_Flow_Calibrator::save_flow_cal}

        dui add dtext $page_name 2260 1220 -font [dui font get $font 14] -text [translate "It is best to adjust flow rate data for where the pressure curve is flat"] -width 480 -fill $orange -anchor center -justify center

        dui add dbutton $page_name 1180 1440 \
            -bwidth 492 -bheight 120 \
            -shape round -fill $foreground_colour -radius 60\
            -label [translate "Exit"] -label_font [dui font get $font_bold 18] -label_fill $button_label_colour -label_pos {0.5 0.5} \
            -command {::plugins::Graphical_Flow_Calibrator::exit}

        dui add dbutton $page_name 280 1440 \
            -bwidth 492 -bheight 120 \
            -shape round -fill $foreground_colour -radius 60\
            -labelvariable {[translate "load the"] $::history_button_label [translate "most recent history file"]} -label_width 400 -label_font [dui font get $font 16] -label_fill $button_label_colour -label_pos {0.5 0.5} \
            -command {
                ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file
                ::plugins::Graphical_Flow_Calibrator::toggle_history
            }

        proc toggle_history {} {
            incr ::gfc_history_file
            if {$::gfc_history_file == 7} {
                set ::gfc_history_file 1
            }
        ::plugins::Graphical_Flow_Calibrator::history_button_label
        }

        proc history_button_label {} {
            if {$::gfc_history_file == 1} {set ::history_button_label ""}
            if {$::gfc_history_file == 2} {set ::history_button_label [translate "2nd"]}
            if {$::gfc_history_file == 3} {set ::history_button_label [translate "3rd"]}
            if {$::gfc_history_file == 4} {set ::history_button_label [translate "4th"]}
            if {$::gfc_history_file == 5} {set ::history_button_label [translate "5th"]}
            if {$::gfc_history_file == 6} {set ::history_button_label [translate "6th"]}
        }

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

        proc history_data {pos} {
            set p [expr $pos - 1]
            set file_name [::plugins::Graphical_Flow_Calibrator::history_position $p]
            array set history_data [read_file "[homedir]/history/$file_name"]
            foreach lg [::plugins::Graphical_Flow_Calibrator::graph_list] {
                $lg length 0
                $lg append $history_data($lg)
            }

            set ::gfc_orig_flow $history_data(espresso_flow)
            set ::gfc_espresso_flow $history_data(espresso_flow)
            espresso_flow length 0

            foreach flow $::gfc_espresso_flow {
                espresso_flow append [expr $::settings(calibration_flow_multiplier) * $flow / $::gfc_flow_cal_backup]
            }
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
                set ::gfc_history_calibration_flow_multiplier $h_settings(calibration_flow_multiplier)
            }

            #set ::settings(calibration_flow_multiplier) $::gfc_history_calibration_flow_multiplier
            #espresso_flow length 0
            #foreach flow $::gfc_espresso_flow {
            #    espresso_flow append [expr $::settings(calibration_flow_multiplier) * $flow / $::gfc_flow_cal_backup]
            #}
        }

        proc gfc_warning {} {
            if {$::gfc_flow_cal_backup != $::gfc_history_calibration_flow_multiplier} {
                return "This graph was recorded while the flow calibration was set to $::gfc_history_calibration_flow_multiplier and is not suitable for the current setting $::gfc_flow_cal_backup"
            } else {
                return ""
            }
        }

        proc clear_GFC_graph {} {
            espresso_elapsed length 0
            espresso_pressure length 0
            espresso_flow_weight length 0
            espresso_weight length 0

        }

        proc load_GFC_graph {graph} {
            ::plugins::Graphical_Flow_Calibrator::clear_GFC_graph
            ::plugins::Graphical_Flow_Calibrator::history_data $graph
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
            set s {    }
            return "$s$s$s$s$date$s$c$b$pm"
        }

        proc flow_cal_up {} {
            if {$::gfc_orig_flow == ""} {
                ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file
                ::plugins::Graphical_Flow_Calibrator::toggle_history
            }
            if {$::settings(calibration_flow_multiplier) <= 0.35} {
                popup [translate "minimum setting reached"]
                return
            }
            set ::settings(calibration_flow_multiplier) [round_to_two_digits [expr $::settings(calibration_flow_multiplier) + 0.01]]
            espresso_flow length 0
            foreach flow $::gfc_espresso_flow {
                espresso_flow append [expr $::settings(calibration_flow_multiplier) * $flow / $::gfc_flow_cal_backup]
            }
        }

        proc flow_cal_down {} {
            if {$::gfc_orig_flow == ""} {
                ::plugins::Graphical_Flow_Calibrator::load_GFC_graph $::gfc_history_file
                ::plugins::Graphical_Flow_Calibrator::toggle_history
            }
            if {$::settings(calibration_flow_multiplier) >= 1.65} {
                popup [translate "maximum setting reached"]
                return
            }
            set ::settings(calibration_flow_multiplier) [round_to_two_digits [expr $::settings(calibration_flow_multiplier) - 0.01]]
            espresso_flow length 0
            foreach flow $::gfc_espresso_flow {
                espresso_flow append [expr $::settings(calibration_flow_multiplier) * $flow / $::gfc_flow_cal_backup]
            }
        }

        proc cancel_flow_cal {} {
            set ::settings(calibration_flow_multiplier) $::gfc_flow_cal_backup
            espresso_flow length 0
            foreach flow $::gfc_espresso_flow {
                espresso_flow append $::gfc_orig_flow
            }
        }

        proc save_flow_cal {} {
            set ::gfc_flow_cal_backup $::settings(calibration_flow_multiplier)
            save_settings
            set_calibration_flow_multiplier $::settings(calibration_flow_multiplier)
        }
        return $page_name
    }

    proc exit {} {
        ::plugins::Graphical_Flow_Calibrator::clear_GFC_graph
        if {$::settings(skin) == "DSx"} {restore_DSx_live_graph}
        if {$::settings(skin) == "DSx2"} {restore_live_graphs}
        set_next_page off off
        dui page load off
        set ::settings(calibration_flow_multiplier) $::gfc_flow_cal_backup
        set ::gfc_history_file 1
        ::plugins::Graphical_Flow_Calibrator::history_button_label
    }

    proc main {} {
        plugins gui Graphical_Flow_Calibrator [build_ui]
    }
}
