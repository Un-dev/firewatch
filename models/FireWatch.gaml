/**
* Name: FireWatch
* Based on the internal empty template. 
* Author: Francois
* Tags: 
*/


model FireWatch

global {
	int displatTextSize <-4;
	//defining predicates 
	predicate patrol_desire <- new_predicate("patrol");
	predicate has_water <- new_predicate("has water",true);
	predicate needs_water <- new_predicate("has water", false) ;
	predicate share_information <- new_predicate("share information") ;
	predicate fire_location <- new_predicate(fireLocation) ;
	string fireLocation <- "fireLocation";
	
	//initializing global variable
	//We consider communication dist as infinite
	float communication_dist <- 20000.0;
	
	//Drone's speed is different if they carri water or if they are empty
	float empty_drone_speed <- 2.0;
	float full_drone_speed <- 1.0;
	
	//iniatilizing agents
	init {
		create fireArea number:1;
		create waterArea number:1;
		create drone number: 2;
		create truck number: 2;
	}
	//stops simulation when all fires are extinguished
	reflex stop when: length(fireArea) = 0 {
		do pause;
	}
}

species truck skills: [moving] control: simple_bdi{
	float waterValue;
	grille place <- one_of(grille);
	
	
	
	//here we consider that truck will start fully loaded in water, to be ready at any time
	init {
		waterValue <-25.0;
		location<-place.location;
	}
	
	//functions that updates trucks beliefs, linked to water needs
	perceive target:self {
		if(waterValue>0){
			do add_belief(has_water);
			do remove_belief(needs_water);
		}
		if(waterValue<=0 and fireLocation){
			do add_belief(needs_water);
			do remove_belief(has_water);
		}
	}
	
	
	//functions that perceive fires
	//todo: prevent drone from getting water if 
	perceive target:fireArea where place.can_burn in: 5{ 
		if (fireArea != nil){
			focus id:fireLocation var:location strength:10.0; 
			ask myself{
				//do add_desire(predicate:share_information);
				//do remove_intention(patrol_desire, true);
				}	 
		}		
	}
	
	
	
	//trucks like drone no matter what
	perceive target: drone in: communication_dist {
    	socialize liking: 1;
    }
	
	//truck don't patrol, they wait on drones information
//	plan patrolling intention:patrol_desire{
//		do wander amplitude: 10.0 speed: empty_drone_speed;
//	}
	
	
	//The plan that is executed when the agent got the intention of extinguish a fire.
	plan stopFire intention: fire_location priority:5{
	if(point(get_predicate(get_current_intention())) != nil){
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
						if (length(get_beliefs_with_name(fireLocation)) <= 0){
							do add_desire(patrol_desire,1.0);
						}
					}
					}else {
						do goto(target: target_fire, speed:full_drone_speed);
					}
				}else{
					do remove_belief(get_predicate(get_current_intention()));
					do remove_intention(get_predicate(get_current_intention()), true);
					if (length(get_beliefs_with_name(fireLocation)) <= 0){
							do add_desire(patrol_desire,1.0);
					}
				}
			
			
		} else {
			do add_subintention(get_current_intention(),has_water,true);
			do current_intention_on_hold();
		}
	}
	
	}  
	
	//The plan to take water when the agent get the desire of water.
    plan gotoTakeWater intention: has_water priority:2 {
    	waterArea wa <- first(waterArea);
    	list<grille> voisins <-  (grille(location) neighbors_at (1)) + grille(location);
			path cheminSuivi <-  goto(target: wa, speed: empty_drone_speed) ;
    	if (self distance_to wa <= 1) {
    		waterValue <- waterValue + 2.0;
		}
    }
     
     
    //list all the drones in the simulation (we consider that they are all interconnected)   
//    list<drone> my_friends;
    
    //the plan that share the location of a fire when found by a drone
//    plan share_information_to_friends intention: share_information priority:1 instantaneous: true{    
//    	my_friends <- list<drone>((social_link_base where (each.liking > 0)) collect each.agent);
//    	loop known_fire_at_location over: get_beliefs_with_name(fireLocation) {
//        	ask my_friends {
//        		do remove_intention(patrol_desire, true);
//        		do add_directly_belief(known_fire_at_location);	
//        	}        		
//       
//    	}
//    		do remove_intention(share_information, true); 
//    }

	
	rule belief: new_predicate(fireLocation) new_desire: get_predicate(get_belief_with_name(fireLocation));
	rule belief: needs_water new_desire: has_water strength: 10.0;
	
	aspect base {
		draw square(3) color:color rotate: 90 + heading;
		draw "B="+length(get_beliefs_with_name(fireLocation)) at: location color:#white ;
	}
}

