
llc: llc.vala $(addsuffix .dat,$(filter-out %.dat,$(wildcard content/*)))
	valac --pkg gtk4 $<

content/%.dat: content/%
	strfile $<

.PHONY: clean
clean:
	git clean -Xfd
