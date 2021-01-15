using namespace std;
#include <string.h>
#include <iostream>

// classes for union
class class_identifier {
    public: enum ttype { id, array_with_var, array_with_num } type;
    public: char* var_name;
    public: char* var_index;
    public: int num_index;

    public: class_identifier(char* v_n){
        type = ttype::id;
        var_name = v_n;
    }
    public: class_identifier(char* v_n, char* v_i){
        type = ttype::array_with_var;
        var_name = v_n;
        var_index = v_i;
    }
    public: class_identifier(char* v_n, int n_i){
        type = ttype::array_with_num;
        var_name = v_n;
        num_index = n_i;
    }
};