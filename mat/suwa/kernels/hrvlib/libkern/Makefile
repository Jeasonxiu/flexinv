FFLAGS= $(FFLAG) -e
LFLAGS= -L$(MYLIB) 

.f.o:
	f77 $(FFLAGS) -Nl100 -c $*.f

.f.a:
	f77 $(FFLAGS) -Nl100 -c   $<
	ar rv $@ $*.o
	rm -f $*.o

#-------------------------------------------------------------------------

LIB=libkern

$(MYLIB)/$(LIB).a: \
	$(MYLIB)/$(LIB).a(ebspl.o) \
	$(MYLIB)/$(LIB).a(radial_basis.o)

$(MYLIB)/$(LIB).a: ; ranlib $(MYLIB)/$(LIB).a

