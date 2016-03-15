include config.mk

FLAGS=-C -d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg libnotify --pkg posix --pkg dflib -X -ldflib

APPV := $(wildcard $(SRCPATH)/app/*.vala)
LIBV := $(wildcard $(SRCPATH)/lib/*.vala)
TESTV := $(wildcard $(SRCPATH)/tests/*.vala)
APPP := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vapi, $(APPV))
LIBP := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vapi, $(LIBV))
TESTP := $(patsubst $(SRCPATH)/%.vala,$(OBJPATH)/%.vapi, $(TESTV))
APPI := $(patsubst $(SRCPATH)/%.vala, --use-fast-vapi=$(OBJPATH)/%.vapi, $(APPV))
LIBI := $(patsubst $(SRCPATH)/%.vala, --use-fast-vapi=$(OBJPATH)/%.vapi, $(LIBV))
TESTI := $(patsubst $(SRCPATH)/%.vala, --use-fast-vapi=$(OBJPATH)/%.vapi, $(TESTV))
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

$(OBJPATH)/%.vapi: $(SRCPATH)/%.vala
	valac $< --fast-vapi=$@

$(GENPATH)/%.c: $(SRCPATH)/%.vala $(APPP)
	valac $< $(APPI) $(FLAGS) $(LIBS)

$(OBJPATH)/%.o: $(GENPATH)/%.c
	# valac $< $(FLAGS) $(LIBS)

all: $(LIBNAME) $(APPNAME) $(TESTNAME)
.PHONY: all

$(APPNAME): $(LIBNAME) $(APPO)
	# $(VALAC) $(APPV) -o $(APPNAME) $(FLAGS) $(LIBS)

$(LIBNAME): #$(LIBO)
	# $(VALAC) $(LIBV) -o $(LIBNAME) $(FLAGS) $(LIBS)

$(TESTNAME): $(LIBNAME) $(TESTO)
	# $(VALAC) $(TESTV) -o $(TESTNAME) $(FLAGS) $(LIBS)

.PHONY: test
test: $(TESTNAME)
	gtester -k -o $(TESTAPP).log $(TESTAPP)

.PHONY: clean
clean:
	rm -f $(APPNAME)

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
