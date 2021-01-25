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
#include <bitset>
#include <regex>
#include "header.h"
using namespace std;

// created machine code
string machine_code;

// methods
int  yylex(void);
void yyset_in(FILE * in_str);

string get_variable_to_rejestr(string name, char rejestr);
string save_iterator_to_memmory(string name, char rejestr);
string save_variable_to_memmory(string name, char rejestr1, char rejestr2);
string create_constant_value(int value, char rejestr);

int  number_of_lines(string text);
string remove_empty_lines(string text);

/*
********************************************************************* 
******************************** tokens *****************************
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
********************************************************************* 
******************************* grammar *****************************
*********************************************************************
*/

input:
    "DECLARE" declarations "BEGIN" commands "END" {
        stringstream ss;
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
        // if(!is_declared($3)){
        //     err(errors::UndeclaredVar, $3);
        // }
        // else if(!is_initialized($3)){
        //     err(errors::UninitializedVar, $3);
        // }
        ss << $3 << "\n";
        ss << save_variable_to_memmory($1, 'b', 'c') << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ELSE" commands "ENDIF" {
        int commands_1_lines = number_of_lines($4);
        int commands_2_lines = number_of_lines($6);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 2) << "\n";
        ss << $4 << "\n";
        ss << "JUMP " << (commands_2_lines + 1) << "\n";
        ss << $6 << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ENDIF" {
        int commands_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 1) << "\n";
        ss << $4 << "\n";
        $$ = ss.str();
    }
    | "WHILE" condition "DO" commands "ENDWHILE" {
        int condition_1_lines = number_of_lines($2);
        int commands_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 2) << " \n";
        ss << $4 << "\n";
        ss << "JUMP -" << (condition_1_lines + commands_1_lines + 1) << "\n";
        $$ = ss.str();
    }
    | "REPEAT" commands "UNTIL" condition ";" {
        int commands_1_lines = number_of_lines($2);
        int condition_1_lines = number_of_lines($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << $4 << "\n";
        ss << "JZERO b 2 \n";
        ss << "JUMP -" << (commands_1_lines + condition_1_lines + 1) << "\n";
        $$ = ss.str();
    }
    | "FOR" iterator "FROM" value "TO" value "DO" commands "ENDFOR" {
        int commands_1_lines = number_of_lines($8);

        stringstream ss;
        ss << get_variable_to_rejestr($6, 'c');
        ss << get_variable_to_rejestr($4, 'b');
        ss << save_iterator_to_memmory("iter" + $2, 'c');
        ss << "DEC a \n";
        ss << "STORE b c \n";
        ss << $8;
        ss << get_variable_to_rejestr($2, 'b');
        ss << "INC a \n";
        ss << "LOAD c c \n";
        ss << "SUB c b \n";
        ss << "JZERO c 3 \n";
        ss << "INC b \n";
        ss << "JUMP -" << (commands_1_lines + 6) << "\n";
        $$ = ss.str();
        remove_iterator($2);
    }
    | "FOR" iterator "FROM" value "DOWNTO" value "DO" commands "ENDFOR" {
        int commands_1_lines = number_of_lines($8);

        stringstream ss;
        ss << get_variable_to_rejestr($6, 'c');
        ss << get_variable_to_rejestr($4, 'b');
        ss << save_iterator_to_memmory("iter" + $2, 'c');
        ss << "DEC a \n";
        ss << "STORE b c \n";
        ss << $8;
        ss << get_variable_to_rejestr($2, 'b');
        ss << "INC a \n";
        ss << "LOAD c c \n";
        ss << "SUB c b \n";
        ss << "JZERO c 3 \n";
        ss << "DEC b \n";
        ss << "JUMP -" << (commands_1_lines + 6) << "\n";
        $$ = ss.str();
        remove_iterator($2);
    }
    | "READ" identifier ";" {
        stringstream ss;
        ss << "GET b \n";
        ss << save_variable_to_memmory($2, 'b', 'c') << "\n";
        initialize_variable($2);
        $$ = ss.str();
    }
    | "WRITE" value ";" {
        stringstream ss;
        ss << get_variable_to_rejestr($2, 'b') << "\n";
        ss << "PUT b" << "\n";
        $$ = ss.str();
    }

expression:
    value {
        $$ = get_variable_to_rejestr($1, 'b');
    }
    | value "+" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << "ADD b c \n";
        $$ = ss.str();
    }
    | value "-" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << "SUB b c \n";
        $$ = ss.str();
    }
    | value "*" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << "RESET d \n";
        ss << "ADD d b \n;";
        ss << "SUB b c \n";
        ss << "JZERO b 6 \n";
        ss << "RESET b \n";
        ss << "ADD b c \n;";
        ss << "RESET c \n";
        ss << "ADD c d \n;";
        ss << "JUMP 3 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n;";
        ss << "SUB d d \n";
        ss << "JZERO b 11 \n";
        ss << "JODD b 4 \n";
        ss << "SHR b \n";
        ss << "ADD c c \n";
        ss << "JUMP -4 \n";
        ss << "ADD d c \n";
        ss << "SHR b \n";
        ss << "ADD c c \n";
        ss << "JUMP -8 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n;";
        $$ = ss.str();
    }
    | value "/" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << "JZERO c 25 \n"; // cannot devide by 0
        ss << "RESET d \n";
        ss << "ADD d b \n";
        ss << "RESET f \n";
        ss << "INC f \n";
        ss << "SUB b c \n";
        ss << "JZERO b 6 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "SHL c \n";
        ss << "SHL f \n";
        ss << "JUMP -6 \n";
        ss << "RESET e \n";
        ss << "ADD e c \n";
        ss << "SUB c d \n";
        ss << "JZERO c 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB d e \n";
        ss << "ADD b f \n";
        ss << "RESET c \n";
        ss << "ADD c e \n";
        ss << "SHR c \n";
        ss << "SHR f \n";
        ss << "JZERO f 3 \n";
        ss << "JUMP -12 \n";
        ss << "SUB b b \n";
        $$ = ss.str();
    }
    | value "%" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'b') << "\n";
        ss << get_variable_to_rejestr($3, 'c') << "\n";
        ss << "JZERO c 30 \n"; // modulo of 0 is 0
        ss << "RESET d \n";
        ss << "ADD d b \n";
        ss << "SUB f f \n";
        ss << "INC f \n";
        ss << "SUB b c \n";
        ss << "JZERO b 6 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "ADD c c \n";
        ss << "ADD f f \n";
        ss << "JUMP -6 \n";
        ss << "RESET e \n";
        ss << "ADD e c \n";
        ss << "SUB c d \n";
        ss << "JZERO c 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB d e \n";
        ss << "ADD b f \n";
        ss << "RESET c \n";
        ss << "ADD c e \n";
        ss << "SHR c \n";
        ss << "SHR f \n";
        ss << "JZERO f 4 \n";
        ss << "JUMP -11 \n";
        ss << "SUB b b \n";
        ss << "JUMP 3 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "JUMP 2 \n";
        ss << "SUB b b \n";
        $$ = ss.str();
    }

