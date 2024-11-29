%{
#include "y.tab.h"
#include <string.h>
#define MAX_ID_LENGTH 31

void lexerror(const char *s);  // Declarar lexerror
%}

%option noyywrap

%%

[ \t\r\n]+          ;  // Ignorar espacios en blanco

"!"[^\n\r]*         ;  // Comentarios de una sola línea que comienzan con '!'

"<!"(.|\n)*?"!>"    ;  // Comentarios de múltiples líneas entre '<!' y '!>'

"program"           { return PROGRAM; }  // Palabra clave 'program'
"end"               { return END; }      // Palabra clave 'end'
"do"                { return DO; }       // Palabra clave 'do'
"if"                { return IF; }       // Palabra clave 'if'
"else"              { return ELSE; }     // Palabra clave 'else'
"elseif"            { return ELSEIF; }   // Palabra clave 'elseif'
"then"              { return THEN; }     // Palabra clave 'then'
"endif"             { return ENDIF; }    // Palabra clave 'endif'
"print"             { return PRINT; }    // Palabra clave 'print'

"**"                { return POWER; }    // Operador de potencia
"*"                 { return MUL; }      // Operador de multiplicación
"+"                 { return PLUS; }     // Operador de suma
"-"                 { return MINUS; }    // Operador de resta
"/"                 { return DIV; }      // Operador de división
"="                 { return EQ; }       // Operador de igualdad
","                 { return COMMA; }    // Coma
"("                 { return LPAREN; }   // Paréntesis izquierdo
")"                 { return RPAREN; }   // Paréntesis derecho

[0-9]+              {
                            yylval.intval = atoi(yytext);
                            return NUM;  // Números enteros
                        }

[a-zA-Z]([a-zA-Z0-9_])*   {
                                if (strlen(yytext) > MAX_ID_LENGTH)
                                    lexerror("Identificador demasiado largo");
                                else {
                                    yylval.strval = strdup(yytext);
                                    return ID;  // Identificadores
                                }
                              }

.                   { lexerror("Carácter inválido"); }  // Carácter inválido

%%

void lexerror(const char *s)
{
    fprintf(stderr, "Error del analizador léxico: %s en el símbolo '%s'\n", s, yytext);
}