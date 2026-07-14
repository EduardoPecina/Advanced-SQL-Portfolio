-- WINDOW FUNCTIONS
-- 1. Display a ranking of all teams, including their points and current position.
SELECT 
RANK() OVER (ORDER BY 
Points DESC,
GoalDifference DESC,
GoalsFor DESC
) AS Position, Team, Points
FROM Standings;
-- 2. Display a ranking of the top 5 teams in the league.
SELECT *
FROM (SELECT RANK() OVER (ORDER BY 
Points DESC,
GoalDifference DESC,
GoalsFor DESC
) AS Position, Team, Points
FROM Standings
) AS Ranking
WHERE Position <= 5;
-- 3. Display a ranking of the bottom 3 teams in the league.
SELECT *
FROM (SELECT RANK() OVER (ORDER BY 
Points DESC,
GoalDifference DESC,
GoalsFor DESC
) AS Position, Team,
Points FROM Standings
) AS Ranking
ORDER BY Position DESC
LIMIT 3;
-- 4. Display a ranking of all players based on their market value.
SELECT * FROM (SELECT RANK() OVER (ORDER BY MarketValue DESC)
AS Ranking, Player, MarketValue
FROM Players) 
ORDER BY Ranking ASC;
-- 5. Display a ranking of the 10 most valuable players in the league.
SELECT * FROM (SELECT RANK() OVER (ORDER BY MarketValue DESC) AS Ranking, Player, MarketValue
FROM Players
) AS RankedPlayers
WHERE Ranking <= 10;
-- 6. Display a ranking of the top 10 goal scorers.
SELECT *
FROM (SELECT RANK() OVER (ORDER BY Goals DESC) AS Ranking, Player, Goals
FROM Goals
) 
AS RankedGoals
WHERE Ranking <= 10;
-- 7. Display a ranking of the top 10 assist providers.
SELECT *
FROM (SELECT RANK() OVER (ORDER BY Assists DESC) AS Ranking, Player, Assists
FROM Assists
) 
AS RankedAssists
WHERE Ranking <= 10;
-- 8. Display a ranking of players whose market value is above the league average.
-- Average per player
WITH Average AS (SELECT AVG(MarketValue) AS AvgMarketValue FROM Players), 
-- Ranking
RankedPlayers AS (SELECT RANK() OVER (ORDER BY MarketValue DESC) 
AS Ranking, Player, MarketValue
FROM Players)
-- MarketValue > Average 
SELECT Ranking, Player, MarketValue
FROM RankedPlayers
WHERE MarketValue > (SELECT AvgMarketValue FROM Average);
-- 9. Display a ranking of players who scored more goals than the league average.
-- Average per Player
WITH Average AS(SELECT ROUND(AVG(Goals),0) AS GoalsAvg FROM Goals),
-- Rankings      
RankedPlayers AS (SELECT RANK()OVER(ORDER BY Goals DESC) AS Ranking, Player, Goals FROM Goals)
-- Goals > Average       
SELECT Ranking, Player, Goals 
FROM RankedPlayers
WHERE Goals > (SELECT GoalsAvg FROM Average);
-- 10. Display a ranking of players who recorded more assists than the league average.
-- Average per Player
WITH Average AS(SELECT ROUND(AVG(Assists),0) AS AssistsAvg FROM Assists),
-- Rankings      
RankedPlayers AS (SELECT RANK()OVER(ORDER BY Assists DESC) AS Ranking, Player, Assists FROM Assists)
-- Assists > Average       
SELECT Ranking, Player, Assists
FROM RankedPlayers
WHERE Assists > (SELECT AssistsAvg FROM Average);

