# R
caropetas de codigos en R

echo "# abner" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/abnerlugo1/abner.git
git push -u origin main





with 
    cur_ciblage AS 
    ( select a.product_id as product_target_id, p.product_name, a.account_id, b.territory_id, a.rx_segment segment, b.start_day_id start_date_id, b.end_day_id end_date_id, cast(b.product_activity_goal as integer) obj, cast(b.product_activity_actual as integer) real, a.orgunit
      from CRMF.d_product_metrics a 
           inner join CRMF.D_PRODUCT_CATALOG p on p.product_catalog_id = a.product_id
           inner join CRMF.f_mc_cycle_plan_detail b on a.account_id = b.account_id and a.product_id = b.product_catalog_id and b.product_activity_goal > 0 and b.deleted_ind = 0 and to_date(b.END_DAY_ID, 'yyyyMMdd') >= current_date()
      where a.rx_segment in ('A', 'B', 'C', 'D', 'E') and a.deleted_ind = 0
    ),
    cur_cibles AS 
    ( select distinct a.product_id as product_target_id, p.product_name, a.orgunit
      from CRMF.d_product_metrics a 
           inner join CRMF.D_PRODUCT_CATALOG p on p.product_catalog_id = a.product_id
           inner join CRMF.f_mc_cycle_plan_detail b on a.account_id = b.account_id and a.product_id = b.product_catalog_id and b.product_activity_goal > 0 and b.deleted_ind = 0 and to_date(b.END_DAY_ID, 'yyyyMMdd') >= current_date()
      where a.rx_segment in ('A', 'B', 'C', 'D', 'E') and a.deleted_ind = 0
    ),
    cur_account as
    ( select distinct A.account_id, ac.account_is_person_ind, ac.external_aid, ac.SOURCE_ACCOUNT_AID, ac.RX_STATUS, ac.SPECIALTY_1
      from 
      ( select distinct account_id from CRMF.d_account where rx_gigya_id is not null
        union all
        select distinct account_id from CRMF.f_mc_consent
        union all
        select distinct account_id from CRMF.d_product_metrics
        union all
        select distinct account_id from CRMF.f_sent_email where to_date(ACTIVITY_DATE_ID, 'yyyyMMdd') BETWEEN add_months(current_date(), -12) AND current_date()-- période sur 24mois
        union all
        select distinct account_id from CRMF.f_call_summary where to_date(LOCAL_CALL_DATE_ID, 'yyyyMMdd') BETWEEN add_months(current_date(), -12) AND current_date()-- période sur 24mois 
        union all
        select distinct attendee_id from CRMF.f_medical_event_attendee where to_date(CREATED_DATE_ID, 'yyyyMMdd') BETWEEN add_months(current_date(), -12) AND current_date()-- période sur 24mois 
        union all
        select distinct account_id from CRMF.SCD_ACCOUNT_CUSTOMER_JOURNEY
      ) A inner join CRMF.d_account ac on ac.account_id = A.account_id 
    ),

Ciblage as (select distinct c.product_target_id, a.external_aid, c.account_id, a.SOURCE_ACCOUNT_AID account_aid, c.territory_id, c.segment, 'Ciblé' rgpt_segment, c.start_date_id, c.end_date_id, c.obj, real,  a.account_is_person_ind hcp_ind, a.RX_STATUS, a.SPECIALTY_1,  product_name, c.orgunit 
    from cur_ciblage c 
         inner join cur_account a on a.account_id = c.account_id
    where  territory_id  <> -1

    union all

    select distinct ci.product_target_id, a.external_aid, a.account_id, a.SOURCE_ACCOUNT_AID account_aid, 0, 'HC', 'HC', concat(year(current_date()), '0101'), concat(year(current_date()), '1231'), 0, 0, a.account_is_person_ind, a.RX_STATUS, a.SPECIALTY_1, product_name, ci.orgunit
    from cur_account a, cur_cibles ci
    where not exists (select account_id from cur_ciblage c where c.account_id = a.account_id and c.product_target_id = ci.product_target_id)),

    ---Ajout meryle---
combined_data AS  (
     SELECT 
        vq.*,
        vr.RACE AS race_final,
        vr.rank
    FROM 
        france_uat.veeva_qualification vq
    LEFT JOIN 
        france_uat.veeva_race vr 
    ON 
        vq.account_id = vr.account_id 
        AND vq.product_id = vr.product_catalog_id
    WHERE  vr.rank = 1),

    ---Identification des doublons---
ranked_records AS (
    SELECT
    *,
    row_number() OVER (PARTITION BY account_id, product_id, race_final ORDER BY rank = 1) AS row_num
    FROM combined_data
),

---Enregistrememnt sans doublons---
filterd_records AS (
    SELECT
        *
FROM ranked_records
WHERE row_num = 1),

--- Check des doublons ---
duplicate_chek AS (
    SELECT
    account_id,
    product_id,
    race_final,
    COUNT(*) as cnt
    FROM filterd_records
    GROUP BY 
    account_id,
    product_id,
    race_final
    HAVING cnt > 1
)
    SELECT 
   c.account_id,
    c.account_aid, 
    c.EXTERNAL_AID, 
    HCP_ind, 
    RX_STATUS, 
    SPECIALTY_1,
    c.product_target_id,
    c.product_name,
    rgpt_segment,
    c.segment,
    obj, 
    real,
    c.TERRITORY_ID,
    s.field_force_name,
    date_format(to_date(start_date_id, 'yyyyMMdd'), 'dd/MM/yyyy') start_date_mccp,
    date_format(to_date(end_date_id, 'yyyyMMdd'), 'dd/MM/yyyy') end_date_mccp,
  RACE, 
  RACE_court,
    atlas_persona_id, 
    atlas_persona,
 --date_format(to_timestamp(last_modified_date, 'yyyy-MM-dd''T''HH:mm:ss.SSS'), 'dd/MM/yyyy') last_modified_date,
    c.orgunit

 FROM Ciblage c  
 left join filterd_records fr on c.account_id = fr.account_id and c.product_target_id = fr.product_id
 left join france_uat.veeva_secto s on c.territory_id = s.territory_id


