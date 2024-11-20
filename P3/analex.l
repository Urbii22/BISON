%{ 
 #include "y.tab.h" 
%} 
%option noyywrap 
%x COM 
%% 
 
"<!"        {BEGIN(COM);}   //Comentarios multilÌnea 
<COM>"!>"   {BEGIN(INITIAL);} 
<COM>.|\n   ; 
 
"print"     return PRINT; 
"while"     return WHILE; 
"endwhile"  return ENDWHILE; 
"if"        return IF; 
"else"      return ELSE; 
"elseif"    return ELSEIF; 
"endif"     return ENDIF; 
"="        return ASIGNAR; 
"++"        return INCRASIG; 
"--"        return DECRASIG; 
 
[0-9]+                  {yylval.num = atoi(yytext); return NUM;}  
[A-Za-z_][0-9A-Za-z_]*  {yylval.id = strdup(yytext); return ID;} 
 
" "|\t|\n|\r    ;   // Ignorar espacios, tabuladores, saltos de lÌnea 
"!".*\n         ;   // Ignorar comentarios de linea 
.               return yytext[0];   // Devolver cualquier otro caracter 
 
  