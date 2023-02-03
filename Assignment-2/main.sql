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
    select yearID, teamID, W as wins
    from Teams
    where Teams.divwin = True
    order by wins desc
),
maxWins as
(
    select teamID, max(wins) as num_wins
    from validYears
    group by teamID
), teamWins as
(
    select distinct teamID, num_wins
    from maxWins, TeamsFranchises
), teamNameTableTemp as
(
    select Teams.teamID, Teams.name, yearid, franchid, num_wins
    from teamWins, Teams
    where teamWins.teamID = Teams.teamID
), teamNameTable as
(
    select t1.teamID, t1.name, franchid, num_wins
    from teamNameTableTemp as t1
    join 
    (
        select teamID, max(yearid) as maxyearid
        from teamNameTableTemp
        group by teamID
    ) as t2
    on t1.teamID = t2.teamID
    and t1.yearid = t2.maxyearid
)
select teamid, name as teamname, franchname as franchisename, num_wins
from teamNameTable, TeamsFranchises
where teamNameTable.franchid = TeamsFranchises.franchid
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
    and Salaries1.salary = Salaries2.ms
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
with b1 as
(
    select avg(salary) as groupSalary, 'batsman'::text as groupNew
    from Salaries
    where Salaries.playerID = any(select playerId from Batting)
), p1 as
(
    select avg(salary) as groupSalary, 'pitcher'::text as groupNew
    from Salaries
    where Salaries.playerID = any(select playerId from Pitching)
), mergedTable as
(
    select *
    from b1
    union all
    select *
    from p1
)
select groupNew as player_category, groupSalary as avg_salary
from mergedTable
order by avg_salary desc
limit 1;

-- 10 --
with p1Temp as
(
    select CollegePlaying1.playerID, count(distinct CollegePlaying2.playerID) as number_of_batchmates
    from CollegePlaying as CollegePlaying1, CollegePlaying as CollegePlaying2
    where CollegePlaying1.schoolID = CollegePlaying2.schoolID
    and CollegePlaying1.yearID = CollegePlaying2.yearID
    and CollegePlaying1.playerID <> CollegePlaying2.playerID
    group by CollegePlaying1.playerID
), p2 as
(
    select playerId, 0 as number_of_batchmates
    from CollegePlaying
    where playerid not in (select playerid from p1Temp)
), p1 as
(
    select * from p1Temp
    union
    select * from p2
)
select People.playerID as playerid,
case when People.nameFirst is null then (case when People.nameLast is null then '' else People.nameLast end)
else (case when People.nameLast is null then People.nameFirst else (People.nameFirst || ' ' || People.nameLast) end)
end as playername,
number_of_batchmates
from p1, People
where p1.playerID = People.playerID
order by number_of_batchmates desc, playerid;



-- 11 --
with validSeasons as
(
    select teamID, yearID, count(WSWin) as cntWSWin, sum(G) as games
    from Teams
    where WSWin = True
    group by teamID, yearID
    having sum(G) >= 110
),
totalWSWins as
(
    select teamID, count(*) as totalWins
    from validSeasons
    group by teamID
),
yearAppended as
(
    select totalWSWins.teamID as teamid, Teams.name as teamname, Teams.yearID, totalWins
    from totalWSWins, Teams
    where Teams.teamID = totalWSWins.teamID
    order by Teams.teamid, yearID desc
)
select yearAppended1.teamID as teamid, teamname, totalWins as total_ws_wins
from yearAppended as yearAppended1
join
(
    select teamid, max(yearID) as yearID
    from yearAppended
    group by teamid
) as yearAppended2
on yearAppended1.teamID = yearAppended2.teamID
and yearAppended2.yearID = yearAppended1.yearID
order by total_ws_wins desc, yearAppended1.teamid, teamname
limit 5;


-- 12 --
with careerSaves as
(
    select playerID, count(distinct yearID) as num_seasons, sum(SV) as career_saves
    from Pitching
    group by playerID
    having count(distinct yearID) >= 15
)
select People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, career_saves, num_seasons
from People, careerSaves
where People.playerID = careerSaves.playerID
order by career_saves desc, num_seasons desc, People.playerID, firstname, lastname
limit 10;


