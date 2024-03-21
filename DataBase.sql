if DB_ID('ArtChat') Is NULL    
    Create DataBase ArtChat COLLATE Arabic_CI_AS
Go
if Not Exists(Select * From Sys.syslogins Where Name = 'WebApi')
    Create Login WebApi With Password = 'P@$$w0rd'
GO
Use ArtChat
Go
if Not Exists(Select * From Sys.sysusers Where Name = 'WebApi')
    Create User WebApi For Login WebApi
GO
if Object_ID('TBError') Is Null
    Create Table TBError(
        ID Int Identity(1,1) Primary Key,
        [Type] NVarchar(100),
        Msg VarChar(max),
        EDate DateTime
    )
Go
if OBJECT_ID('TBUser') Is Null
    Create Table TBUser(
        ID Int Primary Key,
        Family NVarChar(50),
        Mobile NVarChar(50),
        Email NVarChar(50),
        [Password] NVarChar(500),
        Token UNIQUEIDENTIFIER,
        TokenTime DateTime,
        Active TinyInt,
        [Admin] Tinyint,
        FcmToken NVarChar(max),
        [LastLogin] DATETIME,
        [LastIP]  NVarChar(100),
        RegDate DateTime,
        GoogleID NVarChar(300),
        GoogleToken NVarChar(max),
        GoogleImg NVarChar(max),
        CONSTRAINT IDX_User_Mobile UNIQUE(Mobile),
        CONSTRAINT IDX_User_Email UNIQUE(Email)
    )
Go
If Object_ID('TBSetting') Is Null
    Create Table TBSetting( 
        ID SmallInt Identity(1,1) Primary Key,
        [Key] NVarChar(30),
        [Value] NVarChar(100),
        IP NVarChar(20),
        Browser NvarChar(500),
        EDate DateTime,
        UserID Int
    )    
Go
Grant Select On TBSetting to WebApi
Go
if Object_ID('TBAttachment') Is Null
    Create Table TBAttachment(
        ID Int Identity(1,1) Primary Key,
        [FileName] VarChar(100),
        [Unique] NVarChar(6),
        Avatar TinyInt,
        UserID Int,
        EDate DateTime
    )
Go
Drop TRIGGER If Exists TRGDelAttachment
Go
CREATE TRIGGER TRGDelAttachment
ON TBAttachment
FOR DELETE
AS
    if Exists(Select * From deleted Where Avatar = 1)
        THROW 50001, 'cannot be deleted', 1
Go
if Not Exists(Select * From Sys.Syscolumns Where id = Object_ID('TBUser') And [Name] = 'FileID')
Begin
    Alter Table TBUser Add FileID Int FOREIGN Key References TBAttachment(ID)
End
Go
if Object_ID('TBChatGroup') Is Null
    Create Table TBChatGroup(
        ID SmallInt Primary Key,
        Title NVarChar(30) Not Null,
        [Owner] Int Foreign Key References TBUser(ID),
        FileID Int Foreign Key References TBAttachment(ID),
        [Date] DateTime Default GetDate()
    )
Go
if Object_ID('TBChatGroup_Member') Is Null
    Create Table TBChatGroup_Member(
        GrpID SmallInt Foreign Key References TBChatGroup(ID),
        [Member] Int Foreign Key References TBUser(ID),
        [JoinDate] DateTime Default GetDate(),
        Primary Key(GrpID,Member)
    )
Go
if Object_ID('TBChat') Is Null
    Create Table TBChat(
        ID BigInt Primary Key,
        [From] Int Not Null Foreign Key References TBUser(ID),
        [To] Int Foreign Key References TBUser(ID),
        [ToGroup] SmallInt Foreign Key References TBChatGroup(ID),
        [Msg] NVarChar(200) Not Null,
        [Seen] TinyInt,
        FileID Int Foreign Key References TBAttachment(ID),
        [Date] DateTime Default GetDate(),
        ReplyTo BigInt Foreign Key References TBChat(ID)
    )
Go
if Object_ID('TBChatLike') Is Null
    Create Table TBChatLike(
        ChatID BigInt Foreign Key References TBChat(ID),
        UserID Int Foreign Key References TBUser(ID),
        Kind TinyInt Not Null,
            --1=like
            --2=love
            --3=laugh
            --4=suprise
            --5=cry
            --6=dislike
        Primary Key(ChatID,UserID)
    )
