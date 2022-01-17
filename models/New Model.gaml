/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Flann
* Tags: 
*/


model NewModel

global {
	int displatTextSize <-4;
	
	predicate patrol_desire <- new_predicate("patrol");
	predicate has_water <- new_predicate("has water",true);
	predicate needs_water <- new_predicate("has water", false) ;
	string fireLocation <- "fireLocation";
	
	init {
		create fireArea number:1;
		create waterArea number:1;
		create drone number: 1;
	}
	
	reflex stop when: length(fireArea) = 0 {
		do pause;
	}
}

species drone skills: [moving] control: simple_bdi{
	float waterValue;
	grille place <- one_of(grille);
	
	init {
		waterValue <-2.0;
		location<-place.location;
		do add_desire(patrol_desire );
	}
	
	perceive target:self {
		if(waterValue>0){
			do add_belief(has_water);
			do remove_belief(needs_water);
		}
		if(waterValue<=0){
			do add_belief(needs_water);
			do remove_belief(has_water);
		}
	}
	
	perceive target:fireArea in: 15{ 
		focus id:"fireLocation" var:location strength:10.0; 
		ask myself{
			do remove_intention(patrol_desire, true);
		} 
	}
	
	rule belief: new_predicate(fireLocation) new_desire: get_predicate(get_belief_with_name(fireLocation));
	rule belief: needs_water new_desire: has_water strength: 10.0;
	
	aspect base {
		draw triangle(3) color:color rotate: 90 + heading;
	}
}

species fireArea control:simple_bdi{
	float size <-1.0;
	grille place;
	
	init{
		place <- one_of(grille);
		location <- place.location;
	}
	
	reflex die when: place.pv <= 0{
    	do die;
    }
    
	reflex burn when: place.pv > 0 { 
		//TO DO : add fire intensity 	
    	place.pv <- place.pv - 0.005 ;
    }
    
	reflex propagation when: place.pv > 0 {
    	bool propagates <- rnd(0.01)/0.01 > 0.8 ? true : false;
    	grille neighbour_place <- one_of (place.neighbors);
    	if propagates = true and place.pv < 0.6 {
    		
			create fireArea number:1{
				place <- neighbour_place;
				location <- place.location;
			}
		}
    }
    
	aspect base {
	  draw file("../includes/Fire.png") size: 5;
	}
}

species waterArea{
	init {
		grille place <- one_of(grille);
		location <- place.location;
	}
	aspect base {
	  draw square(5) color: #blue border: #black;		
	}
}

grid grille width: 25 height: 25 neighbors:4 {
	float pv <- 1.0;
	rgb color <- rgb(int(255 * (1 - pv)), 255, int(255 * (1 - pv)))
	update: rgb(0, int(255 *pv), 0) ;
}

experiment FireWatch type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display view {
			grid grille lines: #darkgreen;
			
			species waterArea aspect:base;
			species fireArea aspect:base;
			species drone aspect:base;
		}
	}
}
