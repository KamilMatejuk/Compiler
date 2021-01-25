#include "header.h"

#include <iostream>

#include <string.h>
#include <string>
#include <vector>
#include <regex>
using namespace std;

vector<var> vars = {};
long long memmoryIterator = 0;


/* check if variable of given name was previously declared */
bool is_declared(string name){
    if(name == ""){
        return true;
    }
    for(var v : vars) {
        if(v.name == name){
            return true;
        }
    }
    return false;
}

/* check if variable of given name was already initialized */
bool is_initialized(string name){
    if(name == ""){
        return true;
    }
    for(var v : vars) {
        if(v.name == name){
            return v.initialized;
        }
    }
    return false;
}

/* check if is declared and change to initialized */
void initialize_variable(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        iter->initialized = true;
    } else {
        err(errors::UndeclaredVar, name);
    }
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

/* check if is declared and mark as iterator */
void set_as_iterator(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        iter->iterator = true;
    } else {
        err(errors::UndeclaredVar, name);
    }
}

/* delete variable after its scope */
void remove_iterator(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        vars.erase(iter);
    }
}

/* check if used type is correct, and returns only name of variable */
found_var_type check_var_type(string name){
    found_var_type t;
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
                    if(v.var_type != var::array){
                        err(errors::BadVarType, n);
                    }
                    else if(v.scope_start > a || v.scope_end < a){
                        err(errors::BadArrayScope, n);
                    }
                    t.type = found_var_type::VariableArrayWithNumericIndex;
                    t.v1 = v;
                    t.number = a;
                    return t;
                }
            }
        } else {
            /* array with variable argument */
            for(var v1 : vars) {
                if(v1.name == n){
                    if(v1.var_type != var::array){
                        err(errors::BadVarType, n);
                    }
                    for(var v2 : vars) {
                        if(v2.name == arg){
                            if(v2.var_type != var::integer){
                                err(errors::BadVarType, arg);
                            }
                            t.type = found_var_type::VariableArrayWithVariableIndex;
                            t.v1 = v1;
                            t.v2 = v2;
                            return t;
                        }
                    }
                }
            }
        }
    } else {
        if(is_number(name)){
            /* just number */
            int a = stoi(name);
            t.type = found_var_type::RegularInteger;
            t.number = a;
            return t;
        } else {
            /* regular variable type integer */
            for(var v : vars) {
                if(v.name == name){
                    if(v.var_type != var::integer){
                        err(errors::BadVarType, name);
                    }
                    t.type = found_var_type::VariableInteger;
                    t.v1 = v;
                    return t;
                }
            }
        }
    }
    t.type = found_var_type::NotRecognisable;
    return t;
}

bool is_number(string& s){
    return !s.empty() && std::find_if(s.begin(), 
        s.end(), [](unsigned char c) { return !std::isdigit(c); }) == s.end();
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
    if(start > end){
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
    memmoryIterator += end - start + 1;
}
