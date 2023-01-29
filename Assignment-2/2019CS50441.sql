-- 1 --
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, total_caught_stealing
from People, (
    select playerID, sum(CS) as total_caught_stealing
    from Batting
    group by playerID
    order by total_caught_stealing desc
    limit 10
) as CaughtStealing
where CaughtStealing.playerID = People.playerID
order by total_caught_stealing desc, firstname asc, lastname asc, playerid asc;

-- 2 --
select People.playerID as playerid, People.nameFirst as firstname, runscore
from People, (
    select playerID, (Batting.2B * 2 + Batting.3B * 3 + Batting.HR * 4) as runscore
    from Batting
    group by playerID
    order by runscore desc
    limit 10
) as PlayerRunScore
where PlayerRunScore.playerID = People.playerID
order by runscore desc, firstname desc, playerid asc;

-- 3 --
select People.playerID as playerid, People.nameFirst + " " + People.nameLast as playername, total_points
from People, (
    select playerID, sum(pointsWon) as total_points
    from AwardsSharePlayers
    where yearID >= 2000
    group by playerID
) as PeoplePoints
where People.playerID = PeoplePoints.playerID
order by total_points desc, playerid asc;

-- 4 --
with BattingWithoutNull as
(
    select *
    from Batting
    where AB is not null and H is not null
),
temp1 as
(
    select playerID, count(stint) as distinctSeasons -- distinctSeasons
    from BattingWithoutNull
    group by playerID
),
PlayersWith10Seasons as
(
    select playerID
    from temp1
    group by playerID
    where distinctSeasons >= 10
),
relevantRows as
(
    select BattingWithoutNull.playerid, H/AB as seasonAverage
    from BattingWithoutNull, PlayersWith10Seasons
    where BattingWithoutNull.playerID in (select playerID from PlayersWith10Seasons)
),
PlayersCareerAverage as
(
    select playerID, AVG(seasonAverage) as careerAverage
    from relevantRows
    group by playerID
    order by careerAverage
    limit 10
)
select playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, careerAverage as career_batting_average
from PlayersCareerAverage, People
where People.playerID = PlayersCareerAverage.playerID
order by career_batting_average desc, playerid asc, firstname asc, lastname asc;


-- 5 --
with battingSeasonsTable as
(
    select playerID, distinct stint as battingSeasons
    from Batting
    group by playerID
),
fieldingSeasonsTable as
(
    select playerID, distinct stint as fieldingSeasons
    from Fielding
    group by playerID
),
pitchingSeasonsTable as
(
    select playerID, distinct stint as pitchingSeasons
    from Pitching
    group by playerID
),
distinctSeasonsTable as 
(
    select playerID, count(distinct seasons) as countDistinctSeasons
    from battingSeasonsTable, fieldingSeasonsTable, pitchingSeasonsTable
    where pitchingSeasonsTable.playerID = fieldingSeasonsTable.playerID
    and pitchingSeasonsTable.playerID = battingSeasonsTable.playerID
)
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, People.birthYear + "-" + People.birthMonth + "-" + People.birthDay
from People, distinctSeasonsTable
where People.playerID = distinctSeasonsTable.playerID;


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
with validTeams as
(
    select teamID, count(W) as winCount
    from Teams
    group by teamID
    where winCount >= 20
),
validRows as
(
    select teamID, Teams.name as teamname, yearID as seasonid, (Teams.W/Teams.G)*100 as winningPercentage
    from Teams, validTeams
    where Teams.teamID in (select teamID from validTeams)
)
select teamID as teamid, teamname, seasonid, max(winningPercentage) as winning_percentage
from validRows
group by teamID
order by winning_percentage desc, teamid, teamname, seasonid;

-- 8 --
with maxSalarySeasonWise as
(
    select teamID, yearID, max(salary) as maxSalary
    from Salaries
    group by teamID, yearID
),
PlayerMaxSalarySeasonWise as
(
    select teamID, yearID as seasonid, playerID, Salaries.salary
    from maxSalarySeasonWise, Salaries
    where maxSalarySeasonWise.maxSalary = Salaries.salary
    group by teamID, yearID
),
subTableTeamID as
(
    select teamID
    from PlayerMaxSalarySeasonWise
),
subTableTeamName as
(
    select Teams.teamID, Teams.name
    from Teams, subTableTeamID
    where Teams.teamID = subTableTeamID.teamID
)
subTablePlayerID as
(
    select playerID
    from PlayerMaxSalarySeasonWise
),
subTablePlayerName as
(
    select People.playerID, People.nameFirst, People.nameLast
    from subTablePlayerID, People
    where People.playerID = subTablePlayerID.playerID
),
attachedTeamName as
(
    select subTableTeamName.teamID, subTableTeamName.name, seasonid, playerID, salary
    from PlayerMaxSalarySeasonWise, subTableTeamName
    where PlayerMaxSalarySeasonWise.teamID = subTableTeamName.teamID
)
select attachedTeamName.teamID as teamid, attachedTeamName.name as teamname, seasonid, attachedTeamName.playerID as playerid, subTablePlayerName.nameFirst as player_firstname, subTablePlayerName.nameLast as player_lastname, salary
from attachedTeamName, subTablePlayerName
where subTablePlayerName.playerID = attachedTeamName.playerID
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
    select AVG(averageSalary) as groupSalary, 'batsman' as group
    from battingPlayers, playerSalaries
    where battingPlayers.playerID = playerSalaries.playerID
),
pitchingSalaries as
(
    select AVG(averageSalary) as groupSalary, 'pitcher' as group
    from pitchingPlayers, playerSalaries
    where pitchingPlayers.playerID = playerSalaries.playerID
),
merged as
(
    select *
    from battingSalaries union pitchingSalaries
    order by battingSalaries.groupSalary desc

)
select group as player_category, groupSalary as avg_salary
from merged
limit 1;


-- 10 --
with playerIDBatchmates as
(
    select CollegePlaying1.playerID, count(distinct CollegePlaying2.playerID) as number_of_batchmates
    from CollegePlaying as CollegePlaying1, CollegePlaying as CollegePlaying2
    where CollegePlaying1.schoolID = CollegePlaying2.schoolID
    and CollegePlaying1.year = CollegePlaying2.year
    and CollegePlaying1.playerID <> CollegePlaying2.playerID
)
select People.playerID as playerid, (People.nameFirst + " " + People.nameLast) as playername, number_of_batchmates
from playerIDBatchmates, People
where playerIDBatchmates.playerID = People.playerID
order by number_of_batchmates desc, playerid
