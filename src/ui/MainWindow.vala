/*
* Copyright (c) 2017 APP Developers (http://github.com/alons45/quotes)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Author <alons45@gmail.com>
*/

public class MainWindow : Gtk.ApplicationWindow {
	protected Gtk.Label quote_text;
	protected Gtk.Label quote_author;
	protected Gtk.Label quote_url;
	protected Gtk.Stack quote_stack;
	protected Gtk.Spinner spinner;
	protected bool searching = false;

    public signal void search_begin ();	
    public signal void search_end (Json.Object? url, Error? e);

    protected void on_search_begin () {    	
    	if (!this.quote_stack.visible) {
    		this.quote_stack.set_visible (true);
    	}
    	this.quote_stack.set_visible_child_name ("spinner");
    	this.spinner.start ();
	    this.searching = true;
    }

    protected void on_search_end (Json.Object? quote, Error? error) {
    	this.searching = false;
	    if (error != null) {
	    	return;
	    }
	    this.quote_text.set_text (quote.get_string_member ("quoteText"));
	    this.quote_author.set_text (quote.get_string_member ("quoteAuthor"));
	    this.quote_url.set_text (quote.get_string_member ("quoteLink"));

	    this.quote_stack.set_visible_child_name ("quote_box");
    }

	public MainWindow (Application application) {
		Object (
			application: application,
			title: "Quotes",
			default_width: 600,
			default_height: 400
		);
		this.set_border_width (12);
		this.set_position (Gtk.WindowPosition.CENTER);

		this.search_begin.connect (this.on_search_begin);
		this.search_end.connect (this.on_search_end);

		// Initialize widgets
		this.quote_text = new Gtk.Label ("...");
		this.quote_author = new Gtk.Label ("...");
		this.quote_url = new Gtk.Label ("...");
		this.quote_stack = new Gtk.Stack ();
		this.spinner = new Gtk.Spinner ();

		// Create Toolbar
	    var toolbar = new Gtk.Toolbar ();

		// Create Main Box
		Gtk.Box quote_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		quote_box.set_spacing (10);

		// Add widgets to Main Box
	    quote_box.pack_start (toolbar, false, false, 0);
		quote_box.pack_start (quote_text);
		quote_box.pack_start (quote_author);
		quote_box.pack_start (quote_url);

	    // Create Toolbar buttons
		Gtk.Image refresh_icon = new Gtk.Image.from_icon_name (
			"view-refresh", Gtk.IconSize.SMALL_TOOLBAR
		);
		Gtk.ToolButton refresh_tool_button = new Gtk.ToolButton (refresh_icon, null);
		refresh_tool_button.is_important = true;
		toolbar.add (refresh_tool_button);

		Gtk.Image copy_icon = new Gtk.Image.from_icon_name (
			"edit-copy", Gtk.IconSize.SMALL_TOOLBAR
		);
		Gtk.ToolButton share_tool_button = new Gtk.ToolButton (copy_icon, null);
		toolbar.add (share_tool_button);

		refresh_tool_button.clicked.connect ( () => {
			quote_query.begin();
		});

		// Stack
		this.quote_stack.add_named (this.spinner, "spinner");
		this.quote_stack.add_named (quote_box, "quote_box");

		this.add(quote_stack);
		this.show_all();
		this.quote_stack.set_visible (false);

		quote_query.begin ();

	}

	protected async void quote_query () {
		// TODO: Include another api source: http://quotesondesign.com/wp-json/posts
		this.search_begin ();

		Application app = (Application)this.application;
		Soup.URI uri = new Soup.URI (app.quote_host);
		Json.Parser parser = new Json.Parser();	
		Json.Object root_object;

		try {
			Soup.Request request = app.session.request(uri.to_string (false));
			BufferedInputStream stream = new BufferedInputStream (
				yield request.send_async (null)
			);

			// Read the JSON data and extract its root.
			yield parser.load_from_stream_async(stream, null);
			root_object = parser.get_root().get_object();

			this.search_end (root_object, null);
		}
		catch (Error error) {
			this.search_end (null, error);
		}
	}
}