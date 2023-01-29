SELECT COUNT(*) FROM Matches JOIN Tournaments ON Matches.tournament_id = Tournaments.tournament_id AND tournament_name = '2014 FIFA World Cup';

SELECT COUNT(*) FROM (SELECT DISTINCT Goals.match_id FROM Players JOIN Goals
ON Players.player_id = Goals.player_id AND Players.family_name = 'Mbappe' AND given_name
= 'Kylian') AS t;

SELECT DISTINCT team_name FROM Teams JOIN Matches ON (Teams.team_id = Matches.home_team_id
OR Teams.team_id = Matches.away_team_id) AND Matches.stage_name = 'final';

SELECT COUNT(*) FROM Teams JOIN (SELECT * FROM Matches JOIN Teams ON ((Teams.team_id
= Matches.home_team_id OR Teams.team_id = Matches.away_team_id) AND team_name =
'Germany')) AS t ON ((Teams.team_id = t.home_team_id OR Teams.team_id = t.away_team_id)
AND Teams.team_name = 'France' AND t.stage_name != 'group stage');

SELECT DISTINCT player_id FROM Goals JOIN (SELECT * FROM Matches JOIN Tournaments ON Matches.tournament_id = Tournaments.tournament_id AND tournament_name
= '1930 FIFA World Cup') AS t1 ON Goals.match_id = t1.match_id AND Goals.own_goal = FALSE
