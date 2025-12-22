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
  private TextView question_view;


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
    question_label = new Label ("Level 1");
    question_label.set_name ("questioni");
    // var font_desc = Pango.FontDescription.from_string ("Sans 26");
    // label.override_font (font_desc);

    center_box.append (question_label);

    // Create a TextView
    question_view = new TextView ();
    question_view.set_name ("question");
    question_view.wrap_mode = WrapMode.WORD;
    question_view.editable = false;
    question_view.cursor_visible = false;

    // remove border/padding
    question_view.set_left_margin (6);
    question_view.set_right_margin (6);
    question_view.set_top_margin (6);
    question_view.set_bottom_margin (6);

    // Put it inside a ScrolledWindow
    var scroller = new ScrolledWindow ();
    scroller.set_size_request (500, 300);
    scroller.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    scroller.hexpand = true;
    scroller.vexpand = true;
    scroller.halign = Align.FILL;
    scroller.valign = Align.CENTER;
    scroller.set_child (question_view);


    // Center it in the window layout
    center_box.hexpand = true;
    center_box.vexpand = true;
    center_box.halign = Align.FILL;
    center_box.valign = Align.FILL;
    center_box.append (scroller);

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
      question_label.set_text ("Level 1");
      question_view.get_buffer ().set_text ("");
      this.run_fortune_async ("magic");
    });

    button_b.clicked.connect (() => {
      stdout.printf ("B\n");
      button_a.sensitive = false;
      question_label.set_text ("Level 2");
      question_view.get_buffer ().set_text ("");
      this.run_fortune_async ("love");
    });

    button_c.clicked.connect (() => {
      stdout.printf ("C\n");
      button_a.sensitive = false;
      button_b.sensitive = false;
      question_label.set_text ("Level 3");
      question_view.get_buffer ().set_text ("");
      this.run_fortune_async ("goedel");
    });

    button_box.append (button_a);
    button_box.append (button_b);
    button_box.append (button_c);

    vbox.append (button_box);

    // CSS for 26pt centered label
    var css = new CssProvider ();
    css.load_from_string ("""
#question {
    font-size: 26pt;
    vertical-align: middle;
}
label#questioni {
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
          question_view.get_buffer ().set_text (fortune ? .strip ());
          return false;
        });
        stdout.printf ("Fortune done\n");
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