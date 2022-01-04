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
		create fire number:1{
			place <- one_of(grille);
		}
		create waterZone number:1;
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
	grille place;
	
	init{
		
		location <- place.location;		
	}
	
	aspect base {
	  draw file("../includes/Fire.png") size: 5;
	}
	
	reflex burn when: place.pv > 0 { 
	//TO DO : add fire intensity 	
    place.pv <- place.pv - 0.1 ;
    }
    
    reflex die when: place.pv <= 0{
    	do die;
    }
    
    reflex propagation when: place.pv > 0 {
    	grille neighbour_place2 <- one_of (place.neighbors2);
		create fire number:1{
			location <- neighbour_place2.location;
		}
    
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
	float pv <- 1.0;
	rgb color <- rgb(int(255 * (1 - pv)), 255, int(255 * (1 - pv)))
	update: rgb(0, int(255 *pv), 0) ;
	list<grille> neighbors2  <- (self neighbors_at 2);
	
}

experiment FireWatch type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display view {
			grid grille lines: #darkgreen;
			
			species waterZone aspect:base;
			species fire aspect:base;
		}
	}
}
