COMPONENT=NodeC

INCLUDE=-IdataStructures
INCLUDE+=-IdataStructures/interfaces/ -IdataStructures/modules
INCLUDE+=-Ilib/interfaces -Ilib/modules
CFLAGS += -DTOSH_DATA_LENGTH=28
CFLAGS+=$(INCLUDE)

include $(MAKERULES)
