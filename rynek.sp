#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <codmod301>
/*
 TO DO:
 Dodać komendę '/rynek'. Po wpisaniu tej komendy gracze będą mogli wystawić/kupić perk od innego gracza za nieśmiertelniki
 wystawiając perk wystawiasz go za własną cenę w nśm, po wpisaniu komenty niech wyskakują 3 opcje do wyboru
 1. wystaw | 2. kup | 3. anuluj oferte
 -----------
 TO DO dla th7:
 Zaimplementować: CodMod_GetDogtagCount | CodMod_SetDogtagCount <--- nieśmiertelniki
 Dodać include dla: CodMod_GetPerk | CodMod_SetPerk | CodMod_GetPerkArmor | CodMod_SetPerkDurability
 -----------
 MINI PRZEMYŚLENIA:
 /rynek otwiera menu z wystawionymi perkami
 /sprzedaj <ilość> wystawia obecnie posiadany perk za <ilość> nieśmiertelników
 gracz może wystawić max 2 perki na raz
 wystawione perki wypierdala w przestrzeń kosmiczną przy zmianie mapy
 max ilość perków na rynku jednocześnie to 30
 gracz może anulować ofertę poprzez wykupienie perku od siebie samego
 -----------
 OBECNE PROBLEMY:
 oczywista oczywistość - nie mam tego jak skompilować, a więc przetestować u siebie, więc pewnie bug na bugu (th7 gimme some jakieś tools narzędzia żebym mógł live na żywo testować pls ładnie proszę)
*/

enum perkData
{
	perkData_Durability = 0,
	perkData_Price,
	perkData_Seller,
	perkData_SellerSerial,
	String:perkData_Name[64]
}

new g_ePerk[64][perkData];
int clientSoldCount[MAXPLAYERS+1] = {0};

public OnMapStart() {
	for(int i = 0; i < sizeof(clientSoldCount); i++) {
		clientSoldCount[i] = 0;
	}

	for(int i = 0; i < sizeof(g_ePerk); i++) {
		g_ePerk[i][perkData_Name] = 0;
		g_ePerk[i][perkData_SellerSerial] = 0;
	}
}

public int MenuHandler_Rynek(Menu hMenu, MenuAction:iAction, iClient, itemPos)
{
	if(iAction == MenuAction_Select)
	{
		char selectedPos[12];
		hMenu.GetItem(itemPos, selectedPos, sizeof(selectedPos));

		char currentPos[12];
		for (int i=0; i < 32; i++)
		{
			Format (currentPos, 12, "%d", i);
			if (StrEqual(currentPos,selectedPos))
			{
				int sellerID = g_ePerk[i][perkData_Seller];
				int sellerSerial = g_ePerk[i][perkData_SellerSerial];

				if (sellerSerial == GetClientSerial(iClient))
				{
					CodMod_SetPerk(iClient, CodMod_GetPerkId(g_ePerk[i][perkData_Name]), g_ePerk[i][perkData_Durability]);


					clientSoldCount[sellerID]--; // zmniejszenie liczby wystawionych przedmiotów na raz dla danego gracza
					g_ePerk[i][perkData_Name] = 0; // usunięcie perku z rynku
					g_ePerk[i][perkData_SellerSerial] = 0; // żeby dwie osoby mające jednocześnie włączony rynek nie mogły kupić tego samego perku

					PrintToChat(iClient, "Anulowałeś sprzedanie perku!");
					break;
				}
				else if (GetClientFromSerial(sellerSerial) != 0 && IsClientInGame(GetClientFromSerial(sellerSerial))) // clientID sprzedającego się zgadza?
				{
					int buyerDogtagCount = CodMod_GetDogtagCount(iClient);

					if (buyerDogtagCount >= g_ePerk[i][perkData_Price])
					{
						int buyerNewDogtagCount = buyerDogtagCount - g_ePerk[i][perkData_Price];
						int sellerNewDogtagCount = CodMod_GetDogtagCount(sellerID) + g_ePerk[i][perkData_Price];

						CodMod_SetDogtagCount(iClient, buyerNewDogtagCount);// wymiana NŚM
						CodMod_SetDogtagCount(sellerID, sellerNewDogtagCount); // wymiana NŚM
						CodMod_SetPerk(iClient, CodMod_GetPerkId(g_ePerk[i][perkData_Name]), g_ePerk[i][perkData_Durability]); // ustawienie perku dla kupującego

						clientSoldCount[sellerID]--;
						g_ePerk[i][perkData_Name] = 0;
						g_ePerk[i][perkData_SellerSerial] = 0;

						PrintToChat(iClient, "Pomyślnie kupiłeś %s za %d NŚM!",g_ePerk[i][perkData_Name],g_ePerk[i][perkData_Price]);
						PrintToChat(sellerID, "Pomyślnie sprzedałeś %s za %d NŚM!",g_ePerk[i][perkData_Name],g_ePerk[i][perkData_Price]);
					}
				}
				else if (!IsClientInGame(sellerID) || (sellerSerial != GetClientSerial(sellerID)))
				{
					clientSoldCount[sellerID]--;
					g_ePerk[i][perkData_Name] = 0;
					g_ePerk[i][perkData_SellerSerial] = 0;
					PrintToChat (iClient, "Ten perk nie jest już dostępny do kupienia.");
				}
				break;
			}
			else if (StrEqual("X",selectedPos))
			{
				PrintToChat(iClient, "Ten perk nie jest już dostępny do kupienia.");
				break;
			}
		}
	}
    else if (iAction == MenuAction_End)
    {
        delete hMenu;
    }
}

