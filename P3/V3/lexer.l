%{
#include "parser.tab.h"
#include <string.h>
#define MAX_ID_LENGTH 31

void lexerror(const char *s);  // Declare lexerror instead
%}

%option noyywrap

%%

[ \t\r\n]+          ;  // Skip whitespace

"!"[^\n\r]*         ;  // Single-line comments starting with '!'

"<!"(.|\n)*?"!>"    ;  // Multi-line comments between '<!' and '!>'

"program"           { return PROGRAM; }
"end"               { return END; }
"do"                { return DO; }
"if"                { return IF; }
"else"              { return ELSE; }
"elseif"            { return ELSEIF; }
"then"              { return THEN; }
"endif"             { return ENDIF; }
"print"             { return PRINT; }

"**"                { return POWER; }
"*"                 { return MUL; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"/"                 { return DIV; }
"="                 { return EQ; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }

[0-9]+              {
                            yylval.intval = atoi(yytext);
                            return NUM;
                        }

[a-zA-Z]([a-zA-Z0-9_])*   {
                                if (strlen(yytext) > MAX_ID_LENGTH)
                                    lexerror("Identifier too long");
                                else {
                                    yylval.strval = strdup(yytext);
                                    return ID;
                                }
                              }

.                   { lexerror("Invalid character"); }

%%

void lexerror(const char *s)
{
    fprintf(stderr, "Lexer Error: %s at symbol '%s'\n", s, yytext);
}