condition: // returns on rejestr b (1 is true, 0 is false)
    value "=" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "RESET d \n";
        ss << "ADD d b \n";
        ss << "SUB b c \n";
        ss << "JZERO b 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB c d \n";
        ss << "JZERO c 3 \n";
        ss << "SUB b b \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "!=" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "RESET d \n";
        ss << "ADD d b \n";
        ss << "SUB b c \n";
        ss << "JZERO b 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB c d \n";
        ss << "JZERO c 3 \n";
        ss << "SUB b b \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "<" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "SUB c b \n";
        ss << "SUB b b \n";
        ss << "JZERO c 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value ">" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "SUB b c \n";
        ss << "JZERO b 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "<=" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "SUB b c \n";
        ss << "JZERO b 3 \n";
        ss << "SUB b b \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value ">=" value {
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($1, 'd') << "\n";
        ss << "SUB c b \n";
        ss << "JZERO c 3 \n";
        ss << "SUB b b \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }

value:
    T_NUM {
        $$ = $1;
    }
    | identifier {
        found_var_type t = check_var_type($1);
        if(!is_declared(t.v1.name)){
            err(errors::UndeclaredVar, t.v1.name);
        }
        else if(!is_initialized(t.v1.name)){
            err(errors::UninitializedVar, t.v1.name);
        }
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
    found_var_type t = check_var_type(name);
    stringstream ss;
    switch(t.type){
        case found_var_type::RegularInteger: {
            return create_constant_value(t.number, 'a');
        }
        case found_var_type::VariableInteger: {
            ss << create_constant_value(t.v1.memmoryIndex, 'a');
            ss << "LOAD " << rejestr << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithNumericIndex: {
            int n = t.v1.memmoryIndex + t.number - t.v1.scope_start;
            ss << create_constant_value(n, 'a');
            ss << "LOAD " << rejestr << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithVariableIndex: {
            ss << create_constant_value(t.v2.memmoryIndex, 'a');
            ss << "LOAD " << rejestr << " a \n";
            ss << create_constant_value(t.v1.scope_start, 'a');
            ss << "SUB " << rejestr << " a \n";
            ss << create_constant_value(t.v1.memmoryIndex, 'a');
            ss << "ADD a " << rejestr << "\n";
            return ss.str();
        }
        case found_var_type::NotRecognisable: {
            return name;
        }
    }
    return name;
}


string save_iterator_to_memmory(string name, char rejestr){
    for(var v : vars) {
        if(v.name == name){
            stringstream ss;
            ss << create_constant_value(v.memmoryIndex, 'a');
            ss << "STORE " << rejestr << " a \n";
            return ss.str();
        }
    }
    return "\n";
}


string save_variable_to_memmory(string name, char rejestr1, char rejestr2){
    found_var_type t = check_var_type(name);
    stringstream ss;
    switch(t.type){
        case found_var_type::RegularInteger: {
            /* TODO */
            return name;
        }
        case found_var_type::VariableInteger: {
            initialize_variable(t.v1.name);
            ss << create_constant_value(t.v1.memmoryIndex, 'a');
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithNumericIndex: {
            initialize_variable(t.v1.name);
            int n = t.v1.memmoryIndex + t.number - t.v1.scope_start;
            ss << create_constant_value(n, 'a');
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithVariableIndex: {
            initialize_variable(t.v1.name);
            ss << create_constant_value(t.v2.memmoryIndex, 'a');
            ss << "LOAD " << rejestr2 << " a \n";
            ss << create_constant_value(t.v1.scope_start, 'a');
            ss << "SUB " << rejestr2 << " a \n";
            ss << create_constant_value(t.v1.memmoryIndex, 'a');
            ss << "ADD a " << rejestr2 << "\n";
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::NotRecognisable: {
            return name;
        }
    }
    return name;
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
    text.erase(remove(text.begin(), text.end(), ';'), text.end());
    for (string::size_type i = text.size(); i > 1; i--) {
        if(text[i] == '\n' && text[i] == text[i-1]){
            text.erase(i, 1);
        }
    }
    return text;
}


string create_constant_value(int value, char rejestr){
    /* change to binary format */
    bitset<100> binary(value);
    string bin = binary.to_string();
    bin.erase(0, bin.find_first_not_of('0'));
    /* create value in rejestr */
	stringstream ss;
	ss << "SUB " << rejestr << " " << rejestr << "\n";
    if(bin.length() > 0){
        for(string::size_type i = 0; i < bin.length(); i++){
            if(bin[i] == '1'){
                ss << "INC " << rejestr << "\n";
            }
            if(i != bin.length() - 1){
                ss << "SHL " << rejestr << "\n";
            }
        }
    }
    return ss.str();
}