-- 13 --
with validPitchers as
(
    select playerID
    from Pitching
    group by playerID
    having count(distinct teamID) >= 5
),
pitchersWithTeams as
(
    select Pitching.playerID, Pitching.yearID, Pitching.stint, Pitching.teamID
    from Pitching, validPitchers
    where Pitching.playerID = validPitchers.playerID
    order by Pitching.playerID, Pitching.yearID
),
rowAppended as
(
    select *, ROW_NUMBER() over(PARTITION by playerID order by yearID, stint) as row_number
    from pitchersWithTeams
), firstTeam as
(
    select playerID, teamID as firstteamId
    from rowAppended
    where row_number = 1
), secondTeamTemp as
(
    select rowAppended.playerID, rowAppended.teamID, row_number as old_row_number
    from rowAppended, firstTeam
    where rowAppended.playerID = firstTeam.playerID and rowAppended.teamID != firstTeam.firstteamId
), secondTeamNewRow as
(
    select playerId, teamID, ROW_NUMBER() over(PARTITION by playerID order by old_row_number) as row_number
    from secondTeamTemp
), secondTeam as
(
    select playerID, teamID as  secondteamId
    from secondTeamNewRow
    where row_number = 1
), firstTeamNameTableTemp as
(
    select distinct playerId, Teams.name as teamname, yearid
    from firstTeam, Teams
    where firstTeam.firstteamId = Teams.teamID
), secondTeamNameTableTemp as
(
    select distinct playerId, Teams.name as teamname, yearid
    from secondTeam, Teams
    where secondTeam.secondteamId = Teams.teamID
), firstTeamNameTable as
(
    select f1.playerid, teamname
    from firstTeamNameTableTemp as f1
    join
    (
        select playerid, max(yearid) as maxYear
        from firstTeamNameTableTemp
        group by playerid
    ) as f2
    on f1.playerid = f2.playerid and f1.yearid = f2.maxYear
), secondTeamNameTable as
(
    select s1.playerid, teamname
    from secondTeamNameTableTemp as s1
    join
    (
        select playerid, max(yearid) as maxYear
        from secondTeamNameTableTemp
        group by playerid
    ) as s2
    on s1.playerid = s2.playerid and s1.yearid = s2.maxYear
), mergedTeams as
(
    select firstTeamNameTable.playerId, firstTeamNameTable.teamname as first_teamname, secondTeamNameTable.teamname as second_teamname
    from firstTeamNameTable, secondTeamNameTable
    where firstTeamNameTable.playerId = secondTeamNameTable.playerId
)
select mergedTeams.playerId, People.nameFirst as firstname, People.nameLast as lastname, (lower(birthcity) || ' ' || lower(birthstate) || ' ' || lower(birthcountry)) as birth_address, mergedTeams.first_teamname, mergedTeams.second_teamname
from mergedTeams, People
where mergedTeams.playerId = People.playerID
order by mergedTeams.playerId, firstname, lastname, birth_address, first_teamname, second_teamname;


-- 14 --

insert into People (playerID, nameFirst, nameLast)
SELECT 'dunphil02', 'Phil', 'Dunphy'
FROM (VALUES ('dunphil02', 'Phil', 'Dunphy')) AS new_entry
WHERE not ('dunphil02' = any(select playerid from People))

UNION

SELECT 'tuckcam01', 'Cameron', 'Tucker'
FROM (VALUES ('tuckcam01', 'Cameron', 'Tucker')) AS new_entry
WHERE not ('tuckcam01' = any(select playerid from People))

UNION

SELECT 'scottm02', 'Michael', 'Scott'
FROM (VALUES ('scottm02', 'Michael', 'Scott')) AS new_entry
WHERE not ('scottm02' = any(select playerid from People))

UNION

SELECT 'waltjoe', 'Joe', 'Walt'
FROM (VALUES ('waltjoe', 'Joe', 'Walt')) AS new_entry
WHERE not ('waltjoe' = any(select playerid from People))

UNION

SELECT 'adamswi01', 'Willie', 'Adams'
FROM (VALUES ('adamswi01', 'Willie', 'Adams')) AS new_entry
WHERE not ('adamswi01' = any(select playerid from People))

