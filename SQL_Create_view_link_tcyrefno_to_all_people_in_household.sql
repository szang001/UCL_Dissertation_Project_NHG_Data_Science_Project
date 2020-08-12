/* This SQL builds a table linking the tenancy reference number to all people in the household. 

Process:
Inner join [Total Tenents] with [Parties] and establish move-in and move-out dates by cleaning date information and date of birth.

Sub querys:
[Total_Tenants_Dates_Cleaned]:
Cases where hop_start_date > tcy_act_end_date imply that tenant moves in after tenancy has closed. Throw out these cases
Remove only slightly problematic row in [Total Tenents]: tcy_refno Ref = 178537.0, hop_start_date = 2018-09-19, Person Reference=277418.0 (row no = 143559) hop_start_date is in the future, so is surely a typo. Threw this person out as only appears once in Total Tenants table

[Total_Tenants_move_dates]: Determing move in and move out dates of each tenant using [hop_start/end_date] and [tcy_act_start/end_date]

[Parties_reduced]: Select only relevant columns of Parties table

[TT_Parties_joined]: join Total Tenents and Parties tables

[DOB_nulls_removed]: Remove all tenancies which have one or more person with a null date of birth (this reduces tenancies from 70895 to 51709)

[TT_Parties_DOB_cleaned]: Clean up tenancy move in and out dates which don't agree with date of birth of tenant (e.g. tenant is born after move in date)

*/



WITH [Total_Tenants_Dates_Cleaned] AS 
(
SELECT [tcy_refno],[hou_refno],[tin_main_tenant_ind], [tcy_act_start_date],[tcy_act_end_date],[hop_start_date],[hop_end_date],[Person Reference]
FROM [TOTAL TENENTS]
WHERE [hop_start_date] IN
    (CASE WHEN [tcy_act_end_date] IS NULL OR [hop_start_date] < [tcy_act_end_date] THEN
        [hop_start_date] 
    END)
AND [Person Reference] NOT IN (277418.0)
),

[Total_Tenants_move_dates] AS
(
    SELECT [tcy_refno],[hou_refno],[tin_main_tenant_ind],
    
    (CASE WHEN [hop_start_date] > [tcy_act_start_date] THEN
        [hop_start_date] 
    ELSE [tcy_act_start_date]
    END) AS move_in_date,
    
    (CASE WHEN [hop_end_date] IS NOT NULL AND [tcy_act_end_date] IS NOT NULL THEN
        (CASE WHEN  [hop_end_date] < [tcy_act_end_date] THEN
            [hop_end_date]
        ELSE
            [tcy_act_end_date]
        END)
    ELSE 
        (CASE WHEN [hop_end_date] IS NULL AND [tcy_act_end_date] IS NOT NULL THEN
            [tcy_act_end_date]
        ELSE 
            (CASE WHEN [hop_end_date] IS NOT NULL AND [tcy_act_end_date] IS NULL THEN
                [hop_end_date]
            ELSE
                (CASE WHEN [hop_end_date] IS NULL AND [tcy_act_end_date] IS NULL THEN
                    [tcy_act_end_date]
                END)
            END)
        END)
    END) AS move_out_date,
    
    [Person Reference]
    FROM [Total_Tenants_Dates_Cleaned]
),

[Parties_reduced] AS
(
    SELECT 
    [Person Reference],[DATE OF BIRTH],[Language (written)],[Gender], [Nationality],[DISABLED],
    [OAP], [Marital Status], [Ethnic Origin], [AT RISK INDICATOR], [Sexual Orientation]
    FROM [PARTIES]
),

[TT_Parties_joined] AS
(
SELECT [Total_Tenants_move_dates].[tcy_refno], [Total_Tenants_move_dates].[hou_refno], 
[Total_Tenants_move_dates].[tin_main_tenant_ind], [Total_Tenants_move_dates].[move_in_date],
[Total_Tenants_move_dates].[move_out_date],
[Parties_reduced].*
FROM [Total_Tenants_move_dates]
INNER JOIN [Parties_reduced] ON [Parties_reduced].[Person Reference] = [Total_Tenants_move_dates].[Person Reference]
),

[DOB_nulls_removed] AS
(
SELECT * FROM 
    (
    SELECT *, 
    COUNT( IIF([DATE OF BIRTH] IS NULL, 1, NULL) ) OVER(PARTITION BY [tcy_refno] ) AS cnt_nulls
    FROM [TT_Parties_joined]
    ) AS t
WHERE t.cnt_nulls = 0    
),

[TT_Parties_DOB_cleaned] AS
(
SELECT [tcy_refno], [hou_refno], [tin_main_tenant_ind],  
    (CASE WHEN [DATE OF BIRTH] > [move_in_date] THEN
        (CASE WHEN [DATE OF BIRTH] > [move_out_date] THEN
            NULL
        ELSE 
            [DATE OF BIRTH]
        END)
    ELSE 
        [move_in_date]
    END) 
AS [move_in_date],
[move_out_date],[Person Reference], [DATE OF BIRTH],[Language (written)],[Gender], [Nationality],[DISABLED],
[OAP], [Marital Status], [Ethnic Origin], [AT RISK INDICATOR], [Sexual Orientation]
FROM [DOB_nulls_removed]
)

SELECT * FROM [TT_Parties_DOB_cleaned] WHERE [move_in_date] IS NOT NULL
ORDER BY [tcy_refno] 