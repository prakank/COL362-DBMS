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