trigger BracketsMatch on Brackets_Match__c (after insert, after update, after delete, before update, before insert) {


	if( !BracketsMatchUtilities.SKIP_TRIGGER && !BracketsTournamentUtilities.CreatingTournamentTree ) {
		
		if( trigger.isAfter || ( trigger.isUpdate && trigger.isBefore ) ){ BracketsTriggerUtilities.triggerListObject = trigger.newMap;  }
		BracketsTriggerUtilities.newTriggerInstance( trigger.new );
		
		if( Trigger.isAfter ) {
			
			if( trigger.isInsert ) {
				
			}
			
			if( trigger.isUpdate ) {
				BracketsMatchUtilities.checkLocked( Trigger.old , Trigger.new );
				// Update UserMatchPrediction points
				BracketsMatchesPredictionUtil.updateUserMatchPredictionPoints(Trigger.new);
				//Update the following matches
				BracketsMatchUtilities.updateFollowingMatches( Trigger.new );
			}
			
			if( trigger.isDelete ) {
				BracketsMatchUtilities.checkLocked( Trigger.old , Trigger.new );
			}
		}
		
		if( trigger.isBefore ) {
			
			if( trigger.isInsert ) {
				BracketsMatchUtilities.checkExistMatchesInRound( Trigger.new );
				BracketsMatchUtilities.dateMatchesValidation( Trigger.new );
			}
			
			if( trigger.isUpdate ) {
				BracketsMatchUtilities.checkLocked( Trigger.old , Trigger.new );
				BracketsMatchUtilities.checkSetTeam( Trigger.new , Trigger.old );
				BracketsMatchUtilities.setWinnerTeam( Trigger.new , Trigger.old );
				BracketsMatchUtilities.checkRemovedTeam( Trigger.new , Trigger.old );
				BracketsMatchUtilities.publishOff(Trigger.new);
				BracketsMatchUtilities.checkExistMatchesInRound( Trigger.new );
				BracketsMatchUtilities.dateMatchesValidation( Trigger.new );
			}
			
			if( trigger.isDelete ) {
				BracketsMatchUtilities.checkLocked( Trigger.old , Trigger.new );
			}
			
		}
	}
}