UNION

SELECT 'yostne01','Ned', 'Yost'
FROM (VALUES ('yostne01','Ned', 'Yost')) AS new_entry
WHERE not ('yostne01' = any(select playerid from People));

insert into AwardsPlayers (playerID, awardID, yearID, lgID, tie, notes)
SELECT 'dunphil02', 'Best Baseman', 2014, '', TRUE, NULL
FROM (VALUES ('dunphil02', 'Best Baseman', 2014, '', TRUE, NULL)) AS new_entry
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'dunphil02'
  and awardID = 'Best Baseman'
  and yearID = 2014
  and lgID = ''
)
UNION
SELECT 'tuckcam01', 'Best Baseman', 2014, '', TRUE, NULL
FROM (VALUES ('tuckcam01', 'Best Baseman', 2014, '', TRUE, NULL)) AS new_entry
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'tuckcam01'
  and awardID = 'Best Baseman'
  and yearID = 2014
  and lgID = ''
)
UNION
SELECT 'scottm02', 'ALCS MVP', 2015, 'AA', FALSE, NULL
FROM (VALUES ('scottm02', 'ALCS MVP', 2015, 'AA', FALSE, NULL)) AS new_entry
WHERE 1 <> ALL(
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'scottm02'
  and awardID = 'ALCS MVP'
  and yearID = 2015
  and lgID = 'AA'
)
UNION
SELECT 'waltjoe', 'Triple Crown', 2016, '', NULL, NULL
FROM (VALUES ('waltjoe', 'Triple Crown', 2016, '', NULL, NULL)) AS new_entry
WHERE 1 <> ALL (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'waltjoe'
  and awardID = 'Triple Crown'
  and yearID = 2016
  and lgID = ''
)
UNION
SELECT 'adamswi01', 'Gold Glove', 2017, '', FALSE, NULL
FROM (VALUES ('adamswi01', 'Gold Glove', 2017, '', FALSE, NULL)) AS new_entry
WHERE 1 <> ALL (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'adamswi01'
  and awardID = 'Gold Glove'
  and yearID = 2017
  and lgID = ''
)
UNION
SELECT 'yostne01', 'ALCS MVP', 2017, '', NULL, NULL
FROM (VALUES ('yostne01', 'ALCS MVP', 2017, '', NULL, NULL)) AS new_entry
WHERE 1 <> ALL (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'yostne01'
  and awardID = 'ALCS MVP'
  and yearID = 2017
  and lgID = ''
);

with AwardsTable as
(
    select awardID, playerID, count(*) as numAwards
    from AwardsPlayers
    group by awardID, playerID
    order by awardID, numAwards desc, playerID
),
maxAwardsTable as
(
    select maxAwards1.awardID, playerID, numAwards as num_wins
    from AwardsTable as maxAwards1
    join (
        select awardID, max(numAwards) as maxAwards
        from AwardsTable
        group by awardID
    ) as maxAwards2
    on maxAwards1.awardID = maxAwards2.awardID
    and maxAwards = maxAwards1.numAwards
    order by awardID, numAwards desc, playerID asc
),
playerDetails as
(
    select awardID as awardid, People.playerID as playerid, People.nameFirst as firstname, People.nameLast as lastname, num_wins
    from People, maxAwardsTable
    where People.playerID = maxAwardsTable.playerID
)
select distinct on (awardid) *
from playerDetails
order by awardid, num_wins desc;


-- 15 --
with managerOrderTable as
(
    select playerID as managerID, yearID, teamID, inseason as managerOrder
    from Managers
    where yearID >= 2000 and yearID <= 2010
    order by teamid, yearid, managerOrder
), minManagerTable as
(
    select managerOrderTable1.teamid, managerOrderTable1.yearid, managerid
    from managerOrderTable as managerOrderTable1
    join
    (
        select teamid, yearid, min(managerorder) as minManage
        from managerOrderTable
        group by teamid, yearid
    ) as managerOrderTable2
    on managerOrderTable1.teamid = managerOrderTable2.teamid
    and managerOrderTable1.yearID = managerOrderTable2.yearid
    and managerOrderTable1.managerorder = minManage
    order by teamid, yearid, managerid, managerorder
),
teamDetails as
(
    select Teams.teamid, Teams.name as teamname, Teams.yearid as seasonid, managerid
    from minManagerTable, Teams
    where Teams.teamID = minManagerTable.teamID
    and Teams.yearid = minManagerTable.yearid
)
select teamid, teamname, seasonid, managerid, People.nameFirst as managerfirstname, People.nameLast as managerlastname
from teamDetails, People
where playerId = managerid
order by teamid, teamname, seasonid desc, managerid, managerfirstname, managerlastname;