Go
















Drop FUNCTION If Exists [dbo].[FNMiladiToShamsi]
Go
CREATE FUNCTION [dbo].[FNMiladiToShamsi](@MDate DateTime) 
RETURNS Varchar(10)
AS 
BEGIN 
    DECLARE @shYear AS INT ,@shMonth AS INT ,@shDay AS INT ,@intYY AS INT ,@intMM AS INT ,@intDD AS INT ,@Kabiseh1 AS INT ,@Kabiseh2 AS INT ,@d1 AS INT ,@m1 AS INT, @shMaah AS NVARCHAR(max),@shRooz AS NVARCHAR(max),@DayCnt AS INT
    DECLARE @DayDate AS NVARCHAR(max)

    SET @intYY = DATEPART(yyyy, @MDate)

    IF @intYY < 1000 SET @intYY = @intYY + 2000

    SET @intMM = MONTH(@MDate)
    SET @intDD = DAY(@MDate)
    SET @shYear = @intYY - 622
    SET @DayCnt = datepart(dw, '01/02/' + CONVERT(CHAR(4), @intYY))

    SET @m1 = 1
    SET @d1 = 1
    SET @shMonth = 10
    SET @shDay = 11

    IF ( ( @intYY - 1993 ) % 4 = 0 ) SET @shDay = 12

    WHILE ( @m1 != @intMM ) OR ( @d1 != @intDD )
    BEGIN

    SET @d1 = @d1 + 1
    SET @DayCnt = @DayCnt + 1

    IF ( ( @intYY - 1992 ) % 4 = 0) SET @Kabiseh1 = 1 ELSE SET @Kabiseh1 = 0

    IF ( ( @shYear - 1371 ) % 4 = 0) SET @Kabiseh2 = 1 ELSE SET @Kabiseh2 = 0

    IF 
    (@d1 = 32 AND (@m1 = 1 OR @m1 = 3 OR @m1 = 5 OR @m1 = 7 OR @m1 = 8 OR @m1 = 10 OR @m1 = 12))
    OR
    (@d1 = 31 AND (@m1 = 4 OR @m1 = 6 OR @m1 = 9 OR @m1 = 11))
    OR
    (@d1 = 30 AND @m1 = 2 AND @Kabiseh1 = 1)
    OR
    (@d1 = 29 AND @m1 = 2 AND @Kabiseh1 = 0)
    BEGIN
        SET @m1 = @m1 + 1
        SET @d1 = 1
    END

    IF @m1 > 12
    BEGIN
        SET @intYY = @intYY + 1
        SET @m1 = 1
    END
    
    IF @DayCnt > 7 SET @DayCnt = 1

    SET @shDay = @shDay + 1
    
    IF
    (@shDay = 32 AND @shMonth < 7)
    OR
    (@shDay = 31 AND @shMonth > 6 AND @shMonth < 12)
    OR
    (@shDay = 31 AND @shMonth = 12 AND @Kabiseh2 = 1)
    OR
    (@shDay = 30 AND @shMonth = 12 AND @Kabiseh2 = 0)
    BEGIN
        SET @shMonth = @shMonth + 1
        SET @shDay = 1
    END

    IF @shMonth > 12
    BEGIN
        SET @shYear = @shYear + 1
        SET @shMonth = 1
    END
    
    END

    IF @shMonth=1 SET @shMaah='فروردین'
    IF @shMonth=2 SET @shMaah='اردیبهشت'
    IF @shMonth=3 SET @shMaah='خرداد'
    IF @shMonth=4 SET @shMaah='تیر'
    IF @shMonth=5 SET @shMaah='مرداد'
    IF @shMonth=6 SET @shMaah='شهریور'
    IF @shMonth=7 SET @shMaah='مهر'
    IF @shMonth=8 SET @shMaah='آبان'
    IF @shMonth=9 SET @shMaah='آذر'
    IF @shMonth=10 SET @shMaah='دی'
    IF @shMonth=11 SET @shMaah='بهمن'
    IF @shMonth=12 SET @shMaah='اسفند'

    IF @DayCnt=1 SET @shRooz='شنبه'
    IF @DayCnt=2 SET @shRooz='یکشنبه'
    IF @DayCnt=3 SET @shRooz='دوشنبه'
    IF @DayCnt=4 SET @shRooz='سه‌شنبه'
    IF @DayCnt=5 SET @shRooz='چهارشنبه'
    IF @DayCnt=6 SET @shRooz='پنجشنبه'
    IF @DayCnt=7 SET @shRooz='جمعه'

    SET @DayDate = @shRooz + ' ' + LTRIM(STR(@shDay,2)) + ' ' + @shMaah + ' ' + STR(@shYear,4)
    --پنجشنبه 17 اردیبهشت 1394

    if @shMonth < 10
        if @ShDay < 10
            SET @DayDate = Cast(@shYear As VarChar)+'/0'+Cast(@shMonth As VarChar)+'/0'+Cast(@shDay As VarChar)
        Else
            SET @DayDate = Cast(@shYear As VarChar)+'/0'+Cast(@shMonth As VarChar)+'/'+Cast(@shDay As VarChar)
    Else if @ShDay < 10
            SET @DayDate = Cast(@shYear As VarChar)+'/'+Cast(@shMonth As VarChar)+'/0'+Cast(@shDay As VarChar)
        Else
            SET @DayDate = Cast(@shYear As VarChar)+'/'+Cast(@shMonth As VarChar)+'/'+Cast(@shDay As VarChar)

    Return @DayDate
