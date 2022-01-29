# HaveIBeenPwned2MSSQL.ps1
# HaveIBeenPwned.com JSON to Microsoft SQL DB Importer
# by Robert Hollingshead
# roberthollingshead.net (github.com/0xF21D)

#Requires -Modules SQLServer

# This is quick and dirty. It establishes three tables in a SQL database if they don't exist already
# and then imports the data from the JSON. 

# The tables are:
# BreachData = Metadata about the breaches. 
# DataClasses = List of dataclasses for each breach. 
# BreachUser = Each pwned user listed by breach name. 

# You'll need to indicate your SQL setup here. 
# I use a database named OSINT that my regular account has full access to.
# This is what you see below if you have not changed any variables. 

$ServerInstance = 'localhost\SQLExpress'
$Database = 'OSINT'

# Finally the JSON path is the file you saved from HaveIBeenPwned.com. 

$JSONPath = ".\pwned.json"

# Everything below should work as of 1/28/2022. 

$InputFile = Get-Content -Path $JSONPath
[array]$PwndJson = ConvertFrom-Json -InputObject $InputFile
Remove-Variable InputFile

# See if we need to create tables. 

# Does the Breach table exist? If not create it. This table contains breach metadata.
Try 
{ 
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT TOP 1 Name FROM dbo.Breach" -ErrorAction Stop
}
Catch 
{ 
    $Query = 
    "
        BEGIN TRANSACTION GO
        CREATE TABLE [dbo].[Breach](
            [Title] [varchar](max) NULL,
            [Name] [varchar](max) NULL,
            [Domain] [varchar](max) NULL,
            [BreachDate] [date] NULL,
            [AddedDate] [datetime] NULL,
            [ModifiedDate] [datetime] NULL,
            [PwnCount] [bigint] NULL,
            [Description] [varchar](max) NULL,
            [IsVerified] [bit] NULL,
            [IsFabricated] [bit] NULL,
            [IsSensitive] [bit] NULL,
            [IsActive] [bit] NULL,
            [IsRetired] [bit] NULL,
            [IsSpamList] [bit] NULL,
            [IsMalware] [bit] NULL
        )
        COMMIT
    "
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query $Query
}

# Does the DataClasses table exist? If not create it. This table contains data classes for each breach. 
Try 
{ 
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT TOP 1 Name FROM dbo.DataClasses" -ErrorAction Stop
}
Catch 
{
    $Query = 
    "
        BEGIN TRANSACTION GO
        CREATE TABLE [dbo].[DataClasses](
            [Name] [varchar](max) NULL,
            [DataClass] [varchar](max) NULL
        ) 
        COMMIT
    "
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query $Query
}

# Does the BreachUser table exist? If not create it. This maps breached users to their breaches. 
Try 
{ 
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT TOP 1 Alias FROM dbo.BreachUser" -ErrorAction Stop
}
Catch 
{
    $Query = 
    "
        BEGIN TRANSACTION GO
        CREATE TABLE [dbo].[BreachUser](
            [Domain] [varchar](50) NULL,
            [Alias] [varchar](255) NULL,
            [BreachName] [varchar](max) NULL
        ) 
        COMMIT
    "
    Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query $Query
}

# Let's go through the JSON data we loaded and look at each user.
ForEach ($Alias in $PwndJson.BreachSearchResults) 
{
    # Step through each breach for the user.
    ForEach ($Breach in $Alias.Breaches) 
    {
        # Does this breach exist in the Breach table? If not create it.
        If ((Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT DISTINCT Name FROM dbo.Breach WHERE Name = '$($Breach.Name)'").count -eq 0) 
        {
            # Convert the label and description to base64 to deal with special characters. 
            $Query = 
            "
                INSERT INTO dbo.Breach
                VALUES('$([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Breach.Title)))',
                '$($Breach.Name)',
                '$($Breach.Domain)',
                '$($Breach.BreachDate)',
                '$($Breach.AddedDate)',
                '$($Breach.ModifiedDate)',
                '$($Breach.PwnCount)',
                '$([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Breach.Description)))',
                '$($Breach.IsVerified)',
                '$($Breach.IsFabricated)',
                '$($Breach.IsSensitive)',
                '$($Breach.IsActive)',
                '$($Breach.IsRetired)',
                '$($Breach.IsSpamList)',
                '$($Breach.IsMalware)')
            "

            Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query $Query

            # We're going to assume that we also need to put the data classes into the DataClasses table.
            # Going to remove apostrophes from the Class name string since their absence doesn't matter.
            # I'm lazy, change it to use base64 encoding if you want. 
            ForEach ($ClassName in $Breach.DataClasses) 
            {
                $Query = 
                "
                    INSERT INTO dbo.DataClasses
                    VALUES('$($Breach.Name)',
                    '$($ClassName.Replace("'",''))')
                "
                
                Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query $Query
            }
        }

        # Finally does this user show up in the BreachUser table for this breach? If not put them in.
        If ((Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT DISTINCT Alias FROM dbo.BreachUser WHERE Alias = '$($Alias.Alias)' and Domain = '$($Alias.DomainName)' and BreachName = '$($Breach.Name)'").count -eq 0) 
        {
            Invoke-SQLCmd -ServerInstance $ServerInstance -Database $Database -Query "INSERT INTO dbo.BreachUser VALUES('$($Alias.DomainName)','$($Alias.Alias)','$($Breach.Name)')"
        }
    }

}
