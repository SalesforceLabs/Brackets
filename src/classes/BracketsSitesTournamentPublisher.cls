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

public with sharing class BracketsSitesTournamentPublisher {
    
    private Brackets_Tournament__c tournament;
    
    public BracketsSitesTournamentPublisher (){
        this.tournament = this.getTournament();
    }
    
    
    /**
    * Retrive last update from the refered tournament
    * @return oXml : Returns the XML Body;
    */
    public String getOutputXml() {
        String result;
        if(this.tournament.Id == null){
        	System.debug('1234 is null');
            result = this.getXmlError();
        }else{
        	System.debug('1234tournament id is not null');
            result = this.getTournamentXml();
        }
        return result;  
    }
    
    
    /**
    * Get Brackets_Tournament__c object 
    * @return tournament
    */
    private Brackets_Tournament__c getTournament() {
        Brackets_Tournament__c ret = [ Select t.TeamCount__c, t.Start__c, t.Name, t.Id, t.ExternalId__c, t.End__c, t.Description__c, 
                        t.Version__c, t.Allow_Update__c, t.Update_Source__c, t.Type__c, Deadline__c
                 From Brackets_Tournament__c t 
                 where Id =: this.getTournamentId() ];
        
        System.debug('1234 allow update ' + ret.Allow_Update__c);
        
        return ret;
    }
    
    
    /**
    * Return an Error
    * @return oXml
    */
    private String getXmlError(){
        Xmlstreamwriter oXml = new Xmlstreamwriter();   
        oXml.writeStartElement( null, BracketsImportExportUtilities.ERROR_TAG, null );
        oXml.writeCharacters(BracketsImportExportUtilities.MISSING_TOURNAMENT);
        oXml.writeEndElement();
        oXml.writeEndDocument();
        return oXml.getXmlString();
    }
    
    /**
    *   Check if exist an parameter json in the headers
    */
    private Boolean hasUserStatistic(){
        return Apexpages.currentPage().getHeaders().get('json') != null; 
    }
    
    
    /**
    * Method in charge of compiling XML document
    * @return ret : Write a XML Body then return it
    */
    private String getTournamentXml(){ 
        Xmlstreamwriter out = new Xmlstreamwriter();
        out.writeStartDocument(null, '1.0');
        System.debug('1234 allow update ' + tournament.Allow_Update__c + ' and version ' + tournament.Version__c);
        if( tournament.Allow_Update__c && tournament.Version__c > this.getClientVersion() ) {
                    
    
            BracketsExportTeams expTeams = new BracketsExportTeams( tournament.Id, out );
            out.writeStartElement( null, 'export', null );
            out = expTeams.BracketsexportTeams(); 
            
            out.writeStartElement( null, 'Tournament', null );
            
            BracketsImportExportUtilities.writeElement( out, 'id', '' + tournament.Id );
            //RSC do we need this?
            //BracketsImportExportUtilities.writeElement( out, 'externalId', '' + tournament.ExternalId__c );
            BracketsImportExportUtilities.writeElement( out, 'name', '' + tournament.Name );
            BracketsImportExportUtilities.writeElement( out, 'description', '' + tournament.Description__c );
            BracketsImportExportUtilities.writeElement( out, 'teamCount', '' + String.valueOf( tournament.TeamCount__c ) );
            BracketsImportExportUtilities.writeElement( out, 'version', '' + tournament.Version__c );
            BracketsImportExportUtilities.writeElement( out, 'type', '' + tournament.Type__c );
            BracketsImportExportUtilities.writeElement( out, 'source', '' + tournament.Update_Source__c );
            BracketsImportExportUtilities.writeElement( out, 'deadline', '' + String.valueOf( tournament.Deadline__c ) );
            
            out.writeEndElement();
            
            List<Brackets_Round__c> rounds = [ Select r.Brackets_Tournament__c, r.Start__c, r.ScorePoints__c, r.RoundNumber__c, r.Name, r.Id, r.ExternalId__c, r.End__c, r.Deadline__c, 
                                        ( Select Name, Brackets_Round__c, Conference__c, Description__c, FollowingBrackets_Match__c, FollowingIsHome__c, HomeScore__c, HomeBrackets_Team__c, Schedule__c, VisitorScore__c, VisitorBrackets_Team__c, 
                                                WinnerBrackets_Team__c, ExternalId__c, Position__c
                                                From Matches__r Order By Position__c) 
                                        From Brackets_Round__c r where r.Brackets_Tournament__c =: tournament.Id Order By RoundNumber__c];
            
            //----------------------------------------------------
            List<String> roundIds = new List<String>();
            for( Brackets_Round__c round : rounds ){
                roundIds.add( round.Id );
            }
            Map<Id, Brackets_Match__c> matches = new Map<Id, Brackets_Match__c>( [ Select m.Id, m.Position__c,
            														m.VisitorBrackets_Team__c, m.VisitorBrackets_Team__r.ExternalId__c, 
            														m.HomeBrackets_Team__c, m.HomeBrackets_Team__r.ExternalId__c, 
                                                                    m.WinnerBrackets_Team__c, m.WinnerBrackets_Team__r.ExternalId__c, 
                                                                    m.FollowingBrackets_Match__c, m.FollowingBrackets_Match__r.ExternalId__c, m.Conference__c 
                                                                    From Brackets_Match__c m where m.Brackets_Round__c IN : roundIds Order By m.Brackets_Round__r.RoundNumber__c, m.Position__c] );
            //----------------------------------------------------
            
            out.writeStartElement( null, 'Rounds', null );
            for( Brackets_Round__c round : rounds ){
                
                out.writeStartElement( null, 'Round', null );
            
                BracketsImportExportUtilities.writeElement( out, 'id', '' + round.Id );
                //RSC Do we need this?
                //BracketsImportExportUtilities.writeElement( out, 'ExternalId', '' + round.ExternalId__c );
                BracketsImportExportUtilities.writeElement( out, 'name', '' + round.Name );
                BracketsImportExportUtilities.writeElement( out, 'deadline', '' + String.valueOf( round.Deadline__c ) );
                BracketsImportExportUtilities.writeElement( out, 'roundNumber', '' + String.valueOf( round.RoundNumber__c ) );
                BracketsImportExportUtilities.writeElement( out, 'scorePoints', '' + String.valueOf( round.ScorePoints__c ) );
                BracketsImportExportUtilities.writeElement( out, 'tournament', '' + round.Brackets_Tournament__c );
                
                out.writeStartElement( null, 'Matches', null );
                
                for( Brackets_Match__c match : round.Matches__r ){
                    
                    out.writeStartElement( null, 'Match', null );
                    
                    BracketsImportExportUtilities.writeElement( out, 'id', '' + match.Id );
                    BracketsImportExportUtilities.writeElement( out, 'number', '' + match.Name );
                    BracketsImportExportUtilities.writeElement( out, 'description', '' + match.Description__c );
                    BracketsImportExportUtilities.writeElement( out, 'position', '' + match.Position__c );
                    BracketsImportExportUtilities.writeElement( out, 'homeScore', '' + String.valueOf( match.HomeScore__c ) );
                

                    BracketsImportExportUtilities.writeElement( out, 'homeTeam', '' + matches.get( match.Id ).HomeBrackets_Team__c);
                    BracketsImportExportUtilities.writeElement( out, 'vistitorTeam', '' + matches.get( match.Id ).VisitorBrackets_Team__c );
                    BracketsImportExportUtilities.writeElement( out, 'winnerTeam', '' + matches.get( match.Id ).WinnerBrackets_Team__c );
                    BracketsImportExportUtilities.writeElement( out, 'followingMatch', '' + matches.get( match.Id ).FollowingBrackets_Match__c );
                    BracketsImportExportUtilities.writeElement( out, 'round', '' + String.valueOf( round.id ) );

                    
                    BracketsImportExportUtilities.writeElement( out, 'schedule', '' + String.valueOf( match.Schedule__c ) );
                    BracketsImportExportUtilities.writeElement( out, 'visitorScore', '' + String.valueOf( match.VisitorScore__c ) );
                    BracketsImportExportUtilities.writeElement( out, 'conference', '' + match.Conference__c );
                    BracketsImportExportUtilities.writeElement( out, 'followingIsHome', '' + String.valueOf(match.FollowingIsHome__c ) );
                    
                    out.writeEndElement();
                }
                
                out.writeEndElement();//End Matches
                out.writeEndElement();//End Round
            }
            
            out.writeEndElement();//End Rounds
            out.writeEndElement();//End Export
        }
        else {
            out.writeStartElement( null,BracketsImportExportUtilities.ERROR_TAG, null );
            out.writeCharacters(BracketsImportExportUtilities.NOT_UPDATES_FOUND);
            out.writeEndElement();
            out.writeEndDocument();
        }
        return out.getXmlString();
    }
    
    /**
    * Return the related tournament ID
    * @return tournamentId
    */
    public String getTournamentId(){
        String tournamentId = Apexpages.currentPage().getParameters().get('id');
        return tournamentId;
    }
    
    /**
    * Return the Client Tournament  Version 
    * @return version
    */
    public Integer getClientVersion(){
        String ver = Apexpages.currentPage().getParameters().get('tVersion');
        return ( ver != null ) ? Integer.valueOf( ver ) : 0;
    }

    
    //-------------------------------------------------------------------------
    // Test methods
    //-------------------------------------------------------------------------
    
    public testmethod static void testGetOutputXml(){
    	
    	BracketsTournamentUtilities.CreatingTournamentTree = true;
    	
        Brackets_Tournament__c tournament   = new Brackets_Tournament__c();
        tournament.Name            = 'Test';
        tournament.TeamCount__c    = 4;
        tournament.Type__c         = 'Standard';
		tournament.Deadline__c 		= Datetime.now();
        tournament.Allow_Update__c = true;
        tournament.Version__c      = 2;

        insert tournament;
        
        Apexpages.currentPage().getParameters().put( 'id', tournament.Id ); 
        Apexpages.currentPage().getParameters().put( 'tVersion', '1' ); 
        BracketsSitesTournamentPublisher ut = new BracketsSitesTournamentPublisher ();
        system.assert(ut.getOutputXml() != '');
        
        system.debug(LoggingLevel.Info,ut.getOutputXml());
        
        BracketsImportTournament importTour = new BracketsImportTournament(null);

        
        importTour.readingTournamentData(ut.getOutputXml());
        Brackets_Tournament__c t = importTour.tournament;
        system.debug(LoggingLevel.Info,t);
        System.assert(t.deadline__c != null);
        
        
    }
    
    
}