End
Go
Grant Execute On [dbo].[FNMiladiToShamsi] to WebApi
Go
Drop Function If Exists dbo.toDate
Go
CREATE FUNCTION dbo.toDate (@DATE datetime)
RETURNS NVarChar(50)
WITH EXECUTE AS CALLER
AS
BEGIN
    if (Cast(@DATE As Date) = Cast(GetDate() as Date))
        Return 'امروز - '+SubString(Cast(Cast(@date As time) As VarChar), 1, 5);
    if (Cast(@DATE As Date) = Cast(GetDate()-1 as Date))
        Return 'دیروز - '+SubString(Cast(Cast(@date As time) As VarChar), 1, 5);
    if @date is NULL
        return null;
    return dbo.FNMiladiToShamsi(@date)+' - '+SubString(Cast(Cast(@date As time) As VarChar), 1, 5);
END;
GO
Drop Function If Exists dbo.dayName
Go
CREATE FUNCTION dbo.dayName(@DATE datetime)
RETURNS NVarChar(50)
WITH EXECUTE AS CALLER
AS
BEGIN
    Declare @Name NVarChar(100)
    Set @Name = DATEName(WEEKDAY, @DATE)

    Return  Case @Name 
        When 'Saturday' then 'شنبه'
        When 'Sunday' then 'یکشنبه'
        When 'Monday' then 'دوشنبه'
        When 'Tuesday' then 'سه شنبه'
        When 'Wednesday' then 'چهارشنبه'
        When 'Thursday' then 'پنج شنبه'
        When 'Friday' then 'جمعه'
    Else '' End
END;
Go
Drop Procedure If Exists PrcAuthenticate
Go
Create Procedure PrcAuthenticate(@IP NvarChar(20), @Browser NVarChar(500), @Email NVarChar(30), @Pass NVarChar(1000))
As
Begin
    Declare @UserID SMallInt
    Select @UserID = ID
    From TBUser
    Where Email = @Email And [Password] = @Pass

    if Exists(Select * From TBUser Where ID = @UserID And IsNull(Active,0)=0)
        THROW 50001, N'حساب کاربری شما غیرفعال شده است', 1
    Else if @UserID Is Not Null
    BEGIN
        Update TBUser
        Set Token=NEWID(),TokenTime=GETDATE(), [LastLogin] = GETDATE(), LastIP = @IP, LastBrowser = @Browser
        Where ID = @UserID

        Select A.id, A.family, A.mobile, A.email, A.token, A.active, A.[admin],
            A.[lastlogin], B.[Unique] Img, A.GoogleImg
        From TBUser A
            Left Outer Join TBAttachment B On A.FileID = B.ID
        Where A.ID = @UserID
    End
    ELSE    
        Throw 50001, N'پست الکترونیک/رمز عبور صحیح نمی باشد', 1
 End
