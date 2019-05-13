INSERT INTO Workflow (Name, Description, DateCreated, DateModified)
VALUES ('Manual Test', 'Manual Step Test', GETDATE(), GETDATE())
GO

INSERT INTO Step (WorkflowID, Name, Description, StepType, DateCreated, DateModified)
VALUES (1, 'StartStep', 'StartStep for Manual testing', 'StartStep', GETDATE(), GETDATE())
GO

INSERT INTO StartStep (StepID, DateCreated, DateModified)
VALUES (1, GETDATE(), GETDATE())
GO

INSERT INTO Step (WorkflowID, Name, Description, StepType, DateCreated, DateModified)
VALUES (1, 'ManualStep', 'ManualStep for Manual testing', 'ManualStep', GETDATE(), GETDATE())
GO

INSERT INTO ManualStep (StepID, DateCreated, DateModified)
VALUES (2, GETDATE(), GETDATE())
GO

INSERT INTO Step (WorkflowID, Name, Description, StepType, DateCreated, DateModified)
VALUES (1, 'EndStep', 'EndStep for Manual testing', 'EndStep', GETDATE(), GETDATE())
GO

INSERT INTO EndStep (StepID, DateCreated, DateModified)
VALUES (3, GETDATE(), GETDATE())
GO

INSERT INTO StepLink (SourceID, DestinationID, DateCreated, DateModified)
VALUES (1, 2, GETDATE(), GETDATE())
GO

INSERT INTO StepLink (SourceID, DestinationID, DateCreated, DateModified)
VALUES (2, 3, GETDATE(), GETDATE())
GO

