include config.mk

PKGLIBS=glib-2.0 libxml-2.0 webkit2gtk-4.0 sqlheavy-0.1 gee-0.8 granite libnotify
CFLAGS=-g `$(PKGCONFIG) --cflags $(PKGLIBS)`
CLIBS=`$(PKGCONFIG) --libs $(PKGLIBS)` -ldflib
FLAGS=-C -d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg libnotify --pkg posix --pkg dflib

APPV := $(wildcard $(SRCPATH)/app/*.vala)
LIBV := $(wildcard $(SRCPATH)/lib/*.vala)
TESTV := $(wildcard $(SRCPATH)/tests/*.vala)
APPC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(APPV))
LIBC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(LIBV))
TESTC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(TESTV))
APPO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.o, $(APPV))
LIBO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.o, $(LIBV))
TESTO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.o, $(TESTV))

$(shell mkdir -p $(OBJPATH))
$(shell mkdir -p $(OBJPATH)/app)
$(shell mkdir -p $(OBJPATH)/lib)
$(shell mkdir -p $(OBJPATH)/test)
$(shell mkdir -p $(GENPATH))
$(shell mkdir -p $(GENPATH)/app)
$(shell mkdir -p $(GENPATH)/lib)
$(shell mkdir -p $(GENPATH)/test)
$(shell mkdir -p $(VAPIPATH))

LIBNAME=lib$(APPNAME).a
TESTNAME=$(APPNAME)-test

$(OBJPATH)/%.o: $(GENPATH)/%.c
	$(CC) -c $< -o $@ $(CFLAGS)

all: $(LIBNAME) $(APPNAME) $(TESTNAME)
.PHONY: all

# $(LIBC) $(VAPIPATH)/$(APPNAME).vapi: $(LIBV)

# $(APPC): $(APPV) $(VAPIPATH)/$(APPNAME).vapi

$(APPNAME): $(LIBNAME) $(APPV)
	$(VALAC) $(APPV) $(FLAGS) $(LIBS) --vapidir=$(VAPIPATH) --pkg $(APPNAME)
	mv -t $(GENPATH)/app $(patsubst $(SRCPATH)/%.vala, $(SRCPATH)/%.c, $(APPV))
	$(CC) -o $(APPNAME) $(APPO) $(LIBNAME) $(CFLAGS) $(CLIBS)

$(LIBNAME): $(LIBV)
	$(VALAC) $(LIBV) --vapi=$(VAPIPATH)/$(APPNAME).vapi $(FLAGS) $(LIBS)
	mv -t $(GENPATH)/lib $(patsubst $(SRCPATH)/%.vala, $(SRCPATH)/%.c, $(LIBV))
	ar -rs $(LIBNAME) $(LIBO)

$(TESTNAME): $(LIBNAME) #$(TESTV)
	# $(VALAC) $(TESTV) -o $(TESTNAME) $(FLAGS) $(LIBS)

.PHONY: test
test: $(TESTNAME)
	gtester -k -o $(TESTAPP).log $(TESTAPP)

.PHONY: clean
clean:
	rm -f $(APPNAME)
	rm -rf $(GENPATH) $(OBJPATH) $(VAPIPATH)

.PHONY: schema-install
schema-install:
	mkdir -p /usr/local/share/$(APPNAME)
	mkdir -p /usr/local/share/$(APPNAME)/schemas
	cp -f data/schemas/*.sql /usr/local/share/$(APPNAME)/schemas
	cp -f data/org.df458.$(APPNAME).gschema.xml /usr/share/glib-2.0/schemas
	glib-compile-schemas /usr/share/glib-2.0/schemas

.PHONY: install
install: schema-install
	cp -f $(APPNAME) /usr/local/bin
	cp -f data/default.css /usr/local/share/$(APPNAME)
	cp -f data/*.png /usr/local/share/$(APPNAME)