GO
Grant Execute On PrcAuthenticate To WebApi
Go
Drop Procedure If Exists PrcRegister
Go
Create Procedure PrcRegister @IP NvarChar(20), @Browser NVarChar(500), @ID Int, @Family NVarChar(200), @Mobile NVarChar(30), @Email NVarChar(30), @Pass NVarChar(max), @Img NVarchar(30), @OnlyCheck TinyInt
As
Begin
    if Exists(Select * From TBUser Where Mobile = @Mobile And ID <> @ID)
        Throw 500001 , 'شماره همراه قبلا ثبت شده است', 1
    if Exists(Select * From TBUser Where Email = @Email And ID <> @ID)
        Throw 500001 , 'پست الکترونیک قبلا ثبت شده است', 1

    Declare @FileID Int
    Select @FileID = ID
    From  TBAttachment
    Where [Unique] = @Img    

    if @OnlyCheck = 1
        Select 'Success' Msg
    Else
    Begin
        if Exists(Select * From TBUser Where ID = @ID)
            Update TBUser 
            set Family=@Family, Mobile=@Mobile, [Password]=IsNull(@Pass, [Password]), FileID=@FileID--, Token=NEWID(), TokenTime=GETDATE()
            Where ID = @ID
        Else
        Begin
            Select @ID = Max(ID)
            From TBUser
            
            if @ID Is Null
                Set @ID = 100
            Set @ID = IsNull(@ID, 0)+1

            Insert Into TBUser(ID,Family,Mobile,Email,[Password],FileID,Token,TokenTime,Active,RegDate,LastLogin)
            VALUES(@ID, @Family, @Mobile, @Email, @Pass, @FileID, NEWID(), GETDATE(), 1, GETDATE(), GETDATE())
        End
        
        Select A.id, A.family, A.Mobile, A.email, A.token, A.active, A.[admin],
            A.[lastlogin], B.[Unique] Img, A.GoogleImg
        From TBUser A
            Left Outer Join TBAttachment B On A.FileID = B.ID
        Where A.ID = @ID
    End
End
Go
Grant Execute On PrcRegister To WebApi
Go
Drop Procedure If Exists PrcVerifyByToken
GO
Create procedure PrcVerifyByToken(@IP NvarChar(20), @Browser NVarChar(500), @Token UNIQUEIDENTIFIER)
AS
Begin 
    if Not Exists(Select * From TBUser Where Token = @Token)
        THROW 50001, N'شناسه کاربری شما قابل شناسایی نمی باشد', 1
    Else if Exists(Select * From TBUser Where Token = @Token And TokenTime+100 >= GetDate())
    BEGIN
        Update TBUser
        Set [LastLogin] = GETDATE(), LastIP = @IP, LastBrowser = @Browser
        WHERE Token = @Token

        Select A.id, A.family, A.mobile, A.email, A.token, A.active, A.[admin],
            A.[lastlogin], B.[Unique] Img, A.GoogleImg
        From TBUser A
            Left Outer Join TBAttachment B On A.FileID = B.ID
        Where A.Token = @Token
    End
    ELSE    
        Throw 50001, N'token is expired', 1
END 
Go 
Grant Execute On PrcVerifyByToken To WebApi
Go
Drop Procedure If Exists PrcVerifyByGoogle
Go
Create Procedure PrcVerifyByGoogle @IP NvarChar(20), @Browser NVarChar(500), @Email NVarChar(30), @Family NVarChar(200), @GoogleID NVarChar(100), @GoogleToken NVarChar(max), @GoogleImg NVarchar(max)
As
Begin
    if Exists(Select * From TBUser Where Email = @Email And IsNull(Active, 0) = 0)
        throw 50001, 'حساب کاربری شما توسط مدیر سیستم غیرفعال شده است', 1
    if Exists(Select * From TBUser Where Email = @Email)
        Update TBUser 
        set Family=@Family,GoogleID=@GoogleID, GoogleToken = @GoogleToken, GoogleImg=@GoogleImg, Token=NEWID(), TokenTime=GETDATE()
        Where Email = @Email
    Else
    Begin
        Declare @ID Int
        Select @ID = Max(ID)
        From TBUser
        Set @ID = IsNull(@ID, 0)+1

        Insert Into TBUser(ID,Family,Email,GoogleID,GoogleToken,GoogleImg,Token,TokenTime,Active,RegDate)
        VALUES(@ID, @Family, @Email, @GoogleID, @GoogleToken, @GoogleImg, NEWID(), GETDATE(), 1, GETDATE())
    End

    Select A.id, A.family, A.mobile, A.email, A.token, A.active, A.[admin],
        A.[lastlogin], B.[Unique] Img, A.GoogleImg
    From TBUser A
        Left Outer Join TBAttachment B On A.FileID = B.ID
    Where Email = @Email
