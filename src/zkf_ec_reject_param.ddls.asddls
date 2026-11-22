@EndUserText.label: 'Reject Claim Parameters'

define abstract entity ZKF_EC_REJECT_PARAM
{
  @EndUserText.label: 'Rejection Reason'
  @UI.multiLineText: true
  rejection_reason : abap.char(120);
}
