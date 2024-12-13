%{
    /* Código C verbal */ 
    #include <stdio.h>
    #include "sintactico.tab.h"
    int inicio_comentario = 0;

    extern int nerror;

%}

/* MACROS */
D       [0-9]
L       [a-zA-Z]
panico  [^a-zA-Z_0-9"\n\t\r ();,.+\-*/:=]+

%option yylineno

/* Condición de contexto de comentarios */
%x comentario

%%

 /* Blancos y comentarios */
[ \n\t\r]+          ;
"//".+              ;
"/*"                {
                      inicio_comentario = yylineno;
                      BEGIN(comentario);    
                    }
<comentario>.|\n    ;
<comentario>"*/"    { BEGIN(INITIAL); }
<comentario><<EOF>> { printf("Comentario sin cerrar en línea %d\n", inicio_comentario);
                      nerror++;
                      return 0;
                    }

 /* Palabras clave */
void                { return VOID;  }
var                 { return VAR;   }
const               { return CONST; }
if                  { return IF;    }
else                { return ELSE;  }
while               { return WHILE; }
do                  { return DO;    }
for                 { return FOR;   }
print               { return PRINT; }
read                { return READ;  }

 /* Identificadores */
{L}({L}|{D}){0,15}  { 
                      yylval.lexema = strdup(yytext); // Pasamos lexema al analizador sintáctico
                      return ID;    
                    }   

 /* Enteros y cadenas de caracteres */
{D}+                { 
                      if (atoll(yytext) >= 2147483648 || atoll(yytext) <= -2147483649) {
                        printf("ERROR: entero fuera de rango en línea %d: %s\n", yylineno, yytext);
                        nerror++;
                      }
                      
                      yylval.lexema = strdup(yytext); // Pasamos número al analizador sintáctico

                      return ENTERO;
                    }
\"([^"\n]|\\.)*\"   { 
                      yylval.lexema = strdup(yytext); // Pasamos cadena al analizador sintáctico
                      return STRING;    
                    }

 /* Caracteres especiales */
";"                 { return PC;        }
","                 { return COMA;      }
"+"                 { return MAS;       }
"-"                 { return MENOS;     }
"*"                 { return POR;       }
"/"                 { return DIV;       }
"="                 { return IGUAL;     }
"("                 { return PARI;      }
")"                 { return PARD;      }
"<"                 { return MENOR;     }
">"                 { return MAYOR;     }
"!"                 { return EXCLAM;    }
"{"                 { return LLAVEI;    }
"}"                 { return LLAVED;    }

 /* Tratamiento de errores léxicos */
\"([^"\n]|\\.)*     { printf("ERROR en línea %d: las constantes de cadena deben comenzar y terminar con comillas.\n", yylineno); nerror++; }
{L}({L}|{D}){16,99} { printf("ERROR en línea %d: el identificador supera el tamaño máximo.\n", yylineno); nerror++; }
{panico}            { printf("ERROR en línea %d: %s\n", yylineno, yytext); nerror++; }

%%