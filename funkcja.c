

int funkcja(char *buf,int n){
	
	int index = -1;
	int licznik = 0;
	
	for(int i = 0; *(buf+i) != 0;i++){
		if(*(buf+i) == 1){
			if(licznik==0){
				index = i;
			}
			licznik++;
		}
		
		if (licznik==n){
			return index;
		}
	}
	return -1;
}

int main(){
	
}
