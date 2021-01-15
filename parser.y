%code requires {
using namespace std;
}
%{

/*
*********************************************************************
**************** declarations of methods and objects ****************
*********************************************************************
*/

#include "union_classes.h"
#include <iostream>
#include <string.h>
#include <vector>
#include <algorithm>
#include <stack>
using namespace std;

extern int yylineno;
long long memmoryOffset = 0;
long long outputCommandsSize = 0;
long long whileCommandsDecreaser = 0;
vector<string> machine_code;            // created machine code

stack<long long> doWhileJumpStack;
stack<long long> whileJumpStack;
stack<long long> ifJumpStack;
stack<long long> forJumpStack;
stack<char*> iteratorNamesStack;
stack<string> iteratorRegisterNamesStack;

// variables in program
struct var {
    var(): name_in_code(""), name_rejestr(""), initialized(false), scope_start(0), scope_end(0) {}
    string name_in_code;
    string name_rejestr;
    bool initialized;
    enum { integer, array } var_types;
    int scope_start;
    int scope_end;
};
vector<var> vars;

// possible errors
enum errors {
    BadArrayScope,      // error 0
    AlreadyDeclaredVar, // error 1
    UndeclaredVar,      // error 2, 8
    UninitializedVar,   // error 3, 5
    BadVarType,          // error 6, 7
    UnrecognizedText,   // error 4
};

// methods
int  yylex(void);
void yyset_in(FILE * in_str);
void yyerror(char const *s);
void err(errors e, char* var);
bool is_declared(char* name);
bool is_initialized(char* name);
void declare_variable_int(char* name);
void declare_variable_array(char* name, int start, int end);
void initialize_variable_int(char* name);
void initialize_variable_array(char* name, int index);
void read(class_identifier id);
void show_vars_array(); // temporary




/*
********************************************************************* 
******************************** parser *****************************
*********************************************************************
*/

%}
%union {
    char*   strval;
    long     ival;
    class_identifier* identifier;
}

%token <strval> T_PIDENTIFIER
%token <ival> T_NUM

%token T_ASSIGN ":="
%token T_COMMA ","
%token T_COLON ":"
%token T_SEMICOLON ";"
%token T_PAR_OPEN "("
%token T_PAR_CLOSE ")"

%token T_PLUS "+"
%token T_MINUS "-"
%token T_MULTIPLY "*"
%token T_DIVIDE "/"
%token T_MOD "%"

%token T_EQUAL "="
%token T_NOT_EQUAL "!="
%token T_GREATER ">"
%token T_LESS "<"
%token T_GREATER_EQUAL ">="
%token T_LESS_EQUAL "<="

%token T_DECLARE "DECLARE"
%token T_BEGIN "BEGIN"
%token T_END "END"
%token T_IF "IF"
%token T_THEN "THEN"
%token T_ELSE "ELSE"
%token T_ENDIF "ENDIF"
%token T_WHILE "WHILE"
%token T_DO "DO"
%token T_ENDWHILE "ENDWHILE"
%token T_REPEAT "REPEAT"
%token T_UNTIL "UNTIL"
%token T_FOR "FOR"
%token T_FROM "FROM"
%token T_TO "TO"
%token T_DOWNTO "DOWNTO"
%token T_ENDFOR "ENDFOR"
%token T_READ "READ"
%token T_WRITE "WRITE"

%type <identifier> identifier

%%
input:
    "DECLARE" declarations "BEGIN" commands "END" {
        // machine_code.push_back("1");
        machine_code.push_back("HALT");
    }
    | "BEGIN" commands "END" {
        // machine_code.push_back("2");
        machine_code.push_back("HALT");
    }

declarations:
    declarations "," T_PIDENTIFIER {
        // check if var $3 exists and if not, create in memmory
        declare_variable_int($3);
        machine_code.push_back("3");
    }
    | declarations "," T_PIDENTIFIER "(" T_NUM ":" T_NUM ")" {
        // check if var $3 exists and if not, create in memmory
        declare_variable_array($3, $5, $7);
        machine_code.push_back("4");
    }
    | T_PIDENTIFIER {
        // check if var $1 exists and if not, create in memmory
        declare_variable_int($1);
        machine_code.push_back("5");
    }
    | T_PIDENTIFIER "(" T_NUM ":" T_NUM ")" {
        // check if var $1 exists and if not, create in memmory
        declare_variable_array($1, $3, $5);
        machine_code.push_back("6");
    }

commands:
    commands command {
        // end of command $2
        machine_code.push_back("7");
    }
    | command {
        // end of command $1
        machine_code.push_back("8");
    }

command:
    identifier ":=" expression ";" {
        machine_code.push_back("9");
    }
    | "IF" condition "THEN" commands "ELSE" commands "ENDIF" {
        machine_code.push_back("10");
    }
    | "IF" condition "THEN" commands "ENDIF" {
        machine_code.push_back("11");
    }
    | "WHILE" condition "DO" commands "ENDWHILE" {
        machine_code.push_back("12");
    }
    | "REPEAT" commands "UNTIL" condition ";" {
        machine_code.push_back("13");
    }
    | "FOR" T_PIDENTIFIER "FROM" value "TO" value "DO" commands "ENDFOR" {
        machine_code.push_back("14");
    }
    | "FOR" T_PIDENTIFIER "FROM" value "DOWNTO" value "DO" commands "ENDFOR" {
        machine_code.push_back("15");
    }
    | "READ" identifier ";" {
        // STORE value of var $2, if exists
        read(*$2);
        machine_code.push_back("16");
    }
    | "WRITE" value ";" {
        // PUT value of $2, if exists
        machine_code.push_back("17");
    }

