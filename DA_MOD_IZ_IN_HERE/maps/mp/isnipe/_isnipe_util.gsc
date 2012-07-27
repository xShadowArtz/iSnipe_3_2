#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
isnipe v3.1 by banz (rewritten v3)
credits to iNuke
modded by RayZ' Trax
*/

init()
{
/*--------Put dvars here for private match!------*/

	//custom isnipe Dvars 
	setDvarIfUninitialized( "allow_tknife", 1 );
	setDvarIfUninitialized( "tknife_round", 0 );
	setDvarIfUninitialized( "anti_camp", 0 );
	setDvarIfUninitialized( "anti_hs", 0 );
	setDvarIfUninitialized( "anti_crns", 0 );
    	setDvarIfUninitialized( "slowmo_cam", 1 );
	setDvarIfUninitialized( "show_alive", 1 );
	setDvarIfUninitialized( "show_top", 0 );
	setDvarIfUninitialized( "show_streak", 1 );
	setDvarIfUninitialized( "show_rank", 0 );
	setDvarIfUninitialized( "costum_streaks", 0 );
	setDvarIfUninitialized( "isnipe_serverIP", "xservers.sytes.net" );
	
	//DEVELOPER SETTINGS
	level.SpawnBots = false; //Will spawn bots
	
	//Throwing knife round (1st)
	level.allowthrowingknife = GetDvarInt( "allow_tknife" );
	level.knifeFirstRound = GetDvarInt( "tknife_round" );
	
	//'ANTI' STUFF
	level.antiCamp = GetDvarInt( "anti_camp" );
	level.MaxCampTime = 20;

	level.antiHardScope = GetDvarInt( "anti_hs" );
	level.MaxScopeTime = 5;
	
	level.antiCRNS = GetDvarInt( "anti_crns" );

	
	//HUD-Stuff & Killcam
	level.showAliveCounter = GetDvarInt( "show_alive" );
	level.ShowTopPlayer = GetDvarInt( "show_top" );
	level.showKillstreak = GetDvarInt( "show_streak" );
	level.showrankIcon = GetDvarInt( "show_rank" );
	level.slowmoKillcam = GetDvarInt( "slowmo_cam" );
	level.customStreaks = GetDvarInt( "costum_streaks" );
	
	//server IP
	level.serverIP = GetDvarInt( "isnipe_serverIP" );  
	
	//Teamnames
	level.teamnameAllies = "Attack";
	level.teamnameAxis = "Defence";
	
	//com_maxfps
	level.forceMaxFPS = false;
	level.MaxFPS = 0; //0 = unlocked/infinite -- otherwise a number above 60 is recommended
	

	//gametype specific settings (DONT TOUCH!)
	if( level.gametype != "sd" && level.gametype != "sab" ) //alive counter only in round-based gamemodes
		level.showAliveCounter = false;
    else
		level.showAliveCounter = GetDvarInt( "show_alive" );

	if( level.gametype != "sd" ) 
	{
		level.knifeFirstRound = false;
	}
	
	if(!level.allowthrowingknife)
		level.knifeFirstRound = false;
	
	//server Dvars
	
    setDvar( "cl_maxpackets", 100);	
	setDvar( "player_breath_fire_delay ", "0" );
	setDvar( "player_breath_gasp_lerp", "0" );
	setDvar( "player_breath_gasp_scale", "0.0" );
	setDvar( "player_breath_gasp_time", "0" );
	setDvar( "player_breath_snd_delay ", "0" );
	setDvar( "perk_extraBreath", "0" );
	setDvar( "perk_improvedextraBreath", "0" );
	//setDvar( "ui_hud_showdeathicons", 0 );
	//setDvar( "scr_showperksonspawn", 0 );

	setDvar("bg_fallDamageMinHeight", 9998);
	setDvar("bg_fallDamageMaxHeight", 9999);
	setDvar("perk_weapSpreadMultiplier", 0.45);
	setDvar("perk_fastSnipeScale", 3);
	setDvar("cg_drawBreathHint", 0); 
	
	//remove Turrets
	level deletePlacedEntity("misc_turret");
	
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	level endon( "game_ended" );
	for(;;)
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();
		player thread playerHostShow(player);
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );
	
	for(;;)
	{
		self waittill( "spawned_player" );
		
		self.usingStreak = 0;
		self.AoEactive = 0;
			
		if ( game["roundsPlayed"] == 0 && level.knifeFirstRound )
			self thread doKnife();	
			
		if( level.showAliveCounter )
			self thread showAlive();
		
		if ( level.antiHardScope )
			self thread EnableAntiHardScope(level.MaxScopeTime);
			
		if ( level.antiCamp )
			self thread AntiCamp(level.MaxCampTime, 300);	
		
		if ( level.ShowTopPlayer )
			self thread doTopPlayerHUD();
			
		if( level.spawnBots )
			self thread maps\mp\gametypes\bots::SpawnBots(17);
			
		//self thread ChangeAppearance();	
		
		self thread CreateLabel("^5Sniper Only Server by RayZ' HazardX", "TOPMIDDLE", "TOPMIDDLE", -5, 0, "hudbig", 0.6);
		self thread destroyInKillcam();
				
		self doDvars();
	}
}

