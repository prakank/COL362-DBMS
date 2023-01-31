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
    select Pitching.playerID, Pitching.yearID, Pitching.teamID
    from Pitching, validPitchers
    where Pitching.playerID = validPitchers.playerID
    order by Pitching.playerID, Pitching.yearID
),
rowAppended as
(
    select *, ROW_NUMBER() over(PARTITION by playerID order by yearID) as row_number
    from pitchersWithTeams
)
select playerID, distinct teamID
from rowAppended;


-- 14 --
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
    select playerAwards.playerID, CollegePlaying.yearid, schoolid, cntAwards
    from playerAwards, CollegePlaying
    where playerAwards.playerID = CollegePlaying.playerID
),
maxYear as
(
    select collegeAppended1.playerID, collegeAppended1.yearid, schoolid, cntAwards
    from collegeAppended as collegeAppended1
    join
    (
        select playerID, max(collegeAppended.yearid) as maxYear
        from collegeAppended
        group by playerid
    ) as collegeAppended2
    on collegeAppended1.playerID = collegeAppended2.playerID
    and collegeAppended1.yearid = collegeAppended2.maxYear
)
select playerid, schoolName as colleges_name, cntAwards as total_awards
from maxYear, Schools
where maxYear.schoolid = Schools.schoolid
order by total_awards desc, colleges_name, playerid
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
    select distinct on (playerid) topSchools.schoolID, playerid
    from topSchools, CollegePlaying
    where topSchools.schoolID = CollegePlaying.schoolID
    order by playerid
), playerDetails as
(
    select People.playerID, People.nameFirst as firstname, People.nameLast as lastname, schoolID
    from People, playerAttached
    where playerAttached.playerID = People.playerID
)
select Schools.schoolID, schoolname, schoolCity || ' ' || schoolState as schooladdr, playerid, firstname, lastname
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
), routes(playerid, yearid, teamid, depth) as (
    select playerid, yearid, teamid, 0
    from relevantPlayers
    where playerid = 'webbbr01'
    union all
    select distinct relevantPlayers.playerid, relevantPlayers.yearid, relevantPlayers.teamid, depth+1
    from routes, relevantPlayers
    where routes.yearid = relevantPlayers.yearid
    and routes.teamid = relevantPlayers.teamid
    and depth < 100
), final as
(
    select playerid, yearid, teamid
    from routes
    where playerid = 'clemero02'
    and depth >= 3
)
select case when exists (select * from final) then 'True' else 'False' end as pathexists
from final;


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
), routes(playerid, yearid, teamid, depth) as (
    select playerid, yearid, teamid, 0
    from relevantPlayers
    where playerid = 'garcifr02'
    union all
    select distinct relevantPlayers.playerid, relevantPlayers.yearid, relevantPlayers.teamid, depth+1
    from routes, relevantPlayers
    where routes.yearid = relevantPlayers.yearid
    and routes.teamid = relevantPlayers.teamid
    and depth < 30
), final as
(
    select playerid, yearid, teamid, depth
    from routes
    where playerid = 'leagubr01'
    order by depth
    limit 1
), new_table as
(
    SELECT
        CASE WHEN EXISTS 
        (
            SELECT * FROM final
        )
        THEN (select final.depth from final)
        ELSE 0
    END as pathlength
    from final
)
select *
from new_table;


-- 26 --
with recursive graph(teamA, teamB, depth) as (
    select teamIDwinner, teamIDloser, 0
    from SeriesPost
    where teamIDwinner = 'ARI'
    union all
    select distinct graph.teamB, SeriesPost.teamIDloser, depth + 1
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
)
select count(distinct depth) as count
from graph
where teamA = 'ARI'
and teamB = 'DET';


-- 27 --
with recursive graph(teamA, teamB, depth) as (
    select teamIDwinner, teamIDloser, 1
    from SeriesPost
    where teamIDwinner = 'HOU'
    union all
    select distinct graph.teamB, SeriesPost.teamIDloser, depth + 1
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
    and depth < 4
), winnerTeams as
(
    select teamA as teamid, max(depth) as numHops
    from graph
    group by teamA
), loserTeams as
(
    select teamB as teamid, max(depth) as numHops
    from graph
    group by teamB
), mergedTeams as
(
    select * from winnerTeams
    union
    select * from loserTeams
)
select teamid, max(numHops) as num_hops
from mergedTeams
group by teamid
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
), longestPath as
(
    select teamB as teamid, pathlength
    from graph as graph1
    join
    (
        select max(depth) as pathlength
        from graph
    ) as graph2
    on depth = pathlength
)
select Teams.teamid, Teams.name as teamname, pathlength
from longestPath, Teams
where longestPath.teamid = Teams.teamid
order by Teams.teamid, teamname;


-- 29 --
with recursive relevantTeams as 
(
    select teamIDwinner
    from SeriesPost
    where ties > losses
    group by teamIDwinner
), graph(teamA, teamB, depth) as
(
    select distinct relevantTeams.teamIDwinner, teamIDloser, 1
    from relevantTeams, SeriesPost
    where SeriesPost.teamIDwinner = relevantTeams.teamIDwinner
    union all
    select distinct graph.teamB, SeriesPost.teamIDloser, depth + 1
    from graph, SeriesPost
    where graph.teamB = SeriesPost.teamIDwinner
), shortestPath as
(
    select graph1.teamA as teamid, pathlength
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
select *
from shortestPath;



-- 30 --
