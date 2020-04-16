#include <stdio.h>

int funkcja(char *buf,int n){
	
	int index = -1;
	int licznik = 0;
	
	for(int i = 0; *(buf+i) != 0;i++){
		if(*(buf+i) == '1'){
			if(licznik==0){
				index = i;
			}
			licznik++;
		}
		else{
			index = -1;
			licznik=0;
		}
		if (licznik==n){
			return index;
		}
		
	}
	return -1;
}

int main(){
	
	char* s = "98118225324635365374671110";
	int n = 3;
	int a = funkcja(s,n);
	printf("Dla Ciagu %s ilosci wystapien %d wynik wynosi %d",s,n,a);
	
}
