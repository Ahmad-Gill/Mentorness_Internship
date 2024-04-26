CREATE TABLE dbo.player_detail (
    P_ID INT,
    PName NVARCHAR(100),
    L1_Status INT,
    L2_Status INT,
    L1_Code NVARCHAR(50),
    L2_Code NVARCHAR(50)
);

 
-- import the file
BULK INSERT dbo.player_detail
FROM "C:\Users\mahma\Downloads\player_details.csv"
WITH
(
        FORMAT='CSV',
        FIRSTROW=2
);



CREATE TABLE dbo.level_details (
    P_ID INT,
    Dev_ID NVARCHAR(50),
    TimeStamp DATETIME,
    Stages_crossed INT,
    Level INT,
    Difficulty NVARCHAR(50),
    Kill_Count INT,
    Headshots_Count INT,
    Score INT,
    Lives_Earned INT
);


BULK INSERT dbo.level_details
FROM "D:\INTERSHIPS\Internship_Mentorness\level_details2.csv"
WITH
(
        FORMAT='CSV',
        FIRSTROW=2
);

SELECT * FROM player_detail;
SELECT * FROM level_details;


-- Question No.1 
SELECT pd.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty
FROM player_detail pd
INNER JOIN level_details ld ON pd.P_ID = ld.P_ID
WHERE ld.Level = 0;

--Question no.2
SELECT ld.Level AS L1_Code, AVG(ld.Kill_Count) AS Avg_Kill_Count
FROM dbo.level_details ld
JOIN dbo.player_detail pd ON ld.P_ID = pd.P_ID
WHERE ld.Lives_Earned = 2
  AND ld.Stages_crossed >= 3
GROUP BY ld.Level;

-- Question NO.3
SELECT ld.Difficulty AS Difficulty_Level, SUM(ld.Stages_crossed) AS Total_Stages_Crossed
FROM dbo.level_details ld
JOIN dbo.player_detail pd ON ld.P_ID = pd.P_ID
WHERE pd.L2_Status = 1 
  AND ld.Dev_ID LIKE 'zm_series%' 
GROUP BY ld.Difficulty
ORDER BY Total_Stages_Crossed DESC;

--Question NO.4
SELECT P_ID, COUNT(DISTINCT CAST(TimeStamp AS DATE)) AS Unique_Dates_Played
FROM dbo.level_details
GROUP BY P_ID
HAVING COUNT(DISTINCT CAST(TimeStamp AS DATE)) > 1;

--Question NO.5
WITH Medium_Avg_Kill_Count AS (
    SELECT AVG(Kill_Count) AS Avg_Kill_Count
    FROM dbo.level_details
    WHERE Difficulty = 'Medium'
),
Player_Level_Kill_Count AS (
    SELECT P_ID, Level, SUM(Kill_Count) AS Total_Kill_Count
    FROM dbo.level_details ld
    CROSS JOIN Medium_Avg_Kill_Count ma
    WHERE ld.Difficulty = 'Medium' AND ld.Kill_Count > ma.Avg_Kill_Count
    GROUP BY P_ID, Level
)
SELECT P_ID, Level, Total_Kill_Count
FROM Player_Level_Kill_Count;

--Question NO.6

SELECT ld.Level, pd.L1_Code, SUM(ld.Lives_Earned) AS Total_Lives_Earned
FROM dbo.player_detail pd
JOIN dbo.level_details ld ON pd.P_ID = ld.P_ID
WHERE ld.Level <> 0
GROUP BY ld.Level, pd.L1_Code
ORDER BY ld.Level ASC;



-- Question nO.7
WITH RankedScores AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score ASC) AS Rank
    FROM dbo.level_details
)
SELECT Dev_ID, Score, Difficulty
FROM RankedScores
WHERE Rank <= 3;

--Question NO.8
SELECT Dev_ID, MIN(TimeStamp) AS first_login
FROM dbo.level_details
GROUP BY Dev_ID;

--Question NO.9
WITH RankedScores AS (
    SELECT *,
           RANK() OVER (PARTITION BY Difficulty ORDER BY Score ASC) AS Rank
    FROM dbo.level_details
)
SELECT Dev_ID, Score, Difficulty
FROM RankedScores
WHERE Rank <= 5;

--Question NO.10
WITH FirstLogin AS (
    SELECT P_ID, Dev_ID, MIN(TimeStamp) AS first_login
    FROM dbo.level_details
    GROUP BY P_ID, Dev_ID
)
SELECT P_ID, Dev_ID, first_login
FROM FirstLogin;

--Question  NO.11
-- Part A
SELECT P_ID, TimeStamp, Kill_Count,
       SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS total_kill_counts
FROM dbo.level_details;


--Part B
SELECT ld1.P_ID, ld1.TimeStamp, ld1.Kill_Count,
       SUM(ld2.Kill_Count) AS total_kill_counts
FROM dbo.level_details ld1
JOIN dbo.level_details ld2 ON ld1.P_ID = ld2.P_ID AND ld1.TimeStamp >= ld2.TimeStamp
GROUP BY ld1.P_ID, ld1.TimeStamp, ld1.Kill_Count;


-- Question NO.12
WITH CumulativeSum AS (
    SELECT P_ID, TimeStamp, Stages_crossed,
           SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS cumulative_sum
    FROM dbo.level_details
)
SELECT P_ID, TimeStamp, Stages_crossed, cumulative_sum
FROM CumulativeSum;

--Question 13
WITH RankedScores AS (
    SELECT Dev_ID, P_ID, SUM(Score) AS total_score,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
    FROM dbo.level_details
    GROUP BY Dev_ID, P_ID
)
SELECT Dev_ID, P_ID, total_score
FROM RankedScores
WHERE Rank <= 3;

--Question NO.14
WITH PlayerAvgScore AS (
    SELECT P_ID, AVG(Score) AS avg_score
    FROM dbo.level_details
    GROUP BY P_ID
)
SELECT P_ID, SUM(Score) AS total_score
FROM dbo.level_details
GROUP BY P_ID
HAVING SUM(Score) > (0.5 * (SELECT avg_score FROM PlayerAvgScore WHERE PlayerAvgScore.P_ID = dbo.level_details.P_ID));

--Question NO15
CREATE PROCEDURE GetTopHeadshotsCount
    @n INT
AS
BEGIN
    WITH RankedHeadshots AS (
        SELECT Dev_ID, Headshots_Count, Difficulty,
               ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_Count ASC) AS Rank
        FROM dbo.level_details
    )
    SELECT Dev_ID, Headshots_Count, Difficulty
    FROM RankedHeadshots
    WHERE Rank <= @n;
END;









