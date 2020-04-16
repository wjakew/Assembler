bubbleSort3: bubbleSort3.o
		ld -o bubbleSort3 bubbleSort3.o
bubbleSort3.o: bubbleSort3.s
		as -gstabs -o bubbleSort3.o bubbleSort3.s

