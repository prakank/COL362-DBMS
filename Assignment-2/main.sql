-- 1 --
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, total_caught_stealing
from People, (
    select playerID, coalesce(sum(CS),0) as total_caught_stealing
    from Batting
    group by playerID
    order by total_caught_stealing desc
    limit 10
) as CaughtStealing
where CaughtStealing.playerID = People.playerID
order by total_caught_stealing desc, firstname, lastname, playerid;


-- 2 --
select People.playerID as playerid, People.nameFirst as firstname, runscore
from People, (
    select playerID, (coalesce(sum(Batting.H2B),0) * 2 + coalesce(sum(Batting.H3B),0) * 3 + coalesce(sum(Batting.HR),0) * 4) as runscore
    from Batting
    group by playerID
    order by runscore desc
    limit 10
) as PlayerRunScore
where PlayerRunScore.playerID = People.playerID
order by runscore desc, firstname desc, playerid;


-- 3 --
select People.playerID as playerid, People.nameFirst || ' ' || People.nameLast as playername, total_points
from People, (
    select playerID, sum(pointsWon) as total_points
    from AwardsSharePlayers
    where yearID >= 2000
    group by playerID
) as PeoplePoints
where People.playerID = PeoplePoints.playerID
order by total_points desc, playerid;


-- 4 --
with battingAverageTable as
(
    select playerID, yearID, sum(H*1.0)/sum(AB*1.0) as battingAverage
    from Batting
    where AB is not null and H is not null and AB <> 0
    group by playerID, yearID
    order by battingAverage desc
),
seasonAverageTable as
(
    select playerID, count(distinct yearID) as countDistinctSeasons, AVG(battingAverage) as seasonAverage
    from battingAverageTable
    group by playerID
    having count(distinct yearID) >= 10
    order by seasonAverage desc
    limit 10
)
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, seasonAverage as career_batting_average 
from seasonAverageTable, People
where seasonAverageTable.playerID = People.playerID
order by career_batting_average desc, playerid, firstname, lastname;

-- 5 --
with totalSeasons as
(
    select playerID, yearID
    from Batting
    union
    select playerID, yearID
    from Fielding
    union
    select playerID, yearID
    from Pitching
),
numSeasonsTable as
(
    select playerID, count(distinct yearID) as num_seasons
    from totalSeasons
    group by playerID
)
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, People.birthYear || '-' || People.birthMonth || '-' || People.birthDay as date_of_birth, num_seasons
from numSeasonsTable, People
where numSeasonsTable.playerID = People.playerID
order by num_seasons desc, playerid asc, firstname asc, lastname asc, date_of_birth asc;


-- 6 --
with validYears as
(
    select yearID, teamID, franchID, Teams.name as teamname, W as wins
    from Teams
    where Teams.divwin = True
    order by wins desc
),
maxWins as
(
    select teamID, teamname, franchID, max(wins) as num_wins
    from validYears
    group by teamID, teamname, franchID
)
select teamID as teamid, teamname, franchName as franchisename, num_wins
from maxWins, TeamsFranchises
where maxWins.franchID = TeamsFranchises.franchID
order by num_wins desc, teamid, teamname, franchisename;


-- 7 --
with seasonWiseWinning as
(
    select teamID, yearID as seasonid, (sum(Teams.W*1.0)/sum(Teams.G*1.0))*100.0 as winningPercentage, sum(W) as winCount
    from Teams
    group by teamID, yearID
),
maxSeason as
(
    select teamID, max(winningPercentage) as winningPercentage
    from seasonWiseWinning
    group by teamID
    having sum(winCount) >= 20
),
maxSeasonWithID as
(
    select maxSeason.teamID, maxSeason.winningPercentage, seasonid
    from maxSeason, seasonWiseWinning
    where maxSeason.teamID = seasonWiseWinning.teamID
    and maxSeason.winningPercentage = seasonWiseWinning.winningPercentage
)
select Teams.teamID as teamid, Teams.name as teamname, seasonid, maxSeasonWithID.winningPercentage as winning_percentage
from maxSeasonWithID, Teams
where maxSeasonWithID.teamID = Teams.teamID and maxSeasonWithID.seasonid = Teams.yearID
order by winning_percentage desc, teamid, teamname, seasonid
limit 5;


-- 8 --
with playerSalaries as
(
    select teamID, yearID, playerID, sum(salary) as salary
    from Salaries
    group by teamID, yearID, playerID
),
maxSalary as
(
    select Salaries1.teamID, Salaries1.yearID, Salaries1.playerID, Salaries1.salary
    from playerSalaries as Salaries1
    join
    (
        select teamID, yearID, max(salary) as ms
        from playerSalaries
        group by teamID, yearID
    ) as Salaries2
    on Salaries1.teamID = Salaries2.teamID
    and Salaries2.yearID = Salaries1.yearID
),
teamName as
(
    select maxSalary.teamID as teamid, Teams.name as teamname, maxSalary.yearID as seasonid, maxSalary.playerID, salary
    from maxSalary, Teams
    where Teams.teamID = maxSalary.teamID
    and Teams.yearID = maxSalary.yearID
)
select teamid, teamname, seasonid, People.playerID as playerid, People.nameFirst as player_firstname, People.nameLast as player_lastname, salary
from People, teamName
where People.playerID = teamName.playerID
order by teamid, teamname, seasonid, playerid, player_firstname, player_lastname, salary desc;



-- 9 --
with battingPlayers as
(
    select distinct playerID
    from Batting
),
pitchingPlayers as
(
    select distinct playerID
    from Pitching
),
playerSalaries as
(
    select playerID, AVG(salary) as averageSalary
    from Salaries
    group by playerID
),
battingSalaries as
(
    select AVG(averageSalary) as groupSalary, 'batsman'::text as groupNew
    from battingPlayers, playerSalaries
    where battingPlayers.playerID = playerSalaries.playerID
),
pitchingSalaries as
(
    select AVG(averageSalary) as groupSalary, 'pitcher'::text as groupNew
    from pitchingPlayers, playerSalaries
    where pitchingPlayers.playerID = playerSalaries.playerID
),
mergedTable as
(
    select *
    from battingSalaries
    union all
    select *
    from pitchingSalaries
)
select groupNew as player_category, groupSalary as avg_salary
from mergedTable
order by avg_salary desc
limit 1;


-- 10 --
with playerIDBatchmates as
(
    select CollegePlaying1.playerID, count(distinct CollegePlaying2.playerID) as number_of_batchmates
    from CollegePlaying as CollegePlaying1, CollegePlaying as CollegePlaying2
    where CollegePlaying1.schoolID = CollegePlaying2.schoolID
    and CollegePlaying1.yearID = CollegePlaying2.yearID
    and CollegePlaying1.playerID <> CollegePlaying2.playerID
    group by CollegePlaying1.playerID
)
select People.playerID as playerid, (People.nameFirst || ' ' || People.nameLast) as playername, number_of_batchmates
from playerIDBatchmates, People
where playerIDBatchmates.playerID = People.playerID
order by number_of_batchmates desc, playerid;


-- 11 --

