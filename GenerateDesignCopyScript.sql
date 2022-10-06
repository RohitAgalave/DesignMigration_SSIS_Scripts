USE [eBS4_INT_QA2]
GO
/****** Object:  StoredProcedure [sync].[GenerateDesignCopyScript]    Script Date: 10/6/2022 3:35:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Name 
	[Sync].[GenerateDesignCopyScript]

Purpose
	To generate script to copy a design or design version

Return

Params
	@FormIdVar INT, @FDVID INT, @Flag BIT

History
	 On 2022-07-22 SP Created
	 On 2022-09-08 SP Updated : Added changes to zip the FormDesignVersionData, RuleExecutionTreeJSON and RuleEventMapJSON Data, to copy on target

*/



ALTER PROC [sync].[GenerateDesignCopyScript] @FormIdVar INT, @FDVID INT, @Flag BIT
As
Begin

If Object_ID ('[Temp].[Formdesignquery]') Is Not Null
Begin
	Drop Table [Temp].[Formdesignquery]
End
CREATE TABLE [Temp].[Formdesignquery](
	[ID]					[int]			IDENTITY(1,1) NOT NULL,
	[FormdesignVersionID]	[int]			NULL,
	[QueryType]				[Varchar](30)	NUll,
	[Sqlquery]				[nvarchar](max) NULL
) 

If Object_ID ('[Temp].[temp2]') Is Not Null
Begin
	Drop Table [Temp].[temp2]
End
CREATE TABLE [Temp].[temp2](
	[ID]					[int]			IDENTITY(1,1) NOT NULL,
	[RuleID]	[int]			NULL,
) 

Declare @FormdesignVersionList Table (FormDesignID Int NOT NULL,FormdesignVersionID Int ,IsFormDesignCopy bit)

--- We need to pass formdesignID compulsary and formdesignversion id is optional
-- If IsFormDesignCopy flag is 0 then we can copy only form design version and if it is 1 then we are copying form design as well as their version

Insert Into @FormdesignVersionList(FormDesignID ,FormdesignVersionID,IsFormDesignCopy) Values(@FormIdVar,@FDVID,@Flag)

declare @keepGoing				int					=	1
declare @UIElementID			int					=	NULL
declare @FormDesignVersionID	int					=	NULL
declare @AddedBy				Varchar(10)			=	'superuser'
declare @AddedDate				Varchar(20)			
Declare	@RuleCount				Int					=	0
Declare	@RuleID					Int					=	NULL
Declare @DatasourceID			Int					=	NULL
Declare	@FormID					Int					=	NULL
Declare	@FormIDCount			Int					=	1
Declare @Formname				Varchar(Max)		=	NULL
Declare @DatasourceName			varchar(Max)		=	NULL
Declare @MappedUIID				Int					=	NULL
Declare @UIElementName			Varchar(Max)		=	NULL   
Declare @UIelementNameNew          Varchar(Max)		=	NULL    --added shiv
Declare @sql					nvarchar(4000)		=	NULL
Declare @FileLocation			varchar(50)			=	'D:\Import\'
Declare @ServerName				varchar(50)			=	@@servername
Declare @FieldTerminator		varchar(10)			=	'	'
Declare @Formdata				nvarchar(max)		=	NULL
Declare @ParentUIElementID		Int					=	NULL
Declare @ParentUIElementName    Varchar(max)		=	NULL
Declare @RepeaterUIElementID	Int					=	NULL
Declare @RepeaterUIElementName 	Varchar(max)		=	NULL
Declare @KeyParentUIElementID	Int					=	NULL
Declare @KeyParentUIElementName Varchar(max)		=	NULL
Declare @RegexID				Int					=	NULL
Declare @Regexname				Varchar(500)		=	NULL
Declare	@RoleID					Int					=	NULL
Declare	@RoleName				Varchar(250)		=	NULL
Declare	@DocumentDesignName		Varchar(300)		=	NULL
Declare	@DocumentDesignID		Int					=	NULL
Declare @FormdesignGroupID		Int					=	NULL
Declare	@GroupName				Varchar(400)		=	NULL
Declare @DBName					Varchar(max)		=	db_name()
Declare	@DocumentRUleID				Int				=	NULL
Declare	@RepeaterCount			Int					=	1		
Declare @RepeaterUIElement		Int					=	NULL	
Declare @KeyUIElementName		varchar(400)		=	NULL	
declare @targetdesignID			Int					=	NULL
declare @AnchorDesignID			Int					=	NULL
Declare @AnchorDesignName		Varchar(max)		=	NULL
Declare @IsFormDesignCopy		bit					=	NULL
Declare @RepeaterDatasourceID	Int					=	NULL
Declare	@RepeaterDatasourceName varchar(max)		=	NULL
Declare @SectionDatasourceID	Int					=	NULL
Declare	@SectionDatasourceName  varchar(max)		=	NULL
Declare @FormdesignGroupCount				Int		=	0
Declare @FormDesignGroupMappingCount		Int		=	0
Declare @FormDesignVersionCount				Int		=	0
Declare @DataSourceCount					Int		=	0
Declare @UIElementCount						Int		=	0
Declare @DocumentRuleCount					Int		=	0
Declare @DocumentRuleEventMapCount			Int		=	0
Declare @DataSourceMappingCount				Int		=	0
Declare @FormDesignVersionUIElementMapCount Int		=	0
Declare @AlternateUIElementLabelCount		Int		=	0
Declare @CheckBoxUIElementCount				Int		=	0
Declare @CalendarUIElementCount				Int		=	0
Declare @DropDownElementItemCount			Int		=	0
Declare @DropDownUIElementCount				Int		=	0
Declare @KeyProductUIElementMapCount		Int		=	0
Declare @RadioButtonUIElementCount			Int		=	0
Declare @RepeaterUIElementCount				Int		=	0
Declare @SectionUIElementCount				Int		=	0
Declare @TabUIElementCount					Int		=	0
Declare @TextBoxUIElementCount				Int		=	0
Declare @ValidatorCount						Int		=	0
Declare @SrcRuleCount						Int		=	0
Declare @PropertyRuleMapCount				Int		=	0
Declare @ExpressionCount					Int		=	0
Declare @RepeaterKeyUIElementCount			Int		=	0
Declare @RepeaterKeyFilterCount  			Int		=	0 --added by shivani 0209
Declare @Count								Int		=	0
Declare @Datacount							Int		=	0	

Select @AddedDate = Convert(Varchar(10),getdate(),111)

Truncate Table Temp.Formdesignquery

If OBJECT_ID('tempdb..#FormDesignList')Is Not Null
Begin
	Drop Table #FormDesignList
End	

Select	Distinct FormDesignID,FormdesignVersionID
Into			#FormDesignList
From			@FormdesignVersionList

--Select * From #FormDesignList

Update		f
Set			FormdesignVersionID		=	d.FormDesignVersionID
From		#FormDesignList f
Inner Join	UI.FormDesignVersion	d
On			f.FormDesignID			=	d.FormDesignID
Where		f.FormdesignVersionID Is null

--Select * From #FormDesignList
	
	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewUIElementID Int = NULL ' 

	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare	@NewdatasourceID			Int				=	NULL	
				 Declare	@NewMappedUIElementID		Int				=	NULL'

	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		 @FormDesignVersionID,
				 'Declare @NewtRuleID Int = 0 '

	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewParentExpressionID Int = 0 '
	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewFormID Int = 0'

	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewFormdesignVersionID Int	=	0'
	
	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewFormdesignGroupID Int	=	Null'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				' Declare @FormVersiondata nvarchar(max)'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery) -- Added By Rohit
	Select		@FormDesignVersionID,
				' Declare @RuleExecutionTreeJSONData nvarchar(max)'
	
	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery) -- Added By Rohit
	Select		@FormDesignVersionID,
				' Declare @RuleEventMapJSONData nvarchar(max)'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @ParentUIElement Int'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @RepeaterUIElement Int'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @KeyParentElement Int'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewRegexID Int'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewRoleID Int'

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Declare @NewDocumentDesignTypeID Int'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @VersionNumber	Varchar(20)		    =	NULL'
	
	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @NewDocumentRUleID	Int  =	NULL'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @NewRepeaterUIElement	Int  =	NULL'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @UIElementID			Int  =	NULL'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RepeaterDatasourceID	Int  =	NULL'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @SectionDatasourceID	Int  =	NULL'

	Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
	Select		'NewAnchorDesignID','Declare @NewAnchorDesignID Int = Null'

	Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
	Select		'NewPropertyRuleMapID','Declare @NewPropertyRuleMapID Int = Null'

	
	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @FormdesignGroupCount						Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @FormDesignGroupMappingCount				Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @FormDesignVersionCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DataSourceCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @UIElementCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DocumentRuleCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DocumentRuleEventMapCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DataSourceMappingCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @FormDesignVersionUIElementMapCount		Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @AlternateUIElementLabelCount				Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @CheckBoxUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @CalendarUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DropDownElementItemCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DropDownUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @KeyProductUIElementMapCount				Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RadioButtonUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RepeaterUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @SectionUIElementCount						Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @TabUIElementCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @TextBoxUIElementCount						Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @ValidatorCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RuleCount									Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @PropertyRuleMapCount						Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @ExpressionCount							Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RepeaterKeyUIElementCount					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @RepeaterKeyFilterCount					Int  =	0'


	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @FormVersionUIElementID					Int  =	0'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @AlternateUIElementID						Int  =	0'
	
	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @DataSourceMappingUIElementID				Int  =	0'
	
	Insert Into Temp.Formdesignquery(Sqlquery)
	Select		'Declare @UIElementIDNew			               Int  =	NULL' --Added by shivani 07/09

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select      'Declare @FormDesignVersionID  Int'

	Insert Into Temp.Formdesignquery(Sqlquery)
	Select      'Declare @ExpressionID Int'
	
	Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Expression_Rownumber',						
	'DROP TABLE IF EXISTS #NewExpression CREATE TABLE #NewExpression (ExpressionID	INT ,LeftOperand NVARCHAR(500),	RightOperand NVARCHAR(500),	OperatorTypeID INT,	LogicalOperatorTypeID INT,	AddedBy	 VARCHAR (20),AddedDate DATETIME,	UpdatedBy  VARCHAR (20),	UpdatedDate DATETIME,	RuleID INT,	ParentExpressionID INT,	ExpressionTypeID INT,	IsRightOperandElement BIT)'
					

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'IF Object_ID(''Tempdb..#FormdesignData'') Is Not null Begin Drop Table #FormdesignData End' 

	Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
	Select		@FormDesignVersionID,
				'Create Table #FormdesignData(FormDesignVersionData nvarchar(max))'

While(@FormIDCount > 0)

