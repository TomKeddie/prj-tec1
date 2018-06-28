PROJNAME=tec1
PROJPART=xc7a35ticsg324-1l
PROJFILES=top.vhd.v

all : $(PROJNAME).bit

$(PROJNAME).bit : vivado_build_$(PROJNAME).tcl $(PROJNAME).xdc
	vivado -mode tcl -source $<
	mv -f $(PROJNAME).bit $(PROJNAME).bin

vivado_build_$(PROJNAME).tcl : ../xilinx/vivado_build.tcl Makefile
	sed -e "s+PROJNAME+$(PROJNAME)+g" -e "s+PROJPART+$(PROJPART)+g"  -e "s+PROJFILES+$(PROJFILES)+g" < $< > $@

$(PROJNAME).xdc : Digilent-Arty/Resources/XDC/Arty_Master.xdc Makefile
	grep -E 'jb\[[0-3]|CLK100MHZ|qspi_cs|qspi_dq\[[0-1]' $< | cut -c2- >> $@

clean :
	rm -rf $(PROJNAME).bin vivado*.log vivado*.jou vivado*.str vivado_build_$(PROJNAME).tcl $(PROJNAME).cache $(PROJNAME).runs $(PROJNAME).xdc .Xil $(PROJNAME).ip_user_files $(PROJNAME).xpr $(PROJNAME).hw
