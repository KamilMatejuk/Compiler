%code requires {
// #include "variables.h"
// #include "errors.h"
using namespace std;
}
%{

/*
*********************************************************************
**************** declarations of methods and objects ****************
*********************************************************************
*/


#include <algorithm>
#include <iostream>
#include <sstream>
#include <string.h>
#include <string>
#include <vector>
#include <regex>
#include <stack>
#include <map>
#include "variables.h"
#include "errors.h"
using namespace std;

extern int yylineno;
vector<var> vars;           // list of declared variables
// list of things currently stored in each rejestrs
// possible values: "None", name_of_variable, number, "condition", "value"
map<char, string> rejestrs = {
    { 'a', "None" },
    { 'b', "None" },
    { 'c', "None" },
    { 'd', "None" },
    { 'e', "None" },
    { 'f', "None" },
};
long long memmoryIterator = 0; // starting index of used memmory slots
string machine_code;        // created machine code

// methods
extern void err(errors e, string var);

int  yylex(void);
void yyset_in(FILE * in_str);
void yyerror(char const *s);
bool is_declared(string name);
bool is_iterator(string name);
void remove_iterator(string name);
bool is_initialized(string name);
void initialize_variable(string name);
void declare_variable_int(string name);
void declare_variable_array(string name, int start, int end);

string get_variable_to_rejestr(string name, char rejestr);
string save_variable_to_memmory(string name, char rejestr1, char rejestr2);

string add_ASM(char rejestr1, char rejestr2);
string substract_ASM(char rejestr1, char rejestr2);
string multiply_ASM(char rejestr1, char rejestr2);
string divide_ASM(char rejestr1, char rejestr2);
string modulo_ASM(char rejestr1, char rejestr2);
string create_constant_ASM(string value, char rejestr);

int  number_of_lines(string text);
string remove_empty_lines(string text);
string check_var_type(string name);
bool is_number(string& s);

/*
********************************************************************* 
******************************** parser *****************************
*********************************************************************
*/

%}
%define api.value.type {std::string}

/* %union {
    string   str;
    long    num;
} */

%token T_PIDENTIFIER
%token T_NUM

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

%%

/* 
Rejestrs:
    conditions return on 'c' (1 is true, 0 is false)
*/
input:
    "DECLARE" declarations "BEGIN" commands "END" {
        stringstream ss;
        // ss << $2 << "\n" << $4 << "HALT";
        ss << $4 << "HALT";
        machine_code = ss.str();
    }
    | "BEGIN" commands "END" {
        stringstream ss;
        ss << $2 << "HALT";
        machine_code = ss.str();
    }

declarations:
    declarations "," T_PIDENTIFIER {
        declare_variable_int($3);
    }
    | declarations "," T_PIDENTIFIER "(" T_NUM ":" T_NUM ")" {
        declare_variable_array($3, stoi($5), stoi($7));
    }
    | T_PIDENTIFIER {
        declare_variable_int($1);
    }
    | T_PIDENTIFIER "(" T_NUM ":" T_NUM ")" {
        declare_variable_array($1, stoi($3), stoi($5));
    }

commands:
    commands command {
        stringstream ss;
        ss << $1 << "\n" << $2 << "\n";
        $$ = ss.str();
    }
    | command {
        $$ = $1;
    }

command:
    identifier ":=" expression ";" {
        stringstream ss;
        ss << $3 << "\n";
        ss << save_variable_to_memmory($1, 'b', 'c') << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ELSE" commands "ENDIF" {
        int commands_1_lines = number_of_lines($4);
        int commands_2_lines = number_of_lines($6);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO c " << (commands_1_lines + 2) << " \n";
        ss << $4 << "\n";
        ss << "JZERO c " << (commands_2_lines + 1) << " \n";
        ss << $6 << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ENDIF" {
        int commands_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO c " << (commands_1_lines + 1) << " \n";
        ss << $4 << "\n";
        $$ = ss.str();
    }
    | "WHILE" condition "DO" commands "ENDWHILE" {
        int condition_1_lines = number_of_lines($2);
        int commands_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO c " << (commands_1_lines + 2) << " \n";
        ss << $4 << "\n";
        ss << "JZERO c -" << (condition_1_lines + commands_1_lines + 1) << " \n";
        $$ = ss.str();
    }
    | "REPEAT" commands "UNTIL" condition ";" {
        int commands_1_lines = number_of_lines($2);
        int condition_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << $4 << "\n";
        ss << "JZERO c 2 \n";
        ss << "JZERO c -" << (commands_1_lines + condition_1_lines + 1) << " \n";
        $$ = ss.str();
    }
    | "FOR" iterator "FROM" value "TO" value "DO" commands "ENDFOR" {
        initialize_variable($2);
        stringstream ss;
        ss << "RESET f \n";
        ss << create_constant_ASM($4, 'a') << "\n";
        for(int i = stoi($4); i < stoi($6); i++){
            ss << $8 << "\n";
            ss << "INC f \n";
        }
        $$ = ss.str();
        remove_iterator($2);
    }
    | "FOR" iterator "FROM" value "DOWNTO" value "DO" commands "ENDFOR" {
        initialize_variable($2);
        stringstream ss;
        ss << "RESET f \n";
        ss << create_constant_ASM($4, 'a') << "\n";
        for(int i = stoi($4); i > stoi($6); i--){
            ss << $8 << "\n";
            ss << "DEC f \n";
        }
        $$ = ss.str();
        remove_iterator($2);
    }
    | "READ" identifier ";" {
        stringstream ss;
        ss << "RESET a \n";
        ss << "GET a \n";
        ss << "LOAD b a \n";
        ss << save_variable_to_memmory($2, 'b', 'c') << "\n";
        $$ = ss.str();
        initialize_variable($2);
    }
    | "WRITE" value ";" {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << "RESET a \n";
        ss << "STORE b \n";
        ss << "PUT a \n";
        $$ = ss.str();
    }

