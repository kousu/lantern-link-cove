
llc: llc.vala .app.gresource.c .ui.gresource.c
	valac --pkg gtk4 --pkg gee-0.8 $^

.PHONY: play
play: llc
	./$<

.ui.gresource.c: $(addprefix ca/kousu/lanternlinkcove/,$(shell glib-compile-resources --generate-dependencies ui.gresource.xml))
.ui.gresource.c: ui.gresource.xml
	glib-compile-resources --sourcedir ca/kousu/lanternlinkcove --target $@ --generate-source $<

.app.gresource.c: $(addprefix content/,$(shell glib-compile-resources --generate-dependencies app.gresource.xml))
.app.gresource.c: app.gresource.xml
	glib-compile-resources --sourcedir content --target $@ --generate-source $<

# note: this gets included in the DAG indirectly via glib-compile-resources --generate-dependencies
content/%.dat: content/%
	strfile $<

.PHONY: clean
clean:
	git clean -Xfd
