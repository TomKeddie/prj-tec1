all : jmon.hex mon1b.hex mon1.hex mon2.hex util.hex


%.hex : %.rom
	hexdump -v -e '1/1 "%02x " "\n"' $< >$@
