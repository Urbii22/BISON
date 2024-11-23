%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>

 /* Variable para almacenar el lexema de los identificadores y números */
char yytext_copy[32];
%}

%option noyywrap

 /* Definición de los tokens */
%%

 /* Ignorar espacios, tabuladores, saltos de línea y retornos de carro */
[ \t\n\r]+          { /* Ignorar */ }

 /* Comentario de una sola línea empezando con '!' */ 
"!"[^"\n\r"]*("\r")?("\n")? { /* Ignorar comentario de una línea */ }

 /* Comentario multilínea entre '<!' y '!>' */
"<!"([^<]*|<[^!]|![^>])*"!>" { /* Ignorar comentario multilínea */ }

 /* Palabras reservadas */
"program"           { return PROGRAM; }
"end"               { return END; }
"do"                { return DO; }
"if"                { return IF; }
"else"              { return ELSE; }
"elseif"            { return ELSEIF; }
"then"              { return THEN; }
"endif"             { return ENDIF; }
"print"             { return PRINT; }

 /* Operadores y símbolos */
"**"                { return POWER; }
"*"                 { return MUL; }
"/"                 { return DIV; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"="                 { return EQ; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }

 /* Números (NUM) */
[0-9]+              {
                        yylval.num = atoi(yytext);
                        return NUM;
                    }

 /* Identificadores (ID) */
[a-zA-Z][a-zA-Z0-9_]{0,30} {
                        yylval.id = strdup(yytext);
                        return ID;
                    }

 /* Identificadores demasiado largos */
[a-zA-Z][a-zA-Z0-9_]{0,31} {
                        fprintf(stderr, "Error: Identificador '%s' demasiado largo (máximo 31 caracteres).\n", yytext);
                        exit(1);
                    }

 /* Cualquier otro carácter no válido */
.                   { fprintf(stderr, "Caracter inesperado: %s\n", yytext); exit(1); }

%%

