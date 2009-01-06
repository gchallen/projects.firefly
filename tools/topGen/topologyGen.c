
/*
 *
 * topologyGen.c
 * 
 * Sample Usage: 
 * line: ./topologyGen l 5   > line5.nss
 * ring: ./topologyGen r 10  > ring10.nss
 * grid: ./topologyGen g 4 4 > grid4.4.nss
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>


void ring(int Max);
void line(int numNodes);
void grid(int dimx, int dimy);


int main(int argc, char **argv){  
  char topologyType;
  int numNodes, gridy;
  
  /* For 2 arguments, argc is 3 */
  if(argc < 3){
    printf("Usage: topologyGen <topology type: (l, r, g)> <num nodes> \n");
    printf("Grid 'g' option has an additional optional argument: m x n dim \n");
    exit(1);
  }

  topologyType = argv[1][0];
  gridy = numNodes = atoi(argv[2]);
  if(argc == 4){
    //Optional 4th argument to specify other dimension of irregular grid.
    gridy = atoi(argv[3]);
  }

    

  switch(topologyType){

  case 'l':
    line(numNodes);
    break;
    
  case 'r':
    ring(numNodes);
    break;
    
  case 'g':
    grid(numNodes, gridy);
    break;

  default:
    printf("Unknown topology type\n");
  }
  
  return 0;
}



void ring(int Max){
  int i, j;
  //printf("ring topology: Max: %d \n", Max);

  for(i=0; i<Max; i++){
    for(j=0; j<Max; j++){

      if(i == j) continue;

      if(j == ((i+1) % Max) )
	printf("%d:%d:0.0\n", i, j);
      else if(j == ((i-1+Max) % Max))
	printf("%d:%d:0.0\n", i, j);
      else
	printf("%d:%d:1.0\n", i,j);

    }
  }

}


void line(int Max){
  int i, j;

  //printf("line topology \n");
  for(i=0; i<Max; i++){
    for(j=0; j<Max; j++){

      if(i == j) continue;
      
      if(j == i+1)
	printf("%d:%d:0.0\n", i, j);
      else if(j == i-1)
	printf("%d:%d:0.0\n", i, j);
      else
	printf("%d:%d:1.0\n", i,j);
      
    }
  }
  
}


void grid(int dimx, int dimy){
  int i, j;
  int Max = dimx * dimy;

  //printf("grid topology \n");
  
  for(i=0; i<Max; i++){
    for(j=0; j<Max; j++){

      if(i == j) continue;
      
      if(j == i+1){
	if( ((i+1) % dimx) != 0)
	  printf("%d:%d:0.0\n", i, j);
      }
      else if(j == i-1){
	if((i % dimx) != 0)
	  printf("%d:%d:0.0\n", i, j);
      }
      else if(j == i-dimx)
	printf("%d:%d:0.0\n", i, j);
      else if(j == i+dimx)
	printf("%d:%d:0.0\n", i, j);
      else
	printf("%d:%d:1.0\n", i,j);
      
    }
  }

}
