%code requires {
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
#include "header.h"
using namespace std;

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
// created machine code
string machine_code;

// methods
int  yylex(void);
void yyset_in(FILE * in_str);

string get_variable_to_rejestr(string name, char rejestr);
string save_variable_to_memmory(string name, char rejestr1, char rejestr2);
string add_ASM(char rejestr1, char rejestr2);
string substract_ASM(char rejestr1, char rejestr2);
string multiply_ASM(char rejestr1, char rejestr2);
string divide_ASM(char rejestr1, char rejestr2);
string modulo_ASM(char rejestr1, char rejestr2);
string create_constant_ASM(int value, char rejestr);

int  number_of_lines(string text);
string remove_empty_lines(string text);

/*
********************************************************************* 
******************************** parser *****************************
*********************************************************************
*/

%}
%define api.value.type {std::string}

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
        ss << create_constant_ASM(stoi($4), 'a') << "\n";
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
        ss << create_constant_ASM(stoi($4), 'a') << "\n";
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
************************* starting parsing **************************
*********************************************************************
*/
string run_parser(FILE * data){
    yyset_in(data);
    yyparse();

    return remove_empty_lines(machine_code);
}

/*
*********************************************************************
****************** body of methods used in parser *******************
*********************************************************************
*/


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
