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
	init {
		create fire number:1;
	}
	reflex stop when:length(fire)=0{
		do pause;
	}
}

species waterZone{
	init {
		grille place <- one_of(grille);
		location <- place.location;
	}
	aspect base {
	  draw square(4) color: #blue border: #black;		
	}
}

species fire skills: [moving] control:simple_bdi{
	float size <-1.0;
	
	init{
		grille place <- one_of(grille);
		location <- place.location;
	}
	
	aspect base {
	  draw file("../includes/Fire.png") size: 5;
	}
}

species truck skills: [moving] control:simple_bdi{
	int water;
	aspect base {
		draw triangle(2) color:color rotate: 90 + heading;	
		draw circle(15) color: color ;	
	}
}

species drone skills: [moving] control:simple_bdi{
	int water;
	
	aspect base {
		draw triangle(1) color:color rotate: 90 + heading;	
		draw circle(30) color: color ;	
	}
}

grid grille width: 25 height: 25 neighbors:4 {
	rgb color <- #green;
}

experiment FireWatch type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display view {
			grid grille lines: #darkgreen;
			species fire aspect:base;
		}
	}
}