-- CTEs
-- 11. Display teams with a negative goal difference that still avoided relegation.
WITH Ranking AS (SELECT RANK() OVER (ORDER BY
Points DESC,
GoalDifference DESC,
GoalsFor DESC
) AS Position, Team, GoalDifference
FROM Standings
)
SELECT
Team,
Position,
GoalDifference
FROM Ranking
WHERE GoalDifference < 0
AND Position <= 17;
-- 12. Display players whose combined goals and assists are above the league average.
WITH PlayerStats AS (SELECT
G.Player,
G.Goals,
A.Assists, (G.Goals + A.Assists) AS Contributions
FROM Goals G
JOIN Assists A
ON G.Player = A.Player
),
LeagueAverage AS (SELECT AVG(Contributions) AS AvgContributions
FROM PlayerStats
)
SELECT
Player,
Goals,
Assists,
Contributions
FROM PlayerStats
WHERE Contributions > (SELECT AvgContributions FROM LeagueAverage
)
ORDER BY Contributions DESC;
-- 13. Display players under 25 years old whose market value is above average.
WITH Average AS (SELECT AVG(MarketValue) AS AvgMarketValue
FROM Players)
SELECT
Player,
Age,
MarketValue
FROM Players
WHERE Age < 25
AND MarketValue > (SELECT AvgMarketValue FROM Average)
ORDER BY MarketValue DESC;
-- 14. Display players whose market value is above the average for their position.
WITH PositionAverage AS (SELECT Position,
ROUND(AVG(MarketValue),0) AS AvgMarketValue FROM Players GROUP BY Position)
SELECT
P.Player,
P.Position,
P.MarketValue,
PA.AvgMarketValue
FROM Players P
JOIN PositionAverage PA ON P.Position = PA.Position
WHERE P.MarketValue > PA.AvgMarketValue
ORDER BY P.Position, P.MarketValue DESC;
-- 15. Display teams whose budget is above average but whose league position is outside the Top 10.
WITH AverageBudget AS (SELECT AVG(Budget) AS AvgBudget FROM Teams),
TeamRanking AS (SELECT S.Team, T.Budget, RANK() OVER (ORDER BY
S.Points DESC,
S.GoalDifference DESC,
S.GoalsFor DESC
) AS Position
FROM Standings S
JOIN Teams T ON S.Team = T.Team
)
SELECT
Team,
Budget,
Position
FROM TeamRanking
WHERE Budget > (SELECT AvgBudget FROM AverageBudget)
AND Position > 10
ORDER BY Position;
-- 16. Display players who scored more goals than the average of their own team.
WITH TeamAverage AS (SELECT Team, ROUND(AVG(Goals),0) AS AvgGoals FROM Goals GROUP BY Team)
SELECT G.Player, G.Team, G.Goals, TA.AvgGoals
FROM Goals G
JOIN TeamAverage TA
ON G.Team = TA.Team
WHERE G.Goals > TA.AvgGoals;
-- 17. Display players who recorded more assists than the average of their own team.
WITH TeamAverage AS (SELECT Team, ROUND(AVG(Assists),0) AS AvgAssists FROM Assists GROUP BY Team )
SELECT A.Player, A.Team, A.Assists, TA.AvgAssists 
FROM Assists A
JOIN TeamAverage TA ON A.Team = TA.Team
WHERE A.Assists > TA.AvgAssists
ORDER BY A.Team, A.Assists DESC;
-- 18. Display goalkeepers who recorded more clean sheets than the league average.
WITH LeagueAverage AS (SELECT AVG(CleanSheets) AS AvgCleanSheets FROM CleanSheets)
SELECT Player, Team, CleanSheets 
FROM CleanSheets
WHERE CleanSheets > (SELECT AvgCleanSheets FROM LeagueAverage)
ORDER BY CleanSheets DESC;
-- 19. Display teams that have more points than the league average but a negative goal difference.
WITH LeagueAverage AS (SELECT AVG(Points) AS AvgPoints FROM Standings)
SELECT Team, Points, GoalDifference 
FROM Standings
WHERE Points > (SELECT AvgPoints FROM LeagueAverage)
AND GoalDifference < 0
ORDER BY Points DESC;
-- 20. Display players whose market value is below average but whose goals are above average.
WITH LeagueAverage AS (SELECT AVG(p.MarketValue) AS AvgMarketValue, AVG(g.Goals) AS AvgGoals FROM Players p JOIN Goals g)
SELECT p.Player, p.Team, p.MarketValue, g.Goals 
FROM Players p
JOIN Goals g ON p.Player = g.Player
WHERE p.MarketValue < (SELECT AvgMarketValue FROM LeagueAverage) AND g.Goals > (SELECT AvgGoals
FROM LeagueAverage)
ORDER BY g.Goals DESC;

