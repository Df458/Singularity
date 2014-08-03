VALAC=valac
VALAFLAGS= -d . --thread -b ../src -o singularity --pkg libnotify --pkg granite --pkg webkitgtk-3.0 --pkg libxml-2.0 --pkg sqlite3 --pkg glib-2.0 --pkg pantheon --pkg unity

vfiles := $(wildcard .src/*.vala) $(wildcard src/*/*.vala)

all: $(cobjects)
	$(VALAC) $(vfiles) $(VALAFLAGS)

