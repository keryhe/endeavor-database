/* 
	TABLES
*/

CREATE TABLE Workflow
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	Name				VARCHAR(64)			NOT NULL,
	Description			VARCHAR(256),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

CREATE TABLE Step
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	WorkflowID			INT					NOT NULL			FOREIGN KEY REFERENCES Workflow(ID),
	Name				VARCHAR(64)			NOT NULL,
	Description			VARCHAR(256),
	StepType			VARCHAR(64)			NOT NULL,
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL,
	CONSTRAINT 			uc_StepName 		UNIQUE 				(WorkflowID, Name)
)
GO

CREATE TABLE StepLink
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	SourceID			INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	DestinationID		INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	ReleaseValue		VARCHAR(256),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL,
	CONSTRAINT 			uc_StepLink 		UNIQUE 				(SourceID, DestinationID)
)
GO

CREATE TABLE Task
(
	ID					BIGINT				IDENTITY(1,1)		PRIMARY KEY,
	ParentID			BIGINT									FOREIGN KEY REFERENCES Task(ID),
	StepID				INT										FOREIGN KEY REFERENCES Step(ID),
	StatusValue			INT,
	ReleaseValue		VARCHAR(256),
	TaskData			NVARCHAR(MAX),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

ALTER TABLE Task ADD CONSTRAINT [Task Data should be formatted as JSON] CHECK (ISJSON(TaskData)=1)
GO

CREATE TABLE TaskHistory
(
	ID					BIGINT				IDENTITY(1,1)		PRIMARY KEY,
	TaskID				BIGINT				NOT NULL			FOREIGN KEY REFERENCES Task(ID),
	StepID				INT										FOREIGN KEY REFERENCES Step(ID),
	StatusValue			INT,
	ReleaseValue		VARCHAR(256),
	TaskData			NVARCHAR(MAX),
	DateCreated			DATETIME			NOT NULL,
)
GO

ALTER TABLE TaskHistory ADD CONSTRAINT [Task History Data should be formatted as JSON] CHECK (ISJSON(TaskData)=1)
GO

CREATE TABLE StartStep
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	StepID				INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

CREATE TABLE DecisionStep 
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	StepID				INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	Condition			VARCHAR(256)		NOT NULL,
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

CREATE TABLE ManualStep
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	StepID				INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

CREATE TABLE EndStep
(
	ID					INT					IDENTITY(1,1)		PRIMARY KEY,
	StepID				INT					NOT NULL			FOREIGN KEY REFERENCES Step(ID),
	DateCreated			DATETIME			NOT NULL,
	DateModified		DATETIME			NOT NULL
)
GO

/* 
	TRIGGERS
*/

CREATE TRIGGER SetTaskHistory ON Task
AFTER INSERT, UPDATE
AS
BEGIN
	INSERT INTO TaskHistory (TaskID, StepID, StatusValue, ReleaseValue, TaskData, DateCreated) 
		SELECT ID, StepID, StatusValue, ReleaseValue, TaskData, GETDATE() FROM INSERTED
END
GO

/* 
	STORED PROCEDURES
*/

CREATE PROCEDURE StartWorkflow
@WorkflowID 	INT,
@ParentID 		BIGINT
AS
BEGIN
	DECLARE @CreatedDate DATETIME = GETDATE()
	DECLARE @StepID INT

	SELECT @StepID = s.ID from StartStep ss
	INNER JOIN Step s ON s.ID = ss.StepID
	WHERE s.WorkflowID = @WorkflowID

	INSERT INTO Task (ParentID, StepID, StatusValue, DateCreated, DateModified)
	VALUES (@ParentID, @StepID, 0, @CreatedDate, @CreatedDate)
END
GO

CREATE PROCEDURE ReleaseTask
@TaskID 		BIGINT,
@ReleaseValue 	VARCHAR(256),
@TaskData 		VARCHAR(MAX)
AS
BEGIN
	BEGIN TRANSACTION

	UPDATE Task SET StatusValue = 4, ReleaseValue = @ReleaseValue, TaskData = @TaskData 
	WHERE ID = @TaskID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK
		RAISERROR('Error Updating release value and/or task data.', 16, 1)
		RETURN
	END

	DECLARE @NextStepID BIGINT

	SELECT @NextStepID = sl.DestinationID FROM Task t
	INNER JOIN StepLink sl ON t.StepID = sl.SourceID
	WHERE t.ID = @TaskID AND ((sl.ReleaseValue IS NULL AND t.ReleaseValue IS NULL) OR (t.ReleaseValue IS NOT NULL AND t.ReleaseValue = sl.ReleaseValue))

	IF @NextStepID IS NOT NULL
	BEGIN
		UPDATE Task SET StepID = @NextStepID, StatusValue = 0 
		WHERE ID = @TaskID
	END

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK
		RAISERROR('Error releasing task.', 16, 1)
		RETURN
	END

	SELECT @NextStepID AS ID

	COMMIT
END
GO

CREATE PROCEDURE GetTasksByStatus
@Status INT
AS
BEGIN
	SELECT t.ID, t.StepID, s.StepType FROM Task t
	INNER JOIN Step s ON s.ID = t.StepID
	WHERE t.StatusValue = @Status
END
GO

CREATE PROCEDURE GetStartStep
@StepID INT
AS
BEGIN
	SELECT ss.ID, ss.StepID, s.WorkflowID, s.Name, s.Description, s.StepType, s.DateCreated, s.DateModified
	FROM StartStep ss 
    INNER JOIN Step s ON s.ID = ss.StepID
	WHERE ss.StepID = @StepID
END
GO

CREATE PROCEDURE GetDecisionStep
@StepID INT
AS
BEGIN
	SELECT ds.ID, ds.StepID, ds.Condition, s.WorkflowID, s.Name, s.Description, s.StepType
	FROM DecisionStep ds 
    INNER JOIN Step s ON s.ID = ds.StepID
	WHERE ds.StepID = @StepID
END
GO

CREATE PROCEDURE GetManualStep
@StepID INT
AS
BEGIN
	SELECT ms.ID, ms.StepID, s.WorkflowID, s.Name, s.Description, s.StepType
	FROM ManualStep ms 
    INNER JOIN Step s ON s.ID = ms.StepID
	WHERE ms.StepID = @StepID
END
GO

CREATE PROCEDURE GetEndStep
@StepID INT
AS
BEGIN
	SELECT es.ID, es.StepID, s.WorkflowID, s.Name, s.Description, s.StepType, s.DateCreated, s.DateModified
	FROM EndStep es 
    INNER JOIN Step s ON s.ID = es.StepID
	WHERE es.StepID = @StepID
END
GO