species drone skills: [moving] control: simple_bdi{
	float waterValue;
	grille place <- one_of(grille);	
	
	//here we consider that drone will have no water until they find a fire, for speed and energy issues
	//todo slow down drone when it has watervalue > 0
	//add battery value
	init {
		waterValue <-0.0;
		location<-place.location;
		do add_desire(patrol_desire);
	}
	
	//functions that updates drone beliefs, linked to water needs
	perceive target:self {
		if(waterValue>0){
			do add_belief(has_water);
			do remove_belief(needs_water);
		}
		if(waterValue<=0 and fireLocation){
			do add_belief(needs_water);
			do remove_belief(has_water);
		}
	}
	
	
	//functions that perceive fires
	//todo: prevent drone from getting water if 
	perceive target:fireArea where place.can_burn in: 15{ 
		if (fireArea != nil){
			focus id:fireLocation var:location strength:10.0; 
			ask myself{
				do add_desire(predicate:share_information);
				//drones in this simulation are only 'eyes' for the trucks
				do remove_intention(patrol_desire, true);
				}	 
		}		
	}
	
	
	
	//Drones like each other no matter what
	perceive target: drone in: communication_dist {
    	socialize liking: 1;
    }
    
    //Drones like truck no matter what
	perceive target: truck in: communication_dist {
    	socialize liking: 1;
    }
	
	plan patrolling intention:patrol_desire{
		do wander amplitude: 10.0 speed: empty_drone_speed;
	}
	
	
	//The plan that is executed when the agent got the intention of extinguish a fire.
//	plan stopFire intention: fire_location priority:5{
//	point target_fire <- point(get_predicate(get_current_intention()).values["location_value"]);
//		if(waterValue>0){
//			fireArea current_fire <- fireArea first_with (each.location = target_fire);
//			if (current_fire != nil){
//				if (self distance_to target_fire <= 1) {
//					waterValue <- waterValue - 1.0;
//					 current_fire.size <-  current_fire.size - 1;
//					 if ( current_fire.size <= 0) {
//						ask  current_fire {
//							current_fire.place.can_burn <- false;
//							do die;
//						}
//						do remove_belief(get_predicate(get_current_intention()));
//						do remove_intention(get_predicate(get_current_intention()), true);
//						if (length(get_beliefs_with_name(fireLocation)) <= 0){
//							do add_desire(patrol_desire,1.0);
//						}
//					}
//					}else {
//						do goto(target: target_fire, speed:full_drone_speed);
//					}
//				}else{
//					do remove_belief(get_predicate(get_current_intention()));
//					do remove_intention(get_predicate(get_current_intention()), true);
//					if (length(get_beliefs_with_name(fireLocation)) <= 0){
//							do add_desire(patrol_desire,1.0);
//					}
//				}
//			
//			
//		} else {
//			do add_subintention(get_current_intention(),has_water,true);
//			do current_intention_on_hold();
//		}
//	}  
	
	//The plan to take water when the agent get the desire of water.
    plan gotoTakeWater intention: has_water priority:2 {
    	waterArea wa <- first(waterArea);
    	list<grille> voisins <-  (grille(location) neighbors_at (1)) + grille(location);
			path cheminSuivi <-  goto(target: wa, speed: empty_drone_speed) ;
    	if (self distance_to wa <= 1) {
    		waterValue <- waterValue + 2.0;
		}
    }
     
    //list all the drones in the simulation (we consider that they are all interconnected)   
    list<truck> my_friends;
    
    //the plan that share the location of a fire to trucks when found by a drone
    plan share_information_to_friends intention: share_information priority:1 instantaneous: true{    
    	my_friends <- list<truck>((social_link_base where (each.liking > 0)) collect each.agent);
    	loop known_fire_at_location over: get_beliefs_with_name(fireLocation) {
        	ask my_friends {
        		//do remove_intention(patrol_desire, true);
        		do add_directly_belief(known_fire_at_location);	
        		do add_intention(fire_location);
        	}        		
       
    	}
    		do remove_intention(share_information, true); 
    }

	
	rule belief: new_predicate(fireLocation) new_desire: get_predicate(get_belief_with_name(fireLocation));
	rule belief: needs_water new_desire: has_water strength: 10.0;
	
	aspect base {
		draw triangle(3) color:color rotate: 90 + heading;
		draw "B="+length(get_beliefs_with_name(fireLocation)) at: location color:#white ;
	}
}

species fireArea control:simple_bdi{
	float size <-1.0;
	grille place;
	
	init{
		place <- one_of(grille);
		location <- place.location;
		place.can_burn <- false;
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
    	bool propagates <- rnd(0.01)/0.01 > 0.8 ? true : false;
    	grille neighbour_place <- one_of (place.neighbors);
    	if propagates = true and place.pv < 0.6{
    		
    		grille new_place <- neighbour_place;
    		if new_place.can_burn = true{
    			create fireArea number:1{
					place <- new_place;
					location <- place.location;
					place.can_burn <- false;
				}
    		}

		}
    }
    
	aspect base {
	  draw file("../includes/Fire.png") size: 2;
	  // for debug purpose
	  // draw "B="+self.place.can_burn at: location color:#white ;
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

grid grille width: 100 height: 100 neighbors:8 {
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
			species truck aspect:base;
		}
	}
}