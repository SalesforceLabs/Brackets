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

public with sharing class BracketsProccessUpdate {
	
	private Brackets_Tournament__c	tourament;
	private String xmlTournamentReceived;
	
	/**
	* 	Constructor Manual Update
	*
	* 	@param tournamentId
	*/
	public BracketsProccessUpdate( Id tournamentId ){
		this.processManualUpdate( tournamentId );
	}
	
	/**
	* 	Constructor Manual Import
	*
	* 	@param Source
	*/
	public BracketsProccessUpdate( String source ){
		this.tourament = new Brackets_Tournament__c();
		this.tourament.Update_Source__c = source;
		this.getTournamentUpdate();
		BracketsImportTournament itProcess = new BracketsImportTournament(source);
		itProcess.processImportedDocument( xmlTournamentReceived );
		
	}
	
	/**
	*	Process multiple update of tournaments
	*
	*	@param	tournamentsList		a list of tournament	
	*/
	public static void proccessMultipleUpdate(List<Brackets_Tournament__c> tournamentsList){
		for( Brackets_Tournament__c tournament : tournamentsList){
			processSingleUpdate((String)tournament.Update_Source__c);
		}
	}
	
	/**
	*	Process a single update
	*
	*	@param	source	the url to import the recent data from a tournament
	*/
	@future(callout=true)
	public static void processSingleUpdate(String source){
		try{
			new BracketsProccessUpdate( source );	
		}catch(Exception e){
		}
	}
	
	/**
	* 	Get the XML from the URL saved on Tournament Object
	*/
	private void getTournamentUpdate() {
		try{
			String uSource = this.tourament.Update_Source__c;
			HttpRequest req = new HttpRequest();
			req.setEndpoint( uSource );
			req.setMethod('GET');
			Http http = new Http();
			HTTPResponse res = http.send( req );
			xmlTournamentReceived = res.getBody();
			
		}
		catch( Calloutexception ex ) {
			throw new BracketsException(ex.getMessage(), ex);
		}
	}
	
	
	/**
	* 	Proccess the Manual Update
	*	
	* 	@param tournamentId
	*/
	private void processManualUpdate( Id tournamentId ){
		//Get the Tournament by Tournament Id
		this.tourament = [Select t.Update_Source__c, t.TeamCount__c, t.Start__c, t.Name, t.MaxRoundNumber__c, t.Id, t.ExternalId__c, t.End__c, t.Description__c 
							  From Brackets_Tournament__c t 
							  where t.Id =: tournamentId ];
		this.getTournamentUpdate();
		//this.synchronizeUserStatisticSend();
		BracketsImportTournament itProcess = new BracketsImportTournament( (String)tourament.Update_Source__c );
		itProcess.processImportedDocument( xmlTournamentReceived );
	}
	
	
	public static testMethod void test2(){
		Brackets_Tournament__c myTour = BracketsTestUtilities.createFullTournament( 2, BracketsTournamentUtilities.DEFAULT_TOURNAMENT_TYPE );
		myTour.isChild__c = true;
		myTour.Update_Source__c = 'http://www.salesforce.com';
		update myTour;
		List<Brackets_Tournament__c> myTourList = new List<Brackets_Tournament__c>{ myTour };
		
		Test.startTest();
			BracketsProccessUpdate cTest = new BracketsProccessUpdate( myTour.Id );
			
			System.assert( cTest.tourament != null );
		Test.stopTest();
	}
	
	public static testMethod void test3(){
		Brackets_Tournament__c myTour = BracketsTestUtilities.createFullTournament( 2, BracketsTournamentUtilities.DEFAULT_TOURNAMENT_TYPE );
		myTour.isChild__c = true;
		myTour.Update_Source__c = 'http://www.salesforce.com';
		update myTour;
		List<Brackets_Tournament__c> myTourList = new List<Brackets_Tournament__c>{ myTour };
		
		Test.startTest();
			BracketsProccessUpdate.processSingleUpdate(myTour.Update_Source__c);
			System.assert( myTour != null );
		Test.stopTest();
	}
	
	public static testMethod void test4(){
		Brackets_Tournament__c myTour = BracketsTestUtilities.createFullTournament( 2, BracketsTournamentUtilities.DEFAULT_TOURNAMENT_TYPE );
		myTour.isChild__c = true;
		myTour.Update_Source__c = 'http://www.salesforce.com';
		update myTour;
		List<Brackets_Tournament__c> myTourList = new List<Brackets_Tournament__c>{ myTour };
		
		Test.startTest();
			BracketsProccessUpdate.proccessMultipleUpdate( myTourList );
			System.assert( myTour != null );
		Test.stopTest();
	}
	
	
}