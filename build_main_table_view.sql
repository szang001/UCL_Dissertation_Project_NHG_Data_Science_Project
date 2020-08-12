CREATE VIEW dbo.ANALYSIS_TABLE_SKELETON_WIP_JOHN AS
WITH LINK_TCI AS 
    (SELECT [Tenancy Ref],[HOUSEHOLD REF], 
    	    [Start Date] AS tci_start_date, 
    	    [SUCCESSOR INDICATOR], 
    	    [END DATE] AS tci_end_date, 
    	    [Termination Reason], 
    	    [MAIN TENANT INDICATOR]
    FROM [TENANCY INSTANCES]
),

LINK_HHP AS
(
    SELECT LINK_TCI.*, 
    	   [HOUSEHOLD PERSONS].[Person Reference], 
    	   [HOUSEHOLD PERSONS].HOP_HOU_REFNO,
    	   [HOUSEHOLD PERSONS].[Relationship]
    FROM LINK_TCI
    INNER JOIN [HOUSEHOLD PERSONS] 
    ON LINK_TCI.[HOUSEHOLD REF]=[HOUSEHOLD PERSONS].[HOUSEHOLD REF] 
),

LINK_PARTIES AS
(
    SELECT LINK_HHP.*, 
           [PARTIES].[DATE OF BIRTH] AS date_of_birth, 
	   [PARTIES].[Language (written)] AS Language, 
	   [PARTIES].[Gender],
           [PARTIES].[Nationality], 
	   [PARTIES].[DISABLED], 
	   [PARTIES].[OAP], 
	   [PARTIES].[Marital Status],
           [PARTIES].[Ethnic Origin], 
	   [PARTIES].[Sexual Orientation],
	   [PARTIES].[AT RISK INDICATOR]
    FROM LINK_HHP
    INNER JOIN [PARTIES] 
    ON LINK_HHP.[Person Reference]=[PARTIES].[Person Reference]
),

LINK_ACCREV AS
(
    SELECT LINK_PARTIES.*, 
    	   [REVENUE ACCOUNTS].[Account Number], 
	   [REVENUE ACCOUNTS].[Account Start Date] 
    FROM  LINK_PARTIES
    INNER JOIN [REVENUE ACCOUNTS] 
    ON [REVENUE ACCOUNTS].[Tenancy Ref] = LINK_PARTIES.[Tenancy Ref]
    WHERE ([Account Type]='REN')
),

TAB_HB AS
(
    SELECT DISTINCT [HB HISTORY].[Account Number] 
    FROM LINK_ACCREV
    INNER JOIN [HB HISTORY] 
    ON LINK_ACCREV.[Account Number] = [HB HISTORY].[Account Number]
),

MERGE_HB AS
(
    SELECT LINK_ACCREV.*, 
    	   CASE WHEN TAB_HB.[Account Number] IS NULL THEN 0 ELSE 1 END AS had_HB
    FROM LINK_ACCREV
    LEFT JOIN TAB_HB 
    ON (LINK_ACCREV.[Account Number] = TAB_HB.[Account Number])
),

MERGE_TCY AS
(
    SELECT MERGE_HB.*, 
    	   [TENANCIES].[Tenure], 
	   [TENANCIES].[STATUS] AS tcy_status, 
	   [TENANCIES].[Start Date] AS tcy_start_date, 
	   [TENANCIES].[Ended Date] AS tcy_ended_date, 
	   [TENANCIES].[ACTUAL END DATE] AS tcy_actual_end_date
    FROM MERGE_HB
    LEFT JOIN [TENANCIES] 
    ON MERGE_HB.[Tenancy Ref]=[TENANCIES].[Tenancy Ref]
),

MERGE_PROP AS
(
	SELECT MERGE_TCY.*, 
	       [TENANCY HOLDINGS].[NG Database Internal Property Ref], 
	       [TENANCY HOLDINGS].[START DATE], 
	       [TENANCY HOLDINGS].[End Date], 
	       [TENANCY HOLDINGS].[Account Number] AS tcy_account_number_check
	FROM MERGE_TCY
	LEFT JOIN [TENANCY HOLDINGS] 
	ON MERGE_TCY.[Tenancy Ref]=[TENANCY HOLDINGS].[Tenancy Ref]
),

LINK_ADDR AS
(
	SELECT MERGE_PROP.*, 
	       [ADDRESS USAGES].[ADDRESS REFNO]
	FROM MERGE_PROP
	LEFT JOIN [ADDRESS USAGES] 
	ON MERGE_PROP.[NG Database Internal Property Ref]=[ADDRESS USAGES].[NG Database Internal Property Ref]
),

POSTCODE_INFO AS
(
	SELECT LINK_ADDR.*, 
	       [ADDRESSES].POSTCODE
	FROM LINK_ADDR
	LEFT JOIN [ADDRESSES] 
	ON LINK_ADDR.[ADDRESS REFNO]=[ADDRESSES].[ADDRESS REFNO]
),