expression:
    value {
        machine_code.push_back("18");
    }
    | value "+" value {
        machine_code.push_back("19");
    }
    | value "-" value {
        machine_code.push_back("20");
    }
    | value "*" value {
        machine_code.push_back("21");
    }
    | value "/" value {
        machine_code.push_back("22");
    }
    | value "%" value {
        machine_code.push_back("23");
    }

condition:
    value "=" value {
        machine_code.push_back("24");
    }
    | value "!=" value {
        machine_code.push_back("25");
    }
    | value "<" value {
        machine_code.push_back("26");
    }
    | value ">" value {
        machine_code.push_back("27");
    }
    | value "<=" value {
        machine_code.push_back("28");
    }
    | value ">=" value {
        machine_code.push_back("29");
    }

value:
    T_NUM {
        machine_code.push_back("30");
    }
    | identifier {
        machine_code.push_back("31");
    }

identifier:
    T_PIDENTIFIER {
        // nothing
        $$ = new class_identifier($1);
        machine_code.push_back("32");
    }
    | T_PIDENTIFIER "(" T_PIDENTIFIER ")" {
        $$ = new class_identifier($1, $3);
        machine_code.push_back("33");
    }
    | T_PIDENTIFIER "(" T_NUM ")" {
        $$ = new class_identifier($1, $3);
        machine_code.push_back("34");
    }

%%

/*
*********************************************************************
****************** body of methods used in parser *******************
*********************************************************************
*/

void yyerror(char const *s){
    if(s == "syntax error"){
        s = "Unrecognisable text";
    }
    cerr << "\nLine " << yylineno << ": " << s << endl;
    exit(-1);
}

void err(errors e, char* var){
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

vector<string> run_parser(FILE * data){
    machine_code.push_back("RESET a");

    yyset_in(data);
    yyparse();

    show_vars_array();

    return machine_code;
}


/* display on standard output the table with data in array of variable
at current time */
void show_vars_array(){
    cout << "\nVars" << endl;
    cout << "name_in_code \t " << "name_rejestr \t " << "initialized \t " << "var_types \t " << "scope_start \t " << "scope_end" << endl;
    for(std::vector<var>::iterator it = vars.begin(); it != vars.end(); ++it) {
        cout << (*it).name_in_code << " \t\t " << (*it).name_rejestr << " \t\t " << (*it).initialized << " \t\t " << (*it).var_types << " \t\t " << (*it).scope_start << " \t\t " << (*it).scope_end << endl;
    }
    cout << endl;
}


/* check if variable of given name was previously declared */
bool is_declared(char* name){
    for(var v : vars) {
        if(v.name_in_code == name){
            return true;
        }
    }
    return false;
}

/* check if variable of given name was already initialized */
bool is_initialized(char* name){
    for(var v : vars) {
        if(v.name_in_code == name){
            return v.initialized;
        }
    }
    return false;
}


/* check if the name is not taken, and add int variable into table */
void declare_variable_int(char* name){
    /* not used name */
    if(is_declared(name)){
        err(errors::AlreadyDeclaredVar, name);
    }
    struct var temp_v;
    temp_v.name_in_code = name;
    temp_v.var_types = var::integer;
    vars.push_back(temp_v);
}


/* check if the name is not taken, and add array variable into table */
void declare_variable_array(char* name, int start, int end){
    /* correct scope */
    if(start >= end){
        err(errors::BadArrayScope, name);
    }
    /* not used name */
    if(is_declared(name)){
        err(errors::AlreadyDeclaredVar, name);
    }
    struct var temp_v;
    temp_v.name_in_code = name;
    temp_v.var_types = var::array;
    temp_v.scope_start = start;
    temp_v.scope_end = end;
    vars.push_back(temp_v);
    /* free memory rejestr slot */
    /* vector<string> all {"a", "b", "c", "d", "e", "f"};
    vector<string> taken;
    for(var v : vars) {
        taken.push_back(v.name_rejestr);
    }
    for (string a : all){
        if(find(taken.begin(), taken.end(), a) == taken.end()){
            struct var temp_v;
            temp_v.name_in_code = name;
            temp_v.name_rejestr = a;
            temp_v.var_types = var::array;
            temp_v.scope_start = start;
            temp_v.scope_end = end;
            vars.push_back(temp_v);
            return;
        }
    }
    string err = "Not enough rejestr slots {a,b,c,d,e,f} for creating variable '" + (string)name + "'";
    char err_array[100];
    strcpy(err_array, err.c_str());
    yyerror(err_array); */
}


/* check if is declared, if type is correct and change to initialized */
void initialize_variable_int(char* name){
    /* not used name */
    if(!is_declared(name)){
        err(errors::UndeclaredVar, name);
    }
    for(var v : vars) {
        if(v.name_in_code == name){
            if(v.var_types != var::integer){
                err(errors::BadVarType, name);
            }
            v.initialized = true;
        }
    }
}

/* check if is declared, if type and scope is correct and change to initialized */
void initialize_variable_array(char* name, int index){
    /* not used name */
    if(!is_declared(name)){
        err(errors::UndeclaredVar, name);
    }
    for(var v : vars) {
        if(v.name_in_code == name){
            if(v.var_types != var::array){
                err(errors::BadVarType, name);
            }
            if(index < v.scope_start || index > v.scope_end){
                err(errors::BadArrayScope, name);
            }
            v.initialized = true;
        }
    }
}


/* check if declared, if type correct and store value */
void read(class_identifier id){
    switch(id.type){
        case class_identifier::id:
            initialize_variable_int(id.var_name);
            break;
        case class_identifier::array_with_var:
            initialize_variable_array(id.var_name, 0); // TODO
            break;
        case class_identifier::array_with_num:
            initialize_variable_array(id.var_name, id.num_index);
            break;
    }
}