-- 16 --
with playerAwards as
(
    select playerID, count(*) as cntAwards
    from AwardsPlayers
    group by playerID
    order by cntAwards desc
),
collegeAppended as
(
    select distinct playerAwards.playerID, CollegePlaying.yearid, schoolid, cntAwards
    from playerAwards, CollegePlaying
    where playerAwards.playerID = CollegePlaying.playerID
),
maxYear as
(
    select collegeAppended1.playerID, schoolid, cntAwards
    from collegeAppended as collegeAppended1
    join
    (
        select playerID, max(collegeAppended.yearid) as maxYear
        from collegeAppended
        group by playerid
    ) as collegeAppended2
    on collegeAppended1.playerID = collegeAppended2.playerID
    and collegeAppended1.yearid = collegeAppended2.maxYear
), t1 as
(
    select playerid, schoolName as colleges_name, cntAwards as total_awards
    from maxYear, Schools
    where maxYear.schoolid = Schools.schoolid
), t2 as
(
    select playerid, ''::text as colleges_name, cntAwards as total_awards
    from playerAwards
    where playerid not in (select playerid from t1)
), t3 as
(
    select playerid, colleges_name, total_awards
    from t1
    union all
    select playerid, colleges_name, total_awards
    from t2
)
select playerid, colleges_name, total_awards
from t3
order by total_awards desc, colleges_name, playerid asc
limit 10;



-- 17 --
with awardsWonPlayer as
(
    select distinct on (AwardsPlayers1.playerid)
            AwardsPlayers1.playerid, AwardsPlayers1.yearid, awardid
    from AwardsPlayers as AwardsPlayers1
    join
    (
        select playerid, min(yearid) as minYear
        from AwardsPlayers
        group by playerID
    ) as AwardsPlayers2
    on AwardsPlayers1.playerID = AwardsPlayers2.playerID
    and AwardsPlayers1.yearid = minYear
    order by AwardsPlayers1.playerid, awardid
), awardsWonManager as
(
    select distinct on (AwardsManager1.playerid)
            AwardsManager1.playerid, AwardsManager1.yearid, awardid
    from AwardsManagers as AwardsManager1
    join
    (
        select playerid, min(yearid) as minYear
        from AwardsManagers
        group by playerID
    ) as AwardsManager2
    on AwardsManager1.playerID = AwardsManager2.playerID
    and AwardsManager1.yearid = minYear
    order by AwardsManager1.playerid, awardid
), intesectingPlayers as
(
    select playerid
    from awardsWonPlayer
    intersect
    select playerId
    from awardsWonManager
), playerDetails as
(
    select People.playerID, People.nameFirst as firstname, People.nameLast as lastname
    from People, intesectingPlayers
    where intesectingPlayers.playerID = People.playerID
)
select playerDetails.playerID, firstname, lastname, awardsWonPlayer.awardid as playerawardid, awardsWonPlayer.yearid as playerawardyear, awardsWonManager.awardid as managerawardid, awardsWonManager.yearid as managerawardyear
from playerDetails, awardsWonManager, awardsWonPlayer
where playerDetails.playerid = awardsWonManager.playerID
and awardsWonManager.playerID = awardsWonPlayer.playerID
order by playerDetails.playerid, firstname, lastname;

