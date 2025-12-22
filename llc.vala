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

  const uint8 MAX_QUESTIONS = 15;

  private Label question_label;
  private Label section_label;
  private int questions_clicked = 0;

  protected override void activate () {
    var window = new ApplicationWindow (this);
    window.title = "Lantern Link Cove";
    window.set_default_size (800, 400);

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

    section_label = new Label ("");
    section_label.set_name ("section");
    center_box.append (section_label);

    question_label = new Label ("There are two ways to play this game:\n\n1. safely\n2. to grow\n\nThink about which one you want as you stare deeply into each other's eyes like you mean it--seriously, don't chicken out. The first to giggle plays first.");
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
    var button_d = new Button.with_label ("Final Card");
    button_d.sensitive = false; // only for later

    button_a.clicked.connect (() => {

      questions_clicked += 1;
      if (questions_clicked >= MAX_QUESTIONS) {
        button_a.sensitive = false;
        button_a.set_label ("[done]");
        questions_clicked = 0;
      }

      section_label.set_text ("Warm up");
      this.run_fortune_async ("content/level1"); // TODO: move this somewhere findable like /usr
    });

    button_b.clicked.connect (() => {
      if (button_a.sensitive) {
        button_a.sensitive = false;
        button_a.set_label ("[skipped]");
        questions_clicked = 0;
      }

      questions_clicked += 1;
      if (questions_clicked >= MAX_QUESTIONS) {
        button_b.sensitive = false;
        button_b.set_label ("[done]");
        questions_clicked = 0;
      }

      section_label.set_text ("Connection");
      this.run_fortune_async ("content/level2"); // TODO: move this somewhere findable like /usr
    });

    button_c.clicked.connect (() => {
      if (button_a.sensitive) {
        button_a.sensitive = false;
        button_a.set_label ("[skipped]");
        questions_clicked = 0;
      }
      if (button_b.sensitive) {
        button_b.sensitive = false;
        button_b.set_label ("[skipped]");
        questions_clicked = 0;
      }

      questions_clicked += 1;
      if (questions_clicked >= MAX_QUESTIONS) {
        button_c.sensitive = false;
        button_c.set_label ("[done]");
        questions_clicked = 0;

        if (button_a.get_label () == "[done]" && button_b.get_label () == "[done]" && button_c.get_label () == "[done]") {
          button_d.sensitive = true;
        }
      }

      section_label.set_text ("Reflection");
      this.run_fortune_async ("content/level3"); // TODO: move this somewhere findable like /usr
    });

    button_d.clicked.connect (() => {

      questions_clicked += 1;
      if (questions_clicked >= 1) {
        button_d.sensitive = false;
        button_d.set_label ("[done]");
        questions_clicked = 0;
      }

      section_label.set_text ("Final Card");
      this.run_fortune_async ("content/final"); // TODO: move this somewhere findable like /usr
    });

    button_box.append (button_a);
    button_box.append (button_b);
    button_box.append (button_c);
    button_box.append (button_d);

    vbox.append (button_box);

    var css = new CssProvider ();
    css.load_from_string ("""
label#section {
  padding: 1em;
  font-size: 18pt;
  text-decoration: underline;
  text-decoration-style: dashed;
}
label#question {
    padding: 2em;
    font-size: 26pt;
    /* vertical-align: middle; */
    /* height: 800px; */
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
        // argv.append_val ("-s");
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

        // undo word wrap
        // fortune files all(?) have `fold -w 80` run over them.
        // this undoes that by replacing newlines with " " if they're surrounded
        // by non-whitespace. Ish. It's a bit trickier than that.
        var regex = new Regex (@"(?<!\n)\n(?=[^ \t\n\r\f\v])");
        fortune = regex.replace (fortune, fortune.length, 0, " ");

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