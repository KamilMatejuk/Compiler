#include <iostream>
#include <fstream>
#include <string.h>
#include <vector>

using namespace std;

extern vector<string> run_parser(FILE * input);

int main(int argc, char const * argv[]){
  FILE * input;

  // check args
  if(argc != 3){
    cerr << "Please specify input and output files as respectively 2nd and 3rd argument" << endl;
    return -1;
  }

  // open file
  input = fopen(argv[1], "r");
  if(!input){
    cerr << "Couldn't open file " << argv[1] << endl;
    return -1;
  }
  vector<string> machine_code = run_parser(input);
  fclose(input);

  // save output to file
  ofstream output;
  output.open(argv[2]);
  for(std::vector<string>::iterator it = machine_code.begin(); it != machine_code.end(); ++it) {
    output << *it << endl;
  }
  output.close();

  // show output (temporarly)
  for(std::vector<string>::iterator it = machine_code.begin(); it != machine_code.end(); ++it) {
    cout << *it << endl;
  }

  return 0;
}
