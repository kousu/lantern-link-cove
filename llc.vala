#! /usr/bin/env -S vala --pkg gtk4

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

  private Label question_label;

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
    vbox.append (center_box);

    question_label = new Label ("Level 1");
    question_label.set_name ("question");
    question_label.wrap = true;
    question_label.justify = Justification.CENTER;
    center_box.append (question_label);

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
      this.run_fortune_async ("magic");
    });

    button_b.clicked.connect (() => {
      stdout.printf ("B\n");
      button_a.sensitive = false;
      this.run_fortune_async ("love");
    });

    button_c.clicked.connect (() => {
      stdout.printf ("C\n");
      button_a.sensitive = false;
      button_b.sensitive = false;
      this.run_fortune_async ("goedel");
    });

    button_box.append (button_a);
    button_box.append (button_b);
    button_box.append (button_c);

    vbox.append (button_box);

    var css = new CssProvider ();
    css.load_from_string ("""
label#question {
    font-size: 26pt;
    vertical-align: middle;
    padding: 2em;
}
""");

    Gtk.StyleContext.add_provider_for_display (
                                               Gdk.Display.get_default (),
                                               css,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    window.present ();
  }

  private Thread? fortune_thread;
  private void run_fortune_async (params string[] sources) {
    if (fortune_thread != null) {
      stdout.printf ("Fortune is already running\n");
      return;
    }

    var _sources = sources; // for the benefit of the closure
    fortune_thread = new Thread<void> ("run_fortune_async", () => {
      string fortune, err;
      int exit_status;

      try {
        var argv = new Array<string> ();
        argv.append_val ("fortune");
        argv.append_val ("-s");
        foreach (var s in _sources) {
          argv.append_val (s);
        }
        Process.spawn_sync (
                            null,
                            argv.data,
                            null,
                            SpawnFlags.SEARCH_PATH,
                            null,
                            out fortune,
                            out err,
                            out exit_status
        );

        if (exit_status != 0) {
          throw new ShellError.FAILED (err);
        }

        Idle.add (() => {
          question_label.set_text (fortune ? .strip ());
          return false;
        });
      } catch (Error e) {
        string msg = e.message;
        stderr.printf ("Error: %s\n", e.message);
      }
      fortune_thread = null;
    });
  }
}

int main (string[] args) {
  var app = new LanternLinkCoveApp ();
  return app.run (args);
}