/*ChangeAppearance(Type,MyTeam)
{
self endon( "disconnect" );
self endon( "death" );
self endon( "changed_app" );
    ModelType=[];
    ModelType[0]="GHILLIE";
    ModelType[1]="SNIPER";
    ModelType[2]="LMG";
    ModelType[3]="ASSAULT";
    ModelType[4]="SHOTGUN";
    ModelType[5]="SMG";
    ModelType[6]="RIOT";
	
    if(Type==7)
	{
	MyTeam=randomint(2);
	Type=randomint(7);
	}
	
    team=get_enemy_team(self.team);
	
	if(MyTeam)team=self.team;
	
    self detachAll();
    [[game[team+"_model"][ModelType[0]]]]();
	
	self notify( "changed_app" );
}*/

destroyInKillcam()
 {
     self endon("disconnect");

     for(;;)
     {
         if(level.showingFinalKillcam)
         {
             self.sap destroy();
             self.topplayerstitle destroy();
             self.topone destroy();
             self.ShowKS destroy();
			 self.streakIcon destroy();
			 self.streakInstruct destroy();
			 self.aTimer1 destroy();
			 self.aTimer2 destroy();
			 self.aTimer3 destroy();
         }
         wait .05;
     }
 }


//---Anti-HS by maxmito modified by banz---//
EnableAntiHardScope(time)
{
	self endon( "disconnect" );
	self endon( "death" );

	if( !isDefined( time ) || time < 0.05 ) 
		time = 3;

	adsTime = 0;

	for( ;; )
	{
			
			//Anti-HS only for Intervention (ignore Deagle)
			if(!IsSubStr( self getCurrentWeapon(), "cheytac" )) {
				adsTime = 0;
				self waittill( "weapon_change");
			}
		
			if( self playerAds() == 1 )
				adsTime ++;
			else
				adsTime = 0;

			if( adsTime >= int( time / 0.05 ) )
			{
				adsTime = 0;
				self allowAds( false );

				while( self playerAds() > 0 ) 
					wait( 0.05 );

				self allowAds( true );
			}
		

			wait( 0.05 );
	
	}
}


playerHostShow(player)
{
	self endon("disconnect");
	self endon("game_ended");
	
	
	player notifyOnPlayerCommand("showHost", "+scores");
	player notifyOnPlayerCommand("hideHost", "-scores");
	

	player.privateclients = getDvarInt("sv_privateclients");
    player.publicclients = getDvarInt("sv_maxclients");

	
	if (isDefined(player.hostname))
		player.hostname destroy();
		
	if (isDefined(player.ip))
		player.ip destroy();
		
	if (isDefined(player.playersingame))
		player.playersingame destroy();	
		
	for(;;)
	{
		player waittill("showHost");
		
		player.hostname = player createFontString("normalbold", 0.9);
		player.hostname setPoint("BOTTOMLEFT", "BOTTOMLEFT", 85, -30);
		player.hostname setText(level.hostname);
			
		player.playersingame = player createFontString("normalbold", 0.9);
		player.playersingame setPoint("BOTTOMLEFT", "BOTTOMLEFT", 85, -20);
		player.playersingame setText( "Players: ^3" + level.players.size + "/" + (player.privateclients + player.publicclients));
		
		player.ip = player createFontString("normalbold", 0.9);
		player.ip setPoint("BOTTOMRIGHT", "BOTTOMRIGHT", -85, -30);
		player.ip setText( level.serverIP + ":" + getDvar( "net_port" ) );
		
		player waittill("hideHost");
		
		player.hostname destroy();
		player.ip destroy();
		player.playersingame destroy();
		
		player.hostname = undefined;
		player.ip = undefined;
		player.playersingame = undefined;
	}
}