-- PARTITION BY
-- 21. Display the most valuable player from each team.
WITH RankedPlayers AS (SELECT Player, Team, MarketValue, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY MarketValue DESC) AS rn
FROM Players
)
SELECT Player, Team, MarketValue 
FROM RankedPlayers
WHERE rn = 1
ORDER BY Team ASC;
-- 22. Display the top goal scorer from each team.
WITH RankedScorers AS (SELECT Player, Team, Goals, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Goals DESC) AS rn
FROM Goals
)
SELECT Player, Team, Goals 
FROM RankedScorers
WHERE rn = 1
ORDER BY Team;
-- 23. Display the top assist provider from each team.
WITH RankedAssists AS (SELECT Player, Team, Assists, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Assists DESC) AS rn
FROM Assists
)
SELECT Player, Team, Assists 
FROM RankedAssists
WHERE rn = 1
ORDER BY Team;
-- 24. Display the most valuable player in each position.
WITH RankedPlayers AS (SELECT p.Player, p.Position, p.Team, p.MarketValue, pos.PositionID, ROW_NUMBER() OVER (PARTITION BY p.Position
ORDER BY p.MarketValue DESC) AS rn
FROM Players p
JOIN Positions pos ON p.Position = pos.Position
)
SELECT PositionID, Player, Position, Team, MarketValue 
FROM RankedPlayers
WHERE rn = 1
ORDER BY PositionID ASC;
-- 25. Display the highest goal scorer in each position.
WITH RankedScorers AS (SELECT p.Position, pos.PositionID, g.Player, g.Team, g.Goals, ROW_NUMBER() OVER (PARTITION BY p.Position
ORDER BY g.Goals DESC) AS rn
FROM Goals g
JOIN Players p ON g.Player = p.Player
JOIN Positions pos ON p.Position = pos.Position
)
SELECT PositionID, Position, Player, Team, Goals
FROM RankedScorers
WHERE rn = 1
ORDER BY PositionID ASC;
-- 26. Display the highest assist provider in each position.
WITH RankedAssists AS (SELECT pos.PositionID, p.Position, a.Player, a.Team, a.Assists, RANK() OVER (PARTITION BY p.Position
ORDER BY a.Assists DESC) AS rk
FROM Assists a
JOIN Players p ON a.Player = p.Player
JOIN Positions pos ON p.Position = pos.Position
)
SELECT PositionID, Position, Player, Team, Assists 
FROM RankedAssists
WHERE rk = 1
ORDER BY PositionID ASC;
-- 27. Display the top 3 goal scorers from each team.
WITH RankedScorers AS (SELECT Player, Team, Goals, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Goals DESC) AS rn
FROM Goals
)
SELECT Player, Team, Goals 
FROM RankedScorers
WHERE rn <= 3
ORDER BY Team, Goals DESC;
-- 28. Display the top 3 assist providers from each team.
WITH RankedAssists AS (SELECT Player, Team, Assists, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Assists DESC) AS rn
FROM Assists
)
SELECT Player, Team, Assists 
FROM RankedAssists
WHERE rn <= 3
ORDER BY Team, Assists DESC;
-- 29. Display the top 5 most valuable players in each position.
WITH RankedPlayers AS (SELECT pos.PositionID, p.Player, p.Position, p.Team, p.MarketValue, ROW_NUMBER() OVER (PARTITION BY p.Position
ORDER BY p.MarketValue DESC) AS rn
FROM Players p
JOIN Positions pos ON p.Position = pos.Position
)
SELECT PositionID, Player, Position, Team, MarketValue
FROM RankedPlayers
WHERE rn <= 5
ORDER BY PositionID ASC, MarketValue DESC;
-- 30. Display the top 3 most efficient goalkeepers (clean sheets per match started).
WITH RankedGoalkeepers AS (SELECT Player, Team, Position, Starts, CleanSheets,
CAST(CleanSheets AS DECIMAL(10,2)) / Starts AS Efficiency,
ROW_NUMBER() OVER (ORDER BY CAST(CleanSheets AS DECIMAL(10,2)) / Starts DESC) AS rn
FROM CleanSheets
WHERE Position = 'Goalkeeper'
AND Starts > 0
)
SELECT Player, Team, Starts, CleanSheets, Efficiency 
FROM RankedGoalkeepers
WHERE rn <= 3;

