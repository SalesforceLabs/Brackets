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
public with sharing class BracketsExportTeams{
	
	private String tournamentId { get; set; }
	public Xmlstreamwriter out { get; set; }
	
	/** 
	* Constructor
	* @param tourId
	* @param writer
	*/
	public BracketsExportTeams( String tourId, Xmlstreamwriter writer ){
		
		this.tournamentId 	= tourId;
		this.out 			= writer;
	}
	
	/**
	* Method in charge of handling the export task related 
	* @return Xmlstreamwriter
	*/
	public Xmlstreamwriter BracketsexportTeams(){
		
		List<Brackets_Match__c> matches = [ Select m.VisitorBrackets_Team__c, m.Brackets_Round__r.Brackets_Tournament__c, m.Brackets_Round__c, m.Name, m.Id, m.HomeBrackets_Team__c 
										From Brackets_Match__c m where m.Brackets_Round__r.Brackets_Tournament__c =: this.tournamentId ];
		
		Set<ID> teamIds = new Set<ID>();
		for( Brackets_Match__c match : matches ){
			teamIds.add( match.HomeBrackets_Team__c );
			teamIds.add( match.VisitorBrackets_Team__c );
		}

		List<Brackets_Team__c> teams = [ Select Id , Name, ShortName__c, Description__c, Rank__c from Brackets_Team__c where Id IN : teamIds ];
		
		this.buildXmlString( teams );
		
		return this.out; 
	}
	
	/**
	* Method in charge of compiling XML document with Team Information
	* @param teamList
	*/
	public void buildXmlString( List<Brackets_Team__c> teamList ){
		
		this.out.writeStartElement( null, 'Teams', null );
		
		for( Brackets_Team__c team : teamList ){
			
			this.out.writeStartElement( null, 'Team', null );
		
			BracketsImportExportUtilities.writeElement( this.out, 'id', '' + team.Id );
			BracketsImportExportUtilities.writeElement( this.out, 'name', '' + team.Name );
			BracketsImportExportUtilities.writeElement( this.out, 'description', '' + team.Description__c );
			BracketsImportExportUtilities.writeElement( this.out, 'rank', '' + team.Rank__c );
			BracketsImportExportUtilities.writeElement( this.out, 'shortname', '' + team.ShortName__c );
			
			this.out.writeEndElement();
		}
		
		this.out.writeEndElement();
	}
	
	private static testMethod void testExportTeams(){
		Brackets_Tournament__c tournament = BracketsTestUtilities.createFullTournament(4,BracketsTournamentUtilities.STANDARD_TOURNAMENT_TYPE);
		BracketsExportTeams bracketsExportTeams = new BracketsExportTeams(tournament.Id,new Xmlstreamwriter());
		Xmlstreamwriter writer = bracketsExportTeams.BracketsexportTeams();
		System.assert(writer.getXmlString() != null);
	}
	
	private static testmethod void testExportTeamsWithImport() {
		
		
		Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team' + Datetime.now());
		Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team' + Datetime.now());
		Brackets_Team__c           teamC          = BracketsTestUtilities.createTeam('C-Team' + Datetime.now());
		Brackets_Team__c           teamD          = BracketsTestUtilities.createTeam('D-Team' + Datetime.now());
		
		List<Brackets_Team__c> teams = new List<Brackets_Team__c>();
		teams.add( teamA );
		teams.add( teamB );
		teams.add( teamC );
		teams.add( teamD );
		
		insert teams;
		
		List<Brackets_Team__c> allTeams = [Select Id, Name, ExternalID__c From Brackets_Team__c];
		
		delete teams;
		
		BracketsExportTeams exportTeams = new BracketsExportTeams(null, new Xmlstreamwriter());
		
		exportTeams.buildXmlString(teams);
		
		String s = exportTeams.out.getXmlString();
		
		System.debug(LoggingLevel.Info, '1234' + s); 
		
		
		BracketsImportTeams importTeams = new BracketsImportTeams();
		
		importTeams.processImportedDocument(s);
		
		List<Brackets_Team__c> allTeams2 = [Select Id, Name, ExternalID__c From Brackets_Team__c];
		
		System.assert(allTeams.size() == allTeams2.size());
		
		importTeams.processImportedDocument(s);
		
		List<Brackets_Team__c> allTeams3 = [Select Id, Name, ExternalID__c From Brackets_Team__c];
		
		System.assert(allTeams.size() == allTeams3.size());		
		
		
	}
}