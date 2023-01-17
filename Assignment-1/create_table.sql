CREATE table IF NOT EXISTS Players(
    player_id bigint NOT NULL,
    family_name text,
    given_name text,
    count_tournaments bigint,
    CONSTRAINT player_key PRIMARY KEY (player_id)
);

CREATE table IF NOT EXISTS Stadiums(
    stadium_id bigint NOT NULL,
    stadium_name text,
    city_name text,
    country_name text,
    CONSTRAINT stadium_key PRIMARY KEY (stadium_id)
);

CREATE table IF NOT EXISTS Teams(
    team_id bigint NOT NULL,
    team_name text,
    CONSTRAINT team_key PRIMARY KEY (team_id)
);

CREATE table IF NOT EXISTS Tournaments(
    tournament_id bigint NOT NULL,
    tournament_name text,
    tournament_year int,
    host_country text,
    winner text,
    CONSTRAINT tournament_key PRIMARY KEY (tournament_id)
);

CREATE table IF NOT EXISTS Matches(
    match_id bigint NOT NULL,
    tournament_id bigint,
    stage_name text,
    stadium_id bigint,
    home_team_id bigint,
    away_team_id bigint,
    home_team_score int,
    CONSTRAINT match_key PRIMARY KEY (match_id),
    CONSTRAINT tournament_ref FOREIGN KEY (tournament_id) references Tournaments(tournament_id),
    CONSTRAINT home_team_ref FOREIGN KEY (home_team_id) references Teams(team_id),
    CONSTRAINT away_team_ref FOREIGN KEY (away_team_id) references Teams(team_id)
);

CREATE table IF NOT EXISTS Goals(
    goal_id bigint NOT NULL,
    match_id bigint,
    team_id bigint,
    player_id bigint,
    player_team_id bigint,
    own_goal bigint,
    penalty bigint,
    CONSTRAINT goal_key PRIMARY KEY (goal_id),
    CONSTRAINT match_ref FOREIGN KEY (match_id) references Matches(match_id),
    CONSTRAINT team_ref FOREIGN KEY (team_id) references Teams(team_id),
    CONSTRAINT player_ref FOREIGN KEY (player_id) references Players(player_id),
    CONSTRAINT player_team_ref FOREIGN KEY (player_team_id) references Teams(team_id)
);

CREATE table IF NOT EXISTS Penalty Kicks(
    penalty_kick_id bigint NOT NULL,
    match_id bigint,
    team_id bigint,
    player_id bigint,
    converted bigint,
    CONSTRAINT penalty_kick_key PRIMARY KEY (penalty_kick_id),
    CONSTRAINT match_ref FOREIGN KEY (match_id) references Matches(match_id),
    CONSTRAINT team_ref FOREIGN KEY (team_id) references Teams(team_id),
    CONSTRAINT player_ref FOREIGN KEY (player_id) references Players(player_id)
);