# Učitavanje GTK3 biblioteke za GUI
require 'gtk3'

$tasks = []

# Kreiranje aplikacije
app = Gtk::Application.new("todo.app", :flags_none)

app.signal_connect "activate" do |application|

  # Glavni prozor
  window = Gtk::ApplicationWindow.new(application)
  window.title = "To-Do List App"
  window.set_default_size(500, 450)
  window.border_width = 10

  # Funkcija za prikaz popup-a
  def show_popup(parent, text)
    dialog = Gtk::Dialog.new(
      title: "Obavijest",
      parent: parent,
      flags: :destroy_with_parent
    )
    dialog.add_button("OK", :ok)

    content_area = dialog.child  
    label = Gtk::Label.new(text)
    label.override_color(:normal, Gdk::RGBA.new(0,0,0,1))  
    label.set_margin_top(10)
    label.set_margin_bottom(10)
    label.set_margin_start(10)
    label.set_margin_end(10)
    label.wrap = true

    content_area.add(label)
    label.show

    dialog.run
    dialog.destroy
  end

  # CSS stil za izgled
  css = Gtk::CssProvider.new
  css.load(data: <<~CSS)
    window {
      background: #1e1e2f;
    }

    label {
      color: white;
      font-size: 16px;
    }

    .title {
      font-size: 22px;
      font-weight: bold;
    }

    entry {
      background: #2c2c44;
      color: white;
      caret-color: white;
      padding: 6px;
      border-radius: 6px;
    }

    button {
      background: #1e88e5;
      color: white;
      border-radius: 6px;
      padding: 8px;
    }

    button.delete {
      background: #e53935;
    }

    button.done {
      background: #1e88e5;
    }

    button.exit {
      background: #757575;
    }

    button:hover {
      opacity: 0.85;
    }

    treeview {
      background: #2c2c44;
      color: white;
    }
  CSS

  Gtk::StyleContext.add_provider_for_screen(
    Gdk::Screen.default,
    css,
    Gtk::StyleProvider::PRIORITY_APPLICATION
  )

  # Glavni layout
  main_box = Gtk::Box.new(:vertical, 10)
  window.add(main_box)

  # Naslov
  title = Gtk::Label.new("📝 Moja To-Do lista")
  title.style_context.add_class("title")
  main_box.pack_start(title, expand: false, fill: false, padding: 5)

  # Forma za unos
  form_box = Gtk::Box.new(:horizontal, 10)

  desc_entry = Gtk::Entry.new
  desc_entry.placeholder_text = "Unesite opis zadatka..."

  date_entry = Gtk::Entry.new
  date_entry.placeholder_text = "Unesite rok izvršenja..."

  add_btn = Gtk::Button.new(label: "➕ Dodaj zadatak")

  # Dodavanje elemenata u formu
  form_box.pack_start(desc_entry, expand: true, fill: true, padding: 0)
  form_box.pack_start(date_entry, expand: false, fill: false, padding: 0)
  form_box.pack_start(add_btn, expand: false, fill: false, padding: 0)

  main_box.pack_start(form_box, expand: false, fill: false, padding: 5)

  # Tablica za prikaz unesenih zadataka
  store = Gtk::ListStore.new(String, String, String)

  tree = Gtk::TreeView.new(store)
  tree.selection.mode = :single

  ["Opis zadatka", "Rok izvršenja", "Status"].each_with_index do |title, i|
    renderer = Gtk::CellRendererText.new
    renderer.xalign = 0.5
    column = Gtk::TreeViewColumn.new(title, renderer, text: i)
    column.alignment = 0.5
    tree.append_column(column)
  end

  # Dinamičko proporcionalno podešavanje širine stupaca
  tree.signal_connect("size-allocate") do |widget, allocation|
    width_per_column = allocation.width / tree.columns.size
    tree.columns.each do |col|
      col.sizing = :fixed
      col.fixed_width = width_per_column
    end
  end

  scroll = Gtk::ScrolledWindow.new
  scroll.set_policy(:automatic, :automatic)
  scroll.add(tree)

  main_box.pack_start(scroll, expand: true, fill: true, padding: 5)

  # Gumbovi
  buttons = Gtk::Box.new(:horizontal, 10)

  done_btn = Gtk::Button.new(label: "✅ Dovrši")
  done_btn.style_context.add_class("done")

  delete_btn = Gtk::Button.new(label: "🗑️ Obriši")
  delete_btn.style_context.add_class("delete")

  exit_btn = Gtk::Button.new(label: "❌ Izlaz")
  exit_btn.style_context.add_class("exit")

  buttons.pack_start(done_btn, expand: false, fill: false, padding: 0)
  buttons.pack_start(delete_btn, expand: false, fill: false, padding: 0)
  buttons.pack_end(exit_btn, expand: false, fill: false, padding: 0)

  main_box.pack_start(buttons, expand: false, fill: false, padding: 5)

  # Dodavanje novog zadatka
  add_btn.signal_connect("clicked") do
    desc = desc_entry.text.strip
    date = date_entry.text.strip
    if desc.empty? || date.empty?
      show_popup(window, "Ispravno unesite tražene podatke!")
    else
      iter = store.append
      iter[0] = desc
      iter[1] = date
      iter[2] = "🔴 Nedovršeno"

      desc_entry.text = ""
      date_entry.text = ""
    end
  end

  # Označavanje zadatka kao dovršenog
  done_btn.signal_connect("clicked") do
    selected_iter = tree.selection.selected
    if selected_iter
      selected_iter[2] = "🟢 Dovršeno"
    else
      show_popup(window, "Nije odabran nijedan zadatak!")
    end
  end

  # Brisanje zadatka
  delete_btn.signal_connect("clicked") do
    selected_iter = tree.selection.selected
    if selected_iter
      store.remove(selected_iter)
    else
      show_popup(window, "Nije odabran nijedan zadatak!")
    end
  end

  # Izlaz iz aplikacije
  exit_btn.signal_connect("clicked") { application.quit }

  window.show_all
end

app.run
