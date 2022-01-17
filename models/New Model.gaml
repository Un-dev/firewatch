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
		create drone number: 2;
	}
	
	reflex stop when: length(fireArea) = 0 {
		do pause;
	}
}

species drone skills: [moving] control: simple_bdi{
	float waterValue;
	grille place <- one_of(grille);
	
	init {
		waterValue <-0.0;
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
	
	perceive target:fireArea in: 20000{ 
		focus id:"fireLocation" var:location strength:10.0; 
		ask myself{
			do remove_intention(patrol_desire, true);
		} 
	}
	
	plan patrolling intention:patrol_desire{
		do wander amplitude: 30.0 speed: 2.0;
	}
	
		//The plan that is executed when the agent got the intention of extinguish a fire.
	plan stopFire intention: new_predicate(fireLocation) priority:5{
		point target_fire <- point(get_predicate(get_current_intention()).values["location_value"]);
		if(waterValue>0){
			fireArea current_fire <- fireArea first_with (each.location = target_fire);
			if (current_fire != nil){
				if (self distance_to target_fire <= 1) {
					waterValue <- waterValue - 1.0;
					 current_fire.size <-  current_fire.size - 1;
					 if ( current_fire.size <= 0) {
						ask  current_fire {
							current_fire.place.can_burn <- false;
							do die;
						}
						do remove_belief(get_predicate(get_current_intention()));
						do remove_intention(get_predicate(get_current_intention()), true);
						do add_desire(patrol_desire,1.0);
					}
					}else {
						do goto(target: target_fire);
					}
				}else{
					do remove_belief(get_predicate(get_current_intention()));
					do remove_intention(get_predicate(get_current_intention()), true);
					do add_desire(patrol_desire,1.0);
				}
			
			
		} else {
			do add_subintention(get_current_intention(),has_water,true);
			do current_intention_on_hold();
		}
	}  
	
	//The plan to take water when the agent get the desire of water.
    plan gotoTakeWater intention: has_water priority:2 {
    	waterArea wa <- first(waterArea);
    	list<grille> voisins <-  (grille(location) neighbors_at (1)) + grille(location);
			path cheminSuivi <-  goto(wa);
    	if (self distance_to wa <= 1) {
    		waterValue <- waterValue + 2.0;
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
		self.place.can_burn <- false;
    	do die;
    }
    
	reflex burn when: place.pv > 0 { 
		//TO DO : add fire intensity 	
    	place.pv <- place.pv - 0.005 ;
    }
    
	reflex propagation when: place.pv > 0{
		//randomness decides whether the fire propagates, TODO define wind to determine random propagation
    	bool propagates <- rnd(0.01)/0.01 > 0.8 ? true : false;
    	//grille neighbour_place <- any(one_of (place.neighbors) where (each.can_burn = true)) ;
    	list burnable_neighbors <- (place.neighbors where (each.can_burn = true));
    	grille neighbour_place <- one_of(burnable_neighbors);
    	if propagates = true and place.pv < 0.6{
    		
    		grille new_place <- neighbour_place;
			create fireArea number:1{
				place <- new_place;
				location <- place.location;
			}

		}
    }
    
	aspect base {
	  draw file("../includes/Fire.png") size: 5;
	  draw "B="+self.place.can_burn at: location color:#white ;
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
	bool can_burn <- true;
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
