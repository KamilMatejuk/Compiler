using namespace std;
#include <string.h>
#include <string>

void yyerror(char const *s);

enum errors {
    BadArrayScope,      // error 0
    AlreadyDeclaredVar, // error 1
    UndeclaredVar,      // error 2, 8
    UninitializedVar,   // error 3, 5
    BadVarType,         // error 6, 7
    UnrecognizedText,   // error 4
};

void err(errors e, string var){
    string err = "";
    switch(e){
        case BadArrayScope:
            break;
        case AlreadyDeclaredVar:
            err = "Multiple declarations of variable '" + (string)var + "'";
            break;
        case UndeclaredVar:
            err = "Undeclared variable '" + (string)var + "'";
            break;
        case UninitializedVar:
            err = "Undinitialized variable '" + (string)var + "'";
            break;
        case BadVarType:
            err = "Wrong usage of variable '" + (string)var + "' according to its type";
            break;
        case UnrecognizedText:
        default:
            err = "Couldn't recognise text '" + (string)var + "'";
            break;
    }
    yyerror(err.c_str());
}