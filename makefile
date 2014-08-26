VALAC=valac
VALAFLAGS= -d . --thread -o singularity --pkg webkitgtk-3.0 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg gee-0.8

vfiles := $(wildcard src/*.vala) $(wildcard src/*/*.vala)

all:
	$(VALAC) $(vfiles) $(VALAFLAGS)

