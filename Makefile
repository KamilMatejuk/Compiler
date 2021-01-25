FLAGS = -W -pedantic -std=c++17 -O3

.PHONY = all clean cleanall

all: kompilator

kompilator: lexer.o parser.o variables.o errors.o  main.o
	g++ $^ -o $@
	strip $@

%.o: %.cc
	g++ $(FLAGS) -c $^

lexer.cc: lexer.l parser.hh
	flex -o $@ $<

parser.cc parser.hh: parser.y
	bison -Wall -d -o parser.cc $^

clean:
	rm -f *.o parser.cc parser.hh lexer.cc

cleanall: clean
	rm -f kompilator