-- 18 --
with allStarPlayers as
(
    select playerid, min(yearid) as seasonid
    from AllstarFull
    where GP = 1
    group by playerid
), honoredTwoCateg as
(
    select playerID, count(distinct category) as num_honored_categories
    from HallOfFame
    -- where inducted = True
    group by playerID
    having count(distinct category) > 1
), intesectingPlayers as
(
    select playerid
    from allStarPlayers
    intersect
    select playerid
    from honoredTwoCateg
), playerDetails as
(
    select People.playerID, People.nameFirst as firstname, People.nameLast as lastname
    from People, intesectingPlayers
    where intesectingPlayers.playerID = People.playerID
)
select playerDetails.playerID, firstname, lastname, honoredTwoCateg.num_honored_categories, seasonid
from playerDetails, honoredTwoCateg, allStarPlayers
where playerDetails.playerid = honoredTwoCateg.playerID
and honoredTwoCateg.playerID = allStarPlayers.playerID
order by num_honored_categories desc, playerDetails.playerid, firstname, lastname, seasonid;


-- 19 --
with basemanTable as
(
    select playerid, sum(G_1b) as g1b, sum(G_2b) as g2b, sum(G_3b) as g3b, sum(G_all) as gall
    from Appearances
    group by playerid
), filtered as
(
    select *
    from basemanTable
    where
    (
        (g1b > 0 and g2b > 0)
        or
        (g2b > 0 and g3b > 0)
        or
        (g1b > 0 and g3b > 0)
    )
)
select People.playerid, People.nameFirst as firstname, People.nameLast as lastname, gall as G_all, g1b as G_1b, g2b as G_2b, g3b as G_3b
from filtered, People
where People.playerid = filtered.playerid
order by gall desc, People.playerid, firstname, lastname, g1b desc, g2b desc, g3b desc;


-- 20 --
with topSchools as
(
    select schoolID
    from CollegePlaying
    group by schoolID
    order by count (distinct playerid) desc
    limit 5
), playerAttached as
(
    select topSchools.schoolID, playerid
    from topSchools, CollegePlaying
    where topSchools.schoolID = CollegePlaying.schoolID
    order by playerid
), playerDetails as
(
    select People.playerID, People.nameFirst as firstname, People.nameLast as lastname, schoolID
    from People, playerAttached
    where playerAttached.playerID = People.playerID
)
select distinct Schools.schoolID, schoolname, 
case when schoolCity is null then (
    case when schoolState is null then '' else lower(schoolState) end
) else (
    case when schoolState is null then lower(schoolCity) else lower(schoolCity) || ' ' || lower(schoolState) end
) end as schooladdr,
playerid, firstname, lastname
from playerDetails, Schools
where playerDetails.schoolID = Schools.schoolID
order by Schools.schoolid, schoolName, schooladdr, playerid, firstname, lastname;




-- 21 --
with sameCityState as
(
    select People1.playerid as player1, People2.playerID as player2, People1.birthCity, People1.birthState
    from People as People1, People as People2
    where People1.birthCity is not null
    and People1.birthState is not null
    and People2.birthCity is not null
    and People2.birthState is not null
    and People1.playerID <> People2.playerID
    and People1.birthCity = People2.birthCity
    and People1.birthState = People2.birthState
), sameTeamBatting as
(
    select distinct player1, player2, birthCity, birthState
    from Batting as Batting1, Batting as Batting2, sameCityState
    where Batting1.playerid = player1
    and Batting2.playerid = player2
), sameTeamPitching as
(
    select distinct player1, player2, birthCity, birthState
    from Pitching as Pitching1, Pitching as Pitching2, sameCityState
    where Pitching1.playerid = player1
    and Pitching2.playerid = player2
), bothRolesIntersection as
(
    select *
    from sameTeamBatting
    intersect
    select *
    from sameTeamPitching
), bothRoles as
(
    select *, 'both'::text as playerRole
    from bothRolesIntersection
), onlyBattingTemp as
(
    select *
    from sameTeamBatting
    except
    select *
    from bothRolesIntersection
), onlyPitchingTemp as
(
    select *
    from sameTeamPitching
    except
    select *
    from bothRolesIntersection
), onlyBatting as
(
    select *, 'batted'::text as playerRole
    from onlyBattingTemp
), onlyPitching as
(
    select *, 'pitched'::text as playerRole
    from onlyPitchingTemp
), finalTable as
(
    select * from bothRoles
    union
    select * from onlyBatting
    union
    select * from onlyPitching
)
select player1 as player1_id, player2 as player2_id, birthcity, birthState, playerRole as role
from finalTable
order by birthCity, birthState, player1, player2;

