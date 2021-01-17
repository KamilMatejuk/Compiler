#include "header.h"

#include <string.h>
#include <string>
using namespace std;


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
