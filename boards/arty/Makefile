PROJNAME=tec1
PROJPART=xc7a35ticsg324-1l
PROJFILES=top.vhd

all : $(PROJNAME).bit

$(PROJNAME).bit : vivado_build_$(PROJNAME).tcl $(PROJNAME).xdc $(PROJFILES)
	@which vivado >/dev/null 2>&1 || echo "*** Please source settings64.sh from your Vivado installation ***"
	vivado -mode tcl -source $<
	mv -f $(PROJNAME).bin.bit $(PROJNAME).bin

vivado_build_$(PROJNAME).tcl : ../xilinx/vivado_build.tcl Makefile
	sed -e "s+PROJNAME+$(PROJNAME)+g" -e "s+PROJPART+$(PROJPART)+g"  -e "s+PROJFILES+$(PROJFILES)+g" < $< > $@

$(PROJNAME).xdc : Digilent-Arty/Resources/XDC/Arty_Master.xdc Makefile extra.xdc
	sed -E 's/^#(.*)(CLK100MHZ)(.*)/\1\2\3/' $< > $@.1
	sed -E 's/^#(.*)(jb\[[0-7])(.*)/\1\2\3/' $@.1 > $@.2
	sed -E 's/^#(.*)(jc\[[0-7])(.*)/\1\2\3/' $@.2 > $@
	rm -f $@.1 $@.2
	cat extra.xdc >> $@

clean :
	rm -rf $(PROJNAME).bin vivado*.log vivado*.jou vivado*.str vivado_build_$(PROJNAME).tcl $(PROJNAME).cache $(PROJNAME).runs $(PROJNAME).xdc .Xil $(PROJNAME).ip_user_files $(PROJNAME).xpr $(PROJNAME).hw $(PROJNAME).bin $(PROJNAME).ltx $(PROJNAME).bit $(PROJNAME).bit.bin
