VALAC=valac
FLAGS=-d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg gee-0.8

SRC := $(wildcard src/*.vala)

all:
	$(VALAC) $(SRC) -o singularity $(FLAGS) $(LIBS)

clean:
	rm -f singularity

install:
	cp -f singularity /usr/local/bin
	-mkdir /usr/local/share/singularity
	cp -f data/default.css /usr/local/share/singularity
	cp -f data/*.png /usr/local/share/singularity
