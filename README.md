# HaveIBeenPwned2MSSQL
This is a script to take JSON files exported from HaveIBeenPwned and feed the data into a set of Microsoft SQL tables.

## Directions
1. Use this with Microsoft SQL Express and SQL Server Management Studio to query data from HaveIBeenPwned.com using SQL. 
2. Obtain a JSON file from HaveIBeenPwned. You'll need to have a registered domain in order to do this. 
3. Open the script with VSCode, change the variables at top and then execute. 
4. The script will create the appropriate database tables and begin injesting the data. 
5. You can always run this script to import new data into the tables. You can also add extra domains. 


## Why I created this. 
I love writing SQL queries to search datasets and I feel this enables me to search breach data from HaveIBeenPwned
in a way that I'm comfortable with. Plus I wanted to keep myself up to speed with SQL and interfacing it with 
Powershell. I'm making this available publically with the hopes that some may find it useful. Of course I can grant
no warranties. 