-- CASE + WINDOW FUNCTIONS
-- 31. Classify teams according to their league position:
-- League Champion & Champions League Qualification (Position 1)
-- Champions League Qualification (Positions 2–5)
-- Europa League Qualification (Positions 6–7)
-- Conference League Qualification (Position 8)
-- Mid-Table (Positions 9–17)
-- Relegation Zone (Positions 18–20)
WITH LeagueTable AS (SELECT Team, Points, GoalDifference, RANK() OVER (ORDER BY Points DESC, GoalDifference DESC) AS LeaguePosition
FROM Standings
)
SELECT LeaguePosition, Team, Points, GoalDifference, 
CASE
WHEN LeaguePosition = 1 THEN 'Champion & Champions League'
WHEN LeaguePosition BETWEEN 2 AND 5 THEN 'Champions League'
WHEN LeaguePosition BETWEEN 6 AND 7 THEN 'Europa League'
WHEN LeaguePosition = 8 THEN 'Conference League'
WHEN LeaguePosition BETWEEN 9 AND 17 THEN 'Mid Table'
WHEN LeaguePosition BETWEEN 18 AND 20 THEN 'Relegation Zone'
END AS Classification
FROM LeagueTable
ORDER BY LeaguePosition;
-- 32. Classify players according to their market value:
-- World Class
-- Elite
-- Premium
-- Standard
WITH PlayerRanking AS (SELECT Player, Team, MarketValue, NTILE(4) OVER (ORDER BY MarketValue DESC) AS Tier
FROM Players
)
SELECT Player, Team, 
MarketValue, 
CASE
WHEN Tier = 1 THEN 'World Class'
WHEN Tier = 2 THEN 'Elite'
WHEN Tier = 3 THEN 'Premium'
WHEN Tier = 4 THEN 'Standard'
END AS Classification
FROM PlayerRanking
ORDER BY MarketValue DESC;
-- 33. Classify goal scorers according to their goals:
-- Golden Boot Contender
-- Top Scorer
-- Average Scorer
-- Low Scorer
WITH ScorerRanking AS (SELECT Player, Team, Goals, NTILE(4) OVER (ORDER BY Goals DESC) AS Tier
FROM Goals
)
SELECT Player, Team, Goals,
CASE
WHEN Tier = 1 THEN 'Golden Boot Contender'
WHEN Tier = 2 THEN 'Top Scorer'
WHEN Tier = 3 THEN 'Average Scorer'
WHEN Tier = 4 THEN 'Low Scorer'
END AS Classification
FROM ScorerRanking
ORDER BY Goals DESC;
-- 34. Classify goalkeepers according to their clean sheets:
-- Elite Goalkeeper
-- Reliable Goalkeeper
-- Standard Goalkeeper
WITH GoalkeeperRanking AS (SELECT Player, Team, CleanSheets, NTILE(3) OVER (ORDER BY CleanSheets DESC) AS Tier
FROM CleanSheets
WHERE Position = 'Goalkeeper'
)
SELECT Player, Team, CleanSheets,
CASE
WHEN Tier = 1 THEN 'Elite Goalkeeper'
WHEN Tier = 2 THEN 'Reliable Goalkeeper'
WHEN Tier = 3 THEN 'Standard Goalkeeper'
END AS Classification
FROM GoalkeeperRanking
ORDER BY CleanSheets DESC;
-- 35. Classify teams according to their goal difference:
-- Outstanding
-- Positive
-- Neutral
-- Negative
WITH TeamRanking AS (SELECT Team, GoalDifference, NTILE(4) OVER (ORDER BY GoalDifference DESC) AS Tier
FROM Standings
)
SELECT Team, GoalDifference,
CASE
WHEN Tier = 1 THEN 'Outstanding'
WHEN Tier = 2 THEN 'Positive'
WHEN Tier = 3 THEN 'Neutral'
WHEN Tier = 4 THEN 'Negative'
END AS Classification
FROM TeamRanking
ORDER BY GoalDifference DESC;