End
Go
Grant Execute On PrcVerifyByGoogle To WebApi
Go
Drop Procedure If Exists PrcUsers
Go
Create Procedure PrcUsers @IP NVarChar(50), @Browser NVarChar(max), @Token UniqueIdentifier, @Family NVarChar(max)
As
Begin
	if Not Exists(Select * From TBUser Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1)
		Throw 50000, 'You session expired, please login again', 1
	Else if Not Exists(Select * From TBUser Where Token=@Token And IsNull([Admin], 0) = 1)
		Throw 50000, 'مجاز به دسترسی نمی باشید', 1
    Else
	    Select A.ID, A.Family, A.Mobile, A.Email, A.Active, A.[Admin], A.RegDate, A.FcmToken,
            B.[Unique] Img, A.GoogleImg
	    From TBUser A
            Left Outer Join TBAttachment B On A.FileID = B.ID
        Where Trim(@Family) = '' or A.Family Like '%'+@Family+'%'
        Order By A.RegDate Desc
End
Go
Grant Execute On PrcUsers To WebApi
Go
Drop Procedure If Exists PrcAddImage
Go
Create procedure PrcAddImage @Token UNIQUEIDENTIFIER, @Type NVarChar(30), @Id Int, @Idx Int, @File NVarChar(200)
As
Begin
    Declare @UserID Int, @Admin TinyInt, @AttachID Int, @ChatID BigInt
    Select @UserID=ID, @Admin = [admin]
    From TBUser
    Where token = @Token

    If @UserID Is Null 
        throw 500001, 'token not valid', 1
    If Not Exists(Select * From TBUser Where token=@Token And TokenTime+3 >= GetDate())
        throw 500001, 'token expire', 1
    if IsNull(@Admin, 0) = 0 And Not Exists(Select * From TBUser Where ID=@Id And Token=@Token)
        throw 500001, 'مجاز به دسترسی نمی باشید', 1

    
    Insert Into TBAttachment([FileName], [Unique], UserID, EDate)
    Values(@File, LEFT(NEWID(), 6), @UserID, GETDATE())
    Set @AttachID = @@IDENTITY

    if (@Type  = 'profile')
        Update TBUser
        Set FileID=@AttachID
        Where ID = @ID
    else if (@Type  = 'chat')
    Begin
        Select @ChatID = Max(ID)
        From TBChat 
        Set @ChatID = IsNull(@ChatID, 0)+1

        Insert into TBChat(ID,[From],[To],ToGroup,Msg,FileID,[Date])
        Values(@ChatID, @Id, Case When @Idx > 100 Then @Idx End, Case When @Idx < 100 Then @Idx End, 'Attachment', @AttachID, GetDate())
    End

    Select [Unique], @ChatID ChatID
    From TBAttachment
    Where ID = @AttachID
End
Go
Grant Execute On PrcAddImage To WebApi
Go
Drop Procedure If Exists PrcGetFileName
Go
Create Procedure PrcGetFileName @Unique NVarChar(6)
As
Begin
    Select [filename]
    From TBAttachment
    Where [Unique] = @Unique
End
Go
Grant Execute On PrcGetFileName To WebApi
Go
Drop Procedure If Exists PrcLogError
Go
Create Procedure PrcLogError @Type NVarChar(100), @Msg NVarChar(max)
As
Begin 
    Insert Into TBError([Type], Msg, EDate)
    Values(@Type, @Msg, GETDATE());

    Select 'Success' Msg
End
Go
Grant Execute On PrcLogError To WebApi
Go
Drop Procedure If Exists PrcUpdateFcmToken
Go
Create Procedure PrcUpdateFcmToken @FcmToken NVarChar(max), @Token UNIQUEIDENTIFIER
As
Begin
    Declare @UserID Int, @CmpID Int, @Admin TinyInt, @Family NVarChar(200)
    Select @UserID = A.ID
    From TBUser A
    Where A.token = @Token And IsNull(A.Active, 0)=1

    If @UserID Is Null
        throw 500001, 'token not valid', 1
    If Not Exists(Select * From TBUser Where token=@Token And TokenTime+3 >= GetDate())
        throw 500001, 'token expire', 1

    Update TBUser
    Set FcmToken = @FcmToken
    OUTPUT 'Success' Msg
    Where ID = @UserID
