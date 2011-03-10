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
@isTest 
class BracketsExportImportTest {

    static testmethod void testSimpleExportImport() {

        BracketsTournamentUtilities.CreatingTournamentTree = false;
        
        //Create a user
        User testUser = BracketsTestUtilities.createUser();
        
        System.runAs(testUser) {

            List<Brackets_Team__c> baselineTeams = [Select Id, Name, ExternalId__c From Brackets_Team__c];
            List<Brackets_Tournament__c> baselineTour = [Select Id, Name, ExternalId__c From Brackets_Tournament__c];
            List<Brackets_Round__c> baselineRound = [Select Id, Name, ExternalId__c From Brackets_Round__c];
            List<Brackets_Match__c> baselineMatch = [Select Id, Name, ExternalId__c From Brackets_Match__c];

            Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Small Season 2010 ' + Datetime.now(), 12, BracketsTournamentUtilities.NFL_PLAYOFF_TOURNAMENT_TYPE);


            

            Brackets_Group__c          groupp         = BracketsTestUtilities.getGroup(tournament.Id);
            
            Brackets_Team__c           teamA          = BracketsTestUtilities.createTeam('A-Team' + Datetime.now());
            Brackets_Team__c           teamB          = BracketsTestUtilities.createTeam('B-Team' + Datetime.now());
            Brackets_Team__c           teamC          = BracketsTestUtilities.createTeam('C-Team' + Datetime.now());
            Brackets_Team__c           teamD          = BracketsTestUtilities.createTeam('D-Team' + Datetime.now());
            Brackets_Team__c           teamE          = BracketsTestUtilities.createTeam('E-Team' + Datetime.now());
            Brackets_Team__c           teamF          = BracketsTestUtilities.createTeam('F-Team' + Datetime.now());
            Brackets_Team__c           teamG          = BracketsTestUtilities.createTeam('G-Team' + Datetime.now());
            Brackets_Team__c           teamH          = BracketsTestUtilities.createTeam('H-Team' + Datetime.now());
            Brackets_Team__c           teamI          = BracketsTestUtilities.createTeam('I-Team' + Datetime.now());
            Brackets_Team__c           teamJ          = BracketsTestUtilities.createTeam('J-Team' + Datetime.now());
            Brackets_Team__c           teamK          = BracketsTestUtilities.createTeam('K-Team' + Datetime.now());
            Brackets_Team__c           teamL          = BracketsTestUtilities.createTeam('L-Team' + Datetime.now());
            
            List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
            auxList.add( teamA );
            auxList.add( teamB );
            auxList.add( teamC );
            auxList.add( teamD );
            auxList.add( teamE );
            auxList.add( teamF );
            auxList.add( teamG );
            auxList.add( teamH );
            auxList.add( teamI );
            auxList.add( teamJ );
            auxList.add( teamK );
            auxList.add( teamL );
            upsert auxList; 

            //let's make sure we have four rounds
            List<Brackets_Round__c> rounds = [Select Id, Name, Deadline__c From Brackets_Round__c Where Brackets_Tournament__c =: tournament.id Order By RoundNumber__c];

            //make sure that round 0 has 4 matches
            Brackets_Round__c r = rounds.get(0);
            List<Brackets_Match__c> matches = [Select Id, Name, Conference__c, Position__c, FollowingBrackets_Match__c, Schedule__c  From Brackets_Match__c where Brackets_Round__c =: r.id Order By Position__c];

            Brackets_Match__c m1 = matches.get(0);
            m1.HomeBrackets_Team__c = teamA.id;
            m1.VisitorBrackets_Team__c = teamB.id;
            Datetime originalSchedule = Datetime.now().addMinutes(10);
            m1.Schedule__c = originalSchedule;
            
            Brackets_Match__c m2 = matches.get(1);
            m2.HomeBrackets_Team__c = teamC.id;
            m2.VisitorBrackets_Team__c = teamD.id;           

            Brackets_Match__c m3 = matches.get(2);
            m3.HomeBrackets_Team__c = teamE.id;
            m3.VisitorBrackets_Team__c = teamF.id;   

            Brackets_Match__c m4 = matches.get(3);
            m4.HomeBrackets_Team__c = teamG.id;
            m4.VisitorBrackets_Team__c = teamH.id;
            
            update matches;

            Brackets_Round__c r2 = rounds.get(1);
            List<Brackets_Match__c> matches2 = [Select Id, Name, Conference__c, Position__c, FollowingBrackets_Match__c, Schedule__c From Brackets_Match__c where Brackets_Round__c =: r2.id Order By Position__c];         

            Brackets_Match__c m5 = matches2.get(0);
            //m5.HomeBrackets_Team__c = teamA.id;
            m5.VisitorBrackets_Team__c = teamI.id;   
            System.assert(m1.FollowingBrackets_Match__c == m5.Id);       

            Brackets_Match__c m6 = matches2.get(1);
            m6.HomeBrackets_Team__c = teamJ.id;
            //m5.VisitorBrackets_Team__c = teamI.id; 
                
            Brackets_Match__c m7 = matches2.get(2);
            //m7.HomeBrackets_Team__c = teamK.id;
            m7.VisitorBrackets_Team__c = teamK.id;   

            Brackets_Match__c m8 = matches2.get(3);
            m8.HomeBrackets_Team__c = teamL.id;
            //m8.VisitorBrackets_Team__c = teamL.id; 
            
            update matches2;        
        
            //validation
            tournament.deadline__c = Datetime.now().addMinutes(1);
            tournament.Allow_Update__c = true;
            tournament.Version__c = 2.0;
            update tournament;
            
            System.assert([Select Id, Deadline__c From Brackets_Tournament__c Where Id =: tournament.Id].Deadline__c != null);
            
            //now we should be able to export, delete and reimport
            Apexpages.currentPage().getParameters().put( 'id', tournament.Id ); 
            Apexpages.currentPage().getParameters().put( 'tVersion', '1' ); 
            BracketsSitesTournamentPublisher ut = new BracketsSitesTournamentPublisher ();
            
            String updateVersion1 = ut.getOutputXml();
            system.assert(updateVersion1 != null);
            
            //now we'll make some modifications and get an update version 2.
            String teamAName = teamA.Name;
            String teamANewName = 'teamA update update ' + Datetime.now();
            teamA.Name = teamANewName;
            update teamA;
            
            //update match1 so it has a winner.
            m1.WinnerBrackets_Team__c = teamA.id;
            m1.HomeScore__c = 10;
            Datetime updatedSchedule = Datetime.now().addMinutes(5);
            m1.Schedule__c = updatedSchedule;
            update m1;
            
            //update the version of the tournament
            tournament.Version__c = 3.0;
            update tournament;
            
            //get a new version of the code
            Apexpages.currentPage().getParameters().put( 'id', tournament.Id ); 
            Apexpages.currentPage().getParameters().put( 'tVersion', '2' ); 
            BracketsSitesTournamentPublisher ut2 = new BracketsSitesTournamentPublisher ();
            
            String updateVersion2 = ut2.getOutputXml();
            system.assert(updateVersion2 != null);          
            System.debug('1234');
            
            //now clean update a bunch of stuff
            delete tournament;
            List<Brackets_Round__c> postDelete = [Select Id, Name From Brackets_Round__c Where Brackets_Tournament__c =: tournament.id];
            System.assert(postDelete.size() == 0);
            List<Brackets_Team__c> originalteams = [Select Id, Name From Brackets_Team__c Where Id in: auxList];
            System.assert(originalTeams.size() == 12);
            delete originalTeams;
            List<Brackets_Team__c> originalteams2 = [Select Id, Name From Brackets_Team__c Where Id in: auxList];
            System.assert(originalTeams2.size() == 0);
            BracketsImportTournament importTournament = new BracketsImportTournament('manual');
            
            //get all tournaments
            List<Brackets_Tournament__c> allTournamentsPostUpdate = [Select Id, Name From Brackets_Tournament__c];
            List<Brackets_Team__c> allTeams = [Select Id, Name, ExternalId__c From Brackets_Team__c];
            System.assert(allTeams.size() == baselineTeams.size());

            importTournament.processImportedDocument(updateVersion1);
            
            //validate that the correct number of teams are here
            System.assert([Select Id From Brackets_Tournament__c].size() == baselineTour.size() + 1);
            System.assert([Select Id From Brackets_Team__c].size() == baselineTeams.size() + auxList.size());
            System.assert([Select Id From Brackets_Round__c].size() == baselineRound.size() + 4);
            System.assert([Select Id From Brackets_Match__c].size() == baselineMatch.size() + 11);
            
            Brackets_Tournament__c newTournament = importTournament.tournament; 
            
            System.debug(logginglevel.info, '12345: ' + newTournament);
            
            System.assert(newTournament.id != tournament.id);
            System.assert(newTournament.name == tournament.name);
            System.assert(newTournament.deadline__c != null);
            
            List<Brackets_Round__c> newRounds = [Select Id, Name From Brackets_Round__c where Brackets_Tournament__c =: newTournament.id];
            System.assert(newRounds.size() == 4);
            
            Brackets_Round__c newRound1 = newRounds.get(0);
            List<Brackets_Match__c> newMatches = [Select Id, Name, Conference__c, Position__c, Schedule__c, FollowingBrackets_Match__c, HomeBrackets_Team__c, VisitorBrackets_Team__c From Brackets_Match__c where Brackets_Round__c =: newRound1.id Order By Position__c];
            Brackets_Match__c newm1 = newMatches.get(0);
            System.assert(newm1.Schedule__c != null);
            System.assert(originalSchedule != null);
            System.assert(newm1.Schedule__c.minuteGmt() == originalSchedule.minuteGmt(), 'Original: ' + originalSchedule + ' Match: ' + newm1.Schedule__c);
            Brackets_Team__c newTeamA = [Select Id, Name, ExternalId__c From Brackets_Team__c Where Id =: newm1.HomeBrackets_Team__c];
            System.assert(newTeamA.Name == teamAName);
            System.assert(newTeamA.Id != teamA.Id);  
            System.assert(newTeamA.ExternalId__c == teamA.Id);     
            
            //now let's do another update
            BracketsImportTournament importTournament2 = new BracketsImportTournament('manual');
            importTournament2.processImportedDocument(updateVersion2);          
            //validate that the correct number of teams are here
            System.assert([Select Id From Brackets_Tournament__c].size() == baselineTour.size() + 1);
            System.assert([Select Id From Brackets_Team__c].size() == baselineTeams.size() + auxList.size());
            System.assert([Select Id From Brackets_Round__c].size() == baselineRound.size() + 4);
            System.assert([Select Id From Brackets_Match__c].size() == baselineMatch.size() + 11);           
            
            
            //now on to the detail validation
            Brackets_Tournament__c newTournament2 = importTournament2.tournament; 
            System.assert(newTournament2.id != tournament.id);
            System.assert(newTournament2.name == tournament.name);
            
            List<Brackets_Round__c> newRoundsA = [Select Id, Name From Brackets_Round__c where Brackets_Tournament__c =: newTournament2.id];
            System.assert(newRoundsA.size() == 4);
            
            Brackets_Round__c newRound1A = newRoundsA.get(0);
            List<Brackets_Match__c> newMatchesA = [Select Id, Name, Conference__c, Schedule__c, Position__c, FollowingBrackets_Match__c, HomeBrackets_Team__c, VisitorBrackets_Team__c, WinnerBrackets_Team__c, HomeScore__c From Brackets_Match__c where Brackets_Round__c =: newRound1A.id Order By Position__c];
            Brackets_Match__c newm1A = newMatchesA.get(0);
            System.assert(newm1A.Schedule__c.minuteGmt() != originalSchedule.minuteGmt());
            System.assert(newm1A.Schedule__c.minuteGmt() == updatedSchedule.minuteGmt());
            Brackets_Team__c newTeamAA = [Select Id, Name, ExternalId__c From Brackets_Team__c Where Id =: newm1A.HomeBrackets_Team__c];
            System.assert(newTeamAA.Name == teamANewName);
            System.assert(newTeamAA.Id != teamA.Id);  
            System.assert(newTeamAA.ExternalId__c == teamA.Id);  
            
            System.assert(newm1A.WinnerBrackets_Team__c != null);
            System.assert(newm1A.WinnerBrackets_Team__c == newTeamAA.Id);
            System.assert(newm1A.HomeScore__c == m1.HomeScore__c);         
        }
        
    }
}