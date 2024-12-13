void prueba() {
  //Declaraciones  
  var i = 0;
  var j = 10;
  const p = 3;
  var n;

  do{
    print "Bucle do-while numero ", i+1, "\n";
    i = i + 1;
  } while(i<3);
  
  
  print "Se debe ejecutar 5 veces hola\n";
  if(p == 3){
    for(j=10 ; j>0 ; j=j-2){
      n = j/2;
      print "Hola numero ", n, "\n";
    }
  }
  else{
    print "Esto no debe ejecutarse\n";
  }
  
  while(n<=5){
    print "n=",n, "\nn++\n";
    n = n + 1;
  }

  print "Funciona correctamente. Adios";
}