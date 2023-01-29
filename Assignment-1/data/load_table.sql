COPY Players FROM '/tmp/data/players.csv' DELIMITER ',' CSV HEADER;
COPY Stadiums FROM '/tmp/data/stadiums.csv' DELIMITER ',' CSV HEADER;
COPY Teams FROM '/tmp/data/teams.csv' DELIMITER ',' CSV HEADER;
COPY Tournaments FROM '/tmp/data/tournaments.csv' DELIMITER ',' CSV HEADER;
COPY Matches FROM '/tmp/data/matches.csv' DELIMITER ',' CSV HEADER;
COPY Goals FROM '/tmp/data/goals.csv' DELIMITER ',' CSV HEADER;
COPY PenaltyShootouts FROM '/tmp/data/penalty_shootouts.csv' DELIMITER ',' CSV HEADER;
