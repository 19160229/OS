#include<pthread.h>
#include<stdio.h>
#include<stdlib.h>
#define NUM_THREADS 8
char *messages[NUM_THREADS];
struct thread_data{
	int thread_id;
	int sum;
	char *message;
};
struct thread_data thread_data_array[NUM_THREADS];

void *PrintHello(void *threadarg){
	int taskid,sum;
	char *hello_msg;
	struct thread_data *my_data;
	sleep(1);
	my_data=(struct thread_data *) threadarg;
	taskid=my_data->thread_id;
	sum=my_data->sum;
	hello_msg=my_data->message;
	printf("Thread %d : %s Sum=%d\n",taskid,hello_msg,sum);
	pthread_exit(NULL);
}

int main(int argc,char *argv[]){
	pthread_t threads[NUM_THREADS];
	int *taskids[NUM_THREADS];
	int rc,t,sum;
	sum=0;
	messages[0]="C:\tprintf(\"Hello World\");";
	messages[1]="C++:\tcout<<\"Hello World\"<<endl;";
	messages[2]="Java:\tSystem.out.println(\"Hello World\");";
	messages[3]="Python:\tprint(\"Hello World\")";
	messages[4]="C#";
	messages[5]="JavaScript";
	messages[6]="HTML";
	messages[7]="R";

	for(t=0;t<NUM_THREADS;t++){
		sum+=t;
		thread_data_array[t].thread_id=t;
		thread_data_array[t].sum=sum;
		thread_data_array[t].message=messages[t];
		printf("Creating thread %d\n",t);
		rc=pthread_create(&threads[t],NULL,PrintHello,(void*)&thread_data_array[t]);
		if(rc){
			printf("ERROR; return code f is %d\n",rc);
			exit(-1);		
		}
	}
	pthread_exit(NULL);
}

