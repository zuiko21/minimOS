#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
	int x,y,x1,y1,x2,y2,s1,s2,q1,q2,dir;
	int dx[4]={1,0,-1,0};
	int dy[4]={0,1,0,-1};

	srand(time(NULL));

	while(-1) {
		x=rand()&31;
		y=rand()&31;

		dir=rand()&3;
		x1=x+dx[dir];
		y1=y+dy[dir];

		dir=rand()&3;
		x2=x+dx[dir];
		y2=y+dy[dir];

		if((x1!=x2)||(y1!=y2)){
			s1=((x1*x1)>>2)+((y1*y1)>>2);
			s2=((x2*x2)>>2)+((y2*y2)>>2);
			q1=((x1*x1)>>3)+((y1*y1)>>3);
			q2=((x2*x2)>>3)+((y2*y2)>>3);
			printf("(%d,%d)-(%d,%d) = %d/%d - %d/%d\n",x1,y1,x2,y2,s1,s2,q1,q2);
			if (q1==q2)
				printf("[%c,%c]-[%c,%c]\n",32+(x1&1),32+(y1&1),32+(x2&1),32+(y2&1));
		}
	}

	return 0;
}

