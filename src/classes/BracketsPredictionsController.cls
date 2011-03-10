/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/

public with sharing class BracketsPredictionsController {
    public  Boolean showTree    { get; set; }
    public String singleRound { get; set; }
    public String targetPool { get; set; }
    public Brackets_UserTournament__c target {get; set; }
    
	public String  json	        { get; set; }
	public String  message	    { get; set; }
	public String  messageType  { get; set; }
	
	public Boolean hideDialog { get; set; }
	
	//pool type -- 
	public Boolean isFullTournament { get; set; }
	
	//might be locked for any number of reasons
	public Boolean isLocked { get; set; }
	
	//useful for both full tournament and round by round pools
	public Datetime nextDeadline { get; set; }
	public String formattedNextDeadline { get; set; }
	
	//for round by round pools, it indicates the active round
	public Integer activeRound { get; set; }
	
	//for viewing another person's predictions
	public Id targetUserTournament { get; set; }
	public String userTournamentUser { get; set; }
	
	
    /**
    *   Constructor
    */
    public BracketsPredictionsController() {

    	targetPool = Apexpages.currentPage().getParameters().get( 'show' );
    	if (targetPool == null) {
    		targetUserTournament = Apexpages.currentPage().getParameters().get( 'view' );
    	}
        showTree = false;
        List<Brackets_UserTournament__c> userTournaments = this.userJoinedPools();
        this.singleRound = null;
        if( userTournaments.size() == 1 ){
            target = userTournaments.get(0);
            targetPool = target.Brackets_Group__c;
            this.singleRound = target.Brackets_Group__c;
            initNextDeadline();
            if (targetUserTournament == null) {
            	
		        BracketsSettings2__c settings = BracketsSettings2__c.getInstance(UserInfo.getUserId());
		        if (settings != null) {
		        	hideDialog = settings.Hide_Help_Dialog__c;
		        }
		        showTree = true;            	
            } else {
            	if (this.isLocked) {
            		showTree = true;
            	} else {
            		this.message = 'Cannot view a prediction tree before the deadline.';
            		showTree = false;
            	}
            	this.userTournamentUser = target.User__r.Name;
            	hideDialog = true;
            }
            
        }

        
    }

    
    public PageReference goToPoolList(){
        return Page.BracketsPools;  
    }
    
    public PageReference gotoPoolDetail(){
        return new ApexPages.Pagereference('/'+targetPool);
    }
    
    /**
    * Get the User joined Pools
    * @return UserTournament List
    */
    public List<Brackets_UserTournament__c>  userJoinedPools(){
        List<Brackets_UserTournament__c> userTournaments = null;
        
        if (targetPool == null && targetUserTournament == null) {
        	userTournaments = [Select Id, Brackets_Group__c, Brackets_Group__r.TournamentType__c, Brackets_Group__r.Name, Brackets_Group__r.Type__c, Brackets_Tournament__r.Name, Brackets_Tournament__r.Deadline__c, Championship_Point_Prediction__c from Brackets_UserTournament__c where User__c =: Userinfo.getUserId() ];
        } else if (targetUserTournament != null && targetPool == null) {
        	userTournaments = [Select Id, Brackets_Group__c, Brackets_Group__r.TournamentType__c, Brackets_Group__r.Name, Brackets_Group__r.Type__c, Brackets_Tournament__r.Name, Brackets_Tournament__r.Deadline__c, User__r.Name, Championship_Point_Prediction__c from Brackets_UserTournament__c where Id =: targetUserTournament ];
        } else {
        	userTournaments = [Select Id, Brackets_Group__c, Brackets_Group__r.TournamentType__c, Brackets_Group__r.Name, Brackets_Group__r.Type__c, Brackets_Tournament__r.Name, Brackets_Tournament__r.Deadline__c, Championship_Point_Prediction__c from Brackets_UserTournament__c where Brackets_Group__c =: targetPool and User__c =: Userinfo.getUserId() ];
        }
        
        return userTournaments;
    }
    
    	/**
	* Parse string and save predictions 
	*/ 
	public PageReference saveAllPred(){
		
		PageReference page = null;
		
		if (!isLocked) {
			try {
				if (this.json.length() > 0) {
					BracketsMatchesPredictionUtil.saveFromJSON( this.json ,Userinfo.getUserId());
				}
				System.debug('12345'+target);
				update target;
				//init();
				this.message = 'All your predictions has been saved successfully!!';
				this.messageType = 'success';
				page = new PageReference('/apex/BracketsMatchesPrediction?show='+this.targetPool);
				page.setRedirect(true);
			}
			catch( Exception e ) {
				System.debug('exception1:' + e);
				this.message = e.getMessage();
				this.messageType = 'error';	
			}
		} else {
			this.messageType = 'locked';
			this.message = 'Predictions are currently locked.';
		}
		
		updateHideDialog();
		
		return null;
		//return page;
	}
	
	public void initNextDeadline() {
		
		isLocked = false;
		
		if (target.Brackets_Group__r.Type__c == BracketsGroupUtilities.BET_TYPE_FULL_TOURNAMENT) {
			isFullTournament = true;
			nextDeadline = target.Brackets_Tournament__r.Deadline__c;
			if (nextDeadline < Datetime.now()) {
				isLocked = true;
			}
		} else {
			//figure out the next deadline based on
			isFullTournament = false; 
			List<Brackets_Round__c> rounds = [Select Id, Name, Deadline__c, RoundNumber__c From Brackets_Round__c Where Brackets_Tournament__c =: target.Brackets_Tournament__c AND Deadline__c >: Datetime.now() LIMIT 1];
			if (rounds.size() == 0) {
				isLocked = true;
			} else {
				Brackets_Round__c r = rounds.get(0);
				nextDeadline = r.Deadline__c;
				activeRound = Integer.valueOf(''+r.RoundNumber__c);
			}
		}
		
		//we should have a deadline and if we don't that's problematic
		if (!isLocked && nextDeadline == null) {
			throw new BracketsException('Unable to initialize the next deadline.  For Full Tournament pools, this is on the Tournament Object.  For Round By Round pools, this is on the individual Round.');
		}
		
		if (isLocked) {
			formattedNextDeadline = 'Locked';
		} else {
			//get the current users' timezone setting
			User current = [Select Id, TimeZoneSidKey From User Where Id =: UserInfo.getUserId()];
			//now make sure the deadline is in the current users' Z
			formattedNextDeadline = nextDeadline.format('EEE, d MMM yyyy HH:mm a', current.TimeZoneSidKey);
		}		
		
	}
	
	public void updateHideDialog() {
		
		System.debug('Update Hide Dialog' + this.hideDialog);
		
		if (this.hideDialog == null) {
			this.hideDialog = false;
		}
		
		BracketsSettings2__c settings = BracketsSettings2__c.getInstance(UserInfo.getUserId());
		if (settings == null) {
			settings = new BracketsSettings2__c();
			settings.Name = UserInfo.getUserId();
			
		}
		settings.Hide_Help_Dialog__c = this.hideDialog;
		upsert settings;	
		
	}
    
	public String getLastChatterUpdate() {
		
		String ret = new BracketsFeedItemUtility().getLastTournamentGroupChatter(target.Brackets_Group__c,75);
		
		if (ret == '') {
			ret = 'No updates yet - be the first!';
		}
		return ret;
	}
    
    private static testMethod void testPredictionController(){
    	
    	BracketsTournamentUtilities.CreatingTournamentTree = true;
    	
    	//Create a user
    	User testUser = BracketsTestUtilities.createUser();
    	
    	System.runAs(testUser) {
    	
			//test that we get a !showTree when there are no user predictions
			BracketsPredictionsController controller = new BracketsPredictionsController();
			System.assert(!controller.showTree);

			Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 General Prediction Controller', 4);			
			
			Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id);
			Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team');
			Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team');
			
			List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
			auxList.add( teamA );
			auxList.add( teamB );
			upsert auxList;
			
			Brackets_Round__c          round          = BracketsTestUtilities.createRound(tournament,1, null,4,'Round1-Test');

			Brackets_Match__c          match          = BracketsTestUtilities.createMatch(teamA, teamB, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			round.Deadline__c = match.schedule__c.addMinutes(-5);
			update round;
			
			Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);

			//single user tournament so it should automatically show tree
			controller = new BracketsPredictionsController();
			System.assert(controller.showTree);		
			
			//multi user tournament so it should problem for which tournament to show
			Brackets_Group__c          groupp2         = BracketsTestUtilities.getGroup(tournament.Id);
			Brackets_UserTournament__c userTournament2 = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp2.Id);
			controller = new BracketsPredictionsController();
			System.assert(!controller.showTree);			
			
			//multi user tournament with show parameter
			ApexPages.currentPage().getParameters().put('show', groupp.Id);
			controller = new BracketsPredictionsController();
			System.assert(controller.showTree);			
			
			//multi user tournament with a deadline that is before now and should be locked
			tournament.Deadline__c = Datetime.now().addMinutes(-1);
			update tournament;
			ApexPages.currentPage().getParameters().put('show', groupp.Id);
			controller = new BracketsPredictionsController();
			System.assert(controller.showTree);			
			System.assert(controller.isLocked);	
			
			//a couple of Booleans
			System.assert(controller.activeRound == null);
			System.assert(controller.isFullTournament);
			
			
			
    	}

    }


    
    public testmethod static void testSaveAllPred(){
    	
		BracketsTournamentUtilities.CreatingTournamentTree = true;
    	
	
		Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 RoundByRound', 4);
		
		Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id);
		Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team');
		Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team');
		
		List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
		auxList.add( teamA );
		auxList.add( teamB );
		upsert auxList;
		
		Brackets_Round__c          round          = BracketsTestUtilities.createRound(tournament,1, null,4,'Round1-Test');

		Brackets_Match__c          match          = BracketsTestUtilities.createMatch(teamA, teamB, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			round.Deadline__c = match.schedule__c.addMinutes(-5);
			update round;
					
		Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);
		
		String jsonString = '{ "0" : { "matchId" : "'+match.Id+'" ,"userTour" : "'+userTournament.Id+'", "teamId" : "'+teamA.Id+'" , "userPred" : "" }}';
		
		
		ApexPages.currentPage().getParameters().put('show', groupp.Id);
		
		BracketsPredictionsController controller = new BracketsPredictionsController();

		controller.json = jsonString;
		controller.saveAllPred();
		

		System.assert(controller.messageType == 'success','The result of save the prediction should be sucessful. message is : ' + controller.messageType );
	}
	

	//makes sure all the first round stuff works
	public testmethod static void testRoundByRoundOne() {
		
		BracketsTournamentUtilities.CreatingTournamentTree = true;
		    	//Create a user
    	User testUser = BracketsTestUtilities.createUser();
    	
    	System.runAs(testUser) {	
 

			Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 RoundByRound', 4);
			
			Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id, BracketsGroupUtilities.BET_TYPE_BY_ROUND);
			
			Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team');
			Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team');
			Brackets_Team__c           teamC          = BracketsTestUtilities.createTeam('C-Team');
			Brackets_Team__c           teamD          = BracketsTestUtilities.createTeam('D-Team');
			
			List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
			auxList.add( teamA );
			auxList.add( teamB );
			auxList.add( teamC );
			auxList.add( teamD );
			upsert auxList;
			

			Brackets_Round__c          round          = BracketsTestUtilities.createRound(tournament,1, null,4,'Round1-Test');
			
			Brackets_Round__c          round2          = BracketsTestUtilities.createRound(tournament,2, null,8,'Round2-Test');
			
	
			Brackets_Match__c          match          = BracketsTestUtilities.createMatch(teamA, teamB, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			
			Brackets_Match__c	      match2		= BracketsTestUtilities.createMatch(teamC, teamD, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			
			round.Deadline__c = match.schedule__c.addMinutes(-5);
			update round;
			
			Brackets_Match__c	      match3		= BracketsTestUtilities.createMatch(null, null, round2, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			round2.Deadline__c = match3.schedule__c.addMinutes(-5);
			update round2;
			
			
			Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);
			
			ApexPages.currentPage().getParameters().put('show', groupp.Id);
			BracketsPredictionsController controller = new BracketsPredictionsController();
			System.assert(controller.showTree);			
			System.assert(!controller.isLocked);
			
			System.debug('\n\nNextDeadline: ' + controller.nextDeadline + ' but the round deadline is ' + round.Deadline__c);
			System.assert(round.Deadline__c.format() == controller.nextDeadline.format());	
			
			System.assert(!controller.isFullTournament);
			System.assert(controller.activeRound == Integer.valueOf(''+round.RoundNumber__c));
			
    	}
	}
    	
	//makes sure all the second round stuff workds
	public testmethod static void testRoundByRoundTwo() {
		
		BracketsTournamentUtilities.CreatingTournamentTree = true;
		    	//Create a user
    	User testUser = BracketsTestUtilities.createUser();
    	
    	System.runAs(testUser) {	
 

			Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 RoundByRound', 4);
			tournament.deadline__c = tournament.deadline__c.addMinutes(-60);
			update tournament;
			
			Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id, BracketsGroupUtilities.BET_TYPE_BY_ROUND);
			
			Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team');
			Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team');
			Brackets_Team__c           teamC          = BracketsTestUtilities.createTeam('C-Team');
			Brackets_Team__c           teamD          = BracketsTestUtilities.createTeam('D-Team');
			
			List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
			auxList.add( teamA );
			auxList.add( teamB );
			auxList.add( teamC );
			auxList.add( teamD );
			upsert auxList;
			

			Brackets_Round__c          round          = BracketsTestUtilities.createRound(tournament,1, null,4,'Round1-Test');
			
			Brackets_Round__c          round2          = BracketsTestUtilities.createRound(tournament,2, null,8,'Round2-Test');
			
	
			Brackets_Match__c          match          = BracketsTestUtilities.createMatch(teamA, teamB, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			match.Schedule__c = Datetime.now().addMinutes(-30);
			update match;
			
			Brackets_Match__c	      match2		= BracketsTestUtilities.createMatch(teamC, teamD, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			match2.Schedule__c = Datetime.now().addMinutes(-30);
			update match2;
			
			round.Deadline__c = match.schedule__c.addMinutes(-5);
			update round;
			
			Brackets_Match__c	      match3		= BracketsTestUtilities.createMatch(null, null, round2, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			round2.Deadline__c = match3.schedule__c.addMinutes(-5);
			update round2;
			
			
			Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);
			
			ApexPages.currentPage().getParameters().put('show', groupp.Id);
			BracketsPredictionsController controller = new BracketsPredictionsController();
			System.assert(controller.showTree);			
			System.assert(!controller.isLocked);
			
			System.debug('\n\nNextDeadline: ' + controller.nextDeadline + ' but the round deadline is ' + round.Deadline__c);
			System.assert(round2.Deadline__c.format() == controller.nextDeadline.format());	

			System.assert(!controller.isFullTournament);
			System.assert(controller.activeRound == Integer.valueOf(''+round2.RoundNumber__c));
			
			
    	}
    	
    	
    	
	}
	
	
	//makes sure everything shows as locked.
	public testmethod static void testRoundByRoundThree() {
		
		BracketsTournamentUtilities.CreatingTournamentTree = true;
		    	//Create a user
    	User testUser = BracketsTestUtilities.createUser();
    	
    	System.runAs(testUser) {	
 

			Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 RoundByRound', 4);
			tournament.deadline__c = tournament.deadline__c.addMinutes(-60);
			update tournament;
			
			Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id, BracketsGroupUtilities.BET_TYPE_BY_ROUND);
			
			Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team');
			Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team');
			Brackets_Team__c           teamC          = BracketsTestUtilities.createTeam('C-Team');
			Brackets_Team__c           teamD          = BracketsTestUtilities.createTeam('D-Team');
			
			List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
			auxList.add( teamA );
			auxList.add( teamB );
			auxList.add( teamC );
			auxList.add( teamD );
			upsert auxList;
			

			Brackets_Round__c          round          = BracketsTestUtilities.createRound(tournament,1, null,4,'Round1-Test');
			
			Brackets_Round__c          round2          = BracketsTestUtilities.createRound(tournament,2, null,8,'Round2-Test');
			
	
			Brackets_Match__c          match          = BracketsTestUtilities.createMatch(teamA, teamB, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			match.Schedule__c = Datetime.now().addMinutes(-45);
			update match;
			
			Brackets_Match__c	      match2		= BracketsTestUtilities.createMatch(teamC, teamD, round, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			match2.Schedule__c = Datetime.now().addMinutes(-45);
			update match2;
			
			round.Deadline__c = match.schedule__c.addMinutes(-5);
			update round;
			
			Brackets_Match__c	      match3		= BracketsTestUtilities.createMatch(null, null, round2, BracketsTournamentUtilities.NFL_CONFERENCE_AMERICAN);
			match3.Schedule__c = Datetime.now().addMinutes(-30);
			update match3;
						
			round2.Deadline__c = match3.schedule__c.addMinutes(-5);
			update round2;
			
			
			Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);
			
			ApexPages.currentPage().getParameters().put('show', groupp.Id);
			BracketsPredictionsController controller = new BracketsPredictionsController();
			System.assert(controller.showTree);			
			
			System.debug('\n\nNextDeadline: ' + controller.nextDeadline + ' but the round deadline is ' + round.Deadline__c);
			System.assert(controller.nextDeadline == null);	
			System.assert(controller.isLocked);
			
			System.assert(!controller.isFullTournament);
			System.assert(controller.activeRound == null);
			
    	}
    	
    	
    	
	}	
	
	static testmethod void testSimplePageRefs() {
		
		BracketsPredictionsController c = new BracketsPredictionsController();
		
		Pagereference p1 = c.gotoPoolDetail();
		
		System.assert(p1 != null);
		
		Pagereference p2 = c.goToPoolList();
		
		System.assert(p2 != null);
	}
}