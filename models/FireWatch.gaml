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
	float droneSpeed <- 3.0 #km / #h;
	
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
			speed <- droneSpeed;	
		}
		
	}
	reflex stop when:length(fire)=0{
		do pause;
	}
	
	
	//possible predicate concerning drones
	predicate need_water <- new_predicate("need water") ;
	predicate go_to_fire <- new_predicate("go to fire") ;
	predicate has_water <- new_predicate("has water") ;
	predicate has_target <- new_predicate("has target") ;
	predicate current_target <- new_predicate("current target") ;
	
	
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
    	grille neighbour_place <- one_of (place.neighbors);
    	if propagates = true and place.pv < 0.6 and neighbour_place.can_burn = true {
    		
			create fire number:1{
				place <- neighbour_place;
				place.can_burn <- false;
				location <- place.location;
			}
		}
    
    }
}


species drone skills: [moving] control:simple_bdi{
	int water;
	rgb color <- #red;
	float size <-1.0;
	grille place;
	float viewdist<-20000.0;
	point target;

	
	rule belief: has_water new_desire: go_to_fire strength:100;
	
	aspect base {
		draw triangle(3) color:color rotate: 90 + heading;	
	}
	
	init {
		water <- 0;
    }
    
    perceive target:self {
		if(water>0){
			do add_belief(has_water);
			do remove_belief(need_water);
		}
		if(water<=0){
			do add_belief(need_water);
			do remove_belief(has_water);
		}
	}
    
    //if the agent perceive a fire in its neighborhood, it adds a belief a belief concening its location and remove its wandering intention
	perceive target:fire in:viewdist {
		focus id:"location_fire" var:location;
		//ask myself {do remove_intention(wander, false);}
	}
    
    plan return_to_water intention: need_water priority:100{
        do goto target: the_water ;
        if (the_water.location = location)  {
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
	bool can_burn <- true;
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