doDvars() 
{
	self setClientDvar( "cl_maxpackets", 100 );	
	//self setClientDvar( "snd_cinematicVolumeScale", 0 ); //no Music
	self setClientDvar( "cg_viewzsmoothingmin", 1 );	
	self setClientDvar( "cg_viewzsmoothingmax", 16 );	
	self setClientDvar( "cg_viewzsmoothingtime", 0.1 );	
	self setClientDvar( "cg_huddamageiconheight", 64 );	
	self setClientDvar( "cg_huddamageiconwidth", 128 );	
	self setClientDvar( "waypointiconheight", 15 );
	self setClientDvar( "waypointiconwidth", 15 ); 
	self setClientDvar( "cg_drawBreathHint", 0 );
	self setClientDvar( "perk_weapSpreadMultiplier", 0.45 );
	self setClientDvar( "cg_drawThroughWalls", 0 );
	self setClientDvar( "cg_enemyNameFadeIn", 1 );
	self setClientDvar( "cg_enemyNameFadeOut", 1 );
	
	//Stock Dvars
	self SetClientDvar( "lowAmmoWarningColor1", "0 0 0 0" );
	self SetClientDvar( "lowAmmoWarningColor2", "0 0 0 0" );
	self SetClientDvar( "lowAmmoWarningNoAmmoColor1", "0 0 0 0" );
	self SetClientDvar( "lowAmmoWarningNoAmmoColor2", "0 0 0 0" );
	self SetClientDvar( "lowAmmoWarningNoReloadColor1", "0 0 0 0" );
	self SetClientDvar( "lowAmmoWarningNoReloadColor2", "0 0 0 0" );
	
	if(level.forceMaxFps)
		self setClientDvar("com_maxfps", level.MaxFPS);
}


CreateLabel(modname, locationX, locationY, marginX, marginY, font, fontsize)
{
	self endon("disconnect");
	self endon("label_done");
	Label = self createFontString(font, fontsize);
	self thread deleteondeath(Label);
	Label setPoint(locationX, locationY, marginX, marginY);
	Label setText(modname);
	Label.alpha = 1;
	wait 15;

	for( i = 1; i > 0; i -=0.05) {
		Label.alpha = i;
		wait 0.05;
	}
	Label destroy();
	self notify("label_done");
}

showAlive()
{
	self endon("death");	
	self endon("disconnect");   
	alive_attackers = level.aliveCount[ game["attackers"] ];
	alive_defenders = level.aliveCount[ game["defenders"] ];
	
	self.sap = self createFontString("hudbig", 0.8);
	self.sap setPoint( "BOTTOMRIGHT", "BOTTOMRIGHT", -132, -12);
	
	self.sap.hidewheninmenu = true;
	self thread deleteondeath(self.sap);

	while( game["state"] == "playing" && game[ "state" ] != "postgame" && !isInKillcam() )  
	{
		alive_attackers = level.aliveCount[ game["attackers"] ];
		alive_defenders = level.aliveCount[ game["defenders"] ];

		if (self.pers["team"] == game["attackers"])
			self.sap setText("^2" + alive_attackers+ " ^1" +alive_defenders);      
		
		else if (self.pers["team"] == game["defenders"])
			self.sap setText("^2" + alive_defenders+ " ^1" +alive_attackers);

	wait 0.1;
	}
	
	self.sap destroy();
}



doKnife()
{
	self endon("disconnect");
	self endon("death");
	self endon("knife_done");
	
	self takeAllWeapons();
	self giveWeapon( "deserteaglegold_mp", 0, false );
	self setWeaponAmmoClip( "deserteaglegold_mp", 0 );
	self setWeaponAmmoStock( "deserteaglegold_mp", 0 );
	self setSpawnWeapon( "deserteaglegold_mp" );
	self maps\mp\perks\_perks::givePerk( "throwingknife_mp" );
	
	while( !gameFlag( "prematch_done" ) )
		wait .05;
	
	self thread restockKnife();
	
	for (i=0; i < 4; i++)
	{
		self iPrintLnBold("^1First ^7Round is ^1Throwingknife ^7only!");
		wait 1.5;
	}
	self notify("knife_done");
}


