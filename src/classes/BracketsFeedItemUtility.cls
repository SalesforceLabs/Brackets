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
public Class BracketsFeedItemUtility {

    public Boolean isStandardUser() {
    
        return UserInfo.getUserType() == 'Standard';
        
    }
    
    public String getLastTournamentGroupChatter(Id groupId, Integer maxLength) {
    
        if (!isStandardUser()) {
            return '';
        }
        
        String ret = '';
        
        List<Brackets_Group__Feed> items = [Select Id, Body From Brackets_Group__Feed Where 
            ParentId =: groupId 
            and Type = 'TextPost'
            Order By CreatedDate Desc Limit 1];
        
        if (items.size() ==1 ) {
        Brackets_Group__Feed item = items.get(0);
        ret = item.Body;
        if (ret.length() > maxLength) {
        ret = ret.substring(0,maxLength-3);
        if (item.Body.length() > ret.length()) {
            ret += '...';
        }
        }
        }
        
        return ret;    
    
    }
    
    static TestMethod void testLastChatter() {
    
         BracketsTournamentUtilities.CreatingTournamentTree = true;
                //Create a user
        User testUser = BracketsTestUtilities.createUser();
        
        System.runAs(testUser) {    
 

            Brackets_Tournament__c     tournament     = BracketsTestUtilities.createTournament('Test1 RoundByRound', 4);
            
            List<Id> ts = new List<Id>();
            ts.add(tournament.Id);
            
            Brackets_Group__c          groupA         = BracketsTestUtilities.getGroup(tournament.Id, BracketsGroupUtilities.BET_TYPE_BY_ROUND);

           BracketsFeedItemUtility util = new BracketsFeedItemUtility();
           
           String s = util.getLastTournamentGroupChatter(groupA.id,40);

            System.assertEquals(s,'');

            FeedItem item = new FeedItem();
            item.parentId = groupA.id;
            item.body = 'This is a test';
            insert item;
            
           
           s = util.getLastTournamentGroupChatter(groupA.id,40);
           
           System.assert(s != null);
           System.assertEquals(s,'This is a test');

            FeedItem item2 = new FeedItem();
            item2.parentId = groupA.id;
            item2.body = 'This is a test56789 123456789 123456789 123456789';
            insert item2;
           
           s = util.getLastTournamentGroupChatter(groupA.id,40);
           
           System.assert(s != null);
           System.assertEquals(s,'This is a test56789 123456789 1234567...');
        }
    
    }
    
    
    

}