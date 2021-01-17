#include "header.h"

#include <iostream>
#include <string.h>
#include <string>
using namespace std;


extern int yylineno;


void yyerror(char const *s){
    if(s == "syntax error"){
        s = "Unrecognisable text";
    }
    cerr << "\nLine " << yylineno << ": " << s << endl;
    exit(-1);
}


void err(errors e, string var){
    string err = "";
    switch(e){
        case errors::BadArrayScope:
            err = "Wrong scope of variable '" + (string)var + "'";
            break;
        case errors::AlreadyDeclaredVar:
            err = "Multiple declarations of variable '" + (string)var + "'";
            break;
        case errors::UndeclaredVar:
            err = "Undeclared variable '" + (string)var + "'";
            break;
        case errors::UninitializedVar:
            err = "Uninitialized variable '" + (string)var + "'";
            break;
        case errors::BadVarType:
            err = "Wrong usage of variable '" + (string)var + "' according to its type";
            break;
        case errors::UnrecognizedText:
        default:
            err = "Couldn't recognise text '" + (string)var + "'";
            break;
    }
    yyerror(err.c_str());
}
