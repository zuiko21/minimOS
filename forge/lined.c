/* line editor for minimOS!
 * v0.5a1
 * (c)2016 Carlos J. Santisteban
 * last modified 20160428-1012 */
 
#include <stdio.h>

typedef b8 unsigned char;

b8 ram[65536], a, x, y;
int cur, ptr;

int main(void)
{
//pseudo code ahead
	do {
	  if (key==ctl_e) { //edit previous
		if (cur>0) cur--;
		edit=TRUE; //mode: edit existing
		prev(); //go back until CR or begin
		pop(); //copy line into buffer
		prompt(); //print cur> and buffer contents
	  }
	  if (key==ctl_x) { //delete previous
		if (cur>0) { //none if empty
		  src=ptr; //start of current line
		  prev(); //back to previous
		  move_dn(src,ptr); //displace
		  cur--;
		}
	  }
	  if (key==cr) { //insert or accept current
		if (!edit) { //insert new line
		  src=ptr; //current is kept
		  dest=ptr+buflen(); //room for buffer
		  move_up(src,dest)
		} else { //replace old
		  edit=FALSE;
		  optr=ptr; //sace current pos
		  next(); //set ptr to next line (advance current size)
		  delta=optr+buflen()-ptr; //new vs old length
		  if (delta>0) { //now is longer)
			move_up(optr,optr+delta); //get extra room
		  } else if (delta<0) { //now is shorter
			move_dn(optr+delta,optr); //shrink
		  } //don't move if same length
		  ptr=optr; //retrieve
		}
		push(); //copy buffer @ptr
		indent(); //copy leading whitespace into buffer and terminate it
		next(); //point to next
		cur++;
		prompt(); //show cur> and buffer (indent)
	  }
	  if (key==up && cur>1) { //show previous
		cur-=2;
		prev();
		//this should be common
		indent(); //get leading whitespace
		show(); //print cur: and line @ptr, advance ptr! otherwise next()
		cur++;
		prompt(); //show new cur> and buffer (indent)
	  }
	  if (key==down && ram[ptr]) { //show next if not at end
		//common as above
	  }
	  //should do start & end keys
	  //what to do on ESC? common block?
	  if (key==ctl_g) { //goto line
		dest=ask(); //prompt for line number
		for(cur=0;cur<dest;cur++) {
		  optr=ptr; //keep old pos
		  next(); //advance one line
		  if (!ram[ptr]) break; //abort at end
		}
		ptr=optr; //back once, should decr. cur???
		//common as above
	  }
	  if (valid(key)) { //including tabs shown raw
		//edit like READLN in raw
		//don't manage CR/ESC
	  }
	} while(-1);	// loop forever
	
	return 0;
}
