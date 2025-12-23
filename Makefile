
llc: llc.vala .app.gresource.c
	valac --pkg gtk4 $^

.PHONY: play
play: llc
	./$<

.app.gresource.c: $(addprefix content/,$(shell glib-compile-resources --generate-dependencies app.gresource.xml))
.%.gresource.c: %.gresource.xml
	glib-compile-resources --sourcedir content --target $@ --generate-source $<

# note: this gets included in the DAG indirectly via glib-compile-resources --generate-dependencies
content/%.dat: content/%
	strfile $<

.PHONY: clean
clean:
	git clean -Xfd
