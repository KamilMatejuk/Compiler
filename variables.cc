#include "header.h"

#include <string.h>
#include <string>
#include <vector>
#include <regex>
using namespace std;

vector<var> vars = {};
long long memmoryIterator = 0;


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

/* check if is declared, if type is correct and change to initialized */
void initialize_variable(string name){
    string n = check_var_type(name);
    for(var v : vars) {
        if(v.name == n){
            v.initialized = true;
        }
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