-- MONEYBALL
-- 36. Create an indicator called OffensiveContribution:
-- Goals + Assists
-- and rank all players.
WITH OffensiveStats AS (SELECT g.Player, g.Team, g.Goals, a.Assists, (g.Goals + a.Assists) AS OffensiveContribution
FROM Goals g
JOIN Assists a ON g.Player = a.Player
)
SELECT Player, Team, Goals, Assists, OffensiveContribution, DENSE_RANK() OVER (ORDER BY OffensiveContribution DESC) AS PlayerRank
FROM OffensiveStats
ORDER BY PlayerRank;
-- 37. Create an indicator called ValuePerMillion
-- (Goals + Assists) / MarketValue
-- and identify the 20 most efficient players.
WITH PlayerEfficiency AS (SELECT p.Player, p.Team, p.MarketValue,
COALESCE(g.Goals,0) AS Goals,
COALESCE(a.Assists,0) AS Assists,
COALESCE(g.Goals,0) + COALESCE(a.Assists,0) AS OffensiveContribution,
ROUND((COALESCE(g.Goals,0) + COALESCE(a.Assists,0)) / (p.MarketValue / 1000000.0),4) AS
ValuePerMillion
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player
WHERE p.MarketValue > 0),
RankedPlayers AS (SELECT *,RANK() OVER (ORDER BY ValuePerMillion DESC) AS EfficiencyRank
FROM PlayerEfficiency
WHERE OffensiveContribution >= 10
)
SELECT *
FROM RankedPlayers
WHERE EfficiencyRank <= 20
ORDER BY EfficiencyRank;

