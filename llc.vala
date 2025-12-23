// llc.vala
//
// See Makefile for build instructions.

using Gee;
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

    fortunes = new HashTable<string, FortuneDB> (str_hash, str_equal);

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
    button_d.visible = false; // only for later

    button_a.clicked.connect (() => {

      questions_clicked += 1;
      if (questions_clicked >= MAX_QUESTIONS) {
        button_a.sensitive = false;
        button_a.set_label ("[done]");
        questions_clicked = 0;
      }

      section_label.set_text ("Warm up");
      this.run_fortune_async ("resource:///content/level1");
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
      this.run_fortune_async ("resource:///content/level2");
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
          button_a.visible = button_b.visible = button_c.visible = false;
          button_d.visible = true;
        }
      }

      section_label.set_text ("Reflection");
      this.run_fortune_async ("resource:///content/level3");
    });

    button_d.clicked.connect (() => {

      questions_clicked += 1;
      if (questions_clicked >= 1) {
        button_d.sensitive = false;
        button_d.set_label ("[done]");
        questions_clicked = 0;
      }

      section_label.set_text ("Final Card");
      this.run_fortune_async ("resource:///content/final");
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

  private HashTable<string, FortuneDB> fortunes;
  private FortuneDB get_fortunedb (string source) throws Error {
    if (!fortunes.contains (source)) {
      fortunes.insert (source, new FortuneDB ({ source }));
    }

    return fortunes.get (source);
  }

  private Thread? fortune_thread;
  private void run_fortune_async (params string[] sources) {
    if (fortune_thread != null) {
      stdout.printf ("Fortune is already running\n");
      return;
    }

    var _sources = sources; // for the benefit of the closure
    fortune_thread = new Thread<void> ("run_fortune_async", () => {
      try {
        var fortunedb = get_fortunedb (_sources[0]);
        var fortune = fortunedb.random_fortune ();
        // stderr.printf ("picked: |%s|\n", fortune);

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

errordomain FortuneError {
  ARGUMENT_ERROR
}

public class FortuneDB {
  File text_file;
  uint32 version;
  uint32 numstr;
  uint32 longest;
  uint32 shortest;
  uint32 flags;
  uint8 delim;
  uint32[] offsets;

  private Rand rng;
  private HashSet<uint> seen;

  public FortuneDB (string[] paths) throws Error {
    if (paths.length != 1) {
      // TODO: support multiple sources the way fortune(1) does, with equal weight
      throw new FortuneError.ARGUMENT_ERROR ("FortuneDB only supports parsing one source at a time");
    }
    text_file = File.new_for_uri (paths[0]);
    load_index (paths[0] + ".dat");
    rng = new Rand ();
    seen = new HashSet<uint> ();
  }

  private void load_index (string dat_path) throws Error {
    var f = File.new_for_uri (dat_path);
    var dis = new DataInputStream (f.read ());

    // .dat uses big-endian integers
    dis.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);

    // https://man.archlinux.org/man/strfile.1.en#Header
    // #define VERSION 1
    // unsigned long str_version; /* version number */
    // unsigned long str_numstr; /* # of strings in the file */
    // unsigned long str_longlen; /* length of longest string */
    // unsigned long str_shortlen; /* shortest string length */
    // #define STR_RANDOM 0x1 /* randomized pointers */
    // #define STR_ORDERED 0x2 /* ordered pointers */
    // #define STR_ROTATED 0x4 /* rot-13'd text */
    // unsigned long str_flags; /* bit field for flags */
    // char str_delim; /* delimiting character */
    version = dis.read_uint32 ();
    numstr = dis.read_uint32 ();
    longest = dis.read_uint32 ();
    shortest = dis.read_uint32 ();
    flags = dis.read_uint32 ();
    delim = dis.read_byte ();
    dis.read_byte (); // throwaway padding bytes
    dis.read_byte ();
    dis.read_byte ();
    // stderr.printf ("header:\nversion: %u\nnumstr: %u\nlonglen: %u\nshortlen: %u\nflag: %xu\ndelim: %c\n", version, numstr, longest, shortest, flags, delim);

    offsets = new uint32[numstr];
    for (uint i = 0; i < numstr; i++) {
      offsets[i] = dis.read_uint32 ();
      // stderr.printf ("%u\n", offsets[i]);
    }
  }

  public string random_fortune () throws Error {
    if (offsets.length == 0)
      return "";

    if (seen.size >= offsets.length) {
      // reset when we overflow
      seen = new HashSet<uint> ();
      stderr.printf ("resetting seen\n");
    }
    uint i;
    while (seen.contains (i = rng.int_range (0, offsets.length))) {
      // XXX this risks an infinite loop; maybe there's a safer way, like by
      // calling int_range(0, offsets.length - seen.size) once, and instead
      // looping through an array of crossed off items (only counting the uncrossed items).

      // stderr.printf ("skipping fortune %u because we've used it already\n", i);
    }
    seen.add (i);

    uint32 start = offsets[i];
    uint32 end = (i + 1 < offsets.length)
            ? offsets[i + 1]
            : (uint32) text_file.query_info (
                                             FileAttribute.STANDARD_SIZE,
                                             FileQueryInfoFlags.NONE
            ).get_size ();

    end -= 3; // strip trailing '\n%\n'; fortunes are delimited by a % on a line by itself.
    uint32 len = end - start;

    // stderr.printf ("chose %u/%d [seen: %u] @ db[%u:%u+%u]\n", i, offsets.length, seen.size, start, start, len);

    var istream = text_file.read ();
    istream.skip (start);

    uint8[] buf = new uint8[len + 1]; // overallocated to allow for null termination
                                      // unfortunately
    size_t read;
    istream.read_all (buf, out read);
    // stderr.printf ("we actually read: %lu\n", read);
    buf[read - 1] = 0; // null terminate
    // buf[len] = 0; // or should we do this?

    string fortune = (string) buf;
    return fortune;
  }
}


int main (string[] args) {
  var app = new LanternLinkCoveApp ();
  return app.run (args);
}