Begin
		--Select Minimun Formdesign from given Formdesign id

		Select @FormID	=	Min(FormDesignID) From #FormDesignList

		--- select Minimun FormDesignVersion for above Selected Formdesign

		Select @FormDesignVersionID	=	Min(FormDesignVersionID) from #FormDesignList Where FormDesignID	=	@FormID

		--	End loop if Formid Is null 

		If(@FormID Is NULL)
		Begin
				Set	@FormIDCount = 0;
				Break;
		End

	
		Select	@Formname			=	dbo.GetFormname(@FormID)
		Select	@DocumentDesignID	=	DocumentDesignTypeID	From UI.FormDesign where FormID	=	@FormID

		insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
		Select							 @formdesignversionID ,'BEGIN TRY'

		insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
		Select							 @formdesignversionID ,'BEGIN TRANSACTION'


		--- Passing form name as a input to function to get formID from another environment
		
		Select @IsFormDesignCopy	=	 IsFormDesignCopy From @FormdesignVersionList where FormDesignID = @Formid

		IF(@IsFormDesignCopy = 1)
		Begin

			Select @DocumentDesignName	= DocumentDesignName	From UI.DocumentDesignType  where DocumentDesignTypeID	=	@DocumentDesignID

			Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
			Select		'@NewDocumentDesignTypeID',
						'Select @NewDocumentDesignTypeID = DocumentDesignTypeID	From UI.DocumentDesignType Where DocumentDesignName = '''+@DocumentDesignName+''''

			Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)

			Select	
					'Formdesign',
					'Insert Into [UI].[FormDesign] 
					(FormName,DisplayText,IsActive,Abbreviation,TenantID,AddedBy,AddedDate,IsMasterList,DocumentDesignTypeID,Sequence,DocumentLocationID,IsAliasDesignMasterList,UsesAliasDesignMasterList,IsSectionLock,IsMDM,MDMSchemaName)					
					Values('''+FormName+''','''+
							DisplayText+''','+
							Convert(Varchar(10),IsActive)+','''+
							Abbreviation+''','+
							Convert(varchar(10),TenantID)+','+
							QUOTENAME(@addedby,'''')+','+
							Quotename(convert(varchar(10),@AddedDate),'''')+','+
							Convert(varchar(10),IsMasterList)+','+
							'@NewDocumentDesignTypeID'+','+
							Convert(Varchar(10),Isnull([Sequence],-2))+','+
							Convert(Varchar(10),Isnull(DocumentLocationID,-2))+','+
							Convert(Varchar(10),isnull(IsAliasDesignMasterList,0))+','+
							Convert(Varchar(10),Isnull(UsesAliasDesignMasterList,0))+','+
							Convert(Varchar(10),IsSectionLock)+','+
							Convert(Varchar(10),ISNULL(IsMDM,0))+','''+
							Convert(Varchar(30),ISNULL(MDMSchemaName,''))+'''
							)'
			From	 [UI].[FormDesign]
			Where	 FormID	=	@FormID

			Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
			Select	'NewFormID'			,
					'Select @NewFormID		= IDENT_CURRENT(''[UI].[FormDesign]'')'

			Select @FormdesignGroupID	= FormDesignGroupID From UI.FormDesignGroupMapping where FormID	=	@FormID
			Select @GroupName			= GroupName	From UI.FormdesignGroup where FormDesignGroupID	=	@FormdesignGroupID

			If(@GroupName <>'Account')
			Begin

				Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
				Select		'FormDesignGroup',
							'insert Into [UI].[FormDesignGroup]
							(GroupName,TenantID,AddedBy,AddedDate,IsMasterList)
							Values('''+@GroupName+''','+
							Convert(Varchar(10),TenantID)+','+
							QUOTENAME(@AddedBy,'''')+','+
							QUOTENAME(Convert(Varchar(10),@addeddate),'''')+','+
							Convert(Varchar(10),IsMasterList)+')'
				From		[UI].[FormDesignGroup]
				Where		FormDesignGroupID	=	@FormdesignGroupID

				Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
				Select 'NewFormdesignGroupID',
						'Select @NewFormdesignGroupID= IDENT_CURRENT(''[UI].[FormDesignGroup]'')'
				End

			Else
			Begin
					Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
					Select 'NewFormdesignGroupID',
					'Select @NewFormdesignGroupID=  FormdesignGroupID From [UI].[FormDesignGroup] where GroupName = ''Account'''
			End
			Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
			 Select 'FormDesignGroupMapping',
					'Insert Into [UI].[FormDesignGroupMapping]
					(FormDesignGroupID,FormID,Sequence,AllowMultipleInstance,AccessibleToRoles)
					Values('+'@NewFormdesignGroupID'+','+
					'@NewFormID'+','+
					Convert(Varchar(10),[Sequence])+','+
					Convert(Varchar(10),AllowMultipleInstance)+','''+
					AccessibleToRoles+''')'
			From	[UI].[FormDesignGroupMapping]
			Where	FormID	=	@FormID

			select @AnchorDesignID = AnchorDesignID From [UI].[FormDesignMapping] where TargetDesignID = @FormID

			If(@AnchorDesignID Is Not Null Or @AnchorDesignID<>'')
			Begin

				--Select @AnchorDesignName = [dbo].[GetFormName](@AnchorDesignID)
				Select @AnchorDesignName = (select formname from ui.formdesign where formid = @FormID)
				Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
				Select		'NewAnchorDesignID','Select @NewAnchorDesignID = [dbo].[GetFormID]('''+@AnchorDesignName+''')'

				Insert Into Temp.Formdesignquery(QueryType	,Sqlquery)
				select		'FormDesignMapping',
							'Insert Into UI.FormDesignMapping(AnchorDesignID	,TargetDesignID) 
							 select							 @NewAnchorDesignID ,@NewFormID'


			End




	End
		Else If(@IsFormDesignCopy = 0)
		Begin

			Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	,Sqlquery)

			Select	@FormDesignVersionID,
					'NewFormID'			,
					'Select @NewFormID		= Dbo.GetFormID('+Isnull(Quotename(@Formname,''''),'NULL')+')'
		End
		---ithun loop sampla start cha..entries chalu zalya
		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	,Sqlquery)

		Select	@FormDesignVersionID,
				'VersionNumber'			,     -- Added By Rohit
				'Set @VersionNumber	= '+ (select VersionNumber from ui.formdesignversion where FormDesignVersionID = @FormDesignVersionID) 


		--- zip the fordesignversiondata   -- Added By Rohit
		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	,Sqlquery)
		Select	@FormDesignVersionID,
				'FormDesignVersionData'			,
				'Set @FormVersiondata	= '+''''+ IsNull((select dbo.GZip((select FormDesignVersiondata from ui.formdesignversion where FormDesignVersionID = @FormDesignVersionID))),'')+''''

		--- zip the RuleExecutionTreeJSON    -- Added By Rohit
		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	,Sqlquery)
		Select	@FormDesignVersionID,
				'RuleExecutionTreeJSONData'			,
				'Set @RuleExecutionTreeJSONData	= '+''''+ IsNull((select dbo.GZip((select RuleExecutionTreeJSON from ui.formdesignversion where FormDesignVersionID = @FormDesignVersionID))),'')+''''
				
		--- zip the RuleEventMapJSONData     -- Added By Rohit
		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	,Sqlquery)
		Select	@FormDesignVersionID,
				'RuleEventMapJSONData'			,
				'Set @RuleEventMapJSONData	= '+''''+ IsNull((select dbo.GZip((select RuleEventMapJSON from ui.formdesignversion where FormDesignVersionID = @FormDesignVersionID))),'')+''''



		--- Generate query to insert data in FormdesignVersion table select [dbo].[GetVersionNumber]()

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)	
		Select		@FormDesignVersionID,
					'FormdesignVersion' ,
					'Insert Into[UI].[FormDesignVersion]
					(FormDesignID,TenantID,VersionNumber,EffectiveDate,FormDesignVersionData,StatusID,AddedBy,AddedDate,Comments,FormDesignTypeID,LastUpdatedDate,RuleExecutionTreeJSON,RuleEventMapJSON,PBPViewImpacts)
					Values('+'@NewFormID'+','+
					Convert(varchar(10),Isnull(TenantID,-2))+','+
					'@VersionNumber'+','''+
					Isnull(Convert(varchar(10),EffectiveDate,111),'Null')+''','+
					'dbo.UnZip(@FormVersiondata)'+','+				    -- Added By Rohit
					COnvert(Varchar(10),1)+','+
					Quotename(@AddedBy,'''')+','+
					QUOTENAME(@addeddate,'''')+','''+
					Isnull(Comments,'NULL')+''','+
					COnvert(Varchar(10),Isnull(FormDesignTypeID,-2))+','+
					Isnull(Quotename(Convert(Varchar(10),LastUpdatedDate ,111),''''),'NULL')+','+
					'dbo.UnZip(@RuleExecutionTreeJSONData)'+','+		-- Added By Rohit
					'dbo.UnZip(@RuleEventMapJSONData)'+','+				-- Added By Rohit
					'NULL'+'
			
					) ' 
		From	[UI].[FormDesignVersion] 
		Where	FormDesignVersionID	=	@FormDesignVersionID

		--- Find New Generated FormdesignVersionID 

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select	@FormDesignVersionID,
				'NewFormdesignVersion' ,
				'Select @NewFormdesignVersionID = IDENT_CURRENT(''[UI].[FormDesignVersion]'')' 


		--- Generate Script to insert data in Datasource Table For given Formdesignversion

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select	@FormDesignVersionID,
				'Datasource' ,
				'Insert Into [UI].[DataSource]
				(DataSourceName,DataSourceDescription,Type,AddedBy,AddedDate,IsActive,FormDesignID,FormDesignVersionID)
				Values('''+ Isnull(DataSourceName,'NULL')+''','''+
				Isnull(DataSourceDescription,'NULL')+''','''+
				Isnull([Type],'NULL')+''','+
				Quotename(@AddedBy,'''')+','+
				Quotename(@addedDate,'''')+','+
				Convert(Varchar(10),IsActive)+','+
				'@NewFormID'+','+
				'@NewFormdesignVersionID'+')' 
		From	[UI].[DataSource]
		Where	FormDesignVersionID	=	@FormDesignVersionID
		

		--- Find Number Of UIelements for given FOrmdesignversion

		If OBJECT_ID('Tempdb..#Elements')Is Not Null
		Begin
			Drop Table #Elements
		End

		select	Distinct f.UIElementID
		into			#Elements 
		from			UI.FormDesignVersionUIElementMap f
		Inner Join		UI.UIElement u
		On				f.UIElementID		=	u.UIElementID
		Where			FormDesignVersionID	=	@FormDesignVersionID
		And				FormID				=	@FormID


		


		If (@IsFormDesignCopy = 0)
		Begin

			
			If OBJECT_ID('Tempdb..#FormversionUiElementID') Is Not Null
			Begin
				Drop Table #FormversionUiElementID
			End
			
			;With cteElementID As
			(
				Select distinct e.UielementID From [UI].[UIElement] e 
				Inner Join		[UI].[FormDesignVersionUIElementMap] f 
				On				e.UIElementID			=  f.UIElementID 
				Where			e.FormID				=  @FormID 
				And				f.FormDesignVersionID   <> @FormDesignVersionID  

			)

						
			Select		e.UIElementID
			Into		#FormversionUiElementID
			From		#Elements  e 
			Inner Join  cteElementID c 
			On			e.UIelementID = c.UIElementID

			Select @Count = @@ROWCOUNT
			
			Delete	e 
			From		#Elements e 
			Inner Join	#FormversionUiElementID f 
			On			e.UIElementID = f.UIElementID

			If (@Count > 0)
			Begin
				Set @keepGoing = 1
			End
			Else
			Begin
				Set @keepGoing = 0
			End

			While(@keepGoing > 0)

			Begin

				Set @UIElementID	=	NULL

				select @UIElementID = min(UIElementID) from #FormversionUiElementID --ha vegla temp tbl ahe  formdesigncopyflag  0 sathi

		 

				 IF(@UIElementID Is NULL Or @UIElementID = '' )
				 Begin
						Set	@keepGoing	=	0
						Break;
				 End

				 set @UIElementName		= NULL
				 Select @UIElementName	=	UIElementName From [UI].[UIElement] Where UIElementID = @UIElementID
				 
				 If (@UIElementName Is Not null Or @UIElementName <> '')
				 Begin
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
						select	@FormDesignVersionID,'Select @FormVersionUIElementID = [dbo].[GetUIElementID]('+Quotename(@UIElementName,'''')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
				 End

			--- Generate insert script for inserting data of new UIELementID in FormDesignVersionUIElementMap 

				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
				Select @FormDesignVersionID,
						'FormDesignVersionUIElementMap' As QueryType,
						'Insert Into [UI].[FormDesignVersionUIElementMap]
						(FormDesignVersionID,UIElementID,EffectiveDate,EffectiveDateOfRemoval,Operation)
						Values('+'@NewFormdesignVersionID'+','+
						'@FormVersionUIElementID'+','+
						Isnull(Quotename(Convert(varchar(20),EffectiveDate,111),''''),'Null')+','+
						Isnull(Quotename(Convert(varchar(20),EffectiveDateOfRemoval,111),''''),'Null')+','+
						Isnull(Quotename(Operation,''''),'NULL')+')' 

				From	[UI].[FormDesignVersionUIElementMap]
				Where	UIElementID			=	@UIElementID
				And		FormDesignVersionID	=	@FormDesignVersionID

		
				--- Genarte script for inserting data in AlternateUIElement of given UIElement

				Set @UIElementName	=	NULL

				If Exists (Select 1 from [UI].[AlternateUIElementLabel] Where UIElementID= @UIElementID )
				Begin
						Select  @UIElementName = UIElementName From [UI].[UIElement] Where  UIelementID = @UIElementID

						 If (@UIElementName Is Not null Or @UIElementName <> '')
						Begin
							Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
							select	@FormDesignVersionID,'Select @AlternateUIElementID = [dbo].[GetUIElementID]('+Quotename(@UIElementName,'''')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
						End
				End

				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
				select	distinct @FormDesignVersionID,
							'AlternateUIElement',
							'insert into [UI].[AlternateUIElementLabel]
							(FormDesignID, FormDesignVersionID, UIElementID, AlternateLabel )
							values ('+
							'@NewFormID'+', '+
							'@NewFormdesignVersionID'+', '+
							'@AlternateUIElementID'+', '''+
							Isnull(AlternateLabel,'NULL')+''')' 

				from 		[UI].[AlternateUIElementLabel]
				where		UIElementID			= @UIElementID
				And			FormDesignVersionID = @FormDesignVersionID

				--Find DatasourceID and MappedUIElementID of given UIElementID and FOrmdesignversion
			If Exists(Select 1 From [UI].[DataSourceMapping] where UIElementID = @UIElementID)
			Begin

				Select	@datasourceID		=	DatasourceID  ,
						@MappedUIID			=	MappedUIElementID
				From	[dbo].[GetMappedID_DatasourceID](@UIElementID,@FormDesignVersionID)

				If (@datasourceID is not Null and @MappedUIID Is Not Null)
				Begin
		
						-- Once We get datasourceID and UILementID then here we are finding that datasourcename and UIelementName by passing Datasourceid and uielementID

						Select @DatasourceName	=	DataSourceName,
							   @UIElementName	=	UIElementName
						From   [dbo].[GetMappedID_DatasourceName](@datasourceID,@MappedUIID)

				If (@DatasourceName is not Null and @UIElementName Is Not Null)

				Begin
						
						---if datasourcename and uiemenetName is not null then we pass that name to function and get their ID'S from another environment.
			
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						Select	@FormDesignVersionID,
								'NewDatasourceID' ,
								'Select	@NewdatasourceID		=	DataSourceID	,
										@NewMappedUIElementID	=	MappedUIElementID
								From [dbo].[GetIDs] ('+QuoteName(@DatasourceName,'''')+','+Quotename(@UIElementName,'''')+')' 

						Set @UIElementName	=	NULL

						Select @UIElementName	= UIElementName  From [Ui].[UIElement] where UIElementID = @UIElementID

					If(@UIElementName Is Not Null Or @UIElementName <> '')
					Begin
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						Select	@FormDesignVersionID,
							'NewDatasourceID' ,
							'Select @DataSourceMappingUIElementID =  [dbo].[GetUIElementID]('+Quotename(@UIElementName,'''')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
					End

		
				---Generate insert script for inserting data in datasourcemapping table

				Insert Into Temp.Formdesignquery(FormdesignVersionID , QueryType	 ,Sqlquery)
				Select		@FormDesignVersionID,
							'Datasourcemapping',
							'Insert Into [UI].[DataSourceMapping]
							(UIElementID,DataSourceID,MappedUIElementID,IsPrimary,DataSourceElementDisplayModeID,DataSourceFilter,DataCopyModeID,FormDesignID,FormDesignVersionID,IsKey,DataSourceOperatorID,[Value],DataSourceModeID,IncludeChild)
							Values('+'@DataSourceMappingUIElementID'+','+
							'@NewdatasourceID'+','+
							'@NewMappedUIElementID'+','+
							Convert(Varchar(10),IsPrimary)+','+
							Convert(Varchar(10),Isnull(DataSourceElementDisplayModeID,-2))+','''+
							Isnull(DataSourceFilter,'NULL')+''','+
							Convert(Varchar(10),Isnull(DataCopyModeID,-2))+','+
							'@NewFormID'+','+
							'@NewFormdesignVersionID'+','+
							Convert(Varchar(10),IsKey)+','+
							Isnull(Convert(Varchar(10),DataSourceOperatorID),-2)+','''+
							Isnull([Value],'NULL')+''','+
							Convert(Varchar(10),DataSourceModeID)+','+
							Convert(Varchar(10),IncludeChild)+')'

				From		[UI].[DataSourceMapping]
				Where		UIelementID			=	@UIElementID
				And			DataSourceID		=	@DatasourceID
				And			FormDesignVersionID	=	@FormDesignVersionID

			End
		End
   End
		Delete From #FormversionUiElementID	 where UIElementID = @UIElementID

	End

			Set @Count	=	0

	End

	If Not Exists(Select 1 from #Elements)
	Begin
		  Set @keepGoing = 0
	End
	Else
	Begin 
			Set @keepGoing = 1
	End

	while(@keepGoing > 0)
	begin

			
		--Select  mininum UI ELement from list 

		Set @UIElementID   = NULL
		Set @UIElementName = NULL

		 select @UIElementID = min(UIElementID) from #Elements 

		 

		 IF(@UIElementID Is NULL Or @UIElementID = '' )
		 Begin
				Set	@keepGoing	=	0
				Break;
		 End

		 --- Generate Insert Script for inserting data of above selected UI element in UIElement Table 
		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select		@FormDesignVersionID,
					'UIElement'			,
					'Insert into [UI].[UIElement]
				    ([UIElementName], [Label], [IsContainer], [Enabled], [Visible], [Sequence], [RequiresValidation], [HelpText], [AddedBy]
					,[AddedDate] ,[IsActive], [FormID], [UIElementDataTypeID], [HasCustomRule], [CustomRule], [GeneratedName], 
					[DataSourceElementDisplayModeID], [CheckDuplicate], [AllowGlobalUpdates], [ViewType],IsSameSectionRuleSource,IsStandard,[MDMName])
					values ('''+
						 Isnull([UIElementName],'NULL')+''', ''' 
						+Isnull(Replace([Label],char(39), char(39)+char(39)),'NULL')+''', '
						--+'@ParentUIElement'+', '+
						+convert(varchar(10),[IsContainer])+ ', '+
						+convert(varchar(10), case when [Enabled] is null then 0 else [Enabled] end)+', '+
						+convert(varchar(10),case when [Visible] is null then 0 else [Visible] end)+ ', '+
						+convert(varchar(10),[Sequence])+ ', '+
						+convert(varchar(10),[RequiresValidation])+', '''+ 
						+Isnull(Replace([HelpText],char(39), char(39)+char(39)),'NULL')+''', '+
						+quotename(@AddedBy,'''')+', '+
						+quotename(@AddedDate,'''')+', '+
						+convert(varchar(10),[IsActive])+', '+
						+'@NewFormID'+', '+
						+convert(varchar(10),[UIElementDataTypeID])+', '+
						+convert(varchar(10),case when [HasCustomRule] is null then 0 else [HasCustomRule] end)+', '''+
						+Isnull( [CustomRule] ,'null')+''', '''+
						+Isnull([GeneratedName] ,'Null' )+''', '+
						+convert(varchar(10),case when [DataSourceElementDisplayModeID] is null then -2 else [DataSourceElementDisplayModeID] end)+', '+
						+convert(varchar(10),[CheckDuplicate])+', '+
						+convert(varchar(10),case when [AllowGlobalUpdates] is null then 0 else [AllowGlobalUpdates] end)+', '+
						convert(varchar(10), case when [ViewType] is null then -2 else [ViewType] end)+',
						'+convert(varchar(10), case when IsSameSectionRuleSource is null then 0 else IsSameSectionRuleSource end)+',
						'+convert(varchar(10), IsStandard)+','''+
						+Isnull([MDMName],'NULL')+
						''')' 
			
		from	UI.UIElement 
		where	UIElementID = @UIElementID


		--- select Newly generated UIElementID after executing Insert Script of UIElement

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'NewUIElement' ,
					'select @NewUIElementID  = IDENT_CURRENT('+ QUOTENAME('UI.UIElement','''')+')'


		


		If Exists(Select 1 from UI.[DocumentRule] where TargetUIElementID	=	@UIElementID and FormDesignVersionID	=	@FormDesignVersionID )
		Begin
				
							
			 Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
			 Select @FormDesignVersionID,
					'DocumentRule',
					'Insert Into [Ui].[DocumentRule]
					 (DisplayText,Description,AddedBy,AddedDate,IsActive,DocumentRuleTypeID,DocumentRuleTargetTypeID,RuleJSON,FormDesignID,FormDesignVersionID,TargetUIElementID,TargetElementPath,CompiledRuleJSON)
					Values('''+Isnull(Replace(DisplayText,'''',''''''),'NULL')+''','''+
							 Isnull(Replace([Description],'''',''''''),'NULL')+''','+
							 QUOTENAME(@AddedBy,'''') +','+
							 QUOTENAME(Convert(Varchar(20),@AddedDate),'''')+','+
							 Convert(Varchar(10),Isactive)+','+
							 Convert(Varchar(10),DocumentRuleTypeID)+','+
							 convert(Varchar(10),DocumentRuleTargetTypeID)+',dbo.UnZip('''+
							 dbo.GZip(Isnull(RuleJSON,'NULL'))+'''),'+
							'@NewFormID' +','+
							'@NewFormdesignVersionID'+','+
							'@NewUIElementID'+','''+
							Isnull(TargetElementPath,'NULL')+''',
							dbo.UnZip('''+dbo.GZip(Isnull(CompiledRuleJSON,'NULL'))+''')
							 ) '
			 From	[Ui].[DocumentRule]
			 Where	TargetUIElementID	=	@UIElementID
			 And	FormDesignVersionID	=	@FormDesignVersionID

			  Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
			  Select @FormDesignVersionID,
					 'NewDocumentRuleID',
					 'Select @NewDocumentRUleID = IDENT_CURRENT (''[Ui].[DocumentRule]'')'
			 

			 Select @DocumentRUleID = documentRuleID from Ui.documentRule where TargetUIElementID=@UIElementID  And	FormDesignVersionID	=	@FormDesignVersionID
			 IF(@DocumentRUleID is Not NULL Or @DocumentRUleID<>'')
			 Begin
			 Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
			 Select		 @FormDesignVersionID,
						 'DocumentRuleEventMap',
						 'Insert Into [UI].[DocumentRuleEventMap]
						 (DocumentRuleID,DocumentRuleEventTypeID)
						 Values('+'@NewDocumentRUleID'+','+Convert(Varchar(10),DocumentRuleEventTypeID)+')'
			 From		 [UI].[DocumentRuleEventMap]
			 Where		 DocumentRuleID	=	@DocumentRUleID
			
			 End

		End

		---khali add krt ahe
		--- Generate insert script for inserting data of new UIELementID in FormDesignVersionUIElementMap 

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select @FormDesignVersionID,
				'FormDesignVersionUIElementMap' As QueryType,
				'Insert Into [UI].[FormDesignVersionUIElementMap]
				(FormDesignVersionID,UIElementID,EffectiveDate,EffectiveDateOfRemoval,Operation)
				Values('+'@NewFormdesignVersionID'+','+
				'@NewUIElementID'+','+
				Isnull(Quotename(Convert(varchar(20),EffectiveDate,111),''''),'Null')+','+
				Isnull(Quotename(Convert(varchar(20),EffectiveDateOfRemoval,111),''''),'Null')+','+
				Isnull(Quotename(Operation,''''),'NULL')+')' 

		From	[UI].[FormDesignVersionUIElementMap]
		Where	UIElementID			=	@UIElementID
		And		FormDesignVersionID	=	@FormDesignVersionID

		
		--- Genarte script for inserting data in AlternateUIElement of given UIElement

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select	distinct @FormDesignVersionID,
					'AlternateUIElement',
					'insert into [UI].[AlternateUIElementLabel]
					(FormDesignID, FormDesignVersionID, UIElementID, AlternateLabel )
					values ('+
					'@NewFormID'+', '+
					'@NewFormdesignVersionID'+', '+
					'@NewUIElementID'+', '''+
					Isnull(Replace([AlternateLabel],char(39), char(39)+char(39)),'NULL')+''')' 

		from 		[UI].[AlternateUIElementLabel]
		where		UIElementID			= @UIElementID
		And			FormDesignVersionID = @FormDesignVersionID

		--- Generate scrpt for inserting data  in CheckboxUIElement Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select		@FormDesignVersionID,
					'CheckBoxUIElement',
					'insert into [UI].[CheckBoxUIElement]
					(UIElementID, UIElementTypeID, OptionLabel, DefaultValue)
					values(' +
					'@NewUIElementID'+', '+
					convert(varchar(10),UIElementTypeID)+', '''+
					Isnull(OptionLabel,'Null') +''', '+
					convert(varchar(10),case when DefaultValue is null then 0 else DefaultValue end)+' )' 
		from		[UI].[CheckBoxUIElement]
		where		UIElementID = @UIElementID

		--- Generate scrpt for inserting data  in Calendar Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select	@FormDesignVersionID,
				'CalendarUIelement',
				'insert into [UI].[CalendarUIElement] 
				(UIElementID, UIElementTypeID, MinDate, MaxDate, DefaultDate)
				 values(' +
				'@NewUIElementID'+', '+
				convert(varchar(10),UIElementTypeID)+', '+
				Isnull(Quotename(convert(varchar(20),MinDate,111),''''),'null')+', '+
				Isnull(Quotename(convert(varchar(20),MaxDate,111),''''),'null') +', '+
				Isnull(Quotename(convert(varchar(20), DefaultDate,111),''''),'null')+' )'
		from	[UI].[CalendarUIElement]
		where	UIElementID = @UIElementID

			--- Generate scrpt for inserting data  in DropDownUIElement Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select	@FormDesignVersionID,
				'DropDownUIElement',
				'insert into [UI].[DropDownUIElement] 
				(UIElementID, UIElementTypeID, SelectedValue, IsMultiSelect, IsDropDownTextBox, IsSortRequired, IsDropDownFilterable)
				values( ' +
				'@NewUIElementID'+', '+
				convert(varchar(10),[UIElementTypeID])+', '''+
				Isnull(SelectedValue ,'Null')+''', '+
				convert(varchar(10),IsMultiSelect)+', '+
				convert(varchar(10), case when IsDropDownTextBox is null then 0 else IsDropDownTextBox end)+', '+
				convert(varchar(10), case when IsSortRequired is null then 0 else IsSortRequired end)+', '+
				convert(varchar(10), IsDropDownFilterable )+' )'
		from	[UI].[DropDownUIElement]
		where	UIElementID = @UIElementID


		--- Generate scrpt for inserting data  in DropDownElementItem Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select	@FormDesignVersionID,
				'DropdownElementItem',
				'insert into [UI].[DropDownElementItem] 
				( UIElementID, Value, AddedBy, AddedDate,IsActive, DisplayText, Sequence)
				 values(' +
				 '@NewUIElementID'+', '''+
				 [Value]+''', '+
				 quotename(convert(varchar(10),@AddedBy),'''')+', '+
				 quotename(@AddedDate,'''')+', '+
				 convert(varchar(10),IsActive)+', '''+
				 DisplayText+''', '+
				 convert(varchar(10),case when [Sequence] is null then -2 else [Sequence] end)+' ) '   
		from	[UI].[DropDownElementItem]
		where	UIElementID = @UIElementID


	
		--- Generate scrpt for inserting data  in KeyProductUIElementMap Table of given UIElementID
		Select @KeyParentUIElementID = ParentUIelementID From [UI].[KeyProductUIElementMap] 	where	UIElementID = @UIElementID
		

		If(@KeyParentUIElementID Is Not Null)
		Begin
				Select @KeyParentUIElementName	=	[dbo].[GetUIElementName](@KeyParentUIElementID)
				Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
		select	@FormDesignVersionID,'Select @KeyParentElement = [dbo].[GetUIElementID]('+Quotename(@KeyParentUIElementName,'''')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
		End

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select	@FormDesignVersionID,
				'KeyProductUIElement',
				'insert into [UI].[KeyProductUIElementMap] 
				(UIelementID, ParentUIelementID, MasterTemplateID)
				values( ' +
				'@NewUIElementID'+', '+
				'KeyParentElement'+', '+
				convert(varchar(10),[MasterTemplateID])+' )'
		from	[UI].[KeyProductUIElementMap]
		where	UIElementID = @UIElementID


		--- Generate scrpt for inserting data  in RadioButtonUIElement Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		select		@FormDesignVersionID,
					'RadioButtionUIELement',
					'insert into [UI].[RadioButtonUIElement] 
					(UIElementID, UIElementTypeID, OptionLabel, DefaultValue, IsYesNo, OptionLabelNo)
					values( ' +
		 			'@NewUIElementID'+', '+
					convert(varchar(10),[UIElementTypeID])+', '''+
					Isnull(OptionLabel ,'Null')+''', '+
					convert(varchar(10),case when [DefaultValue] is null then 0 else DefaultValue end)+', '+
					convert(varchar(10),[IsYesNo] )+', '''+
					ISNULL([OptionLabelNo] ,'NULL')+''' ) '
		from		[UI].[RadioButtonUIElement]
		where		UIElementID = @UIElementID

		--- Generate scrpt for inserting data  in TextBoxUIElement Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'TextBoxUIElement',
					'Insert Into [UI].[TextBoxUIElement]
					(UIElementID,UIElementTypeID,IsMultiline,DefaultValue,MaxLength,IsLabel,SpellCheck)
					Values('+'@NewUIElementID'+','+
					Convert(Varchar(10),UIElementTypeID)+','+
					Convert(Varchar(10),Isnull(IsMultiline,0))+','''+
					Isnull(DefaultValue,'NULL')+''','+
					Convert(Varchar(10),[MaxLength])+','+
					Convert(Varchar(10),IsLabel)+','+
					Convert(Varchar(10),Isnull(SpellCheck,0))+')'
		From		[UI].[TextBoxUIElement]
		Where		UIElementID	=	@UIElementID

		--- Generate scrpt for inserting data  in TabUIELement Table of given UIElementID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'TabUIElement',
					'Insert Into [UI].[TabUIElement]
					(UIElementID,UIElementTypeID,ChildCount,LayoutTypeID)
					Values('+'@NewUIElementID'+','+
					Convert(Varchar(10),UIElementTypeID)+','+
					Convert(Varchar(10),ChildCount)+','+
					Convert(Varchar(10),LayoutTypeID)+')'
		From		[UI].[TabUIElement]
		Where		UIElementID	=	@UIElementID

		--- Generate scrpt for inserting data  in SectionUIElement Table of given UIElementID

		select @SectionDatasourceID   =  datasourceID   from [UI].[SectionUIElement] where UIElementID = @UIElementID
		Select @SectionDatasourceName =  DataSourceName From [UI].[DataSource]        where DataSourceID = @SectionDatasourceID

		If (@SectionDatasourceName Is Not Null or @SectionDatasourceName <> '')
		Begin
				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
				Select		@FormDesignVersionID,'SectionDatasourceID' ,'select @SectionDatasourceID = [dbo].[GetRepeaterDataSourceID]('''+@SectionDatasourceName+''')'
		End

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType ,Sqlquery)
		Select		@FormDesignVersionID,
					'SectionUIElement',
					'Insert Into [UI].[SectionUIElement] 
					(UIElementID,UIElementTypeID,ChildCount,LayoutTypeID,DataSourceID,CustomHtml)
					Values('+'@NewUIElementID'+','+
					Convert(varchar(10),UIElementTypeID)+','+
					Convert(varchar(10),ChildCount)+','+
					Convert(Varchar(10),LayoutTypeID)+','+
					'@SectionDatasourceID'+','''+
					Isnull(CustomHtml,'NULL')+'''			
					)'
		From		[UI].[SectionUIElement]								
		Where		UIElementID	=	@UIElementID


		--- Generate scrpt for inserting data  in RepeaterUIElement Table of given UIElementID

		select @RepeaterDatasourceID   =  datasourceID   from [UI].[RepeaterUIElement] where UIElementID = @UIElementID
		Select @RepeaterDatasourceName =  DataSourceName From [UI].[DataSource]        where DataSourceID = @RepeaterDatasourceID

		If (@RepeaterDatasourceName Is Not Null or @RepeaterDatasourceName <> '')
		Begin
				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
				Select		@FormDesignVersionID,'RepeaterDatasourceID' ,'select @RepeaterDatasourceID = [dbo].[GetRepeaterDataSourceID]('''+@RepeaterDatasourceName+''')'
		End


		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'RepeaterUIElement',
					'Insert Into [UI].[RepeaterUIElement]
					(UIElementID,UIElementTypeID,LayoutTypeID,ChildCount,DataSourceID,LoadFromServer,IsDataRequired,AllowBulkUpdate,DisplayTopHeader,'+'
					DisplayTitle,FrozenColCount,FrozenRowCount,AllowPaging,RowsPerPage,AllowExportToExcel,AllowExportToCSV,FilterMode)
					Values('+'@NewUIElementID'+','+
					Convert(varchar(10),UIElementTypeID)+' , '+
					COnvert(Varchar(10),LayoutTypeID)+','+
					Convert(Varchar(10),Isnull(ChildCount,-2))+','+
					'@RepeaterDatasourceID'+' ,'+
					COnvert(Varchar(10),LoadFromServer)+','+
					Convert(Varchar(10),IsDataRequired)+','+
					Convert(Varchar(10),AllowBulkUpdate)+','+
					Convert(Varchar(10),DisplayTopHeader)+','+
					Convert(Varchar(10),DisplayTitle)+','+
					Convert(varchar(10),FrozenColCount)+','+
					Convert(Varchar(10),FrozenRowCount)+','+
					Convert(Varchar(10),AllowPaging)+','+
					Convert(varchar(10),RowsPerPage)+','+
					Convert(Varchar(10),AllowExportToExcel)+','+
					Convert(Varchar(10),AllowExportToCSV)+','''+
					FilterMode+'''
					)'
		From		[UI].[RepeaterUIElement] 
		Where		UIElementID	=	@UIElementID

		

		--- Generate scrpt for inserting data  in Validator Table of given UIElementID

		Select @RegexID = LibraryRegexID from [UI].[Validator] where UIElementID = @UIElementID
		Select @Regexname = LibraryRegexName From [UI].[RegexLibrary] where LibraryRegexID = @RegexID

		If (@RegexID Is NOT NULL)
		Begin
			Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
			Select		@FormDesignVersionID,
						'Select @NewRegexID = [dbo].[GetRegexID]('+Quotename(@Regexname,'''') +')'
		End

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'Validator',
					'Insert Into [UI].[Validator]
					(UIElementID,IsRequired,Regex,IsLibraryRegex,LibraryRegexID,AddedBy,AddedDate,IsActive,Message,MaskExpression,MaskFlag)
					Values('+ '@NewUIElementID '+','+
					Convert(Varchar(10),Isnull(IsRequired,0))+','''+
					Isnull(Regex,'NULL')+''','+
					Convert(Varchar(10),Isnull(IsLibraryRegex,0))+','+
					'@NewRegexID' +','+
					QUOTENAME(@AddedBy,'''')+','+
					QUOTENAME(@AddedDate,'''')+','+
					Convert(Varchar(10),IsActive)+','''+
					Isnull(Replace([Message],'''',''''''),'NULL')+''','''+
					Isnull(MaskExpression,'NULL')+''','+
					Convert(Varchar(10),MaskFlag)+')'
		From		[UI].[Validator]
		Where		UIElementID	=	@UIElementID

		
		--- FInd Number of rules for given UIElement ID
		--------------------------------------------------------------------------------------------------------
		--added by shivani...change 1

		delete from #Elements where UIElementID=@UIElementID

		set @UIElementID			=	Null
		Set	@datasourceID			=	Null
		Set	@MappedUIID				=	Null
		Set	@DatasourceName			=	NULL
		Set @UIElementName			=	Null
		Set @KeyParentUIElementID	=	NULL
		Set @ParentUIElementID		=	NULL
		Set @ParentUIElementName    =	NULL
		Set @RepeaterUIElementID	=	NULL
		Set @DatasourceName			=	NULL
		Set	@UIElementName			=	NULL
		Set @ParentUIElementName	=	NULL
		Set @RepeaterUIElementName	=	NULL
		Set	@KeyParentUIElementName	=	NULL
		Set	@RegexID				=	NULL
		Set	@Regexname				=	NULL
		Set	@RoleID					=	NULL
		Set	@RoleName				=	NULL
		Set	@DocumentDesignName		=	NULL
		Set	@DocumentDesignID		=	NULL
		set @FormdesignGroupID		=	NULL
		set	@GroupName				=	NULL
		Set	@DocumentRUleID			=	NULL
		Set @targetdesignID			=	NULL
		Set @AnchorDesignID			=	NULL
		Set @AnchorDesignName		=	NULL

		End
--ithn sgle parentid lgech update krun ghet aahot..Uielments add zalyanantr--by shivani change 2
If OBJECT_ID('Tempdb..#RepeaterElements')Is Not Null
		Begin
			Drop Table #RepeaterElements
		End

		select	Distinct f.UIElementID
		into			#RepeaterElements
		from			UI.FormDesignVersionUIElementMap f
		Inner Join		UI.UIElement u
		On				f.UIElementID		=	u.UIElementID
		Where			FormDesignVersionID	=	@FormDesignVersionID
		And				FormID				=	@FormID


		If (@IsFormDesignCopy = 0)
		Begin
			
			;With cteRepeaterElementID As
			(
				Select distinct e.UielementID From [UI].[UIElement] e 
				Inner Join		[UI].[FormDesignVersionUIElementMap] f 
				On				e.UIElementID			=  f.UIElementID 
				Where			e.FormID				=  @FormID 
				And				f.FormDesignVersionID   <> @FormDesignVersionID  --mnje aapn already tya formdesignversionche uielemntid takle #RepeaterElements tble mdhe ..
				--ani ithe (where e.FormID				=  @FormID) ya  condition ni design mdhle sglya vesrion che uiementid taktoy cteRepeaterElementID ..
				--double hoil mnun khali #RepeaterElements delete kele

			)

			Delete		e 
			From		#RepeaterElements  e 
			Inner Join  cteRepeaterElementID c 
			On			e.UIelementID = c.UIElementID--je uielementid doni tbl mdhe common ahe te #repeaterelements mdhun dlt kele

			

			If Not Exists(Select 1 from #RepeaterElements)
			Begin
				  Set @RepeaterCount = 0
			End


		End



		While(@RepeaterCount > 0)
		Begin
				
				Select  @RepeaterUIElement = Min(UIElementID) From #RepeaterElements

				If (@RepeaterUIElement is  Null )
				Begin
					set	@RepeaterCount	=	0
					Break;
				End

				Set	@UIelementName = Null
				Select @UIelementName = dbo.GetUIElementName(@RepeaterUIElement)

				If(@UIelementName Is Not Null or @UIElementName <> '')
				Begin
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
						Select	@FormDesignVersionID,'Select @UIElementID = [dbo].[GetUIElementID]('''+@UIelementName+''','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
				End
				
				set @ParentUIElementID = NULL
				set @ParentUIElementName = NULL

				Select @ParentUIElementID		=	ParentUIElementID From UI.UIElement where UIElementID	=	@RepeaterUIElement

				If(@ParentUIElementID Is NOT NULL or @ParentUIElementID <> '')

				Begin

					Select @ParentUIElementName	=	[dbo].[GetUIElementName](@ParentUIElementID)

			    	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)	
					Select		@FormDesignVersionID,'Set @ParentUIElement = Null '

			    	Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)	
					Select		@FormDesignVersionID,'Select @ParentUIElement = [dbo].[GetUIElementID]('+ Isnull(Quotename (@ParentUIElementName,''''),'NULL')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'

				End
		
				Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)	
				Select	@FormDesignVersionID,
						'Update Ui.Uielement
						 set ParentUIElementID	= @ParentUIElement
						 Where	UIElementID		= @UIElementID'
				
		--- Generate scrpt for inserting data  in RepeaterKeyUIElement Table of given UIElementID

				Select @RepeaterUIElementID = RepeaterUIElementID From [UI].[RepeaterKeyUIElement]  Where UIElementID	=	@RepeaterUIElement
		
				If(@RepeaterUIElementID Is Not Null or @RepeaterUIElementID <> '' )
				Begin
						Select @RepeaterUIElementName	=	[dbo].[GetUIElementName](@RepeaterUIElementID)
		
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
						Select		@FormDesignVersionID,'Select @RepeaterUIElement = [dbo].[GetRepeaterUIElementID]('+QUOTENAME(@RepeaterUIElementName,'''')+','+'@NewFormID'+')'
		
				End

				Select @KeyUIElementName = UIElementName From UI.UIelement where UIElementID = @RepeaterUIElement and FormID = @FormID

				If(@KeyUIElementName Is Not NULL or @KeyUIElementName <> '' )
				Begin
					  Insert Into	Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
					  Select		@FormDesignVersionID,'Select @NewRepeaterUIElement = [dbo].[GetUIElementID]('+QUOTENAME(@KeyUIElementName,'''')+','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
				End
				
				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
				Select		@FormDesignVersionID,
							'RepeaterKeyUIElement',
							'Insert Into [UI].[RepeaterKeyUIElement]
							(RepeaterUIElementID						 ,UIElementID)
							Values		('+'@RepeaterUIElement'+','+'@NewRepeaterUIElement'+')' 
				From		[UI].[RepeaterKeyUIElement] 
				Where		UIElementID	=	@RepeaterUIElement

				Delete From #RepeaterElements where UIElementID = @RepeaterUIElement

				set @RepeaterUIElement	=	NULL
				Set	@KeyUIElementName	=	NULL
		End

-------------------------------------------------------------------------------
--added by shivani--change 3

	insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,

			'select	@FormDesignVersionID = max(FormDesignVersionID )
			from	[UI].FormDesignVersion 
			where	FormDesignID	=	@NewFormID'
			
			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,
			'drop table if exists #ElementJsonPath'
			
			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,
		    'select	a.UIElementID, [UI].GetElementHierarchyInfo(a.UIElementID,''GeneratedName'',''.'') as JSONPath into #ElementJsonPath
			from	UI.UIElement a
			inner join
				[UI].FormDesignVersionUIElementMap b
			on		a.UIElementID = b.UIElementID
			where	b.FormDesignVersionID	=	@FormDesignVersionID
			And		a.FormID				=	@NewFormID
		
		'
------------------------------------------------------------------------------------------------------------------------------------

--added by shivani--change 3
		If OBJECT_ID('Tempdb..#NewElements')Is Not Null
		Begin
			Drop Table #NewElements
		End

		select	Distinct f.UIElementID
		into			#NewElements 
		from			UI.FormDesignVersionUIElementMap f
		Inner Join		UI.UIElement u
		On				f.UIElementID		=	u.UIElementID
		Where			FormDesignVersionID	=	@FormDesignVersionID
		And				FormID				=	@FormID

	If Not Exists(Select 1 from #NewElements)
	Begin
		  Set @keepGoing = 0
	End
	Else
	Begin 
			Set @keepGoing = 1
	End

	while(@keepGoing > 0)
	begin

			--Declare @UIelementNameNew varchar
		--Select  mininum UI ELement from list 

		Set @UIElementID   = NULL
		Set @UIelementNameNew = NULL

		 select @UIElementID = min(UIElementID) from #NewElements 

		 

		 IF(@UIElementID Is NULL Or @UIElementID = '' )
		 Begin
				Set	@keepGoing	=	0
				Break;
		 End

------------------------------------------------------------------------------
	------	--Find DatasourceID and MappedUIElementID of given UIElementID and FOrmdesignversion

		
		If Object_ID ('Tempdb..#datasourceMap') Is Not Null
		Begin
			Drop table #datasourceMap
		End

		Select Distinct  UIElementID,DatasourceID,MappedUIElementID,FormDesignVersionID 
		Into	#datasourceMap 
		From	[UI].[datasourcemapping] 
		where	UIElementID			= @UIElementID 
		And		FormDesignVersionID = @FormDesignVersionID

		Set @datacount = 1

		While(@datacount > 0 )
		Begin

		
		Select top 1 @datasourceID		=	DatasourceID  ,
			         @MappedUIID		=	MappedUIElementID
		From	#datasourceMap
		WHere UIelementID= @UIElementID
		And	  FormDesignVersionID= @FormDesignVersionID

		If (@datasourceID Is null Or @datasourceID = '')
		Begin
			set @datacount  = 0
			Break;
		End

		If (@datasourceID is not Null and @MappedUIID Is Not Null)

		Begin
		
		-- Once We get datasourceID and UILementID then here we are finding that datasourcename and UIelementName by passing Datasourceid and uielementID

		Select @DatasourceName	=	DataSourceName,
			   @UIElementName	=	UIElementName
		From   [dbo].[GetMappedID_DatasourceName](@datasourceID,@MappedUIID)

		If (@DatasourceName is not Null and @UIElementName Is Not Null)

		Begin
			   Select @UIelementNameNew = dbo.GetUIElementName(@UIElementID)

				If(@UIelementNameNew Is Not Null or @UIelementNameNew <> '')
				Begin
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
						Select	@FormDesignVersionID,'Select @UIElementIDNew = [dbo].[GetUIElementID]('''+@UIelementNameNew+''','+'@NewFormID'+','+'@NewFormdesignVersionID'+')'
				End


			---if datasourcename and uiemenetName is not null then we pass that name to function and get their ID'S from another environment.

			Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
			Select	@FormDesignVersionID,
					'NewDatasourceID' ,
					'Select	@NewdatasourceID		=	DataSourceID	,
							@NewMappedUIElementID	=	MappedUIElementID
					From [dbo].[GetIDs] ('+QuoteName(@DatasourceName,'''')+','+Quotename(@UIElementName,'''')+')' 
		
			---Generate insert script for inserting data in datasourcemapping table

			Insert Into Temp.Formdesignquery(FormdesignVersionID , QueryType	 ,Sqlquery)
			Select		@FormDesignVersionID,
						'Datasourcemapping',
						'Insert Into [UI].[DataSourceMapping]
						(UIElementID,DataSourceID,MappedUIElementID,IsPrimary,DataSourceElementDisplayModeID,DataSourceFilter,DataCopyModeID,FormDesignID,FormDesignVersionID,IsKey,DataSourceOperatorID,[Value],DataSourceModeID,IncludeChild)
						Values('+'@UIElementIDNew'+','+
						'@NewdatasourceID'+','+
						'@NewMappedUIElementID'+','+
						Convert(Varchar(10),IsPrimary)+','+
						Convert(Varchar(10),Isnull(DataSourceElementDisplayModeID,-2))+','''+
						Isnull(DataSourceFilter,'NULL')+''','+
						Convert(Varchar(10),Isnull(DataCopyModeID,-2))+','+
						'@NewFormID'+','+
						'@NewFormdesignVersionID'+','+
						Convert(Varchar(10),IsKey)+','+
						Isnull(Convert(Varchar(10),DataSourceOperatorID),-2)+','''+
						Isnull([Value],'NULL')+''','+
						Convert(Varchar(10),DataSourceModeID)+','+
						Convert(Varchar(10),IncludeChild)+')'

			From		[UI].[DataSourceMapping]
			Where		UIelementID			=	@UIElementID
			And			DataSourceID		=	@DatasourceID
			And			FormDesignVersionID	=	@FormDesignVersionID


			
		End
		End

			delete from #datasourceMap where datasourceID = @datasourceID and MappedUIElementID = @MappedUIID and FormdesignVersionID = @FormDesignVersionID
			set @datasourceID = Null
			Set @MappedUIID = Null
			
			Insert Into Temp.Formdesignquery(FormdesignVersionID , QueryType	 ,Sqlquery)
			Select		@FormDesignVersionID,
						'Datasourcemapping','set @UIElementIDNew=Null'
	End
		


------------------------------------------------------------------------------
--added by shivani change 4



		IF Object_ID('Tempdb..#Rules') Is Not Null
		Begin
			Drop Table #Rules
		End	

		Select	RuleID
		Into	#Rules
		From	UI.PropertyRuleMap 
		Where	UIElementID	=	@UIElementID


		Set	@RuleCount	=	@@ROWCOUNT

		---Find Current ExpressionID

		Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select		@FormDesignVersionID,
					'NewParentExpression',
					'Select  @NewParentExpressionID = IDENT_CURRENT('+Quotename('[UI].[Expression]','''')+')'

		

		While(@RuleCount > 0)

			Begin
					--Take Minimum RuleID 

					select @RuleID	=	NULL

					Select  @RuleID	=	Min(RuleID) From	#Rules

					---If ruleID is null then end while Loop

					If(@RuleID	Is Null)
					Begin
						Set	@RuleCount	=	0
						Break;
					End

					If  Exists(select 1  from [Temp].[temp2] where RuleID =@RuleID ) 
						Begin 
	        			delete from #Rules where RuleID = @RuleID
						Set		@RuleID	=	NULL

						Set	@RuleCount	=	@RuleCount - 1
						End
					Else
					begin
					If  Exists(select 1  from Ui.[Rule] where RuleID =@RuleID )  ---28/10--shiv
					Begin
					IF Object_ID('Tempdb..#PropertyRuleMaptemp') Is Not Null
		               Begin
		               	Drop Table #PropertyRuleMaptemp
		               End	
						---If RuleID is not null then Insert Record in Rule Table

						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						Select		@FormDesignVersionID,
									'Rule',
									'Insert Into [UI].[Rule] 
									( RuleName,RuleDescription,RuleTargetTypeID,ResultSuccess,ResultFailure,AddedBy,AddedDate,IsResultSuccessElement,
									 IsResultFailureElement,Message,RunOnLoad )
									 Values( '''+ RuleName		+ ''','''+
												Isnull(Replace(RuleDescription,char(39), char(39)+char(39)),'NULL' )+''' ,'+
												Convert(Varchar(10),RuleTargetTypeID)+','''+
												Isnull(ResultSuccess,'NULL')+''' ,'''+
												Isnull(ResultFailure,'NULL')+''' ,'+
												quotename(@AddedBy,'''')+','+
												quotename(Convert(Varchar(10),@AddedDate),'''')+','+
												Convert(Varchar(10),IsResultSuccessElement)	+','+
												Convert(Varchar(10),IsResultFailureElement)+','''+
												Isnull(Replace([Message],'''',''''''),'NULL')+''','+
												Convert(Varchar(10),Isnull(RunOnLoad,0))+'
						 
									 )' 

						 From		[UI].[Rule]
						 Where		RuleID	=	@RuleID 

						 ---Find Newly created RuleID after insertion of rule data in rule table

						 Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						 Select		 @FormDesignVersionID,
									 'NewRuleID',
									 'Select	  @NewtRuleID	  =	IDENT_CURRENT('+QUOTENAME('[UI].[Rule]','''')+')'

						
						---Generate Insert Script to insert Data in PropertyRUleMap table
						
					select uielementid into #PropertyRuleMaptemp from [UI].[PropertyRuleMap] where RuleID =@RuleID
						--select uielementid ,dbo.GetUIElementName(@UIElementID) as UIelementName into #PropertyRuleMaptemp from [UI].[PropertyRuleMap] where RuleID =@RuleID

						 
		--shiv		
		                  Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						 Select		@FormDesignVersionID,
									'PropertyRuleMap',
									'Insert Into [UI].[PropertyRuleMap] (RuleID ,UIElementID,TargetPropertyID,AddedBy,AddedDate,IsCustomRule)
									 Values( '+'@NewtRuleID'+','+
									            -- '(select[dbo].[GetUIElementID]('''+UIelementName+''','+'@NewFormID'+','+'@NewFormdesignVersionID'+'))'+','+
											 '(select top 1 UIElementID from #ElementJsonPath where JSONPath='''+ UI.GetElementHierarchyInfo(PRM.Uielementid,'GeneratedName','.')+''')'+','+
											   Convert(Varchar(10),TargetPropertyID)+','+
											   quotename(@AddedBy,'''')+','+
											   quotename(@AddedDate,'''')+','+
											   Convert(Varchar(10),Isnull(IsCustomRule,0))+'
						 
									 )'
						 From		 #PropertyRuleMaptemp TPRM 
						 inner join [UI].[PropertyRuleMap] PRM  on PRM.Uielementid=TPRM.Uielementid
						Where		RuleID = @RuleID  --and uielementid=@UIElementID

						------Chidanand made changes
						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						 Select		 @FormDesignVersionID,
									 'NewpropertyRuleMapID',
									 'Select	  @NewPropertyRuleMapID	  =	IDENT_CURRENT('+QUOTENAME('[UI].[PropertyRuleMap]','''')+')'
                           
						   

						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						Select		@FormDesignVersionID,
									'NewRuleID',
									'Insert Into UI.TargetRepeaterKeyFilter(RuleID,RepeaterKey,RepeaterKeyValue,PropertyRuleMapID)
						         	Values(@NewtRuleID,dbo.GetUIElementNameFromJSONPath('''+(Select UI.GetElementHierarchyInfo(ue.UIElementID,'GeneratedName','.') from UI.UIElement ue inner join ui.formdesign uf on uf.formid=ue.formid inner join ui.formdesignversion fdv on fdv.formdesignid=uf.formid inner join ui.formdesignversionuielementmap um on um.FormDesignVersionID=fdv.FormDesignVersionID and ue.uielementid=um.uielementid where UIElementName=a.RepeaterKey  and um.FormDesignVersionID=@FormDesignVersionID)+''' ,@NewFormID,@NewFormdesignVersionID),'''+RepeaterKeyValue+''',@NewPropertyRuleMapID)'
									--Values(@NewtRuleID,dbo.GetUIElementNameFromJSONPath('''+(Select UI.GetElementHierarchyInfo(UIElementID,'GeneratedName','.') from UI.UIElement where UIElementName=a.RepeaterKey )+''' ,@NewFormID,@NewFormdesignVersionID),'''+RepeaterKeyValue+''',@NewPropertyRuleMapID)'

								 --       '[dbo].[GetUIElementID]('''+(select dbo.GetUIElementName(@PropertyRuleMapElement))+''' ,@NewFormID,@NewFormdesignVersionID)'
						From		UI.TargetRepeaterKeyFilter a
						Where		RuleID	=	@RuleID
				 


							--- generate insert script to insert data in expression table for those Expressions whoes parentExpressionID is Above Newlygenertaed ParentExpressionID

						if OBJECT_ID('tempdb..#Expressions') is not null
						begin
							drop table #Expressions
						end


		
						select row_number() over (order by  ExpressionID) as newPID,0 as NewParentID, * 
						into		#Expressions
						from		[UI].Expression 
						Where		RuleID  = @RuleiD

						--Update		#Expressions set newPID = @ExpressionID+newPID

						update		a 
						set			NewParentID = b.newPID 
						from		#Expressions a
						inner join	#Expressions b
						on			a.ParentExpressionID = b.ExpressionID

						
						DROP TABLE IF EXISTS #ExpressionRN

						SELECT *,ROW_NUMBER() OVER(PARTITION BY  ruleid ORDER BY expressionid) [Rn] INTO #ExpressionRN
						FROM  #Expressions
						WHERE ruleid=@RuleID


						Insert Into Temp.Formdesignquery(Sqlquery)
						Select      'Select @ExpressionID = IDENT_CURRENT(''[UI].[Expression]'')'

						Insert Into Temp.Formdesignquery(Sqlquery)
						Select		'SET IDENTITY_INSERT [UI].[Expression] ON '
		

						Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						Select		@FormDesignVersionID,
									'Expression_NewParent',
									'Insert Into [UI].[Expression] (ExpressionID,LeftOperand,RightOperand,OperatorTypeID,LogicalOperatorTypeID,AddedBy,AddedDate,RuleID,ParentExpressionID,
																	ExpressionTypeID,IsRightOperandElement)
									 Values(@ExpressionID +	'+Convert(varchar(10),newPID)+','''+ Isnull(LeftOperand,'NULL')+''','''+
													   Isnull(RightOperand,'NULL')+''','+
													   Convert(Varchar(10),OperatorTypeID)+','+
													   Convert(Varchar(10),LogicalOperatorTypeID)+','+
													   quotename(@AddedBy,'''')+','+
													   quotename(@AddedDate,'''')+','+
													   '@NewtRuleID'+',
													   '+ Case When NewParentID = 0 Then 'NULL' Else'@ExpressionID + '+
														Convert(Varchar(10),NewParentID) End +' ,'+
													   Convert(Varchar(10),ExpressionTypeID)+','+
													   Convert(Varchar(10),IsRightOperandElement)+')'
								 From		#Expressions 
								 Where		RuleID	=	@RuleID
						
						
						
	

						Insert Into Temp.Formdesignquery(Sqlquery)
						Select		'SET IDENTITY_INSERT [UI].[Expression] OFF'

							
		                  Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
						 Select		@FormDesignVersionID,
									'Expression_Rownumbered','INSERT INTO 	#NewExpression (ExpressionID	 ,LeftOperand ,	RightOperand ,	OperatorTypeID ,	LogicalOperatorTypeID ,	AddedBy	 ,AddedDate,	UpdatedBy  ,	UpdatedDate ,	RuleID ,	ParentExpressionID ,	ExpressionTypeID ,	IsRightOperandElement)
						    SELECT ExpressionID	 ,LeftOperand ,	RightOperand ,	OperatorTypeID ,	LogicalOperatorTypeID ,	AddedBy	 ,AddedDate,	UpdatedBy  ,	UpdatedDate ,	RuleID ,	ParentExpressionID ,	ExpressionTypeID ,	IsRightOperandElement
							FROM  ui.expression
							WHERE ruleid=@NewtRuleID'



				--- added entry in complex operator and targetRepeaterkeyfilter

				If Exists(Select 1 From UI.ComplexOperator where ExpressionID in(Select ExpressionID from UI.Expression where RuleID =@RuleID))
				Begin

					
					Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
					Select		@FormDesignVersionID,'ComplexOperator',
								'Insert Into UI.ComplexOperator (	ExpressionID,OperatorID		,Factor	,FactorValue)
								 Select ExpressionID,OperatorTypeID, '''+cast (Factor as varchar(10))+''' ,'+cast (FactorValue as varchar(10))+'
							
								 From	UI.Expression 
								 Where	RuleID			=	@NewtRuleID
								 And	dbo.GetJSONPathFromUIElementName(LeftOperand,@NewFormID,@NewFormdesignVersionID)	=	'''+dbo.GetJSONPathFromUIElementName(LeftOperand,@FormID,@FormDesignVersionID)+'''
								 And	dbo.GetJSONPathFromUIElementName(RightOperand,@NewFormID,@NewFormdesignVersionID)	=	'''+dbo.GetJSONPathFromUIElementName(RightOperand,@FormID,@FormDesignVersionID)+''''
					From		UI.ComplexOperator a
					Inner Join	UI.Expression      b
					On			a.ExpressionID		=	b.ExpressionID
					Where		RuleID				=   @RuleID

					
				End
				
				
				DROP TABLE IF EXISTS #RepeaterKeyFilter_RowNumbered
				
				
				SELECT rk.*,e.[rn] into #RepeaterKeyFilter_RowNumbered
				FROM  #ExpressionRN e
				inner join ui.RepeaterKeyFilter rk on rk.ExpressionID=e.ExpressionID 
				WHERE ruleid=@ruleid

				
				If Exists(Select 1 From UI.RepeaterKeyFilter where ExpressionID in(Select ExpressionID from UI.Expression where RuleID =@RuleID))
				Begin
					Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)	
					Select		@FormDesignVersionID,'RepeaterKeyFilter',	
								'Insert Into UI.RepeaterKeyFilter(ExpressionID,RepeaterKey,RepeaterKeyValue,IsRightOperand)
								 Select		e.ExpressionID,dbo.GetUIElementNameFromJSONPath('''+(Select UI.GetElementHierarchyInfo(ue.UIElementID,'GeneratedName','.') from UI.UIElement ue inner join ui.formdesign uf on uf.formid=ue.formid inner join ui.formdesignversion fdv on fdv.formdesignid=uf.formid inner join ui.formdesignversionuielementmap um on um.FormDesignVersionID=fdv.FormDesignVersionID and ue.uielementid=um.uielementid where UIElementName=a.RepeaterKey  and um.FormDesignVersionID=@FormDesignVersionID)+''',@NewFormID,@NewFormdesignVersionID),'''+RepeaterKeyValue+''','+Convert(varchar(10),IsRightOperand)+'

								 From		UI.Expression	e
								 inner join 	#NewExpression ne on e.expressionid=ne.expressionid
								 Where		e.RuleID																				=	@NewtRuleID
								 And		dbo.GetJSONPathFromUIElementName(e.LeftOperand,@NewFormID,@NewFormdesignVersionID)	=	'''+dbo.GetJSONPathFromUIElementName(b.LeftOperand,@FormID,@FormDesignVersionID)+'''
								 And		dbo.GetJSONPathFromUIElementName(e.RightOperand,@NewFormID,@NewFormdesignVersionID)	=	'''+dbo.GetJSONPathFromUIElementName(b.RightOperand,@FormID,@FormDesignVersionID)+'''
								 ANd ne.[rn]='+cast(er.[Rn] as varchar(10))+'
								 
								 '

					  
					   --	Select		ExpressionID,dbo.GetUIElementNameFromJSONPath('''+(Select UI.GetElementHierarchyInfo(UIElementID,'GeneratedName','.') from UI.UIElement where UIElementName=a.RepeaterKey )+''',@NewFormID,@NewFormdesignVersionID),'''+RepeaterKeyValue+''','+Convert(varchar(10),IsRightOperand)+'

					From		UI.RepeaterKeyFilter a
					Inner Join	UI.Expression		b
					On			a.ExpressionID		=	b.ExpressionID
					inner join #ExpressionRN er on er.ExpressionId=b.ExpressionID
					Where		b.RuleID				=   @RuleID
					 
				End
				

				
			        Insert  into [Temp].[temp2] (RuleID) select RuleID from #Rules where RuleID = @RuleID

					--Select	RuleID Into	#RulesNameDesc From	#Rules where RuleID = @RuleID --added 0809

					delete from #Rules where RuleID = @RuleID
					Set		@RuleID	=	NULL

					Set	@RuleCount	=	@RuleCount - 1
			    End
				Else
				 Begin 
				     delete from #Rules where RuleID = @RuleID
						Set		@RuleID	=	NULL

						Set	@RuleCount	=	@RuleCount - 1
					End
						
						
			  End
			End
     delete from #NewElements where UIElementID=@UIElementID  

	 		set @UIElementID			=	Null
		Set	@datasourceID			=	Null
		Set	@MappedUIID				=	Null
		Set	@DatasourceName			=	NULL
		Set @UIElementName			=	Null
		Set @KeyParentUIElementID	=	NULL
		Set @ParentUIElementID		=	NULL
		Set @ParentUIElementName    =	NULL
		Set @RepeaterUIElementID	=	NULL
		Set @DatasourceName			=	NULL
		Set	@UIElementName			=	NULL
		Set @ParentUIElementName	=	NULL
		Set @RepeaterUIElementName	=	NULL
		Set	@KeyParentUIElementName	=	NULL
		Set	@RegexID				=	NULL
		Set	@Regexname				=	NULL
		Set	@RoleID					=	NULL
		Set	@RoleName				=	NULL
		Set	@DocumentDesignName		=	NULL
		Set	@DocumentDesignID		=	NULL
		set @FormdesignGroupID		=	NULL
		set	@GroupName				=	NULL
		Set	@DocumentRUleID			=	NULL
		Set @targetdesignID			=	NULL
		Set @AnchorDesignID			=	NULL
		Set @AnchorDesignName		=	NULL

		End

------------------------------------------------------------------------------
			
			Drop table if exists #Elements_UserClaims   --added by ss--04102021

			select	Distinct f.UIElementID
			into			#Elements_UserClaims 
			from			UI.FormDesignVersionUIElementMap f
			Inner Join		UI.UIElement u
			On				f.UIElementID		=	u.UIElementID
			Where			FormDesignVersionID	=	@FormDesignVersionID
			And				FormID				=	@FormID

				Insert Into Temp.Formdesignquery(FormdesignVersionID ,QueryType	 ,Sqlquery)
		Select distinct @FormDesignVersionID,
				'UserClaim',
				'Insert Into [Sec].[UserClaim]
				(ResourceID ,Resource,Action,RoleID,UserId,ResourceType) 
				Values ( (select top 1 UIElementID from #ElementJsonPath where JSONPath='''+ UI.GetElementHierarchyInfo(ResourceID,'GeneratedName','.')+''')'+','''+Resource+''','''+Action+''','+Cast(RoleID as varchar(10))+','+Cast(UserId as varchar(10))+','''+ResourceType+''')'
		from #Elements_UserClaims euc 
		inner join sec.userclaim uc on uc.ResourceID=euc.uielementid


			Select 	@FormdesignGroupCount				=	Count(1) From [UI].[FormDesignGroup] where FormDesignGroupID In(Select  FormDesignGroupID From UI.FormDesignGroupMapping where FormID	=	@FormID)				
			Select	@FormDesignGroupMappingCount		=   Count(1) From [UI].[FormDesignGroupMapping] where FormID	=	@FormID
			Select	@FormDesignVersionCount				=   Count(1) From [UI].[FormDesignVersion] Where FormDesignVersionID	=	@FormDesignVersionID	
			Select	@DataSourceCount					=   Count(1) From [UI].[DataSource]	Where FormDesignVersionID   =   @FormDesignVersionID
			Select	@UIElementCount						=   Count(1) From [UI].UIElement where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@DocumentRuleCount					=	Count(1) From [UI].[DocumentRule]	where FormDesignVersionID	=	@FormDesignVersionID
			Select	@DocumentRuleEventMapCount			=	Count(1) From [UI].[DocumentRuleEventMap] where DocumentRuleID In(Select distinct DocumentRuleID From [UI].[DocumentRule] Where FormDesignVersionID	=	@FormDesignVersionID)
			Select	@DataSourceMappingCount				=   Count(1) From [UI].[DataSourceMapping] Where FormDesignVersionID= @FormDesignVersionID
			Select	@FormDesignVersionUIElementMapCount =   Count(1) From [UI].FormDesignVersionUIElementMap where FormDesignVersionID	=	@FormDesignVersionID
			Select	@AlternateUIElementLabelCount		=	Count(1) From [UI].[AlternateUIElementLabel] where FormDesignVersionID = @FormDesignVersionID
			Select	@CheckBoxUIElementCount				=   Count(1) From [UI].[CheckBoxUIElement] where UIElementID In(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@CalendarUIElementCount				=   Count(1) From [UI].[CalendarUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@DropDownElementItemCount			=   Count(1) From [UI].[DropDownElementItem] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@DropDownUIElementCount				=	Count(1) From [UI].[DropDownUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@KeyProductUIElementMapCount		=	Count(1) From [UI].[KeyProductUIElementMap] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@RadioButtonUIElementCount			=	Count(1) From [UI].[RadioButtonUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@RepeaterUIElementCount				=	Count(1) From [UI].[RepeaterUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@SectionUIElementCount				=	Count(1) From [UI].[SectionUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@TabUIElementCount					=	Count(1) From [UI].[TabUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@TextBoxUIElementCount				=	Count(1) From [UI].[TextBoxUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@ValidatorCount						=	Count(1) From [UI].[Validator] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@SrcRuleCount						=	Count(1) From [UI].[Rule] where RuleID in(Select Distinct RuleID From [UI].[PropertyRuleMap]p Inner Join  [UI].[FormDesignVersionUIElementMap] u on   p.UIElementID = u.UIElementID where FormDesignVersionID = @FormDesignVersionID ) 
			Select	@PropertyRuleMapCount				=	Count(1) From [UI].[propertyRuleMap] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
			Select	@ExpressionCount					=   Count(1) From [UI].[Expression] where RuleID In(Select Distinct p.RuleID From [UI].[PropertyRuleMap] p Inner Join [UI].[FormDesignVersionUIElementMap] u on p.UIElementID = u.UIElementID where u.FormDesignVersionID = @FormDesignVersionID)
			Select	@RepeaterKeyUIElementCount			=   Count(1) From [UI].[RepeaterKeyUIElement] where UIElementID In(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)
		    select @RepeaterKeyFilterCount              =  Count(1) From [UI].[RepeaterKeyFilter] where expressionid in(select expressionId from ui.[Expression] where RuleID in(select RuleID from Ui.[PropertyRuleMap] where UIElementID in (Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @FormDesignVersionID)))

			
			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select 	@FormdesignGroupCount				=	Count(1) From [UI].[FormDesignGroup] where FormDesignGroupID In(Select  FormDesignGroupID From UI.FormDesignGroupMapping where FormID	=	@NewFormID)'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@FormDesignGroupMappingCount		=   Count(1) From [UI].[FormDesignGroupMapping] where FormID	=	@NewFormID'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@FormDesignVersionCount				=   Count(1) From [UI].[FormDesignVersion] Where FormDesignVersionID	=	@NewFormdesignVersionID'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DataSourceCount					=   Count(1) From [UI].[DataSource]	Where FormDesignVersionID   =   @NewFormdesignVersionID'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@UIElementCount						=   Count(1) From [UI].UIElement where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID)'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DocumentRuleCount					=	Count(1) From [UI].[DocumentRule]	where FormDesignVersionID	=	@NewFormdesignVersionID'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DocumentRuleEventMapCount			=	Count(1) From [UI].[DocumentRuleEventMap] where DocumentRuleID In(Select distinct DocumentRuleID From [UI].[DocumentRule] Where FormDesignVersionID	=	@NewFormdesignVersionID)'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DataSourceMappingCount				=   Count(1) From [UI].[DataSourceMapping] Where FormDesignVersionID= @NewFormdesignVersionID'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@FormDesignVersionUIElementMapCount =   Count(1) From [UI].FormDesignVersionUIElementMap where FormDesignVersionID	=	@NewFormdesignVersionID'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@AlternateUIElementLabelCount		=	Count(1) From [UI].[AlternateUIElementLabel] where FormDesignVersionID = @NewFormdesignVersionID'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@CheckBoxUIElementCount				=   Count(1) From [UI].[CheckBoxUIElement] where UIElementID In(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID =  @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@CalendarUIElementCount				=   Count(1) From [UI].[CalendarUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID  )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DropDownElementItemCount			=   Count(1) From [UI].[DropDownElementItem] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID =  @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@DropDownUIElementCount				=	Count(1) From [UI].[DropDownUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@KeyProductUIElementMapCount		=	Count(1) From [UI].[KeyProductUIElementMap] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )
			'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@RadioButtonUIElementCount			=	Count(1) From [UI].[RadioButtonUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@RepeaterUIElementCount				=	Count(1) From [UI].[RepeaterUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@SectionUIElementCount				=	Count(1) From [UI].[SectionUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID  )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@TabUIElementCount					=	Count(1) From [UI].[TabUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@TextBoxUIElementCount				=	Count(1) From [UI].[TextBoxUIElement] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@ValidatorCount						=	Count(1) From [UI].[Validator] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@RuleCount						=	Count(1) From [UI].[Rule] where RuleID in(Select Distinct RuleID From [UI].[PropertyRuleMap]p Inner Join  [UI].[FormDesignVersionUIElementMap]u on   p.UIElementID = u.UIElementID where FormDesignVersionID = @NewFormdesignVersionID ) '


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@PropertyRuleMapCount				=	Count(1) From [UI].[propertyRuleMap] where UIElementID in(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@ExpressionCount					=   Count(1) From [UI].[Expression] where RuleID In(Select Distinct p.RuleID From [UI].[PropertyRuleMap] p Inner Join [UI].[FormDesignVersionUIElementMap]u on   p.UIElementID = u.UIElementID where FormDesignVersionID = @NewFormdesignVersionID )'


			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@RepeaterKeyUIElementCount			=   Count(1) From [UI].[RepeaterKeyUIElement] where UIElementID In(Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID )'
			  
			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select		@FormDesignVersionID,'Select	@RepeaterKeyFilterCount			=   Count(1) From [UI].[RepeaterKeyFilter] where expressionid in(select expressionId from ui.[Expression] where RuleID in(select RuleID from Ui.[PropertyRuleMap] where UIElementID in (Select Distinct UIElementID From [UI].[FormDesignVersionUIElementMap] where FormDesignVersionID = @NewFormdesignVersionID)))' --added by shivani 0902

			
			 
			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Select ''FormdesignGroupCount'','+Convert(Varchar(10),@FormdesignGroupCount	)+' as Source,@FormdesignGroupCount As Destination'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Select ''FormDesignGroupMappingCount'','+Convert(Varchar(10), @FormDesignGroupMappingCount)+' As Source,@FormDesignGroupMappingCount As Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)	
			Select @FormdesignVersionID,'Select ''FormDesignVersionCount'','+Convert(Varchar(10), @FormDesignVersionCount)+' As Source ,@FormDesignVersionCount As Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''DataSourceCount'','+Convert(Varchar(10),@DataSourceCount)+' as Source,	@DataSourceCount as destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)				
			Select @FormdesignVersionID,'Select ''UIElementCount''	,'+Convert(Varchar(10),@UIElementCount)+' as Source,@UIElementCount as Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)					
			Select @FormdesignVersionID,'Select ''DocumentRuleCount''	,'+Convert(Varchar(10),@DocumentRuleCount)+' as Source,@DocumentRuleCount As Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)				
			Select @FormdesignVersionID,'Select ''DocumentRuleEventMapCount'','+Convert(Varchar(10), @DocumentRuleEventMapCount)+' as Source,@DocumentRuleEventMapCount as Destination'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''DataSourceMappingCount'','+Convert(Varchar(10),@DataSourceMappingCount)+' as Source,@DataSourceMappingCount As Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''FormDesignVersionUIElementMapCount '','+Convert(Varchar(10), @FormDesignVersionUIElementMapCount)+' as Source ,@FormDesignVersionUIElementMapCount as Destination' 

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Select ''AlternateUIElementLabelCount'','+Convert(Varchar(10), @AlternateUIElementLabelCount)+' as Source,@AlternateUIElementLabelCount as Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Select ''CheckBoxUIElementCount''	,'+Convert(Varchar(10),@CheckBoxUIElementCount)+' as Source,@CheckBoxUIElementCount as Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''CalendarUIElementCount'','+Convert(Varchar(10), @CalendarUIElementCount)+' as Source,@CalendarUIElementCount as Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''DropDownElementItemCount'','+Convert(Varchar(10),@DropDownElementItemCount)+' as Source,@DropDownElementItemCount As Destination'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''DropDownUIElementCount''	,'+Convert(Varchar(10),@DropDownUIElementCount)+' as Source,@DropDownUIElementCount As Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''KeyProductUIElementMapCount'','+Convert(Varchar(10),@KeyProductUIElementMapCount)+' As Source,@KeyProductUIElementMapCount As Destination'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)	
			Select @FormdesignVersionID,'Select ''RadioButtonUIElementCount'','+Convert(Varchar(10),@RadioButtonUIElementCount)+' as Source,@RadioButtonUIElementCount as Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''RepeaterUIElementCount''	,'+Convert(Varchar(10),@RepeaterUIElementCount)+' as Source,@RepeaterUIElementCount as Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''SectionUIElementCount''	,'+Convert(Varchar(10),@SectionUIElementCount)+' as Source ,@SectionUIElementCount as Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''TabUIElementCount''	,'+Convert(Varchar(10),@TabUIElementCount)+' As Source ,@TabUIElementCount As Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)			
			Select @FormdesignVersionID,'Select ''TextBoxUIElementCount'','+Convert(Varchar(10),@TextBoxUIElementCount)+' As Source ,@TextBoxUIElementCount as Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''ValidatorCount'','+Convert(Varchar(10),@ValidatorCount)+' As Source ,@ValidatorCount  As Destination'				

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''RuleCount''		,'+Convert(Varchar(10),@SrcRuleCount)+' As Source ,@RuleCount as Destination'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'				

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''PropertyRuleMapCount'','+Convert(Varchar(10),@PropertyRuleMapCount)+' As Source ,@PropertyRuleMapCount As Destination'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''ExpressionCount'','+Convert(Varchar(10),@ExpressionCount)+' As Source ,@ExpressionCount As Destination'	

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)
			Select @FormdesignVersionID,'Union'		

			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''RepeaterKeyUIElementCount'','+Convert(Varchar(10),@RepeaterKeyUIElementCount)+' As Source ,@RepeaterKeyUIElementCount As Destination'			
			
			Insert Into Temp.Formdesignquery(FormdesignVersionID	 ,Sqlquery)		
			Select @FormdesignVersionID,'Select ''RepeaterKeyFilterCount'','+Convert(Varchar(10),@RepeaterKeyFilterCount)+' As Source ,@RepeaterKeyFilterCount As Destination'			


			Insert Into Temp.Formdesignquery(FormdesignVersionID ,Sqlquery)
			Select		@FormDesignVersionID,
						'Set @NewUIElementID			= NULL
						 Set @NewdatasourceID			= NULL
						 Set @NewMappedUIElementID		= NULL
						 Set @NewtRuleID				= NULL
						 Set @NewParentExpressionID		= NULL
						 Set @NewFormID					= NULL
						 Set @NewFormdesignVersionID	= NULL
						 Set @NewFormdesignGroupID		= NULL
						 Set @FormVersiondata			= NULL
						 Set @ParentUIElement			= NULL
						 Set @RepeaterUIElement			= NULL
						 Set @KeyParentElement			= NULL
						 Set @NewRegexID				= NULL
						 Set @NewRoleID					= NULL
						 Set @NewDocumentDesignTypeID	= NULL
						 Set @VersionNumber				= NULL
						 Set @NewDocumentRUleID			= NULL
						 Set @NewRepeaterUIElement		= NULL
						  Set @ExpressionID				= NULL
						 
						 ' 
				
			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,' Commit Transaction '

			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,' END TRY '

			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,' Begin Catch '

			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,'IF(@@Error > 0)  Begin 	Rollback Transaction End 
																	SELECT  ERROR_NUMBER() AS ErrorNumber  
																	,ERROR_SEVERITY() AS ErrorSeverity  
																	,ERROR_LINE() AS ErrorLine  
																	,ERROR_MESSAGE() AS ErrorMessage; '

			insert Into Temp.Formdesignquery( FormdesignVersionID , SqlQuery )
			Select							 @formdesignversionID ,' End Catch '

		Delete From #FormDesignList where FormdesignVersionID	= @FormDesignVersionID

		Set		@FormDesignVersionID	=	NULL
		Set     @Formname				=	NULL
		Set		@FormID					=	NULL
		Set     @FormdesignGroupCount		 =  NULL		
		Set		@FormDesignGroupMappingCount =  NULL
		Set		@FormDesignVersionCount			=  NULL		
		Set		@DataSourceCount				=  NULL	
		Set		@UIElementCount					=  NULL	
		Set		@DocumentRuleCount				=  NULL	
		Set		@DocumentRuleEventMapCount		=  NULL	
		Set		@DataSourceMappingCount			=  NULL	
		Set		@FormDesignVersionUIElementMapCount =  NULL
		Set		@AlternateUIElementLabelCount	=  NULL	
		Set		@CheckBoxUIElementCount			=  NULL	
		Set		@CalendarUIElementCount			=  NULL	
		Set		@DropDownElementItemCount		=  NULL	
		Set		@DropDownUIElementCount			=  NULL	
		Set		@KeyProductUIElementMapCount	=  NULL	
		Set		@RadioButtonUIElementCount		=  NULL	
		Set		@RepeaterUIElementCount			=  NULL	
		Set		@SectionUIElementCount			=  NULL	
		Set		@TabUIElementCount				=  NULL	
		Set		@TextBoxUIElementCount			=  NULL	
		Set		@ValidatorCount					=  NULL	
		Set		@SrcRuleCount					=  NULL	
		Set		@PropertyRuleMapCount			=  NULL	
		Set		@ExpressionCount				=  NULL	
		Set		@RepeaterKeyUIElementCount		=  NULL	
		Set     @RepeaterKeyFilterCount         =  NULL	




End

	Update t
	Set		Sqlquery	=	Replace (Sqlquery,', -2,',', NULL ,')
	From	Temp.Formdesignquery t

	Update t
	Set		Sqlquery	=	Replace (Sqlquery,',-2,',', NULL ,')
	From	Temp.Formdesignquery t

	Update t
	Set		Sqlquery	=	Replace (Sqlquery,',-2 ,',', NULL ,')
	From	Temp.Formdesignquery t
	
	Update t
	Set		Sqlquery	=	Replace (Sqlquery,'''NULL''','NULL')
	From	Temp.Formdesignquery t

	Update Temp.Formdesignquery 
	Set		Sqlquery	=	Replace (Sqlquery,'@ExpressionID + -2','NULL')

	--Select [Sqlquery] from Temp.Formdesignquery order by ID
end