expression:
    value {
        $$ = get_variable_to_rejestr($1, 'b');
    }
    | value "+" value {
        stringstream ss;
        /* TODO w dłuższej wersji podział na takie same i pzresunięcie binarne (mnożenie razy 2) zamiast dodawania. */
        // if($1 == $3){
        //     ss << get_variable_to_rejestr($1, 'b');
        //     ss << multiply_ASM('b', 2);
        // } else {
        //     ss << get_variable_to_rejestr($1, 'b');
        //     ss << get_variable_to_rejestr($3, 'c');
        //     ss << add_ASM('b', 'c');
        // }
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << add_ASM('b', 'c') << "\n";
        $$ = ss.str();
    }
    | value "-" value {
        stringstream ss;
        /* TODO w dłuższej wersji podział na takie same i wyzerowanie elementu zamiast odejmowania */
        // if($1 == $3){
        //     ss << get_variable_to_rejestr($1, 'b');
        // } else {
        //     ss << get_variable_to_rejestr($1, 'b');
        //     ss << get_variable_to_rejestr($3, 'c');
        //     ss << add_ASM('b', 'c');
        // }
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << substract_ASM('b', 'c') << "\n";
        $$ = ss.str();
    }
    | value "*" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << multiply_ASM('b', 'c') << "\n";
        $$ = ss.str();
    }
    | value "/" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << divide_ASM('b', 'c') << "\n";
        $$ = ss.str();
    }
    | value "%" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << modulo_ASM('b', 'c') << "\n";
        $$ = ss.str();
    }

condition: // returns on rejestr c, works on (c, d)
    value "=" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        // ...
    }
    | value "!=" value {
        // machine_code.push_back("25");
    }
    | value "<" value {
        // machine_code.push_back("26");
    }
    | value ">" value {
        // machine_code.push_back("27");
    }
    | value "<=" value {
        // machine_code.push_back("28");
    }
    | value ">=" value {
        // machine_code.push_back("29");
    }

value:
    T_NUM {
        $$ = $1;
    }
    | identifier {
        $$ = $1;
    }

identifier:
    T_PIDENTIFIER {
        $$ = $1;
    }
    | T_PIDENTIFIER "(" T_PIDENTIFIER ")" {
        stringstream ss;
        ss << $1 << "(" << $3 << ")";
        $$ = ss.str();
    }
    | T_PIDENTIFIER "(" T_NUM ")" {
        stringstream ss;
        ss << $1 << "(" << $3 << ")";
        $$ = ss.str();
    }

