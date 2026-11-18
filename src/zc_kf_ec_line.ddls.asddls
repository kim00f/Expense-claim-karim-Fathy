@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection line'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_KF_EC_LINE as projection on ZR_KF_EC_LINE
{
    key line_uuid,
    claim_uuid,
    line_number,
    expense_date,
    
    @Consumption.valueHelpDefinition: [
      {
        entity: {
          name: 'ZI_KF_EC_CATEGORY_VH',
          element: 'Category'
        },
        distinctValues: true
      }
    ]
    category,
    description,
    @Semantics.amount.currencyCode: 'currency_code'
    amount,
    currency_code,
    receipt_required,
    number_of_receipts,
    /* Associations */
    _claim : redirected to parent ZC_KF_EC_CLAIM,
    _RECEIPT : redirected  to composition child ZC_KF_EC_RECEIPT
}
