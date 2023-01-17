DROP TABLE IF EXISTS Goals;
DROP TABLE IF EXISTS PenaltyShootouts;
DROP TABLE IF EXISTS Matches;
DROP TABLE IF EXISTS Stadiums;
DROP TABLE IF EXISTS Players;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Tournaments;

CREATE TABLE Tournaments(
  tournament_id TEXT NOT NULL,
  tournament_name TEXT,
  year INTEGER,
  host_country TEXT,
  winner TEXT,
  PRIMARY KEY (tournament_id)
);

CREATE TABLE Teams(
  team_id TEXT NOT NULL,
  team_name TEXT,
  PRIMARY KEY (team_id)
);

CREATE TABLE Players(
  player_id TEXT NOT NULL,
  family_name TEXT,
  given_name TEXT,
  count_tournaments INTEGER,
  PRIMARY KEY (player_id)
);

CREATE TABLE Stadiums(
  stadium_id TEXT NOT NULL,
  stadium_name TEXT,
  city_name TEXT,
  country_name TEXT,
  PRIMARY KEY (stadium_id)
);

CREATE TABLE Matches(
  match_id TEXT NOT NULL,
  tournament_id TEXT NOT NULL,
  stage_name TEXT,
  stadium_id TEXT NOT NULL,
  home_team_id TEXT NOT NULL,
  away_team_id TEXT NOT NULL,
  home_team_score INTEGER,
  away_team_score INTEGER,
  home_team_score_penalties INTEGER,
  away_team_score_penalties INTEGER,
  home_team_win BOOLEAN,
  away_team_win BOOLEAN,
  draw BOOLEAN,
  PRIMARY KEY (match_id),
  FOREIGN KEY (tournament_id) REFERENCES tournaments (tournament_id),
  FOREIGN KEY (stadium_id) REFERENCES stadiums (stadium_id),
  FOREIGN KEY (home_team_id) REFERENCES teams (team_id),
  FOREIGN KEY (away_team_id) REFERENCES teams (team_id)
);

CREATE TABLE Goals(
  goal_id TEXT NOT NULL,
  match_id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  player_id TEXT NOT NULL,
  player_team_id TEXT NOT NULL,
  own_goal BOOLEAN,
  penalty BOOLEAN,
  PRIMARY KEY (goal_id),
  FOREIGN KEY (match_id) REFERENCES matches (match_id),
  FOREIGN KEY (team_id) REFERENCES teams (team_id),
  FOREIGN KEY (player_id) REFERENCES players (player_id),
  FOREIGN KEY (player_team_id) REFERENCES teams (team_id)
);

CREATE TABLE PenaltyShootouts(
  penalty_kick_id TEXT NOT NULL,
  match_id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  player_id TEXT NOT NULL,
  converted BOOLEAN,
  PRIMARY KEY (penalty_kick_id),
  FOREIGN KEY (match_id) REFERENCES matches (match_id),
  FOREIGN KEY (team_id) REFERENCES teams (team_id),
  FOREIGN KEY (player_id) REFERENCES players (player_id)
);
