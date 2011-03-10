trigger BracketsTeam on Brackets_Team__c( before insert, before update, before delete ){
	
	if( trigger.isBefore && trigger.isDelete ){
		if( !BracketsTeamUtilities.canDeleteTeams( trigger.old ) ){
			trigger.old.get(0).addError( 'Teams cannot be deleted, already in use within a Tournament!' );
		}
	}
}