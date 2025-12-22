// llc.vala
// Compile with:
// valac --pkg gtk4 llc.vala

using Gtk;
using GLib;

class LanternLinkCoveApp : Gtk.Application {
  public LanternLinkCoveApp () {
    Object (
            application_id: "ca.kousu.lanternlinkcove",
            flags: ApplicationFlags.DEFAULT_FLAGS
    );
  }

  protected override void activate () {
    var window = new ApplicationWindow (this);
    window.title = "Lantern Link Cove";
    window.set_default_size (600, 400);

    // Main vertical layout
    var vbox = new Box (Orientation.VERTICAL, 0);
    window.set_child (vbox);

    // Center area
    var center_box = new Box (Orientation.VERTICAL, 0);
    center_box.hexpand = true;
    center_box.vexpand = true;
    center_box.halign = Align.CENTER;
    center_box.valign = Align.CENTER;

    // Empty text widget (label) with 26pt font
    var label = new Label ("Slots");
    label.set_name("question");
    // var font_desc = Pango.FontDescription.from_string ("Sans 26");
    // label.override_font (font_desc);

    center_box.append (label);
    vbox.append (center_box);

    // Bottom button bar
    var button_box = new Box (Orientation.HORIZONTAL, 12);
    button_box.halign = Align.CENTER;
    button_box.margin_bottom = 12;
    button_box.margin_top = 12;

    var button_a = new Button.with_label ("Level 1");
    var button_b = new Button.with_label ("Level 2");
    var button_c = new Button.with_label ("Level 3");

    button_a.clicked.connect (() => {
      stdout.printf ("A\n");
    });

    button_b.clicked.connect (() => {
      stdout.printf ("B\n");
      button_a.sensitive = false;
    });

    button_c.clicked.connect (() => {
      stdout.printf ("C\n");
      button_a.sensitive = false;
      button_b.sensitive = false;
    });

    button_box.append (button_a);
    button_box.append (button_b);
    button_box.append (button_c);

    vbox.append (button_box);

    // CSS for 26pt centered label
    var css = new CssProvider ();
    css.load_from_string ("""
label#question {
    font-size: 26pt;
}
""");

    Gtk.StyleContext.add_provider_for_display (
                                               Gdk.Display.get_default (),
                                               css,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    window.present ();
  }
}

int main (string[] args) {
  var app = new LanternLinkCoveApp ();
  return app.run (args);
}