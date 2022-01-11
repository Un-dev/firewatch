/**
* Name: FireWatch
* Based on the internal empty template. 
* Author: Francois
* Tags: 
*/


model FireWatch

global {
	int nbtruck;
	int nbdrones <- 10;
	waterZone the_water;
	
	init {
		create fire number:1{
			place <- one_of(grille);
			self.location <- place.location;	
		}
		create waterZone{
			the_water <- self; 
		}
		create drone number:nbdrones{
			place <- one_of(grille);
			self.location <- place.location;	
		}
		
	}
	reflex stop when:length(fire)=0{
		do pause;
	}
	
	
	//possible predicate concerning drones
	predicate find_water <- new_predicate("find water") ;
	predicate go_to_fire <- new_predicate("go to fire") ;
	
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
	
	aspect base {
	  draw file("../includes/Fire.png") size: 5;
	}
	
	reflex burn when: place.pv > 0 { 
		//TO DO : add fire intensity 	
    	place.pv <- place.pv - 0.005 ;
    }
    
    reflex die when: place.pv <= 0{
    	do die;
    }
    
    reflex propagation when: place.pv > 0 {
    	bool propagates <- rnd(0.01)/0.01 > 0.8 ? true : false;
    	if propagates and place.pv < 0.6 {
    		grille neighbour_place <- one_of (place.neighbors);
			create fire number:1{
				place <- neighbour_place;
				location <- place.location;
			}
		}
    
    }
}


species drone skills: [moving] control:simple_bdi{
	int water <- 0;
	rgb color <- #black;
	float size <-1.0;
	grille place;
	
	aspect base {
		draw triangle(3) color:color rotate: 90 + heading;	
	}
	
	init {
        do add_desire(find_water);
    }
    
    plan return_to_water intention: find_water when: water <= 0{
        do goto target: the_water ;
        if (the_water.location = location)  {
            do remove_belief(find_water);
            do remove_intention(find_water, true);
            water <- 1;
        }
    }
    plan put_out_the_fire intention: find_water when: water >= 1{
        do goto target: the_water ;
        if (the_water.location = location)  {
            do remove_belief(find_water);
            do remove_intention(find_water, true);
            water <- 1;
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



grid grille width: 25 height: 25 neighbors:4 {
	float pv <- 1.0;
	rgb color <- rgb(int(255 * (1 - pv)), 255, int(255 * (1 - pv)))
	update: rgb(0, int(255 *pv), 0) ;
	list<grille> neighbors  <- (self neighbors_at 1);
	
}

experiment FireWatch type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display view {
			grid grille lines: #darkgreen;
			
			species waterZone aspect:base;
			species fire aspect:base;
			species drone aspect:base;
		}
	}
}
