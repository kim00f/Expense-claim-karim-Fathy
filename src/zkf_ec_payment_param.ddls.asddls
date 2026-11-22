@EndUserText.label: 'Payment Parameters'

define abstract entity ZKF_EC_PAYMENT_PARAM
{
  @EndUserText.label: 'Payment Reference'
  payment_reference : abap.char(50);

  @EndUserText.label: 'Payment Date'
  payment_date : abap.dats;
}
