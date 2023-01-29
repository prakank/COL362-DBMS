-- 1 --
select tournament_id, tournament_name, year, winner
from Tournaments
where winner = host_country;

-- 2 --
select player_id, family_name, given_name, count_tournaments
from Players
where count_tournaments >= 4;

-- 3 --
select count(*) as num_matches
from Matches, Teams
where Teams.team_name = 'Croatia'
and Matches.draw = True
and (Matches.home_team_id = Teams.team_id or Matches.away_team_id = Teams.team_id);

-- 4 --
select Stadiums.stadium_name, Stadiums.city_name, Stadiums.country_name
from Stadiums, Matches, (
    select tournament_id
    from Tournaments
    where tournament_name = '1990 FIFA World Cup'
) as TournamentID
where Matches.stage_name = 'final'
and Matches.tournament_id = TournamentID.tournament_id
and Stadiums.stadium_id = Matches.stadium_id;

-- 5 --
select count(*) as num_goals
from Goals, Players
where Players.family_name = 'Ronaldo' and Players.given_name = 'Cristiano'
and Goals.player_id = Players.player_id
and Goals.own_goal = False;

-- 6 --
select Players.player_id, family_name, given_name, num_goals
from Players, (
    select Goals.player_id, count(*) as num_goals
    from Goals, (
        select match_id
        from Tournaments, Matches
        where (Tournaments.year > 2001 and Tournaments.year < 2019)
        and Tournaments.tournament_id = Matches.tournament_id
    ) as PlayedMatches
    where Goals.match_id = PlayedMatches.match_id
    group by Goals.player_id
) as IdGoals
where IdGoals.player_id = Players.player_id
order by num_goals desc
limit 1;

-- 7 --
select Teams.team_id, Teams.team_name, num_goals as num_self_goals
from Teams, (
    select player_team_id as team_id, count(*) as num_goals
    from Goals, (
        select match_id
        from Matches, (
            select tournament_id
            from Tournaments
            order by year desc
            limit 3
        ) as Tournaments3WC
        where Tournaments3WC.tournament_id = Matches.tournament_id
    ) as ValidMatches
    where Goals.match_id = ValidMatches.match_id
    and Goals.own_goal = True
    group by player_team_id
) as TeamGoals
where Teams.team_id = TeamGoals.team_id
order by num_goals desc
limit 3;