-- 22 --
with Average as
(
    select awardid, yearid, avg(pointswon) as avgpoints
    from AwardsSharePlayers
    group by awardid, yearid
)
select Average.awardID, Average.yearid as seasonid, playerid, pointsWon as playerpoints, avgpoints as averagepoints
from Average, AwardsSharePlayers
where Average.awardID = AwardsSharePlayers.awardID
and Average.yearid = AwardsSharePlayers.yearid
and pointsWon >= Average.avgpoints
order by Average.awardID, seasonid, playerpoints desc, playerid;


-- 23 --
with minusPlayerAward as
(
    select playerid from People
    except
    select distinct playerid from AwardsPlayers
), minusManagerAward as
(
    select playerid from minusPlayerAward
    except
    select distinct playerid from AwardsManagers
)
select People.playerid, People.nameFirst || ' ' || People.nameLast as playername, case when deathYear>0 then False else True end as alive
from People, minusManagerAward
where minusManagerAward.playerid = People.playerid
order by People.playerid, playername;


-- 24 --
with recursive pitchingPlayers as
(
    select distinct playerid, yearid, teamid
    from Pitching
), allStarPlayers as
(
    select distinct playerid, yearid, teamid
    from AllstarFull
    where GP=1
), relevantPlayers as
(
    select *
    from pitchingPlayers
    union
    select *
    from allStarPlayers
), routeTemp as (
    select p1.playerid as playera, p2.playerid as playerb, 1 as edge
    from relevantPlayers as p1, relevantPlayers as p2
    where p1.yearid = p2.yearid
    and p2.teamid = p1.teamid
), routes(playera, playerb, edge, path) as (
    select playera, playerb, edge, array[playera::text, playerb::text]
    from routeTemp
    where playera = 'webbbr01'
    union all
    select distinct r1.playera, r2.playerb, 0, path || r2.playerb::text
    from routes as r1, routeTemp as r2
    where r1.playerb = r2.playera
    and (not (r2.playerb = any(path)))
)
select exists (select playera, playerb from routes where playerb = 'clemero02') as pathexists;



-- 25 --
with recursive pitchingPlayers as
(
    select distinct playerid, yearid, teamid
    from Pitching
), allStarPlayers as
(
    select distinct playerid, yearid, teamid
    from AllstarFull
    where GP=1
), relevantPlayers as
(
    select *
    from pitchingPlayers
    union
    select *
    from allStarPlayers
), routeTemp as (
    select p1.playerid as playera, p2.playerid as playerb, count(distinct p1.yearid) as edge
    from relevantPlayers as p1, relevantPlayers as p2
    where p1.yearid = p2.yearid
    and p2.teamid = p1.teamid
    and p1.playerid <> p2.playerid
    group by p1.playerid, p2.playerid
), routes(playera, playerb, edge, depth, path) as (
    select playera, playerb, edge, 0 as depth, array[playera::text, playerb::text]
    from routeTemp
    where playera = 'garcifr02'
    union all
    select distinct r1.playera, r2.playerb, r1.edge + r2.edge as edge, depth+1, path || r2.playerb::text
    from routes as r1, routeTemp as r2
    where r1.playerb = r2.playera
    and (not (r2.playerb = any(path)))
    -- and depth < 2
)
select min(edge) as pathlength
from routes
where playerb = 'leagubr01';


-- 26 --
with recursive graph(teamA, teamB, depth, path) as (
    select teamIDwinner, teamIDloser, 0, array[teamIDwinner::text,teamIDloser::text]
    from SeriesPost
    where teamIDwinner = 'ARI'
    -- and yearid >= 1990
    -- and yearid <= 2010
    union all
    select distinct graph.teamA, SeriesPost.teamIDloser, depth+1, path || SeriesPost.teamIDloser::text
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
    and (not (SeriesPost.teamIDloser = any(path)) )
    -- and yearid >= 1990
    -- and yearid <= 2010
)
select count(*) as count
from graph
where teamB = 'DET';


