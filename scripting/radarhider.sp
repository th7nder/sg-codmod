

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("ProcessSpottedEntityUpdate"), Hook_ProcessSpottedEntityUpdate, true);
}

public Action Hook_ProcessSpottedEntityUpdate(UserMsg msg_id, Handle bf, const players[], playersNum, bool reliable, bool init)
{
	int iFieldCount = PbGetRepeatedFieldCount(bf, "entity_updates");
	Handle hMessage = null;
	for(int i = 0; i < iFieldCount; i++)
	{
		hMessage = PbReadRepeatedMessage(bf, "entity_updates", i);
		int iEntity = PbReadInt(hMessage, "entity_idx");
		PrintToServer("entity_updates: %d entity: %d", i, iEntity);
		//PbRemoveRepeatedFieldValue(bf, "entity_updates", i);
	}
	return Plugin_Handled;
}