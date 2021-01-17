#include <string.h>
#include <string>
#include <vector>
using namespace std;


/*
*********************************************************************
***************************** variables *****************************
*********************************************************************
*/

struct var {
    var(): name(""), memmoryIndex(-1), initialized(false), iterator(false), var_type(integer), scope_start(-1), scope_end(-1) {}
    public: string name;
    public: long long memmoryIndex;
    public: bool initialized;
    public: bool iterator;
    public: enum { integer, array } var_type;
    public: int scope_start;
    public: int scope_end;
};

extern vector<var> vars;
extern long long memmoryIterator;

bool is_declared(string name);
bool is_iterator(string name);
void remove_iterator(string name);
bool is_initialized(string name);
void initialize_variable(string name);
void declare_variable_int(string name);
void declare_variable_array(string name, int start, int end);

string check_var_type(string name);
bool is_number(string& s);


/*
*********************************************************************
****************************** errors *******************************
*********************************************************************
*/
enum errors {
    BadArrayScope,      // error 0
    AlreadyDeclaredVar, // error 1
    UndeclaredVar,      // error 2, 8
    UninitializedVar,   // error 3, 5
    BadVarType,         // error 6, 7
    UnrecognizedText,   // error 4
};

void err(errors e, string var);
void yyerror(char const *s);
