# endeavor-database

Scripts to create the Endeavor database. Currently, only contains SqlServer, but MySql and PostgreSQL will be added soon.

- endeavor.sql - The database creation scripts
- example.sql - Creates a sample workflow with a StartStep, Manualstep, and EndStep. ( see [endeavor-steps](https://github.com/keryhe/endeavor-steps) for a list of all the available 'built-in' steps)

## Creating steps
When creating a new step ( see [endeavor-steps](https://github.com/keryhe/endeavor-steps) ), a new table is needed to store the step data and a stored procedure is needed for retrieving the data. The following examples are for SqlServer.

1. Create a table for the step. for example: `SomethingStep`. Below is the create table script with the required fields. Add any other columns you need for your step.

    ```sql
    CREATE TABLE SomethingStep
    (
	    ID INT IDENTITY(1,1) PRIMARY KEY,
	    StepID INT NOT NULL FOREIGN KEY REFERENCES Step(ID),
	    DateCreated DATETIME NOT NULL,
	    DateModified DATETIME NOT NULL
    )
    ```

2. Create a stored procedure. Use the script below as a template. The stored procedure name is important. If you named your step and table `SomethingStep`, the the stored procedure should be called `GetSomethingStep`. Add any additional fields you want to return to the select query.

    ```sql
    CREATE PROCEDURE GetSomethingStep
    @StepID INT
    AS
    BEGIN
	    SELECT ss.ID, ss.StepID, s.WorkflowID, s.Name, s.Description, s.StepType, s.DateCreated, s.DateModified
	    FROM SomethingStep ss 
        INNER JOIN Step s ON s.ID = ss.StepID
	    WHERE ss.StepID = @StepID
    END
    ```
   
