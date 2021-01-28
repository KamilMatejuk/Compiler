#include "header.h"

#include <iostream>

#include <string.h>
#include <string>
#include <vector>
#include <regex>
using namespace std;

vector<var> vars = {};
long long memoryIterator = 8;


/**
 * Check if variable was previously declared.
 * 
 * @param name name of variable.
 */
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

/**
 * Check if variable was already initialized.
 * 
 * @param name name of variable.
 */
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

/**
 * Check if variable was declared and initialize it.
 * 
 * @param name name of variable.
 */
void initialize_variable(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        iter->initialized = true;
    } else {
        err(errors::UndeclaredVar, name);
    }
}

/**
 * Check if variable is marked as iterator.
 * 
 * @param name name of variable.
 */
bool is_iterator(string name){
    for(var v : vars) {
        if(v.name == name){
            return v.iterator;
        }
    }
    return false;
}

/**
 * Check if variable was declared and mark it as iterator.
 * 
 * @param name name of variable.
 */
void set_as_iterator(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        iter->iterator = true;
    } else {
        err(errors::UndeclaredVar, name);
    }
}

/**
 * Delete obsolete variable after iteration.
 * 
 * @param name name of variable.
 */
void remove_iterator(string name){
    auto iter = std::find_if(vars.begin(), vars.end(), [&](var const & v) {return v.name == name;});
    if(iter != vars.end()){
        vars.erase(iter);
    }
}

/**
 * Returns type of variable, with names and/or numeric values.
 * 
 * @param name variable written as 0 / x / x(0) / x(y).
 */
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

/**
 * Check if string is a natural number.
 * 
 * @param s string to be checked.
 */
bool is_number(string& s){
    return !s.empty() && std::find_if(s.begin(), 
        s.end(), [](unsigned char c) { return !std::isdigit(c); }) == s.end();
}

/**
 * Check if variable wasn't declared and store new var structure.
 * 
 * @param name name of variable.
 */
void declare_variable_int(string name){
    /* not used name */
    if(is_declared(name)){
        err(errors::AlreadyDeclaredVar, name);
    }
    struct var v;
    v.name = name;
    v.memoryIndex = memoryIterator++;
    v.var_type = var::integer;
    vars.push_back(v);
}


/**
 * Check if variable wasn't declared , if scope is correct and store new var structure.
 * 
 * @param name name of variable.
 * @param start starting index of array scope.
 * @param end ending index of array scope.
 */
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
    v.memoryIndex = memoryIterator++;
    v.var_type = var::array;
    v.scope_start = start;
    v.scope_end = end;
    vars.push_back(v);
    memoryIterator += end - start + 1;
}
