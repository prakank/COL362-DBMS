insert into People (playerID, nameFirst, nameLast)
SELECT 'dunphil02', 'Phil', 'Dunphy'
FROM (VALUES ('dunphil02', 'Phil', 'Dunphy')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'dunphil02'
)
UNION
SELECT 'tuckcam01', 'Cameron', 'Tucker'
FROM (VALUES ('tuckcam01', 'Cameron', 'Tucker')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'tuckcam01'
)
UNION
SELECT 'scottm02', 'Michael', 'Scott'
FROM (VALUES ('scottm02', 'Michael', 'Scott')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'scottm02'
)
UNION
SELECT 'waltjoe', 'Joe', 'Walt'
FROM (VALUES ('waltjoe', 'Joe', 'Walt')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'waltjoe'
)
UNION
SELECT 'adamswi01', 'Willie', 'Adams'
FROM (VALUES ('adamswi01', 'Willie', 'Adams')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'adamswi01'
)
UNION
SELECT 'yostne01','Ned', 'Yost'
FROM (VALUES ('yostne01','Ned', 'Yost')) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM People 
  WHERE playerID = 'yostne01'
);

insert into AwardsPlayers (playerID, awardID, yearID, lgID, tie, notes)
SELECT 'dunphil02', 'Best Baseman', 2014, '', TRUE, NULL
FROM (VALUES ('dunphil02', 'Best Baseman', 2014, '', TRUE, NULL)) AS tmp
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
FROM (VALUES ('tuckcam01', 'Best Baseman', 2014, '', TRUE, NULL)) AS tmp
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
FROM (VALUES ('scottm02', 'ALCS MVP', 2015, 'AA', FALSE, NULL)) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'scottm02'
  and awardID = 'ALCS MVP'
  and yearID = 2015
  and lgID = 'AA'
)
UNION
SELECT 'waltjoe', 'Triple Crown', 2016, '', NULL, NULL
FROM (VALUES ('waltjoe', 'Triple Crown', 2016, '', NULL, NULL)) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'waltjoe'
  and awardID = 'Triple Crown'
  and yearID = 2016
  and lgID = ''
)
UNION
SELECT 'adamswi01', 'Gold Glove', 2017, '', FALSE, NULL
FROM (VALUES ('adamswi01', 'Gold Glove', 2017, '', FALSE, NULL)) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'adamswi01'
  and awardID = 'Gold Glove'
  and yearID = 2017
  and lgID = ''
)
UNION
SELECT 'yostne01', 'ALCS MVP', 2017, '', NULL, NULL
FROM (VALUES ('yostne01', 'ALCS MVP', 2017, '', NULL, NULL)) AS tmp
WHERE NOT EXISTS (
  SELECT 1
  FROM AwardsPlayers
  WHERE playerID = 'yostne01'
  and awardID = 'ALCS MVP'
  and yearID = 2017
  and lgID = ''
);