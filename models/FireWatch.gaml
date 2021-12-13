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

	reflex stop when:length(fire)=0{
		do pause;
	}
}

species fire {
	
}

species truck skills: [moving] control:simple_bdi{
	int water;
}

species drone skills: [moving] control:simple_bdi{
	int water;
}

grid grille width: 25 height: 25 neighbors:4 {
	rgb color <- #green;
}

experiment FireWatch type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display view {
			grid grille lines: #darkgreen;
		}
	}
}
