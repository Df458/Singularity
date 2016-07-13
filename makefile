include config.mk

PKGLIBS=glib-2.0 libxml-2.0 webkit2gtk-4.0 sqlheavy-0.1 gee-0.8 granite libnotify
CFLAGS=-g -I generated/lib -Wno-incompatible-pointer-types `$(PKGCONFIG) --cflags $(PKGLIBS)`
CLIBS= -ldflib `$(PKGCONFIG) --libs $(PKGLIBS)`
FLAGS=-d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg libnotify --pkg posix --pkg dflib

LJSC = $(SRCPATH)/lib/jshandler.c
APPV := $(wildcard $(SRCPATH)/app/*.vala)
LIBV := $(wildcard $(SRCPATH)/lib/*.vala)
TESTV := $(wildcard $(SRCPATH)/test/*.vala)
EXTV := $(wildcard $(SRCPATH)/ext/*.vala)
APPC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(APPV))
LIBC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(LIBV))
TESTC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(TESTV))
EXTC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(EXTV))
APPO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(APPV))
LIBO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(LIBV)) $(OBJPATH)/lib/jshandler.o
TESTO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(TESTV))
EXTO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(EXTV))

$(shell mkdir -p $(OBJPATH))
$(shell mkdir -p $(OBJPATH)/app)
$(shell mkdir -p $(OBJPATH)/lib)
$(shell mkdir -p $(OBJPATH)/test)
$(shell mkdir -p $(OBJPATH)/ext)
$(shell mkdir -p $(GENPATH))
$(shell mkdir -p $(GENPATH)/app)
$(shell mkdir -p $(GENPATH)/lib)
$(shell mkdir -p $(GENPATH)/test)
$(shell mkdir -p $(GENPATH)/ext)
$(shell mkdir -p $(VAPIPATH))

LIBNAME=lib$(APPNAME).a
EXTNAME=$(APPNAME)-ext.so
TESTNAME=$(APPNAME)-test-0

$(OBJPATH)/app/%.vala.o: $(GENPATH)/app/%.c
	$(CC) -c $< -o $@ $(CFLAGS) -pie -fPIE

$(OBJPATH)/test/%.vala.o: $(GENPATH)/test/%.c
	$(CC) -c $< -o $@ $(CFLAGS) `$(PKGCONFIG) --cflags valadate-1.0` -pie -fPIE

$(OBJPATH)/ext/%.vala.o: $(GENPATH)/ext/%.c
	$(CC) -c $< -o $@ $(CFLAGS) `$(PKGCONFIG) --cflags webkit2gtk-web-extension-4.0`

# TODO: Uncomment after resolving PIC issue (Will probably just rebuild dflib)
all: $(LIBNAME) $(APPNAME) $(EXTNAME) #$(TESTNAME)
.PHONY: all

# $(LIBC) $(VAPIPATH)/$(APPNAME).vapi: $(LIBV)

# $(APPC): $(APPV) $(VAPIPATH)/$(APPNAME).vapi

# $(APPO): $(APPC)
# 	$(CC) -c $< -o $@ $(CFLAGS)

$(APPNAME): $(LIBNAME) appsrc $(APPO)
	# $(CC) -c
	# mv -t $(OBJPATH)/app ./*.vala.o
	$(CC) -o $(APPNAME) $(APPO) $(LIBNAME) $(CFLAGS) $(CLIBS)

$(LIBNAME): $(LIBV)
	$(VALAC) -c $(LIBV) $(LJSC) --vapi=$(VAPIPATH)/$(APPNAME).vapi --header=$(GENPATH)/lib/$(APPNAME).h $(FLAGS) $(LIBS) --vapidir=$(VAPIPATH) --pkg jshandler -X -pie -X -fPIE
	mv -t $(OBJPATH)/lib ./*.o
	ar -rs $(LIBNAME) $(LIBO)
	ranlib $(LIBNAME)

$(EXTNAME): $(EXTV)
	valac --library=singularity-ext -H singularity-ext.h $(EXTV) --pkg webkit2gtk-web-extension-4.0 -X -fPIC -X -shared -o singularity-ext.so

$(TESTNAME): $(LIBNAME) testsrc $(TESTO)
	$(CC) -o $(TESTNAME) $(TESTO) $(LIBNAME) $(CFLAGS) $(CLIBS) `$(PKGCONFIG) --cflags --libs valadate-1.0` -pie -fPIE

.PHONY: appsrc
appsrc: $(APPV)
	$(VALAC) -C $(APPV) $(FLAGS) $(LIBS) --vapidir=$(VAPIPATH) --pkg $(APPNAME) --pkg jshandler
	cp -t $(GENPATH)/app $(SRCPATH)/lib/jshandler.c
	cp -t $(GENPATH)/lib $(SRCPATH)/lib/jshandler.h
	mv -t $(GENPATH)/app $(SRCPATH)/app/*.c

$(OBJPATH)/app/jshandler.o: $(SRCPATH)/lib/jshandler.c
	$(CC) -c $< -o $@ $(CFLAGS) -pie -fPIE
	cp $(SRCPATH)/lib/jshandler.h $(GENPATH)/lib

.PHONY: testsrc
testsrc: $(TESTV)
	$(VALAC) -C $(TESTV) $(FLAGS) $(LIBS) --vapidir=$(VAPIPATH) --library $(TESTNAME) --gir $(TESTNAME).gir --pkg valadate-1.0 --pkg $(APPNAME)
	# valac --library $(TESTNAME) --gir $(TESTNAME)-0.gir --pkg valadate-1.0 $(LIBS) --vapidir=$(VAPIPATH) --pkg $(APPNAME) -X -pie -X -fPIE $(TESTV) -X -I$(GENPATH)/lib -X $(LIBNAME)
	mv -t $(GENPATH)/test $(SRCPATH)/test/*.c

.PHONY: test
test: $(TESTNAME)
	./$(TESTNAME) --tap

.PHONY: clean
clean:
	rm -f $(APPNAME)
	rm -f $(LIBNAME)
	rm -rf $(GENPATH) $(OBJPATH) $(VAPIPATH)/$(APPNAME).vapi

.PHONY: schema-install
schema-install:
	mkdir -p /usr/local/share/$(APPNAME)
	mkdir -p /usr/local/share/$(APPNAME)/schemas
	cp -f data/schemas/*.sql /usr/local/share/$(APPNAME)/schemas
	cp -f data/org.df458.$(APPNAME).gschema.xml /usr/share/glib-2.0/schemas
	glib-compile-schemas /usr/share/glib-2.0/schemas

.PHONY: ext-install
ext-install:
	cp -f $(APPNAME)-ext.so /usr/local/share/$(APPNAME)

.PHONY: install
install: schema-install ext-install
	cp -f $(APPNAME) /usr/local/bin
	cp -f data/default.css /usr/local/share/$(APPNAME)
	cp -f data/*.png /usr/local/share/$(APPNAME)