-- 38. Identify the most undervalued players in the league (low market value, high output).
WITH PlayerImpact AS (SELECT p.Player, p.Team, p.Position, p.MarketValue,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,
COALESCE(cs.CleanSheets, 0) AS CleanSheets,
ROUND((COALESCE(g.Goals, 0) * 1.0 + COALESCE(a.Assists, 0) * 0.75 + COALESCE(cs.CleanSheets, 0) *
0.50),2) AS ImpactScore,
ROUND((COALESCE(g.Goals, 0) * 1.0 + COALESCE(a.Assists, 0) * 0.75 + COALESCE(cs.CleanSheets, 0) * 0.50) / (p.MarketValue / 1000000.0),4) AS UndervaluationScore
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player
LEFT JOIN CleanSheets cs ON p.Player = cs.Player
WHERE p.MarketValue > 0),
RankedPlayers AS (SELECT *, RANK() OVER (ORDER BY UndervaluationScore DESC) AS UndervaluationRank
FROM PlayerImpact
WHERE ImpactScore >= 10)
SELECT UndervaluationRank, Player, Team, Position, MarketValue, Goals, Assists, CleanSheets, ImpactScore, UndervaluationScore
FROM RankedPlayers
WHERE UndervaluationRank <= 20
ORDER BY UndervaluationRank;
-- 39. Identify the most overrated players in the league (high market value, low output).
WITH PlayerImpact AS (SELECT p.Player, p.Team, p.Position, p.MarketValue,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,
COALESCE(cs.CleanSheets, 0) AS CleanSheets,
ROUND(
COALESCE(g.Goals, 0) * 1.0 +
COALESCE(a.Assists, 0) * 0.75 +
COALESCE(cs.CleanSheets, 0) * 0.50, 2) AS ImpactScore
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player
LEFT JOIN CleanSheets cs ON p.Player = cs.Player
WHERE p.MarketValue > 0),
RankedPlayers AS (SELECT *, ROUND((MarketValue / 1000000.0) / NULLIF(ImpactScore, 0),4) AS OvervaluationScore, RANK() OVER (ORDER BY (MarketValue / 1000000.0) / NULLIF(ImpactScore, 0) DESC) AS OvervaluationRank
FROM PlayerImpact
WHERE ImpactScore >= 5)
SELECT OvervaluationRank, Player, Team, Position, MarketValue, Goals, Assists, CleanSheets, ImpactScore, OvervaluationScore,
CASE
WHEN OvervaluationRank <= 5 THEN 'Highly Overvalued'
WHEN OvervaluationRank <= 10 THEN 'Overvalued'
ELSE 'Slightly Overvalued'
END AS Category
FROM RankedPlayers
WHERE OvervaluationRank <= 20
ORDER BY OvervaluationRank;
-- 40. Determine the player who generates the highest offensive contribution per monetary unit invested.
WITH PlayerContribution AS (SELECT p.Player, p.Team, p.Position, p.MarketValue,
COALESCE(g.Goals,0) AS Goals,
COALESCE(a.Assists,0) AS Assists,
COALESCE(g.Goals,0) + COALESCE(a.Assists,0) AS OffensiveContribution,
ROUND((COALESCE(g.Goals,0) + COALESCE(a.Assists,0)) / (p.MarketValue / 1000000.0),4) AS ContributionPerMillion
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player
WHERE p.MarketValue > 0)
SELECT Player, Team, Position, MarketValue, Goals, Assists, OffensiveContribution, ContributionPerMillion
FROM PlayerContribution
WHERE OffensiveContribution >= 10
ORDER BY ContributionPerMillion DESC
LIMIT 10;
-- 41. Display the internal ranking of each team based on market value.
SELECT Player, Team, Position, MarketValue, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY MarketValue DESC) AS TeamRank
FROM Players
ORDER BY Team, TeamRank;
-- 42. Display the internal ranking of each team based on goals scored.
SELECT Player, Position, Team, Goals, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Goals DESC) AS TeamGoalRank
FROM Goals
ORDER BY Team, TeamGoalRank;
-- 43. Display the internal ranking of each team based on assists.
SELECT Player, Team, Assists, ROW_NUMBER() OVER (PARTITION BY Team ORDER BY Assists DESC) AS TeamAssistRank
FROM Assists
ORDER BY Team, TeamAssistRank;
-- 44. Display the internal ranking of each position based on market value.
SELECT Player, Position, Team, MarketValue, RANK() OVER (PARTITION BY Position ORDER BY MarketValue DESC) AS PositionRank
FROM Players
ORDER BY Position, PositionRank;
-- 45. Display the internal ranking of each position based on goals scored.
SELECT pos.PositionID, g.Player, p.Position, g.Team, g.Goals, DENSE_RANK() OVER (PARTITION BY p.Position
ORDER BY g.Goals DESC) AS PositionGoalRank
FROM Goals g
JOIN Players p ON g.Player = p.Player
JOIN Positions pos ON p.Position = pos.Position
ORDER BY pos.PositionID, PositionGoalRank;
-- 46. Display the internal ranking of each position based on assists.
SELECT pos.PositionID, a.Player, p.Position, a.Team, a.Assists, RANK() OVER (PARTITION BY p.Position ORDER BY a.Assists DESC) AS PositionAssistRank
FROM Assists a
JOIN Players p ON a.Player = p.Player
JOIN Positions pos ON p.Position = pos.Position
ORDER BY pos.PositionID, PositionAssistRank;
-- 47. Display the internal ranking of each team based on:
-- Goals + Assists
WITH OffensiveStats AS (SELECT p.Player, p.Team, p.Position,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,
COALESCE(g.Goals, 0) + COALESCE(a.Assists, 0) AS OffensiveContribution
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player)
SELECT Player, Team, Position, Goals, Assists, OffensiveContribution, RANK() OVER (PARTITION BY Team ORDER BY OffensiveContribution DESC) AS TeamRank
FROM OffensiveStats
ORDER BY Team, TeamRank;
-- 48. Display the top 5 players from each team based on offensive contribution.
WITH OffensiveStats AS (SELECT p.Player, p.Team, p.Position,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,
COALESCE(g.Goals, 0) + COALESCE(a.Assists, 0) AS OffensiveContribution
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player),
RankedPlayers AS (SELECT *, DENSE_RANK() OVER (PARTITION BY Team ORDER BY OffensiveContribution DESC) AS TeamRank
FROM OffensiveStats)
SELECT Player, Team, Position, Goals, Assists, OffensiveContribution, TeamRank
FROM RankedPlayers
WHERE TeamRank <= 5
ORDER BY Team, TeamRank;
-- 49. Display players whose offensive contribution is above their team's average.
WITH OffensiveStats AS (SELECT p.Player, p.Team, p.Position,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,
COALESCE(g.Goals, 0) + COALESCE(a.Assists, 0) AS OffensiveContribution
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player),
TeamStats AS (SELECT *, AVG(OffensiveContribution) OVER (PARTITION BY Team) AS TeamAverage
FROM OffensiveStats)
SELECT Player, Team, Position, Goals, Assists, OffensiveContribution, ROUND(TeamAverage, 2) AS TeamAverage
FROM TeamStats
WHERE OffensiveContribution > TeamAverage
ORDER BY Team, OffensiveContribution DESC;