End
Go
Grant Execute On PrcUpdateFcmToken To WebApi
Go
Drop Procedure If Exists PrcFcmTokens
Go
Create Procedure PrcFcmTokens @Token UNIQUEIDENTIFIER, @Admin TinyInt
As
Begin
	if Not Exists(Select * From TBUser Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1)
		Throw 50000, 'You session expired, please login again', 1
    
    Select FcmToken
    From TBUser
    Where FcmToken Is Not Null And (@Admin = 0 Or IsNull([Admin], 0) = @Admin)
End
GO
Grant Execute On PrcFcmTokens To WebApi
Go
Drop Procedure If Exists PrcFriends
Go
Create Procedure PrcFriends @IP NVarChar(50), @Browser NVarChar(max), @Token UniqueIdentifier
As
Begin
    Declare @UserID Int
    Select @UserID = ID
    From TBUser 
    Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1

	if @UserID Is Null
		Throw 50000, 'You session expired, please login again', 1
    
    ;With Frnds As
    (
        Select Distinct ID
        From (
            Select Distinct A.[To] ID
            From TBChat A
            Where A.[From] = @UserID
            Union All
            Select Distinct A.[From]
            From TBChat A
            Where A.[To] = @UserID
        ) A        
    )
    Select A.ID, A.Title Family, Null Email, Null LastLogin, B.[Unique] Img,
        (Select Top 30 C.ID, C.[From], D.Family FromFamily, E.[Unique] FromImg, C.[ToGroup] [To], dbo.toDate(C.[Date]) [Time], C.Msg, C.Seen, F.[Unique],
            parsename(F.[FileName], 1) Extension,
            0 likes, 
            0 Liked,
            Sum(Case When G.[Kind]=1 Then 1 Else 0 End) Emojilike,
            Sum(Case When G.[Kind]=2 Then 1 Else 0 End) Emojilove,
            Sum(Case When G.[Kind]=3 Then 1 Else 0 End) Emojilaugh,
            Sum(Case When G.[Kind]=4 Then 1 Else 0 End) Emojisuprise,
            Sum(Case When G.[Kind]=5 Then 1 Else 0 End) Emojicry,
            Sum(Case When G.[Kind]=6 Then 1 Else 0 End) Emojidislike
        From TBChat C
            Inner Join TBUser D On C.[From] = D.ID
            Left Outer Join TBAttachment E On D.[FileID] = E.ID
            Left Outer Join TBAttachment F On C.[FileID] = F.ID
            Left Outer Join TBChatLike G On C.ID = G.ChatID
        Where [ToGroup] = A.ID
        Group By C.ID, C.[From], D.Family, E.[Unique], C.[ToGroup], C.[Date], C.Msg, C.Seen, F.[Unique], F.[FileName]
        Order by C.[Date] DESc For Json Path) chats
    From TBChatGroup A
        Left Outer Join TBAttachment B On A.FileID = B.ID
        Inner Join TBChatGroup_Member C On A.ID = C.GrpID
    Where  C.Member = @UserID
    Union All
    Select A.ID, A.Family, A.Email, dbo.toDate(A.LastLogin) LastLogin, B.[Unique] Img,
        (Select Top 30 C.ID, C.[From], D.Family FromFamily, E.[Unique] FromImg, C.[To], dbo.toDate(C.[Date]) [Time], C.Msg, C.Seen, F.[Unique],
            parsename(F.[FileName], 1) Extension,
            0 likes, 
            0 Liked,
            Sum(Case When G.[Kind]=1 Then 1 Else 0 End) Emojilike,
            Sum(Case When G.[Kind]=2 Then 1 Else 0 End) Emojilove,
            Sum(Case When G.[Kind]=3 Then 1 Else 0 End) Emojilaugh,
            Sum(Case When G.[Kind]=4 Then 1 Else 0 End) Emojisuprise,
            Sum(Case When G.[Kind]=5 Then 1 Else 0 End) Emojicry,
            Sum(Case When G.[Kind]=6 Then 1 Else 0 End) Emojidislike
        From TBChat C
            Inner Join TBUser D On C.[From] = D.ID
            Left Outer Join TBAttachment E On D.[FileID] = E.ID
            Left Outer Join TBAttachment F On C.[FileID] = F.ID
            Left Outer Join TBChatLike G On C.ID = G.ChatID
        Where ([From] = A.ID And [To] = @UserID) or ([From] = @UserID And [To] = A.ID) 
        Group By C.ID, C.[From], D.Family, E.[Unique], C.[To], C.[Date], C.Msg, C.Seen, F.[Unique], F.[FileName]
        Order by C.[Date] DESc For Json Path) chats
    From TBUser A
        Left Outer Join TBAttachment B On A.FileID = B.ID
        Inner Join Frnds C On A.ID = C.ID
    Where  A.Token <> @Token
