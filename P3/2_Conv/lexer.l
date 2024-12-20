%{
#include "y.tab.h"
#include <string.h>
#include <stdio.h>

void lexerror(const char *s);
%}

%option noyywrap

%%

 /* Ignorar espacios y saltos de línea */
[ \t\r\n]+             ;

 /* Comentarios en línea que comienzan con ">>" */
">>"[^\n]*             ;

 /* Palabras clave */
"IF"                   { return IF; }
"THEN"                 { return THEN; }
"ELSE"                 { return ELSE; }
"FI"                   { return FI; }
"DO"                   { return DO; }
"WHILE"                { return WHILE; }
"FOR"                  { return FOR; }
"TO"                   { return TO; }
"PRINT"                { return PRINT; }
"OD"                   { return OD; }

 /* Operadores y símbolos */
":="                   { return ASSIGN; }
"+"                  { return PLUS; }   
"-"                    { return MINUS; }
"*"                  { return MUL; }    
"/"                    { return DIV; }
"("                    { return LPAREN; }
")"                    { return RPAREN; }

 /*  Números enteros */
[0-9]+ {
    yylval.intval = atoi(yytext);
    return NUM; 
}

 /* Identificadores */
[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.strval = strdup(yytext);
    return ID;
}

 /* Cualquier otro carácter no válido  */
. {
    lexerror("Carácter inválido");
}

%%

void lexerror(const char *s)
{
    fprintf(stderr, "Error léxico: %s en '%s'\n", s, yytext);
}
