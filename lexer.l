%option noyywrap
%option yylineno
%option nounput
%{
// #include "variables.h"
// #include "errors.h"
#include <iostream>
#include <string.h>
#include <string>
#include "parser.hh"
using namespace std;

int yylex();
%}
%%
\[([^\)]|\n)*\] ;
[ \t\n]+        ;

[_a-z]+         {
                    yylval = strdup(yytext);
                    // yylval.str = strdup(yytext);
                    return T_PIDENTIFIER;
                };
\-?[0-9]+       {
                    yylval = strdup(yytext);
                    // yylval.str = strdup(yytext);
                    // yylval.num = atoi(yytext);
                    return T_NUM;
                };

":="            { return T_ASSIGN; };

","             { return T_COMMA; };
":"             { return T_COLON; };
";"             { return T_SEMICOLON; };
"("             { return T_PAR_OPEN; };
")"             { return T_PAR_CLOSE; };

"+"             { return T_PLUS; };
"-"             { return T_MINUS; };
"*"             { return T_MULTIPLY; };
"/"             { return T_DIVIDE; };
"%"             { return T_MOD; };

"="             { return T_EQUAL; };
"!="            { return T_NOT_EQUAL; };
">"             { return T_GREATER; };
"<"             { return T_LESS; };
">="            { return T_GREATER_EQUAL; };
"<="            { return T_LESS_EQUAL; };

"DECLARE"       { return T_DECLARE; };
"BEGIN"         { return T_BEGIN; };
"END"           { return T_END; };
"IF"            { return T_IF; };
"THEN"          { return T_THEN; };
"ELSE"          { return T_ELSE; };
"ENDIF"         { return T_ENDIF; };
"WHILE"         { return T_WHILE; };
"DO"            { return T_DO; };
"ENDWHILE"      { return T_ENDWHILE; };
"REPEAT"        { return T_REPEAT; };
"UNTIL"         { return T_UNTIL; };
"FOR"           { return T_FOR; };
"FROM"          { return T_FROM; };
"TO"            { return T_TO; };
"DOWNTO"        { return T_DOWNTO; };
"ENDFOR"        { return T_ENDFOR; };
"READ"          { return T_READ; };
"WRITE"         { return T_WRITE; };
%%
