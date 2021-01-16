using namespace std;
#include <string.h>
#include <string>

struct var {
    var(): name(""), memmoryIndex(-1), initialized(false), iterator(false), var_type(integer), scope_start(-1), scope_end(-1) {}
    public: string name;
    public: long long memmoryIndex;
    public: bool initialized;
    public: bool iterator;
    public: enum { integer, array } var_type;
    public: int scope_start;
    public: int scope_end;
};