public Action Command_Sprzedaj (int iClient, int args)
{
	if ((IsClientInGame(iClient)) && (!IsFakeClient(iClient)))
	{
		if (CodMod_GetPerk(iClient) == 0)
		{
			PrintToChat(iClient, "Nie masz perku, który mógłbyś wystawić na rynek!");
		}
		else if (args < 1)
		{
			PrintToChat (iClient, "Nie podałeś prawidłowej ceny!");
		}
		else if (clientSoldCount[iClient] > 1)
		{
			PrintToChat (iClient, "Wystawiłeś już 2 perki na raz!");
		}
		else if (g_ePerk[30][perkData_Name] != 0)
		{
			PrintToChat(iClient, "Na rynku jest już za dużo perków!");
		}
		else if (!IsPlayerAlive(iClient))
		{
			PrintToChat (iClient, "Nie możesz wystawić perku gdy jesteś martwy!");
		}
		else
		{
			for (int i = 0; i < sizeof(g_ePerk); i++)
			{
				if (g_ePerk[i][perkData_Name] == 0)
				{
					char arg[8];
					GetCmdArg(1, arg, sizeof(arg));
					int iPrice = StringToInt(arg);
					if(iPrice > 100000)
					{
						return Plugin_Handled;
					}
					CodMod_GetPerkName(CodMod_GetPerk(iClient), g_ePerk[i][perkData_Name]);
					g_ePerk[i][perkData_Durability] = CodMod_GetPerkArmor(iClient);
					g_ePerk[i][perkData_Price] = iPrice;
					g_ePerk[i][perkData_Seller] = iClient;
					g_ePerk[i][perkData_SellerSerial] = GetClientSerial(iClient);

					CodMod_SetPerk(iClient, 0, 0); //ustawienie "brak perku" dla sprzedającego, po wystawieniu na rynek
					clientSoldCount[iClient]++; // zwiększenie liczby sprzedanych perków dla sprzedającego (max 2)
					PrintToChat(iClient, "Perk został wystawiony na rynek za %d NŚM",iPrice);
					break;
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Rynek (int iClient, int iArgs)
{
	char szName[128];
	if ((IsClientInGame(iClient)) && (!IsFakeClient(iClient)))
	{
		Menu hMenu = new Menu(MenuHandler_Rynek);
		hMenu.SetTitle("Rynek perków - Serwery-GO.pl (%d NŚM)",CodMod_GetDogtagCount(iClient));
		char szItem[128];
		char szOption[12];

		for(int i = 0; i < sizeof(g_ePerk); i++)
		{
			if (g_ePerk[i][perkData_Price] == 0) // gdy pętla przejdzie już po wszystkich wystawionych perkach
			{
				break;
			}
			else if (g_ePerk[i][perkData_Name] == 0) // gdy pętla natknie się na perk sprzedany wcześniej
			{
				continue;
				//hMenu.AddItem("X", "Perk niedostępny");
			}
			else
			{
				Format(szItem, 128, "%s Cena:%d Wytrz.:%d", g_ePerk[i][perkData_Name], g_ePerk[i][perkData_Price], g_ePerk[i][perkData_Durability]);
				Format(szOption, 12, "%d",i);
				hMenu.AddItem(szOption, szItem);
			}
		}

		hMenu.ExitButton = true;
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public void OnPluginStart()
{
	RegConsoleCmd("rynek", Command_Rynek);
	RegConsoleCmd("sprzedaj", Command_Sprzedaj);
}
