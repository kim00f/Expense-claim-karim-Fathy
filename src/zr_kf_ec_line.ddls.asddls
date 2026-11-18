@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS FOR LINE'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_KF_EC_LINE as select from ZKF_EC_LINE
association to parent ZR_KF_EC_CLAIM as _claim on $projection.claim_uuid = _claim.claim_uuid

composition [0..*] of ZR_KF_EC_RECEIPT as _RECEIPT 
{
    key line_uuid ,
    claim_uuid ,
    line_number,
    expense_date ,
    category ,
    description,
    @Semantics.amount.currencyCode: 'currency_code'
    amount ,
    currency_code ,
    receipt_required,
    number_of_receipts,
    _RECEIPT,
    _claim // Make association public
}