-- 27 --
with recursive graph(teamA, teamB, depth, path) as (
    select teamIDwinner, teamIDloser, 1, array[teamIDwinner::text,teamIDloser::text]
    from SeriesPost
    where teamIDwinner = 'HOU'
    union all
    select distinct graph.teamA, SeriesPost.teamIDloser, depth+1, path || SeriesPost.teamIDloser::text
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
    and (not (SeriesPost.teamIDloser = any(path)) )
    -- and depth < 3
), finalTable as
(
    select teamB as teamid, max(depth) as num_hops
    from graph
    group by teamB
)
select *
from finalTable
order by teamid;


-- 28 --
with recursive graph(teamA, teamB, depth) as (
    select teamIDwinner, teamIDloser, 0
    from SeriesPost
    where teamIDwinner = 'WS1'
    union all
    select distinct graph.teamB, SeriesPost.teamIDloser, depth + 1
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
    -- and depth < 5
), longestPath as
(
    select distinct teamB as teamid, pathlength
    from graph as graph1
    join
    (
        select max(depth) as pathlength
        from graph
    ) as graph2
    on depth = pathlength
), teamDetails as
(
    select distinct Teams.teamid, Teams.name as teamname, yearid, pathlength
    from longestPath, Teams
    where longestPath.teamid = Teams.teamid
    order by Teams.teamid, teamname
), finalTeam as
(
    select distinct f1.teamid, teamname, pathlength
    from teamDetails as f1
    join
    (
        select teamid, max(yearid) as maxYear
        from teamDetails
        group by teamid
    ) as f2
    on f1.teamid = f2.teamid and f1.yearid = f2.maxYear
)
select distinct *
from finalTeam
order by teamid, teamname;


-- 29 --
with recursive relevantTeams as 
(
    select teamIDwinner
    from SeriesPost
    where ties > losses
    group by teamIDwinner
), graph(teamA, teamB, depth, path) as
(
    select distinct relevantTeams.teamIDwinner, teamIDloser, 1, array[relevantTeams.teamIDwinner::text,teamIDloser::text]
    from relevantTeams, SeriesPost
    where SeriesPost.teamIDwinner = relevantTeams.teamIDwinner
    union all
    select distinct graph.teamA, SeriesPost.teamIDloser, depth + 1, path || SeriesPost.teamIDloser::text
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
    and (not (SeriesPost.teamIDloser = any(path)) )
    -- and depth < 8
), shortestPath as
(
    select distinct graph1.teamA as teamid, pathlength
    from graph as graph1
    join
    (
        select teamA, min(depth) as pathlength
        from graph
        where teamB = 'NYA'
        group by teamA
    ) as graph2
    on depth = pathlength
    and teamB = 'NYA'
)
select distinct *
from shortestPath;



-- 30 --
with recursive graph(teamA, teamB, depth, cycle, path) as (
    select teamIDwinner, teamIDloser, 1, 0, array[teamIDwinner::text,teamIDloser::text]
    from SeriesPost
    where teamIDwinner = 'DET'
    -- and SeriesPost.yearid >= 1970
    -- and SeriesPost.yearid <= 2000
    union all
    select distinct graph.teamA, SeriesPost1.teamIDloser, depth+1, 
    case
        when exists (
            select *
            from SeriesPost as SeriesPost2
            where SeriesPost1.teamIDloser = SeriesPost2.teamIDwinner
            and SeriesPost2.teamIDloser = 'DET'
            -- and SeriesPost2.yearid >= 1970
            -- and SeriesPost2.yearid <= 2000
        ) then 1
        else 0
        end as cycle
    , path || SeriesPost1.teamIDloser::text
    from graph, SeriesPost as SeriesPost1
    where graph.teamB = SeriesPost1.teamIDwinner
    and (not (SeriesPost1.teamIDloser = any(path)) )
    -- and SeriesPost1.yearid <= 2000
    -- and SeriesPost1.yearid >= 1970
), finalTable as
(
    select teamB as teamid, depth, path
    from graph as g1
    join
    (
        select max(depth) as pathlength
        from graph
        where cycle=1
    ) as g2
    on depth = pathlength
    where cycle=1
)
select depth + 1 as cyclelength, count(*) as numcycles
from finalTable
group by depth;