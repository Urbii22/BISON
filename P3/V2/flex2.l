%{
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%option noyywrap
%x COM

%%

"<!"        {BEGIN(COM);}   //Comentarios multilÌnea 
<COM>"!>"   {BEGIN(INITIAL);} 
<COM>.|\n   ;

 /* Palabras clave (insensibles a mayúsculas) */
[Pp][Rr][Oo][Gg][Rr][Aa][Mm]     { return PROGRAM; }
[Ee][Nn][Dd][Ii][Ff]               { return ENDIF; }
[Ee][Nn][Dd]                       { return END; }
[Dd][Oo]                           { return DO; }
[Ii][Ff]                           { return IF; }
[Tt][Hh][Ee][Nn]                   { return THEN; }
[Ee][Ll][Ss][Ee]                   { return ELSE; }
[Ee][Ll][Ss][Ee][Ii][Ff]           { return ELSEIF; }
[Pp][Rr][Ii][Nn][Tt]               { return PRINT; }

 /* Operadores y símbolos */
"**"                               { return POW; }
"="                                { return ASSIGN; }
","                                { return COMMA; }
"("                                { return LPAREN; }
")"                                { return RPAREN; }
"+"                                { return SUM; }
"-"                                { return RESTA; }
"*"                                { return MULT; }
"/"                                { return DIV; }

 /* Números */
[0-9]+                             { yylval.num = atoi(yytext); return NUM; }

 /* Identificadores: comienzan con una letra, seguidos de hasta 30 letras, dígitos o guiones bajos */
[A-Za-z][A-Za-z0-9_]{0,30}         { yylval.id = strdup(yytext); return ID; }

" "|\t|\n|\r    ;   // Ignorar espacios, tabuladores, saltos de lÌnea 
"!".*\n         ;   // Ignorar comentarios de linea 
.               return yytext[0];   // Devolver cualquier otro caracter 
%%

