minic : main.c sintactico.tab.c lex.yy.c listaSimbolos.c listaCodigo.c
	gcc -g main.c sintactico.tab.c lex.yy.c listaSimbolos.c listaCodigo.c -lfl -o minic

lex.yy.c : lexico.l sintactico.tab.h
	flex lexico.l

sintactico.tab.h sintactico.tab.c : sintactico.y
	bison -d sintactico.y

clean :
	rm -f lexico lex.yy.c sintactico.tab.h sintactico.tab.c sintactico.output programa.s minic

run : minic codigo_correcto.mc codigo_erroneo.mc
	./minic codigo_correcto.mc > programa.s
	./minic codigo_erroneo.mc
