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

public with sharing class BracketsJoinInvitedUser {
	
	private final String UID 		= Userinfo.getUserId();
	private final String GID 		= Apexpages.currentPage().getParameters().get('gId'); 
	private Brackets_Tournament__c tour		= new Brackets_Tournament__c();
	private Brackets_Group__c cGroup			= new Brackets_Group__c();
	private Brackets_UserTournament__c uTour	= new Brackets_UserTournament__c();
	public  Boolean showButtons;
	
	/**
	* Constructor
	*/
	public BracketsJoinInvitedUser() { 	}
	
	
	/**
	* Index
	* @return null 
	*/
	public Pagereference index() {
		if( GID != null && GID != '' ) {
			List<Brackets_UserTournament__c> cUserTournament = [	Select Id from Brackets_UserTournament__c where Brackets_Group__c =: GID and User__c =: UID ];
			if( cUserTournament.isEmpty() ){ 
				cGroup = [Select Brackets_Tournament__c, Brackets_Tournament__r.Id, Id from Brackets_Group__c where Id =: GID limit 1];
				this.tour 		 = cGroup.Brackets_Tournament__r;
				this.showButtons = true;
				return null;
			}
		}
		return this.cancel(); 
	}
	
	
	public Boolean getShowButtons() {
		return this.showButtons;
	}
	
	
	
	/**
	* Join User action
	* @return pageref PageReference 
	*/
	public Pagereference joinUser() {
		
		
		this.uTour.Brackets_Group__c 		= GID;
		this.uTour.Brackets_Tournament__c 	= this.tour.Id;
		this.uTour.User__c			= UID;
		insert this.uTour;
		
		//join Chatter.
		/*
		Integer alreadySubscribed = [Select Count() From EntitySubscription Where SubscriberId = :UID and ParentId = :GID];
		
		if (alreadySubscribed == 0) {
			EntitySubscription es = new EntitySubscription();
			System.debug('UID ' + UID);
			System.debug('GID ' + GID);
			es.SubscriberId = UID;
			es.ParentId = GID;
			insert es;
		}
		*/
		
		return new Pagereference('/apex/BracketsPredictions?show='+GID);
	}
	
	/**
	* Return to HomePage
	* @return pageref PageReference
	*/
	public Pagereference cancel(){ 
		return Page.BracketsPools;
	}
	
	
	/**
	* Test Methods
	*/
	
	//Test Join Successfully 
	public static testMethod void test(){
		//Create enviroment
		Brackets_Group__c mGroup = BracketsTestUtilities.getGroup(null);
		Apexpages.currentPage().getParameters().put( 'gId', mGroup.Id );
		BracketsJoinInvitedUser cTest = new BracketsJoinInvitedUser();
		Test.startTest();
			Pagereference tRef = cTest.index();
			tRef = cTest.cancel();
			tRef = cTest.joinUser();
		Test.stopTest();
		List<Brackets_UserTournament__c> uTour = [Select Id from Brackets_UserTournament__c where User__c =: UserInfo.getUserId() and Brackets_Group__c =: mGroup.Id];  
		System.assert( !uTour.isEmpty() );
	}
	
	//Test Not URL parm
	public static testMethod void test1(){
		//Create enviroment
		Brackets_Group__c mGroup = BracketsTestUtilities.getGroup( null );
		BracketsJoinInvitedUser cTest = new BracketsJoinInvitedUser();
		Test.startTest();
			Pagereference tRef = cTest.index();
		Test.stopTest();
		List<Brackets_UserTournament__c> uTour = [Select Id from Brackets_UserTournament__c where User__c =: UserInfo.getUserId() and Brackets_Group__c =: mGroup.Id];  
		System.assert( uTour.isEmpty() );
	}
	
	//Test already Join 
	public static testMethod void test2(){
		//Create enviroment
		Brackets_Tournament__c mTour 	= BracketsTestUtilities.getNewStandardTournament();
		Brackets_Group__c mGroup 		= BracketsTestUtilities.getGroup( mTour.Id );
		Brackets_UserTournament__c uTour	= BracketsTestUtilities.createUserTournament( Userinfo.getUserId() , mTour.Id, mGroup.Id );
		Apexpages.currentPage().getParameters().put( 'gId', mGroup.Id );  
		
		BracketsJoinInvitedUser cTest = new BracketsJoinInvitedUser();
		Test.startTest();
			Pagereference tRef = cTest.index();
			cTest.getShowButtons();
		Test.stopTest();
		List<Brackets_UserTournament__c> uTr = [Select Id from Brackets_UserTournament__c where User__c =: UserInfo.getUserId() and Brackets_Group__c =: mGroup.Id];  
		System.assert( !uTr.isEmpty() );
	}
}