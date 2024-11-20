%{
#include "parser.tab.h"
#include <string.h>
%}

%option noyywrap
%option caseless

%x COM

%%

"<!"        {BEGIN(COM);}   //Comentarios multilÌnea 
<COM>"!>"   {BEGIN(INITIAL);} 
<COM>.|\n   ;

"program"                  { return PROGRAM; }
"endif"                    { return ENDIF; }
"end"                      { return END; }
"do"                       { return DO; }
"if"                       { return IF; }
"then"                     { return THEN; }
"else"                     { return ELSE; }
"elseif"                   { return ELSEIF; }
"print"                    { return PRINT; }

"="                        { return ASSIGN; }
","                        { return COMMA; }
"("                        { return LPAREN; }
")"                        { return RPAREN; }
"+"                        { return PLUS; }
"-"                        { return MINUS; }
"**"                       { return POW; }
"*"                        { return MULT; }
"/"                        { return DIV; }

[0-9]+                     { yylval.intVal = atoi(yytext); return NUM; }
[a-zA-Z][a-zA-Z0-9_]{0,30} { yylval.strVal = strdup(yytext); return ID; }

"!".*\n         ;   // Ignorar comentarios de linea
.                          { printf("Caracter inválido: %s\n", yytext); exit(1); }

%%