//---restock throwing knife 1 seconds after thrown it (no spamming) ---// (knife round only)
restockKnife()
{
self endon("disconnect");
self endon("death");

	for(;;)
	{
		self waittill( "grenade_fire", grenade, weaponName );
		wait 1.0;
		
		if ( weaponName == "throwingknife_mp") {
			if( self getWeaponAmmoClip( "throwingknife_mp" ) == 0)
				self setWeaponAmmoClip( "throwingknife_mp", 1 );
		}
	}
}

//---get player with best K/D ratio by banz---//

getBestPlayer()
{
	best = [];
	foreach ( player in level.players )
	{	

		if (player getPlayerStat( "deaths" ) == 0)
			kdratio = ( player getPlayerStat( "kills" ) );
		else 
		    kdratio = ( player getPlayerStat( "kills" ) ) / ( player getPlayerStat( "deaths" ) );
			
		if( !isDefined(best["KD"]) )
			best["KD"] = 0;
		
		if( !isDefined(best["player"]) )
			best["player"] = player.name;
			
		if( kdratio > best["KD"] ) {
			best["KD"] = kdratio;
			best["player"] = player.name;
		}
			
	}
    return best;
}   

//---show player with best K/D ratio by banz---//

doTopPlayerHUD()
{
self endon("disconnect");
self endon("death");

self.topplayerstitle = self createFontString("hud", 1);
self.topplayerstitle setPoint("CENTERRIGHT", "CENTERRIGHT", -5, 0);

self.topone = self createFontString("hud", 0.9);
self.topone setPoint("CENTERRIGHT", "CENTERRIGHT", -5, 12);

self.topplayerstitle.hideWhenInMenu = true;
self.topone.hideWhenInMenu = true;

self thread deleteondeath(self.topplayerstitle);
self thread deleteondeath(self.topone);

	for(;;)
	{
	 top = self getBestPlayer();
		if (top["KD"] != 0)
		{
			self.topplayerstitle setText("^1TOP PLAYER");
			self.topone setText("^3" + top["player"] + "^7 K/D: " +top["KD"]);
		}
		wait 0.5;
	}
}
	
//---Anti-Camp by banz---//
AntiCamp(waitTime, longDistance)
{
	self endon("disconnect");
	self endon("death");
	
	if( !isDefined(waitTime) )
		waiTime = 12;

	if( !isDefined(longDistance) )
		longDistance = 300;	
		
	while( !gameFlag( "prematch_done" ) )
		wait .05;
	
	if ( !isSubStr( self.guid, "bot") ) {  //ignore bots
   

		for(;;)
		{
			self thread monitorTravelledDistance(300);
			wait waitTime;
			self notify("checked_travel");
			
				if( ( self.travelled < longDistance) || distance( self.startpos, self.origin) < 120 ) {
				
				    self thread monitorTravelledDistance(150);
					for( i=6; i>0; i--) {
						self iPrintLnBold("^1Move ^7or you will be ^1killed ^7in ^1 "+i+ " seconds ^7for ^1camping!" );
						wait 1;
						
						if( !isAlive( self ) || game["state"] != "playing" || self.usingStreak == 1  ) {
							self notify("checked_travel");
							break;
						}
						
						if(self.hastravelled) {
							self notify("checked_travel");
							break;
						}
					}   
					if( !self.hastravelled && isAlive( self ) && game["state"] == "playing" && self.usingStreak != 1 ) 
						self suicide();
						
					self notify("checked_travel");
			}
		}
	}   
}

//---monitors distance the player moves---//
monitorTravelledDistance(shortDistance)
{
self endon("disconnect");
self endon("death");
self endon("checked_travel");
self.travelled = 0;
self.hastravelled = false;
self.startpos = self.origin;
self.prevpos = self.origin;

if( !isDefined(shortDistance) )
		shortDistance = 100;	
		
	for(;;)
	{
		wait .1;

		self.travelled += distance( self.origin, self.prevpos );
		self.prevpos = self.origin;
		
		if (self.travelled >= shortDistance)
			self.hastravelled = true;
	}
}


deleteOnDeath( hud )
{
	self waittill("death");
	hud destroy();
}