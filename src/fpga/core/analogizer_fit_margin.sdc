# Fitter-only margin targets for the Analogizer revision (ap_core_analogizer).
#
# The Analogizer build sits at ~97% ALMs, and with only "met" as the target the
# fitter lands hold and CRAM0 input slack below what upstream's ap_core
# achieves. These constraints apply while quartus_fit places and routes,
# so it aims for extra margin on those paths. Signoff timing (quartus_sta) still
# uses only core_constraints.sdc, so reported slack is against the real limits.

if {$::TimeQuestInfo(nameofexecutable) eq "quartus_fit"} {
    set fit_clk_sys [get_clocks {ic|mp1|mf_pllbase_inst|sys_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

    # Hold: ask for ~0.1 ns more than the real requirement inside clk_sys and
    # clk_74a. I/O paths are left alone so SDRAM output delay chains are not
    # padded for hold at the cost of write setup.
    set fit_clk_74a [get_clocks {clk_74a}]
    set_clock_uncertainty -add -hold 0.100 -from $fit_clk_sys -to $fit_clk_sys
    set_clock_uncertainty -add -hold 0.100 -from $fit_clk_74a -to $fit_clk_74a

    # CRAM0 read data: one clk_sys period in signoff, 0.35 ns tighter here.
    set fit_cram0_inputs [get_ports {cram0_dq[*] cram0_wait}]
    set_max_delay [expr {[get_clock_info -period $fit_clk_sys] - 0.350}] \
        -from $fit_cram0_inputs -to $fit_clk_sys
}
