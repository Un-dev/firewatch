/**
* Name: FireWatch
* Based on the internal empty template. 
* Author: Francois
* Tags: 
*/


model FireWatch

global {
	int nbtruck;
	int nbdrones;
	base the_base;
	init {
		create base {
			the_base <-self;
		}
	}
	reflex stop when:length(fire)=0{
		do pause;
	}
}

