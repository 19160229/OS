#include<pthread.h>
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<unistd.h>
#define NUM_THREADS 20
int balance[10];
int bankFree[10];
pthread_mutex_t mutex;
pthread_mutex_t bank_mutex[10];

struct thread_data{
	int id;
	int source;
	int target;
	int money;
};
struct thread_data thread_data_array[NUM_THREADS];

void *Bank(void *threadarg){
	int source,target,money,id;
	struct thread_data *my_data;
	my_data=(struct thread_data *) threadarg;
	id=my_data->id;
	source=my_data->source;
	target=my_data->target;
	money=my_data->money;
	printf("thread:%d\tsource:%d\ttarget:%d\tmoney:%d\n",id,source,target,money);
	if(source==target){
		pthread_exit(NULL);
	}
	while(1){
		pthread_mutex_lock(&mutex);
		if(bankFree[source]==1&&bankFree[target]==1){
			bankFree[source]=0;
			bankFree[target]=0;
			pthread_mutex_lock(&bank_mutex[source]);
			pthread_mutex_lock(&bank_mutex[target]);
			pthread_mutex_unlock(&mutex);
			break;	
		}else{
			pthread_mutex_unlock(&mutex);
		}
	}
	if(balance[source]>1000&&balance[source]>money){
		balance[source]-=money;
		balance[target]+=money;
	}	
	printf("thread:%d\tbalance[%d]:%d\tbalance[%d]:%d\n",id,source,balance[source],target,balance[target]);
	pthread_mutex_lock(&mutex);
	bankFree[source]=1;
	bankFree[target]=1;
	pthread_mutex_unlock(&bank_mutex[source]);
	pthread_mutex_unlock(&bank_mutex[target]);
	pthread_mutex_unlock(&mutex);
	pthread_exit(NULL);
}

int main(int argc,char *argv[]){
	int rc;
	int i=0,t=0;
	for(i=0;i<10;i++){
		balance[i]=10000;
		pthread_mutex_init(&bank_mutex[i],NULL);
		bankFree[i]=1;
	}
	pthread_mutex_init(&mutex,NULL);
	srand((int)time(0));
	for(i=0;i<NUM_THREADS;i++){
		int source=rand()%10;
		int target=rand()%10;
		int money=rand()%10000;
		thread_data_array[i].id=i;
		thread_data_array[i].source=source;
		thread_data_array[i].target=target;
		thread_data_array[i].money=money;
	}
	for(t=0;t<NUM_THREADS;t++){
		pthread_t thread;
		rc=pthread_create(&thread,NULL,Bank,(void*)&thread_data_array[t]);
		if(rc){
			printf("ERROR; return code f is %d\n",rc);
			exit(-1);		
		}
	}
	pthread_exit(NULL);
}