End
Go
Grant Execute On PrcFriends To WebApi
Go
Drop Procedure If Exists PrcChat
GO
Create Procedure PrcChat @Token UniqueIdentifier, @From Int, @To Int, @Msg NVarChar(200)
As
Begin
	if Not Exists(Select * From TBUser Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1)
		Throw 50000, 'You session expired, please login again', 1

    Declare @ID BigInt
    Select @ID = Max(ID)
    From TBChat
    Set @ID = IsNull(@ID, 0)+1

    Insert Into TBChat(ID,[From], [To],ToGroup,Msg,[Date])
    Values(@ID, @From, Case when @To > 100 Then @To End, Case when @To < 100 Then @to End, @Msg, GETDATE())

    Select A.ID, A.[From], C.Family [FromFamily], IsNull(A.[To], A.ToGroup) [To], A.Msg, A.Seen,
        (
            SELECT ','+Cast([Member] as varchar) 
            FROM TBChatGroup_Member
            Where GrpID = A.[ToGroup]
            FOR XML PATH('')
        ) GrpMembers, B.FcmToken,
        Sum(Case When D.[Kind]=1 Then 1 Else 0 End) Emojilike,
        Sum(Case When D.[Kind]=2 Then 1 Else 0 End) Emojilove,
        Sum(Case When D.[Kind]=3 Then 1 Else 0 End) Emojilaugh,
        Sum(Case When D.[Kind]=4 Then 1 Else 0 End) Emojisuprise,
        Sum(Case When D.[Kind]=5 Then 1 Else 0 End) Emojicry,
        Sum(Case When D.[Kind]=6 Then 1 Else 0 End) Emojidislike
    From TBChat A
        Left Outer Join TBUser B On A.[To] = B.ID
        Left Outer Join TBUser C On A.[From] = C.ID
        Left Outer Join TBChatLike D On A.ID = D.ChatID
    Where  A.ID = @ID
    Group By A.ID, A.[From], C.Family, A.[To], A.ToGroup, A.Msg, A.Seen, B.FcmToken
End
Go
Grant Execute On PrcChat To WebApi
Go
Drop Procedure If Exists PrcSeenChat
Go
Create Procedure PrcSeenChat @from Int, @To Int
As
Begin
    Update TBChat
    Set [Seen]=1
    Where [From] = @from And [To] = @To
End
Go
Grant Execute On PrcSeenChat To WebApi
Go
Drop Procedure if Exists PrcChatByID
Go
Create Procedure PrcChatByID @ID BigInt
As
Begin
    Select C.ID, C.[From], D.Family FromFamily, E.[Unique] FromImg, IsNull(C.[To], C.ToGroup) [To], dbo.toDate(C.[Date]) [Time], C.Msg, C.Seen, F.[Unique],
        parsename(F.[FileName], 1) Extension,
        (
            SELECT ','+Cast([Member] as varchar) 
            FROM TBChatGroup_Member
            Where GrpID = C.[ToGroup]
            FOR XML PATH('')
        ) GrpMembers,
        (Select Count(*)  From string_split(C.Likes, ',')) likes, 
        0 Liked
    From TBChat C
        Inner Join TBUser D On C.[From] = D.ID
        Left Outer Join TBAttachment E On D.[FileID] = E.ID
        Left Outer Join TBAttachment F On C.[FileID] = F.ID
    Where C.ID = @ID
