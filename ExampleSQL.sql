-- This query combines all three tables.

SELECT

BU.Domain,
BU.Alias,
BU.BreachName,
BN.[Label],
BN.[Name],
BN.Domain,
BN.BreachDate,
BN.PwnCount,
BN.IsVerified,
BN.IsFabricated,
BN.IsSensitive,
BN.IsActive,
BN.IsRetired,
BN.IsSpamList,
BN.IsMalware,
DC.*

FROM dbo.BreachUser BU

LEFT JOIN (SELECT *,CAST(CAST(Title AS XML).value('.','varbinary(max)') AS NVARCHAR(max)) AS [Label] FROM dbo.Breach) BN ON BU.BreachName=BN.[Name]
LEFT JOIN (SELECT * FROM dbo.DataClasses) DC ON BN.[Name]=DC.[Name]

-- This query retrieves the breach metadata. 
-- Note that the Title and the Description are stored as base64 encoded and must
-- therefore be decoded when displayed.

SELECT 

[Name],
CAST(CAST(Title AS XML).value('.','varbinary(max)') AS NVARCHAR(max)) AS [Label],
Domain,
PwnCount,
BreachDate,
AddedDate,
ModifiedDate,
CAST(CAST([Description] AS XML).value('.','varbinary(max)') AS NVARCHAR(max)) AS FullDescription

FROM dbo.Breach
