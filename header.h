#include <string.h>
#include <string>
#include <vector>
using namespace std;


/*
*********************************************************************
***************************** variables *****************************
*********************************************************************
*/

// storing all required data for each variable
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
// returning type of used variable
struct found_var_type {
    found_var_type(): v1(), v2(), number(-1) {}
    public: enum {
        RegularInteger,
        VariableInteger,
        VariableArrayWithNumericIndex,
        VariableArrayWithVariableIndex,
        NotRecognisable } type;
    public: var v1;
    public: var v2;
    public: int number;
};

extern vector<var> vars;
extern long long memmoryIterator;

bool is_declared(string name);
bool is_iterator(string name);
void set_as_iterator(string name);
void remove_iterator(string name);
bool is_initialized(string name);
void initialize_variable(string name);
void declare_variable_int(string name);
void declare_variable_array(string name, int start, int end);

found_var_type check_var_type(string name);
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