End
Go
Grant Execute On PrcChatByID To WebApi
Go
Drop Procedure If Exists PrcDelChat
Go
Create Procedure PrcDelChat @Token UniqueIdentifier, @ID BigInt
As
Begin
    Declare @UserID Int, @To Int, @ToGroup Int, @FileID Int
    Select @UserID = ID
    From TBUser 
    Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1
	
    if @UserID Is Null
		Throw 50000, 'You session expired, please login again', 1

    Select @To = [To], @ToGroup = ToGroup, @FileID = FileID
    From TBChat
    Where ID = @ID

    Delete TBChat
    Where ID = @ID
    Delete TBAttachment
    Where ID = @FileID

    if @To Is Not Null
        Select ','+Cast(@To As VarChar) As GrpMembers
    Else
        Select (SELECT ','+Cast([Member] as varchar) 
            FROM TBChatGroup_Member
            Where GrpID = @ToGroup
            FOR XML PATH('')
        ) As GrpMembers
End
Go
Grant Execute On PrcDelChat To WebApi
Go
Drop Procedure If Exists PrcFindFriends
Go
Create Procedure PrcFindFriends @IP NVarChar(50), @Browser NVarChar(max), @Token UniqueIdentifier, @Family NVarChar(100)
As
Begin
    Declare @UserID Int
    Select @UserID = ID
    From TBUser 
    Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1

	if @UserID Is Null
		Throw 50000, 'You session expired, please login again', 1
    
    Select A.ID, A.Family, A.Email, dbo.toDate(A.LastLogin) LastLogin, B.[Unique] Img
    From TBUser A
        Left Outer Join TBAttachment B On A.FileID = B.ID
    Where  A.Token <> @Token And (A.Family Like '%'+@Family+'%' or A.Mobile Like '%'+@Family+'%' or A.Email Like '%'+@Family+'%')
End
Go
Grant Execute On PrcFindFriends To WebApi
Go
Drop Procedure If Exists PrcLoadAvatars
Go
Create Procedure PrcLoadAvatars @IP NVarChar(50), @Browser NVarChar(max), @Token UniqueIdentifier
As
Begin
    Declare @UserID Int
    Select @UserID = ID
    From TBUser 
    Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1

	if @UserID Is Null
		Throw 50000, 'You session expired, please login again', 1
    
    Select [Unique]
    From TBAttachment
    Where Avatar = 1
End
Go
Grant Execute On PrcLoadAvatars To WebApi
Go
Drop Procedure If Exists PrcChatLike
Go
Create Procedure PrcChatLike @Token UniqueIdentifier, @chatID BigInt, @Kind TinyInt
As
Begin
    Declare @UserID Int, @Old TinyInt
    Select @UserID = ID
    From TBUser 
    Where Token=@Token And TokenTime+100 >= GetDate() And IsNull(Active, 0) = 1

	if @UserID Is Null
		Throw 50000, 'You session expired, please login again', 1

    Select @Old = [Kind]
    From TBChatLike
    Where ChatID = @ChatID And UserID = @UserID

    if Exists(Select * From TBChat Where ID = @ChatID)
        If @Old Is Null
            Insert Into TBChatLike(ChatID,UserID,[Kind])
            Values(@ChatID, @UserID, @kind)
        Else  if @Old = @Kind
            Delete TBChatLike
            Where ChatID = @ChatID And UserID = @UserID
        Else
            Update TBChatLike
            Set Kind = @Kind
            Where ChatID = @ChatID And UserID = @UserID
        
    Select A.ID,Sum(Case When D.[Kind]=1 Then 1 Else 0 End) [Kind1],
            Sum(Case When D.[Kind]=2 Then 1 Else 0 End) [Kind2],
            Sum(Case When D.[Kind]=3 Then 1 Else 0 End) [Kind3],
            Sum(Case When D.[Kind]=4 Then 1 Else 0 End) [Kind4],
            Sum(Case When D.[Kind]=5 Then 1 Else 0 End) [Kind5],
            Sum(Case When D.[Kind]=6 Then 1 Else 0 End) [Kind6],
        (
            SELECT ','+Cast([Member] as varchar) 
            FROM TBChatGroup_Member
            Where GrpID = A.[ToGroup]
            FOR XML PATH('')
        ) GrpMembers, A.[To], A.[From]
    From TBChat A
        Left Outer Join TBUser B On A.[To] = B.ID
        Left Outer Join TBUser C On A.[From] = C.ID
        Left Outer Join TBChatLike D On A.ID =  D.ChatID
    Where A.ID = @ChatID
    Group By A.ID, A.[To], A.[From], A.ToGroup
End
Go
Grant Execute On PrcChatLike To WebApi
Go