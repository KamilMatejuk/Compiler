#include <iostream>
#include <fstream>
#include <string.h>
#include <vector>

using namespace std;

extern string run_parser(FILE * input, bool debug);

int main(int argc, char const * argv[]){
  FILE * input;

  // check args
  if(argc < 3 || argc > 5){
    cerr << "Please specify input and output files as respectively 2nd and 3rd argument" << endl;
    cerr << "You can add --debug as a last argument, for debugging options";
    return -1;
  }

  // open file
  input = fopen(argv[1], "r");
  if(!input){
    cerr << "Couldn't open file " << argv[1] << endl;
    return -1;
  }
  bool debug = (argc == 4 && string(argv[3]) == "--debug");
  string machine_code = run_parser(input, debug);
  fclose(input);

  // save output to file
  ofstream output;
  output.open(argv[2]);
  output << machine_code;
  output.close();

  return 0;
}