GDN_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [PROPERTY ELEMENTS].[Element Code]
	FROM [PROPERTY ELEMENTS] 
	WHERE [PROPERTY ELEMENTS].[Element Code]='GDN'
),

LINK_GDN AS
(
	SELECT POSTCODE_INFO.*, 
	       CASE WHEN GDN_INFO.[Element Code]='GDN' THEN 1 ELSE 0 END AS has_garden
	FROM POSTCODE_INFO
	LEFT JOIN GDN_INFO 
	ON POSTCODE_INFO.[NG Database Internal Property Ref]=GDN_INFO.[NG Database Internal Property Ref] 
),

BED_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [PROPERTY ELEMENTS].[Element Code], 
	       [PROPERTY ELEMENTS].[Element Numeric Value] AS n_beds
	FROM [PROPERTY ELEMENTS] 
	WHERE [PROPERTY ELEMENTS].[Element Code]='BED'
),

LINK_BED AS
(
	SELECT LINK_GDN.*, 
	       BED_INFO.n_beds
	FROM LINK_GDN
	LEFT JOIN BED_INFO 
	ON LINK_GDN.[NG Database Internal Property Ref]=BED_INFO.[NG Database Internal Property Ref] 
),

HCAT_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [PROPERTY ELEMENTS].[Element Code], 
	       [PROPERTY ELEMENTS].[Attribute Code] AS housing_category,
	       [PROPERTY ELEMENTS].[Start Date],
	       [PROPERTY ELEMENTS].[Element End Date]
	FROM [PROPERTY ELEMENTS] 
	WHERE [PROPERTY ELEMENTS].[Element Code]='HCAT'
),

LINK_HCAT AS
(
	SELECT LINK_BED.*, 
	       HCAT_INFO.housing_category, 
	       HCAT_INFO.[Start Date] AS hcat_start_date,
	       HCAT_INFO.[Element End Date] AS hcat_end_date
	FROM LINK_BED
	LEFT JOIN HCAT_INFO 
	ON LINK_BED.[NG Database Internal Property Ref]=HCAT_INFO.[NG Database Internal Property Ref] 
),

MAN_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS managed_by, 
	       [Start Date] AS managed_by_start_date, 
	       [Element End Date] AS managed_by_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='MAN' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL)
),

LINK_MAN AS
(
	SELECT LINK_HCAT.*, 
	       MAN_INFO.managed_by, 
	       MAN_INFO.managed_by_start_date,
	       MAN_INFO.managed_by_end_date
	FROM LINK_HCAT
	LEFT JOIN MAN_INFO 
	ON LINK_HCAT.[NG Database Internal Property Ref]=MAN_INFO.[NG Database Internal Property Ref] 
),

PBC_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS purpose_built	
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='PBC' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL)
),

LINK_PBC AS
(
	SELECT LINK_MAN.*, 
	       PBC_INFO.purpose_built
	FROM LINK_MAN
	LEFT JOIN PBC_INFO
	ON LINK_MAN.[NG Database Internal Property Ref]=PBC_INFO.[NG Database Internal Property Ref]
),

SHA_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS exclusivity, 
	       [Start Date] AS exclusivity_start_date, 
	       [Element End Date] AS exclusivity_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='SHA' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL)
),

LINK_SHA AS
(
	SELECT LINK_PBC.*,	
	       SHA_INFO.exclusivity, 
	       SHA_INFO.exclusivity_start_date, 
	       SHA_INFO.exclusivity_end_date
	FROM LINK_PBC
	LEFT JOIN SHA_INFO
	ON LINK_PBC.[NG Database Internal Property Ref]=SHA_INFO.[NG Database Internal Property Ref]
),

ATB_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS atb_pilot, 
	       [Start Date] AS atb_pilot_start_date, 
	       [Element End Date] AS atb_pilot_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='ATB' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
	AND [Attribute Code]='CUR'
),

LINK_ATB AS
(
	SELECT LINK_SHA.*, 
	       ATB_INFO.atb_pilot, 
	       ATB_INFO.atb_pilot_start_date, 
	       ATB_INFO.atb_pilot_end_date
	FROM LINK_SHA
	LEFT JOIN ATB_INFO 
	ON LINK_SHA.[NG Database Internal Property Ref]=ATB_INFO.[NG Database Internal Property Ref]
),

RTYP_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS rent_regime, 
	       [Start Date] AS rent_regime_start_date, 
	       [Element End Date] AS rent_regime_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='RTYP' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_RTYP AS
(
	SELECT LINK_ATB.*, 
	       RTYP_INFO.rent_regime, 
	       RTYP_INFO.rent_regime_start_date, 
	       RTYP_INFO.rent_regime_end_date
	FROM LINK_ATB
	LEFT JOIN RTYP_INFO
	ON LINK_ATB.[NG Database Internal Property Ref]=RTYP_INFO.[NG Database Internal Property Ref]
),

FLRB_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS bottom_floor, 
	       [Start Date] AS bottom_floor_start_date, 
	       [Element End Date] AS bottom_floor_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='FLRB' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_FLRB AS
