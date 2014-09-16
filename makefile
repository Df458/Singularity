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
	@echo "Warning: Before running this application, please create a folder called singularity in your local data directory, and copy the contents of /data to it."
