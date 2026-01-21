#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Set basic window properties
  gtk_window_set_title(window, "VaultSafe");
  gtk_window_set_default_size(window, 1280, 720);
  gtk_window_set_resizable(window, TRUE);

  // Set minimum size
  gtk_widget_set_size_request(GTK_WIDGET(window), 800, 600);

  // Prevent screenshots for security (Linux-specific)
  #ifdef GDK_WINDOWING_X11
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk_window) {
      // Set _NET_WM_WINDOW_TYPE_NORMAL
      GdkAtom type_atom = gdk_atom_intern("_NET_WM_WINDOW_TYPE", FALSE);
      GdkAtom normal_atom = gdk_atom_intern("_NET_WM_WINDOW_TYPE_NORMAL", FALSE);
      gulong data = static_cast<gulong>(normal_atom);
      gdk_property_change(gdk_window, type_atom, GDK_ATOM_TYPE, 32,
                         GDK_PROP_MODE_REPLACE, reinterpret_cast<guchar*>(&data), 1);
    }
  #endif

  // Create Flutter view
  GtkBox* box = GTK_BOX(gtk_box_new(GTK_ORIENTATION_VERTICAL, 0));
  gtk_widget_show(GTK_WIDGET(box));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(box));

  // Initialize Flutter
  FlutterDesktopPluginRegistrar* registrar =
      flutter_desktop_plugin_registrar_new(GTK_WINDOW(window));

  // Register plugins
  flutter_desktop_plugins_register(registrar);

  // Create Flutter view
  GtkWidget* flutter_widget = gtk_drawing_area_new();
  gtk_box_pack_start(box, flutter_widget, TRUE, TRUE, 0);
  gtk_widget_show(flutter_widget);

  // Run Flutter engine
  const gchar* entrypoint = self->dart_entrypoint_arguments ? self->dart_entrypoint_arguments[0] : nullptr;

  FlutterDesktopEngineProperties engine_properties = {};
  engine_properties.assets_path = "/usr/share/vaultsafe/data";
  engine_properties.icu_data_path = "/usr/share/vaultsafe/data/icudtl.dat";
  engine_properties.dart_entrypoint = entrypoint;

  FlutterDesktopEngine* engine = flutter_desktop_engine_create(&engine_properties);
  flutter_desktop_engine_set_window_offset_callback(engine, [](void* user_data, int x, int y) {
    // Handle window position changes
  }, nullptr);

  flutter_desktop_engine_run_engine(engine, nullptr);

  // Show window
  gtk_widget_show(GTK_WIDGET(window));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = *arguments + 1;
  g_application_activate(application);
  *exit_status = 0;
  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", "com.vaultsafe.app",
                                     "flags", G_APPLICATION_HANDLES_COMMAND_LINE,
                                     nullptr));
}