(
	SELECT LINK_RTYP.*, 
	       FLRB_INFO.bottom_floor, 
	       FLRB_INFO.bottom_floor_start_date, 
	       FLRB_INFO.bottom_floor_end_date
	FROM LINK_RTYP
	LEFT JOIN FLRB_INFO
	ON LINK_RTYP.[NG Database Internal Property Ref]=FLRB_INFO.[NG Database Internal Property Ref]
),

FLRT_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS top_floor, 
	       [Start Date] AS top_floor_start_date, 
	       [Element End Date] AS top_floor_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='FLRT' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_FLRT AS
(
	SELECT LINK_FLRB.*, 
	       FLRT_INFO.top_floor, 
	       FLRT_INFO.top_floor_start_date, 
	       FLRT_INFO.top_floor_end_date
	FROM LINK_FLRB
	LEFT JOIN FLRT_INFO
	ON LINK_FLRB.[NG Database Internal Property Ref]=FLRT_INFO.[NG Database Internal Property Ref]
),

LPT_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS letting_type	
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='LPT' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_LPT AS
(
	SELECT LINK_FLRT.*, 
	       LPT_INFO.letting_type
	FROM LINK_FLRT
	LEFT JOIN LPT_INFO
	ON LINK_FLRT.[NG Database Internal Property Ref]=LPT_INFO.[NG Database Internal Property Ref]
),

CH_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS central_heating, 
	       [Start Date] AS central_heating_start_date, 
	       [Element End Date] AS central_heating_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='CH' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_CH AS
(
	SELECT LINK_LPT.*, 
	       CH_INFO.central_heating, 
	       CH_INFO.central_heating_start_date, 
	       CH_INFO.central_heating_end_date
	FROM LINK_LPT
	LEFT JOIN CH_INFO
	ON LINK_LPT.[NG Database Internal Property Ref]=CH_INFO.[NG Database Internal Property Ref] 
),

ADAP_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS adapted_prop, 
	       [Start Date] AS adapted_prop_start_date, 
	       [Element End Date] AS adapted_prop_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='ADAP' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_ADAP AS
(
	SELECT LINK_CH.*, 
	       ADAP_INFO.adapted_prop, 
	       ADAP_INFO.adapted_prop_start_date, 
	       ADAP_INFO.adapted_prop_end_date
	FROM LINK_CH
	LEFT JOIN ADAP_INFO
	ON LINK_CH.[NG Database Internal Property Ref]=ADAP_INFO.[NG Database Internal Property Ref] 
),

EQUI_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Element Numeric Value] AS equity, 
	       [Start Date] AS equity_start_date, 
	       [Element End Date] AS equity_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='EQUI' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_EQUI AS
(
	SELECT LINK_ADAP.*, 
	       EQUI_INFO.equity, 
	       EQUI_INFO.equity_start_date, 
	       EQUI_INFO.equity_end_date
	FROM LINK_ADAP
	LEFT JOIN EQUI_INFO
	ON LINK_ADAP.[NG Database Internal Property Ref]=EQUI_INFO.[NG Database Internal Property Ref]
),

AREA_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Element Numeric Value] AS area_sqm, 
	       [Start Date] AS area_sqm_start_date, 
	       [Element End Date] AS area_sqm_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='AREA' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_AREA AS
(
	SELECT LINK_EQUI.*, 
	       AREA_INFO.area_sqm, 
	       AREA_INFO.area_sqm_start_date, 
	       AREA_INFO.area_sqm_end_date
	FROM LINK_EQUI
	LEFT JOIN AREA_INFO
	ON LINK_EQUI.[NG Database Internal Property Ref]=AREA_INFO.[NG Database Internal Property Ref]
),

DG_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS window_glazing	
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='DG' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_DG AS
(
	SELECT LINK_AREA.*, 
	       DG_INFO.window_glazing
	FROM LINK_AREA
	LEFT JOIN DG_INFO
	ON LINK_AREA.[NG Database Internal Property Ref]=DG_INFO.[NG Database Internal Property Ref]
),

PAR_INFO AS
(
	SELECT [NG Database Internal Property Ref], 
	       [Attribute Code] AS parking, 
	       [Start Date] AS parking_start_date, 
	       [Element End Date] AS parking_end_date
	FROM [PROPERTY ELEMENTS]
	WHERE [Element Code]='PAR' 
	AND ([Element End Date]>'2011-01-01' OR [Element End Date] IS NULL) 
),

LINK_PAR AS
(
	SELECT LINK_DG.*, 
	       PAR_INFO.parking, 
	       PAR_INFO.parking_start_date, 
	       PAR_INFO.parking_end_date
	FROM LINK_DG
	LEFT JOIN PAR_INFO
	ON LINK_DG.[NG Database Internal Property Ref]=PAR_INFO.[NG Database Internal Property Ref]
)

SELECT * 
FROM LINK_PAR 
WHERE ([Tenancy Ref] IS NOT NULL 
AND [MAIN TENANT INDICATOR]='Y' 
AND [Tenancy Ref] NOT IN (13410, 33535, 4918, 3550 ))
