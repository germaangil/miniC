#include <stdio.h>
#include <stdlib.h>

extern int yyparse();
extern FILE * yyin;
extern int nerror;
extern int nierror;

int main(int argc, char ** argv)
{
    if (argc != 2)
    {
        printf("Uso: %s archivo\n", argv[0]);
        exit(1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        printf("\nNo se puede abrir %s\n", argv[1]);
        exit(2);
    }

    yyparse();

    if(nerror) 
        printf("\x1b[31m\nSe han detectado %d errores de compilación.\n\n\x1b[0m", nerror);
}