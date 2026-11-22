@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root  view entity ZC_KF_EC_CLAIM 
provider contract transactional_query
 as projection on ZR_KF_EC_CLAIM
{
    key claim_uuid,
    claim_number,
    employee_name,
    trip_purpose,
    @Consumption.valueHelpDefinition: [
  {
    entity: {
      name: 'I_CountryText',
      element: 'Country'
    }
  }
]
destination_country,
    
    trip_start_date,
    trip_end_date,
    @Semantics.amount.currencyCode: 'currency_code'
    total_amount,
    @Consumption.valueHelpDefinition: [
  {
    entity: {
      name: 'I_CurrencyStdVH',
      element: 'Currency'
    }
  }
]
    currency_code,
    status,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_KF_EC_STATUS_CRIT'
    virtual status_criticality : abap.int1,
    submitted_on,
    decision_date,
    rejection_reason,
    payment_reference,
    payment_date,
    created_by,
    created_at,
    last_changed_by,
    last_changed_at,
    local_last_changed_at,
    
    /* Associations */
    _line : redirected to composition child ZC_KF_EC_LINE
}
