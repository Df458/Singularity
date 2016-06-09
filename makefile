include config.mk

PKGLIBS=glib-2.0 libxml-2.0 webkit2gtk-4.0 sqlheavy-0.1 gee-0.8 granite libnotify
CFLAGS=-g -I generated/lib -Wno-incompatible-pointer-types `$(PKGCONFIG) --cflags $(PKGLIBS)`
CLIBS= -ldflib `$(PKGCONFIG) --libs $(PKGLIBS)`
FLAGS=-d . --thread
LIBS=--pkg webkit2gtk-4.0 --pkg libsoup-2.4 --pkg granite --pkg libxml-2.0 --pkg sqlheavy-0.1 --pkg glib-2.0 --pkg libnotify --pkg posix --pkg dflib

APPV := $(wildcard $(SRCPATH)/app/*.vala)
LIBV := $(wildcard $(SRCPATH)/lib/*.vala)
TESTV := $(wildcard $(SRCPATH)/test/*.vala)
APPC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(APPV))
LIBC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(LIBV))
TESTC := $(patsubst $(SRCPATH)/%.vala, $(GENPATH)/%.c, $(TESTV))
APPO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(APPV))
LIBO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(LIBV))
TESTO := $(patsubst $(SRCPATH)/%.vala, $(OBJPATH)/%.vala.o, $(TESTV))

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
TESTNAME=$(APPNAME)-test-0

$(OBJPATH)/app/%.vala.o: $(GENPATH)/app/%.c
	$(CC) -c $< -o $@ $(CFLAGS) -pie -fPIE

$(OBJPATH)/test/%.vala.o: $(GENPATH)/test/%.c
	$(CC) -c $< -o $@ $(CFLAGS) `$(PKGCONFIG) --cflags valadate-1.0` -pie -fPIE

# TODO: Uncomment after resolving PIC issue (Will probably just rebuild dflib)
all: $(LIBNAME) $(APPNAME) #$(TESTNAME)
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
	$(VALAC) -c $(LIBV) --vapi=$(VAPIPATH)/$(APPNAME).vapi --header=$(GENPATH)/lib/$(APPNAME).h $(FLAGS) $(LIBS) -X -pie -X -fPIE
	mv -t $(OBJPATH)/lib ./*.vala.o
	ar -rs $(LIBNAME) $(LIBO)
	ranlib $(LIBNAME)

$(TESTNAME): $(LIBNAME) testsrc $(TESTO)
	$(CC) -o $(TESTNAME) $(TESTO) $(LIBNAME) $(CFLAGS) $(CLIBS) `$(PKGCONFIG) --cflags --libs valadate-1.0` -pie -fPIE
# $(TESTNAME): $(LIBNAME)
# 	valac --library $(TESTNAME) --gir $(TESTNAME)-0.gir --pkg valadate-1.0 $(LIBS) --vapidir=$(VAPIPATH) --pkg $(APPNAME) -X -pie -X -fPIE $(TESTV) -X -I$(GENPATH)/lib -X $(LIBNAME)

.PHONY: appsrc
appsrc: $(APPV)
	$(VALAC) -C $(APPV) $(FLAGS) $(LIBS) --vapidir=$(VAPIPATH) --pkg $(APPNAME)
	mv -t $(GENPATH)/app $(SRCPATH)/app/*.c

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
