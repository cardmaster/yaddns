# custom vars
TGT		:= yaddns
VERSION		:= 0.2-dev
INFO		:= http://gna.org/projects/yaddns

SERVICES	= dyndns

EXTRA_LIBS	= 

# global vars
CFLAGS		+= -DD_NAME="\"$(TGT)\"" -DD_VERSION="\"$(VERSION)\"" \
                   -DD_INFO="\"$(INFO)\"" -DENABLE_SYSLOG \
		   $(FPIC) -std=gnu99 -D_GNU_SOURCE \
		   -Wall -Wextra -Werror -Wbad-function-cast -Wshadow \
		   -Wcast-qual -Wold-style-definition -Wmissing-noreturn \
		   -Wstrict-prototypes -Waggregate-return -Wformat=2 \
		   -Wswitch-default -Wundef -Wbad-function-cast \
		   -Wunused-parameter -Wpointer-arith \
		   -I./include
LDFLAGS		+= -Wall
LDLIBS		+= $(EXTRA_LIBS)

ifeq ($(MODE), debug)
MAKEFLAGS	+= 'DEBUG=y'
CFLAGS		+= -g -DDEBUG
else
MAKEFLAGS	+=
CFLAGS		+= -Os -fomit-frame-pointer -DNDEBUG
endif

INSTALL		= /usr/bin/install
DESTDIR		= /usr/sbin

# files
core_sources	:= src/services.c $(wildcard src/*.c)
services_sources:= $(foreach service, $(SERVICES), $(addprefix src/services/, $(addsuffix .c, $(service))))
sources		:= $(core_sources) $(services_sources)
objects		:= $(sources:.c=.o)

# rules
.PHONY: all
all: $(TGT)

$(TGT): $(objects)
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@

# Generate services declarations
.PHONY: src/services.c
src/services.c:
	@echo > $@
	@echo '/* Autogenerated. Do NOT edit! */' >> $@
	@echo >> $@
	@echo "#include \"service.h\"" >> $@
	@echo "#include \"list.h\"" >> $@
	@echo >> $@
	@echo "struct list_head service_list;" >> $@
	@echo >> $@
	@for s in $(SERVICES); do echo "extern struct service $${s}_service;" >> $@; done
	@echo >> $@
	@echo "void services_populate_list(void)" >> $@
	@echo "{">> $@
	@echo "     INIT_LIST_HEAD(&service_list);" >> $@
	@for s in $(SERVICES); \
	do \
		echo "     list_add_tail( &$${s}_service.list, &service_list );" >> $@; \
	done
	@echo "}">> $@

.PHONY: install
install:
	$(INSTALL) -d $(DESTDIR)/usr/bin
	$(INSTALL) -m 770 $(TGT) $(DESTDIR)/usr/bin/

.PHONY: clean
clean:
	find -name "*.o" -delete
	rm -f src/services.c
	rm -f $(TGT)

.PHONY: mrproper
mrproper: clean