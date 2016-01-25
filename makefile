VALAC=valac
FLAGS=-d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg libnotify --pkg posix --pkg dflib -X -ldflib
SRC := $(wildcard src/*.vala)

all:
	$(VALAC) $(SRC) -o singularity $(FLAGS) $(LIBS)

clean:
	rm -f singularity

schema-install:
	mkdir -p /usr/local/share/singularity
	mkdir -p /usr/local/share/singularity/schemas
	cp -f data/schemas/*.sql /usr/local/share/singularity/schemas
	cp -f data/org.df458.singularity.gschema.xml /usr/share/glib-2.0/schemas
	glib-compile-schemas /usr/share/glib-2.0/schemas

install: schema-install
	cp -f singularity /usr/local/bin
	cp -f data/default.css /usr/local/share/singularity
	cp -f data/*.png /usr/local/share/singularity