iterator: // saved on rejestr f
    T_PIDENTIFIER {
        if(is_declared($1) || is_iterator($1)){
            err(errors::AlreadyDeclaredVar, $1);
        }
        declare_variable_int($1);
        for(var v : vars) {
            if(v.name == $1){
                v.initialized = true;
                v.iterator = true;
            }
        }
        $$ = $1;
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


string run_parser(FILE * data){
    yyset_in(data);
    yyparse();

    return remove_empty_lines(machine_code);
}


/* check if variable of given name was previously declared */
bool is_declared(string name){
    for(var v : vars) {
        if(v.name == name){
            return true;
        }
    }
    return false;
}

/* check if variable of given name was already initialized */
bool is_initialized(string name){
    for(var v : vars) {
        if(v.name == name){
            return v.initialized;
        }
    }
    return false;
}

/* check if variable of given name was already initialized */
bool is_iterator(string name){
    for(var v : vars) {
        if(v.name == name){
            return v.iterator;
        }
    }
    return false;
}

/* check if used type is correct, and returns only name of variable */
string check_var_type(string name){
    int par1 = name.find("(", 0);
    if(par1 > -1){
        string n = name.substr(0, par1);
        int len = name.length() - par1 - 2;
        string arg = name.substr(par1 + 1, len);
        if(is_number(arg)){
            /* array with numeric argument */
            int a = stoi(arg);
            for(var v : vars) {
                if(v.name == n){
                    if(v.var_type != var::array || v.scope_start > a || v.scope_end < a){
                        err(errors::BadVarType, name);
                    }
                    return n;
                }
            }
        } else {
            /* array with variable argument */

        }

    } else {
        /* regular variable type integer */
        for(var v : vars) {
            if(v.name == name){
                if(v.var_type != var::integer){
                    err(errors::BadVarType, name);
                }
                return name;
            }
        }
    }
    return name;
}

bool is_number(string& s){
    return !s.empty() && std::find_if(s.begin(), 
        s.end(), [](unsigned char c) { return !std::isdigit(c); }) == s.end();
}


/* delete variable after its scope */
void remove_iterator(string name){
    int i = 0;
    for(var v : vars) {
        if(v.name == name){
            break;
        }
        i++;
    }
    vars.erase(vars.begin() + (i - 1));
}



/* check if the name is not taken, and add int variable into table */
void declare_variable_int(string name){
    /* not used name */
    if(is_declared(name)){
        err(errors::AlreadyDeclaredVar, name);
    }
    struct var v;
    v.name = name;
    v.memmoryIndex = memmoryIterator++;
    v.var_type = var::integer;
    vars.push_back(v);
}


/* check if the name is not taken, and add array variable into table */
void declare_variable_array(string name, int start, int end){
    /* correct scope */
    if(start >= end){
        err(errors::BadArrayScope, name);
    }
    /* not used name */
    if(is_declared(name)){
        err(errors::AlreadyDeclaredVar, name);
    }
    struct var v;
    v.name = name;
    v.memmoryIndex = memmoryIterator++;
    v.var_type = var::array;
    v.scope_start = start;
    v.scope_end = end;
    vars.push_back(v);
    memmoryIterator += end - start;
}


/* check if is declared, if type is correct and change to initialized */
void initialize_variable(string name){
    string n = check_var_type(name);
    for(var v : vars) {
        if(v.name == n){
            v.initialized = true;
        }
    }
}


string get_variable_to_rejestr(string name, char rejestr){
    /* TODO - jego funkcja myLOAD() */
    return "\n";
}
string save_variable_to_memmory(string name, char rejestr1, char rejestr2){
    stringstream ss;
    int par1 = name.find("(", 0);
    if(par1 > -1){
        string n = name.substr(0, par1);
        int len = name.length() - par1 - 2;
        string arg = name.substr(par1 + 1, len);
        if(is_number(arg)){
            /* array with numeric argument */
            int a = stoi(arg);
            for(var v : vars) {
                if(v.name == n){
                    if(v.var_type != var::array || v.scope_start > a || v.scope_end < a){
                        err(errors::BadVarType, name);
                    }
                    ss << create_constant_ASM(a, 'a');
                    ss << "LOAD " << rejestr2 << " a";
                    ss << create_constant_ASM(v.memmoryIndex, 'a');
                    ss << "SUB " << rejestr2 << " a";
                    ss << create_constant_ASM(v.scope_start, 'a');
                    ss << "ADD a " << rejestr2;
                    return ss.str();
                }
            }
        } else {
            /* array with variable argument */

        }

    } else {
        /* regular variable type integer */
        for(var v : vars) {
            if(v.name == name){
                if(v.var_type != var::integer){
                    err(errors::BadVarType, name);
                }
                ss << create_constant_ASM(v.memmoryIndex, 'a');
                ss << "STORE " << rejestr1 << " a";
                return ss.str();
            }
        }
    }
    return name;
    return "\n";
}
string add_ASM(char rejestr1, char rejestr2){
    return "\n";
}
string substract_ASM(char rejestr1, char rejestr2){
    return "\n";
}
string multiply_ASM(char rejestr1, char rejestr2){
    return "\n";
}
string divide_ASM(char rejestr1, char rejestr2){
    return "\n";
}
string modulo_ASM(char rejestr1, char rejestr2){
    return "\n";
}

string create_constant_ASM(int value, char rejestr){
    return "\n";
}

int number_of_lines(string text){
    text = remove_empty_lines(text);
    int lines = 1;
    string::size_type pos = 0;
    while ((pos = text.find("\n", pos)) != string::npos) {
        lines++;
        pos += 1;
    }
    int n = text.length();
    if(n > 2 && text.substr(n-1, 1) == "\n"){
        lines--;
    }
    return lines;
}

string remove_empty_lines(string text){
    for (string::size_type i = text.size(); i > 1; i--) {
        if(text[i] == text[i-1]){
            text.erase(i, 1);
        }
    }
    return text;
}

/*
*********************************************************************
************************* assembler code ****************************
*********************************************************************
*/