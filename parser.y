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
bool debug;

// methods
int  yylex(void);
void yyset_in(FILE * in_str);

string get_variable_to_rejestr(string name, char rejestr);
string save_iterator_to_memmory(string name, char rejestr);
string save_variable_to_memmory(string name, char rejestr1, char rejestr2);
string create_constant_value(int value, char rejestr);

int  number_of_commands(string text);
string remove_empty_lines(string text);

void show_vars();
string add_comments(string text);

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
    identifier ":=" expression ";" { // działa
        stringstream ss;
        ss << $3 << "\n";
        ss << save_variable_to_memmory($1, 'b', 'c') << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ELSE" commands "ENDIF" { // działa
        int commands_1_lines = number_of_commands($4);
        int commands_2_lines = number_of_commands($6);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 2) << "\n";
        ss << $4 << "\n";
        ss << "JUMP " << (commands_2_lines + 1) << "\n";
        ss << $6 << "\n";
        $$ = ss.str();
    }
    | "IF" condition "THEN" commands "ENDIF" { // działa
        int commands_1_lines = number_of_commands($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 1) << "\n";
        ss << $4 << "\n";
        $$ = ss.str();
    }
    | "WHILE" condition "DO" commands "ENDWHILE" { // działa
        int condition_1_lines = number_of_commands($2);
        int commands_1_lines = number_of_commands($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << "JZERO b " << (commands_1_lines + 2) << " \n";
        ss << $4 << "\n";
        ss << "JUMP -" << (condition_1_lines + commands_1_lines + 1) << "\n";
        $$ = ss.str();
    }
    | "REPEAT" commands "UNTIL" condition ";" { // działa
        int commands_1_lines = number_of_commands($2);
        int condition_1_lines = number_of_commands($4);

        stringstream ss;
        ss << $2 << "\n";
        ss << $4 << "\n";
        ss << "JZERO b -" << (commands_1_lines + condition_1_lines) << "\n";
        $$ = ss.str();
    }
    | "FOR" iterator "FROM" value "TO" value "DO" commands "ENDFOR" { // działa
        // create var for end of scope 
        string iter_end = $6 + "_iter_end";
        iter_end.erase(remove(iter_end.begin(), iter_end.end(), '('), iter_end.end());
        iter_end.erase(remove(iter_end.begin(), iter_end.end(), ')'), iter_end.end());
        declare_variable_int(iter_end);
        // useful lengths of blocks
        int commands_1_lines = number_of_commands($8);
        int var_1_lines = number_of_commands(get_variable_to_rejestr($2, 'b'));
        int var_2_lines = number_of_commands(get_variable_to_rejestr(iter_end, 'c'));
        int iter_1_lines = number_of_commands(save_iterator_to_memmory($2, 'b'));
        stringstream ss;
        // save end
        ss << get_variable_to_rejestr($6, 'b') << "\n";
        ss << save_iterator_to_memmory(iter_end, 'b') << "\n";
        // save iterator
        ss << get_variable_to_rejestr($4, 'b') << "\n";
        ss << save_iterator_to_memmory($2, 'b') << "\n";
        // condition
        ss << get_variable_to_rejestr($2, 'c') << "\n";
        ss << get_variable_to_rejestr(iter_end, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "SUB b c \n";
        ss << "JZERO b 4 \n";
        ss << "RESET b \n";
        ss << "INC b \n";
        ss << "JUMP 5 \n";
        ss << "SUB c d \n";
        ss << "RESET b \n";
        ss << "JZERO c 2 \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        // end of condition
        ss << "JZERO b " << (commands_1_lines + var_1_lines + iter_1_lines + 3) << "\n";
        // loop
        ss << $8 << "\n";
        ss << get_variable_to_rejestr($2, 'b') << "\n";
        ss << "INC b \n";
        ss << save_iterator_to_memmory($2, 'b') << "\n";
        // end of loop
        ss << "JUMP -" << (var_1_lines + var_2_lines + commands_1_lines + var_1_lines + iter_1_lines + 14) << "\n";
        remove_iterator($2);
        $$ = ss.str();
    }
    | "FOR" iterator "FROM" value "DOWNTO" value "DO" commands "ENDFOR" { // działa
        // create var for end of scope 
        string iter_end = $6 + "_iter_end";
        iter_end.erase(remove(iter_end.begin(), iter_end.end(), '('), iter_end.end());
        iter_end.erase(remove(iter_end.begin(), iter_end.end(), ')'), iter_end.end());
        declare_variable_int(iter_end);
        // useful lengths of blocks
        int commands_1_lines = number_of_commands($8);
        int var_1_lines = number_of_commands(get_variable_to_rejestr($2, 'b'));
        int var_2_lines = number_of_commands(get_variable_to_rejestr(iter_end, 'c'));
        int iter_1_lines = number_of_commands(save_iterator_to_memmory($2, 'b'));
        stringstream ss;
        // save end
        ss << get_variable_to_rejestr($6, 'b') << "\n";
        ss << save_iterator_to_memmory(iter_end, 'b') << "\n";
        // save iterator
        ss << get_variable_to_rejestr($4, 'b') << "\n";
        ss << save_iterator_to_memmory($2, 'b') << "\n";
        // condition
        ss << get_variable_to_rejestr($2, 'c') << "\n";
        ss << get_variable_to_rejestr(iter_end, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b c \n";
        ss << "SUB b d \n";
        ss << "JZERO b 4 \n";
        ss << "RESET b \n";
        ss << "INC b \n";
        ss << "JUMP 5 \n";
        ss << "SUB d c \n";
        ss << "RESET b \n";
        ss << "JZERO d 2 \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        // end of condition
        ss << "JZERO b " << (commands_1_lines + var_1_lines + iter_1_lines + 4) << "\n";
        // loop
        ss << $8 << "\n";
        ss << get_variable_to_rejestr($2, 'b') << "\n";
        ss << "JZERO b " << (iter_1_lines + 3) << "\n";
        ss << "DEC b \n";
        ss << save_iterator_to_memmory($2, 'b') << "\n";
        // end of loop
        ss << "JUMP -" << (var_1_lines + var_2_lines + commands_1_lines + var_1_lines + iter_1_lines + 14) << "\n";
        remove_iterator($2);
        $$ = ss.str();
    }
    | "READ" identifier ";" { // działa
        stringstream ss;
        ss << "RESET a \n";
        ss << "GET a \n";
        ss << "LOAD b a \n";
        ss << save_variable_to_memmory($2, 'b', 'c') << "\n";
        $$ = ss.str();
    }
    | "WRITE" value ";" { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($2, 'b') << "\n";
        ss << "RESET a \n";
        ss << "STORE b a \n";
        ss << "PUT a \n";
        $$ = ss.str();
    }

expression: // returns on rejestr b
    value {
        $$ = get_variable_to_rejestr($1, 'b') + "\n";
    }
    | value "+" value { // działa
        stringstream ss;
        if($1 == $3){
            ss << get_variable_to_rejestr($1, 'b') << "\n";
            ss << "SHL b \n";
        } else {
            ss << get_variable_to_rejestr($1, 'b') << "\n";
            ss << get_variable_to_rejestr($3, 'c') << "\n";
            ss << "ADD b c \n";
        }
        $$ = ss.str();
    }
    | value "-" value { // działa
        stringstream ss;
        if($1 == $3){
            ss << "RESET b \n";
        } else {
            ss << get_variable_to_rejestr($1, 'b') << "\n";
            ss << get_variable_to_rejestr($3, 'c') << "\n";
            ss << "SUB b c \n";
        }
        $$ = ss.str();
    }
    | value "*" value { // działa
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
        ss << "RESET d \n";
        ss << "JZERO b 9 \n";
        ss << "JODD b 4 \n";
        ss << "SHR b \n";
        ss << "SHL c \n";
        ss << "JUMP -4 \n";
        ss << "ADD d c \n";
        ss << "SHR b \n";
        ss << "SHL c \n";
        ss << "JUMP -8 \n";
        ss << "RESET b \n";
        ss << "ADD b d \n;";
        $$ = ss.str();
    }
    | value "/" value { // działa
        stringstream ss;
        if($1 == $3){
            ss << "RESET b \n";
            ss << "INC b \n";
        } else {
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
            ss << "RESET b \n";
        }
        $$ = ss.str();
    }
    | value "%" value { // działa
        stringstream ss;
        if($1 == $3){
            ss << "RESET b \n";
        } else {
            ss << get_variable_to_rejestr($1, 'b') << "\n";
            ss << get_variable_to_rejestr($3, 'c') << "\n";
            ss << "JZERO c 30 \n"; // modulo of 0 is 0
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
            ss << "JZERO f 4 \n";
            ss << "JUMP -12 \n";
            ss << "RESET b \n";
            ss << "JUMP 3 \n";
            ss << "RESET b \n";
            ss << "ADD b d \n";
            ss << "JUMP 2 \n";
            ss << "RESET b \n";
        }
        $$ = ss.str();
    }

condition: // returns on rejestr b (1 is true, 0 is false)
    value "=" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "SUB b c \n";
        ss << "JZERO b 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB c d \n";
        ss << "JZERO c 3 \n";
        ss << "RESET b \n";
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "!=" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "SUB b c \n";
        ss << "JZERO b 2 \n";
        ss << "JUMP 3 \n";
        ss << "SUB c d \n";
        ss << "JZERO c 3 \n";
        ss << "RESET b \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "<" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "SUB d c \n";
        ss << "RESET b \n";
        ss << "JZERO d 2 \n"; // d <= c
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value ">" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "SUB c d \n";
        ss << "RESET b \n";
        ss << "JZERO c 2 \n"; // c <= d
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value "<=" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b d \n";
        ss << "SUB b c \n";
        ss << "JZERO b 4 \n"; // d <= c
        ss << "RESET b \n";
        ss << "INC b \n";
        ss << "JUMP 5 \n"; // skok do końca
        ss << "SUB c d \n";
        ss << "RESET b \n";
        ss << "JZERO c 2 \n"; // c <= d
        ss << "JUMP 2 \n";
        ss << "INC b \n";
        $$ = ss.str();
    }
    | value ">=" value { // działa
        stringstream ss;
        ss << get_variable_to_rejestr($1, 'c') << "\n";
        ss << get_variable_to_rejestr($3, 'd') << "\n";
        ss << "RESET b \n";
        ss << "ADD b c \n";
        ss << "SUB b d \n";
        ss << "JZERO b 4 \n"; // c <= d
        ss << "RESET b \n";
        ss << "INC b \n";
        ss << "JUMP 5 \n"; // skok do końca
        ss << "SUB d c \n";
        ss << "RESET b \n";
        ss << "JZERO d 2 \n"; // d <= c
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
        for(var v : vars){
            if(v.name == $1 && v.var_type != var::integer){
                err(errors::BadVarType, $1);
            }
        }
        $$ = $1;
    }
    | T_PIDENTIFIER "(" T_PIDENTIFIER ")" {
        for(var v : vars){
            if(v.name == $1 && v.var_type != var::array){
                err(errors::BadVarType, $1);
            }
        }
        if(!is_declared($3)){
            err(errors::UndeclaredVar, $3);
        }
        else if(!is_initialized($3)){
            err(errors::UninitializedVar, $3);
        }
        stringstream ss;
        ss << $1 << "(" << $3 << ")";
        $$ = ss.str();
    }
    | T_PIDENTIFIER "(" T_NUM ")" {
        for(var v : vars){
            if(v.name == $1 && v.var_type != var::array){
                err(errors::BadVarType, $1);
            }
        }
        stringstream ss;
        ss << $1 << "(" << $3 << ")";
        $$ = ss.str();
    }

iterator:
    T_PIDENTIFIER {
        if(is_declared($1) || is_iterator($1)){
            err(errors::AlreadyDeclaredVar, $1);
        }
        declare_variable_int($1);
        initialize_variable($1);
        set_as_iterator($1);
        $$ = $1;
    }

%%

/*
*********************************************************************
************************* starting parsing **************************
*********************************************************************
*/

string run_parser(FILE * data, bool d){
    debug = d;
    yyset_in(data);
    yyparse();

    machine_code = remove_empty_lines(machine_code);
    if(debug){
        show_vars();
        machine_code = add_comments(machine_code);
        cout << machine_code << endl;
        cout << endl;
        cout << "Total " << number_of_commands(machine_code) << " commands \n";
    }

    return machine_code;
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
            return create_constant_value(t.number, rejestr);
        }
        case found_var_type::VariableInteger: {
            ss << create_constant_value(t.v1.memmoryIndex, 'a') << "\n";
            ss << "LOAD " << rejestr << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithNumericIndex: {
            int n = t.v1.memmoryIndex + t.number - t.v1.scope_start;
            ss << create_constant_value(n, 'a') << "\n";
            ss << "LOAD " << rejestr << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithVariableIndex: {
            ss << create_constant_value(t.v2.memmoryIndex, 'a') << "\n";
            ss << "LOAD " << rejestr << " a \n";
            ss << create_constant_value(t.v1.scope_start, 'a') << "\n";
            ss << "SUB " << rejestr << " a \n";
            ss << create_constant_value(t.v1.memmoryIndex, 'a') << "\n";
            ss << "ADD a " << rejestr << "\n";
            ss << "LOAD " << rejestr << " a \n";
            return ss.str();
        }
        case found_var_type::NotRecognisable: {
            return "\n";
        }
    }
    return "\n";
}


string save_iterator_to_memmory(string name, char rejestr){
    for(var v : vars) {
        if(v.name == name){
            stringstream ss;
            ss << create_constant_value(v.memmoryIndex, 'a') << "\n";
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
            return "\n";
        }
        case found_var_type::VariableInteger: {
            if(is_iterator(t.v1.name)){
                err(errors::BadVarType, t.v1.name);
            }
            initialize_variable(t.v1.name);
            ss << create_constant_value(t.v1.memmoryIndex, 'a') << "\n";
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithNumericIndex: {
            initialize_variable(t.v1.name);
            int n = t.v1.memmoryIndex + t.number - t.v1.scope_start;
            ss << create_constant_value(n, 'a') << "\n";
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::VariableArrayWithVariableIndex: {
            initialize_variable(t.v1.name);

            ss << create_constant_value(t.v2.memmoryIndex, 'a') << "\n";
            ss << "LOAD " << rejestr2 << " a \n";
            ss << create_constant_value(t.v1.scope_start, 'a') << "\n";
            ss << "SUB " << rejestr2 << " a \n";
            ss << create_constant_value(t.v1.memmoryIndex, 'a') << "\n";
            ss << "ADD a " << rejestr2 << "\n";
            ss << "STORE " << rejestr1 << " a \n";
            return ss.str();
        }
        case found_var_type::NotRecognisable: {
            return "\n";
        }
    }
    return "\n";
}

int number_of_commands(string text){
    vector<string> possible_commands = {"GET", "PUT", "LOAD", "STORE", "ADD", "SUB", "RESET", "INC", "DEC", "SHR", "SHL", "JUMP", "JZERO", "JODD", "HALT"};
    int commands = 0;
    for(string command : possible_commands){
        string::size_type pos = 0;
        while ((pos = text.find(command, pos )) != string::npos) {
            commands++;
            pos += command.length();
        }
    }
    return commands;
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
	ss << "RESET " << rejestr << "\n";
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


/*
*********************************************************************
************************ debugging helpers **************************
*********************************************************************
*/

void show_vars(){
    cout << endl;
    cout << "\t\t\t\t\t\tVARIABLES" << endl;
    cout << "name \tmemmoryIndex \tinitialized \titerator \tvar_type \tscope_start \tscope_end" << endl;
    for(var v : vars){
        cout << v.name << " \t";
        cout << v.memmoryIndex << " \t\t";
        cout << v.initialized << " \t\t";
        cout << v.iterator << " \t\t";
        cout << v.var_type << " \t\t";
        cout << v.scope_start << " \t\t";
        cout << v.scope_end << endl;
    }
    cout << endl;
    cout << endl;
}

string add_comments(string text){
    string with_comments = "";
    istringstream iss(text);
    for (string line; getline(iss, line); ){
        // split line
        vector<string> v;
        size_t pos = line.find(' ');
        size_t initialPos = 0;
        while(pos != string::npos) {
            v.push_back(line.substr(initialPos, pos - initialPos));
            initialPos = pos + 1;
            pos = line.find(' ', initialPos);
        }
        v.push_back(line.substr(initialPos, min(pos, line.size()) - initialPos + 1));
        // add comment
        if(v.size() >= 2 && v[0] == "GET"){
            with_comments += line + "\t\t (p[" + v[1] + "] <- wpisana wartość) \n";
        }
        else if(v.size() >= 2 && v[0] == "PUT"){
            with_comments += line + "\t\t (wyświetla p[" + v[1] + "]) \n";
        }
        else if(v.size() >= 3 && v[0] == "LOAD"){
            with_comments += line + "\t (" + v[1] + " <- p[" + v[2] + "]) \n";
        }
        else if(v.size() >= 3 && v[0] == "STORE"){
            with_comments += line + "\t (p[" + v[2] + "] <- " + v[1] + ") \n";
        }
        else if(v.size() >= 2 && v[0] == "SHR"){
            with_comments += line + "\t\t (" + v[1] + " <- " + v[1] + " / 2) \n";
        }
        else if(v.size() >= 2 && v[0] == "SHL"){
            with_comments += line + "\t\t (" + v[1] + " <- " + v[1] + " * 2) \n";
        }
        else {
            with_comments += line + "\n";
        }
    }
    return with_comments;
}