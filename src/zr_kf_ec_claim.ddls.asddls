@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS FOR CLAIM'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_KF_EC_CLAIM as select from zkf_ec_claim
composition [0..*] of  ZR_KF_EC_LINE as _line 
{
    key claim_uuid,
    claim_number ,
    employee_name ,
    trip_purpose ,
    destination_country ,
    trip_start_date ,
    trip_end_date ,
    @Semantics.amount.currencyCode : 'currency_code'
    total_amount ,
    currency_code ,
    status,
    submitted_on ,
    decision_date ,
    rejection_reason,
    payment_reference ,
    payment_date,
    @Semantics.user.createdBy: true
    created_by,
    @Semantics.systemDateTime.createdAt: true
    created_at ,
    @Semantics.user.lastChangedBy: true
    last_changed_by,
    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at ,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at ,
    
    
    _line // Make association public
}
