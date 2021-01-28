FLAGS = -W -pedantic -std=c++17 -O3

.PHONY = all clean cleanall

all: virtual_machine virtual_machine-cln

virtual_machine: lexer.o parser.o mw.o main.o variables.h errors.h
	$(CXX) $^ -o $@
	strip $@

virtual_machine-cln: lexer.o parser.o mw-cln.o main.o
	$(CXX) $^ -o $@ -l cln
	strip $@

%.o: %.cc
	$(CXX) $(FLAGS) -c $^

lexer.cc: lexer.l parser.hh
	flex -o $@ $<

parser.cc parser.hh: parser.y
	bison -Wall -d -o parser.cc $^

clean:
	rm -f *.o parser.cc parser.hh lexer.cc

cleanall: clean
	rm -f virtual_machine virtual_machine-cln