-- 50. Final Exercise:
-- Build a table using:

-- CTE
-- DENSE_RANK()
-- RANK()
-- PARTITION BY
-- CASE

-- Including at least 3 calculated metrics.
-- The table must display:

-- Player
-- Team
-- Position
-- Goals
-- Assists
-- Market Value
-- Offensive Contribution
-- Value Per Million
-- League Ranking
-- Team Ranking

WITH PlayerStats AS (SELECT p.Player, p.Team, p.Position, p.MarketValue,
COALESCE(g.Goals, 0) AS Goals,
COALESCE(a.Assists, 0) AS Assists,                     
-- Métrica 1
COALESCE(g.Goals, 0) +
COALESCE(a.Assists, 0) AS OffensiveContribution,              
-- Métrica 2
ROUND((COALESCE(g.Goals, 0) + COALESCE(a.Assists, 0)) / (p.MarketValue / 1000000.0),4) AS ValuePerMillion
FROM Players p
LEFT JOIN Goals g ON p.Player = g.Player
LEFT JOIN Assists a ON p.Player = a.Player
WHERE p.MarketValue > 0),
-- Ranking Liga
RankedPlayers AS (SELECT *, DENSE_RANK() OVER (ORDER BY OffensiveContribution DESC) AS LeagueRanking,
-- Ranking interno Equipo
RANK() OVER (PARTITION BY Team ORDER BY OffensiveContribution DESC) AS TeamRanking,
-- Ranking interno Posición
RANK() OVER (PARTITION BY Position ORDER BY OffensiveContribution DESC) AS PositionRanking,
-- Métrica 3
AVG(OffensiveContribution) OVER (PARTITION BY Team) AS TeamAverageContribution
FROM PlayerStats)
SELECT Player, Team, Position, Goals, Assists, MarketValue, OffensiveContribution, ValuePerMillion, LeagueRanking, TeamRanking, PositionRanking,
CASE
WHEN LeagueRanking <= 10 THEN 'Elite'
WHEN LeagueRanking <= 25 THEN 'Star'
WHEN LeagueRanking <= 50 THEN 'Starter'
ELSE 'Squad Player'
END AS PlayerCategory
FROM RankedPlayers
ORDER BY LeagueRanking;
