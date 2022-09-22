
/*
	Design Migration SSIS Project Scripts/Queries
	Contributor - Rohit Agalave
*/



/*  1
	Activity Name : EST_To_Get_FormDesignID's
	Activity Type : Execute SQL Task
	Purpose : For Fetching All FormDesignID's
*/
-- Query
select formid from ui.formdesign



/*  2
	Activity Name : EST_Count_FDV
	Activity Type : Execute SQL Task
	Purpose : For getting count of FormDesignVersion
*/
-- Query
select count(*) from ui.formdesignversion where formdesignid = 0



/*  3
	Activity Name : EST_To_Change_Flag_1
	Activity Type : Execute SQL Task
	Purpose : If the count is greater than 0 then set flag to 1
*/
-- Query
declare @cnt int
set @cnt = (select top 1(formid) from ui.FormDesign)
if(@cnt>0)
begin
	declare @flag int
	set @flag = 1
	select @flag
end



/*  4
	Activity Name : EST_To_Get_DesignVersions
	Activity Type : Execute SQL Task
	Purpose : To get latest FormDesignVersionID of each year based on FormID 
*/
-- Query
select max(formDesignVersionId),year(EffectiveDate) from ui.formdesignversion  where FormDesignID =  0 group by EffectiveDate


/*  5
	Activity Name : EST_To_Copy_Script_From_Table_To_SQL_File
	Activity Type : Execute SQL Task
	Purpose : To copy generated queries from client Temp.Formdesignquery to test.sql file
*/
-- Query

EXEC Master..xp_CMDShell 'BCP "select Sqlquery from eBS_AHP_PROD.temp.Formdesignquery order by id" queryout E:\test.sql -c -T'



/*  6
	Activity Name : EST_To_Execute_SQL_File_On_Target
	Activity Type : Execute SQL Task
	Purpose : To execute test.sql script on S1 DB to copy design and delete entries from Temp.Formdesignquery
*/
-- Query
EXEC master..xp_CMDShell 'sqlcmd -S  AZ-VDI-D1-244 -d eBS_AHP_PROD -i E:\\test.sql -x'
delete from temp.Formdesignquery








-- To extract DB name and Server name from connectionstring

-- To Get The ServerName/DataSource From Connection String
declare @ConStr nvarchar(500)
declare @DataSource nvarchar(500)
set @ConStr = 'Data Source=AZ-VDI-D1-244;User ID=sa;Password=sa@123;Initial Catalog=eBS4_INT_QA2;Persist Security Info=True;Application Name=SSIS-Package1-{32A90FC6-368B-4397-9F27-E07C946C547E}AZ-VDI-D1-244.eMS_STD_QA.sa;'

select @DataSource = left(@ConStr,charindex(';', @ConStr)-1) 
select SUBSTRING(@DataSource,CHARINDEX('=', @DataSource)+1,len(@DataSource))

-- TO Get The DataBase Name From Connection String
declare @ConStr nvarchar(500)
declare @Catalog nvarchar(500)
declare @Index int
set @ConStr = 'Data Source=AZ-VDI-D1-244;User ID=sa;Password=sa@123;Initial Catalog=eBS4_INT_QA2;Persist Security Info=True;Application Name=SSIS-Package1-{32A90FC6-368B-4397-9F27-E07C946C547E}AZ-VDI-D1-244.eMS_STD_QA.sa;'

select @Index = CHARINDEX('Catalog',@ConStr)
select @Catalog = left(@ConStr, CHARINDEX(';',@ConStr,@Index)-1)

select SUBSTRING(@Catalog,CHARINDEX('=', @Catalog,@Index)+1,len(@Catalog))